[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$GameRoot, [string]$SourcePath, [switch]$Worker, [int]$AnsiCodePage=0)
$ErrorActionPreference = 'Stop'
try {
    $GameRoot = (Resolve-Path -LiteralPath $GameRoot).ProviderPath
    if (-not $SourcePath) { $SourcePath = Join-Path $GameRoot 'Interface\xMacro\Runtime.lua' }
    $SourcePath = (Resolve-Path -LiteralPath $SourcePath).ProviderPath
    # kgui.dll imports its Lua API from engine_lua5.dll, not lua5.dll.
    $LuaDll = Join-Path $GameRoot 'engine_lua5.dll'
    if (-not (Test-Path -LiteralPath $LuaDll -PathType Leaf)) { throw 'NATIVE_LUA_DLL_MISSING: engine_lua5.dll' }
    $DllBytes = [IO.File]::ReadAllBytes($LuaDll)
    if ($DllBytes.Length -lt 64 -or [BitConverter]::ToUInt16($DllBytes,0) -ne 0x5A4D) { throw 'Invalid Lua DLL DOS header.' }
    $PeOffset = [BitConverter]::ToInt32($DllBytes,0x3C)
    if ($PeOffset -lt 0 -or $PeOffset + 6 -gt $DllBytes.Length -or [BitConverter]::ToUInt32($DllBytes,$PeOffset) -ne 0x4550) { throw 'Invalid Lua DLL PE header.' }
    $Machine = [BitConverter]::ToUInt16($DllBytes,$PeOffset+4)
    if ($Machine -eq 0x14C) { $TargetBits = 32 }
    elseif ($Machine -eq 0x8664) { $TargetBits = 64 }
    else { throw 'Unsupported Lua DLL architecture.' }
    if ([IntPtr]::Size * 8 -ne $TargetBits) {
        if ($Worker) { throw 'Native Lua worker bitness mismatch.' }
        if ($TargetBits -eq 32) { $ChildPath = Join-Path $env:WINDIR 'SysWOW64\WindowsPowerShell\v1.0\powershell.exe' }
        else { $ChildPath = Join-Path $env:WINDIR 'Sysnative\WindowsPowerShell\v1.0\powershell.exe' }
        if (-not (Test-Path -LiteralPath $ChildPath -PathType Leaf)) { throw 'Matching Windows PowerShell runtime unavailable.' }
        & $ChildPath -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -GameRoot $GameRoot -SourcePath $SourcePath -Worker -AnsiCodePage $AnsiCodePage
        exit $LASTEXITCODE
    }
    $Hasher = [Security.Cryptography.SHA256]::Create()
    try { $DllHash = [BitConverter]::ToString($Hasher.ComputeHash($DllBytes)).Replace('-', '') }
    finally { $Hasher.Dispose() }
    Write-Output ('NATIVE_LUA_DLL: ' + $LuaDll)
    Write-Output ('NATIVE_LUA_DLL_SHA256: ' + $DllHash)
    Write-Output ('NATIVE_LUA_BITS: ' + $TargetBits)
    [Environment]::CurrentDirectory = $GameRoot
    $DllLiteral = $LuaDll.Replace('"','""')
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class XMacroNativeLua {
 [DllImport("kernel32.dll", SetLastError=true)] private static extern int MultiByteToWideChar(uint page, uint flags, byte[] source, int size, IntPtr target, int capacity);
 public static byte[] ConvertAnsi(byte[] source, uint page) {
    int size=MultiByteToWideChar(page,0,source,source.Length,IntPtr.Zero,0);
    if(size==0) throw new InvalidOperationException("ANSI conversion failed");
    IntPtr wide=Marshal.AllocHGlobal(checked(size*2));
    try {
        if(MultiByteToWideChar(page,0,source,source.Length,wide,size)!=size) throw new InvalidOperationException("ANSI conversion failed");
        return System.Text.Encoding.UTF8.GetBytes(Marshal.PtrToStringUni(wide,size));
    } finally { Marshal.FreeHGlobal(wide); }
 }
 [DllImport(@"$DllLiteral", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr luaL_newstate();
 [DllImport(@"$DllLiteral", CallingConvention=CallingConvention.Cdecl)] public static extern int luaL_loadbuffer(IntPtr state, byte[] source, UIntPtr size, string name);
 [DllImport(@"$DllLiteral", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr lua_tolstring(IntPtr state, int index, ref UIntPtr size);
 [DllImport(@"$DllLiteral", CallingConvention=CallingConvention.Cdecl)] public static extern void lua_close(IntPtr state);
}
"@
    $State = [XMacroNativeLua]::luaL_newstate()
    if ($State -eq [IntPtr]::Zero) { throw 'Native Lua state allocation failed.' }
    try {
        $Source = [IO.File]::ReadAllBytes($SourcePath)
        Write-Output ('NATIVE_LUA_SOURCE: ' + $SourcePath + ' bytes=' + $Source.Length)
        # Match kgui's UTF-8 BOM branch before invoking its actual Lua parser.
        if ($Source.Length -ge 3 -and $Source[0] -eq 0xEF -and $Source[1] -eq 0xBB -and $Source[2] -eq 0xBF) {
            $WithoutBom = New-Object byte[] ($Source.Length-3)
            [Array]::Copy($Source,3,$WithoutBom,0,$WithoutBom.Length)
            $Source = $WithoutBom
            Write-Output 'NATIVE_SOURCE_ENCODING: UTF8_BOM (native loader bypasses ANSI conversion)'
        } elseif ($AnsiCodePage -gt 0 -and ($Source.Length -eq 0 -or $Source[0] -ne 0x1B)) {
            $Source = [XMacroNativeLua]::ConvertAnsi($Source,[uint32]$AnsiCodePage)
            Write-Output ('NATIVE_SOURCE_ENCODING: ANSI_TO_UTF8 cp=' + $AnsiCodePage)
        } else {
            Write-Output 'NATIVE_SOURCE_ENCODING: RAW (no BOM; native ANSI conversion not simulated)'
        }
        # Compile only: never call lua_pcall/lua_call or execute addon/game actions.
        $Code = [XMacroNativeLua]::luaL_loadbuffer($State,$Source,[UIntPtr]::new([UInt32]$Source.Length),'@Runtime.lua')
        if ($Code -eq 0) {
            Write-Output 'NATIVE_COMPILE_OK: parser accepted source; addon was NOT executed.'
        } else {
            $Length = [UIntPtr]::Zero
            $Pointer = [XMacroNativeLua]::lua_tolstring($State,-1,[ref]$Length)
            $Count = [Math]::Min([UInt64]$Length.ToUInt64(),4096)
            $ErrorBytes = New-Object byte[] ([int]$Count)
            if ($Count -gt 0) { [Runtime.InteropServices.Marshal]::Copy($Pointer,$ErrorBytes,0,[int]$Count) }
            Write-Output ('NATIVE_COMPILE_FAIL: code=' + $Code + ' ' + [Text.Encoding]::UTF8.GetString($ErrorBytes))
        }
    } finally { [XMacroNativeLua]::lua_close($State) }
    if ($Code -ne 0) { exit 2 }
} catch {
    Write-Output ('NATIVE_CHECK_ERROR: ' + $_.Exception.Message)
    exit 2
}
