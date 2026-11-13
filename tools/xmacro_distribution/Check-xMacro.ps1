[CmdletBinding()]
param([string]$GameRoot, [string]$ReportPath, [switch]$NoPrompt)
$ErrorActionPreference = 'Stop'
$Lines = New-Object 'System.Collections.Generic.List[string]'
function Write-ReportLine([string]$Value) {
    $Lines.Add($Value)
    Write-Output $Value
}
function Get-PayloadHash([string]$FilePath) {
    $Hasher = [Security.Cryptography.SHA256]::Create()
    $Stream = [IO.File]::OpenRead($FilePath)
    try { return [BitConverter]::ToString($Hasher.ComputeHash($Stream)).Replace('-', '') }
    finally { $Stream.Dispose(); $Hasher.Dispose() }
}
if (-not $ReportPath) { $ReportPath = Join-Path $PSScriptRoot 'xMacro-check.txt' }
$ResultCode = 0
try {
    Write-ReportLine 'XMACRO CHECK - installed files and native Lua parser'
    Write-ReportLine ('Time: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    $ManifestPath = Join-Path $PSScriptRoot 'xMacro-expected.json'
    $Expected = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $Roots = @()
    if ($GameRoot) {
        $Roots = @((Resolve-Path -LiteralPath $GameRoot).ProviderPath)
        Write-ReportLine 'Discovery: MANUAL PATH (running client path not verified)'
    } else {
        try {
            if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
                $Processes = @(Get-CimInstance Win32_Process -Filter "Name='jx3client.exe' OR Name='game.exe'")
            } else {
                [void][Reflection.Assembly]::LoadWithPartialName('System.Management')
                $ProcessQuery = New-Object System.Management.ManagementObjectSearcher("SELECT Name, ProcessId, ExecutablePath FROM Win32_Process WHERE Name='jx3client.exe' OR Name='game.exe'")
                try { $Processes = @($ProcessQuery.Get()) } finally { $ProcessQuery.Dispose() }
            }
            foreach ($GameProcess in $Processes) {
                if ($GameProcess.ExecutablePath) {
                    Write-ReportLine ('CLIENT PID=' + $GameProcess.ProcessId + ' EXE=' + $GameProcess.ExecutablePath)
                    $Roots += Split-Path -Parent $GameProcess.ExecutablePath
                } else {
                    Write-ReportLine ('CLIENT PID=' + $GameProcess.ProcessId + ' executable path unavailable')
                }
            }
        } catch { Write-ReportLine ('Process discovery unavailable: ' + $_.Exception.Message) }
        $Roots = @($Roots | Sort-Object -Unique)
        if ($Roots.Count -gt 0) { Write-ReportLine 'Discovery: RUNNING CLIENT executable path' }
    }
    if ($Roots.Count -eq 0) {
        if ($NoPrompt) { throw 'NO_CLIENT_PATH: open game first, or pass -GameRoot explicitly.' }
        Add-Type -AssemblyName System.Windows.Forms
        $Picker = New-Object System.Windows.Forms.OpenFileDialog
        $Picker.Title = 'Chon jx3client.exe hoac game.exe cua ban game dang choi'
        $Picker.Filter = 'Game client|jx3client.exe;game.exe'
        if ($Picker.ShowDialog() -ne 'OK') { throw 'NO_CLIENT_PATH: cancelled.' }
        $Roots = @(Split-Path -Parent $Picker.FileName)
        Write-ReportLine 'Discovery: MANUAL EXE (running client path not verified)'
    }
    foreach ($Root in $Roots) {
        Write-ReportLine ''
        Write-ReportLine ('GAME_ROOT: ' + $Root)
        $ClientFound = (Test-Path -LiteralPath (Join-Path $Root 'jx3client.exe') -PathType Leaf) -or
                       (Test-Path -LiteralPath (Join-Path $Root 'game.exe') -PathType Leaf)
        if (-not $ClientFound) {
            Write-ReportLine 'INVALID_ROOT: missing jx3client.exe/game.exe'
            $ResultCode = 2
            continue
        }
        $AddonRoot = Join-Path $Root 'Interface\xMacro'
        Write-ReportLine ('ADDON_ROOT: ' + $AddonRoot)
        $InfoPath = Join-Path $AddonRoot 'info.ini'
        if (Test-Path -LiteralPath $InfoPath -PathType Leaf) {
            $Info = [IO.File]::ReadAllText($InfoPath)
            $Version = [regex]::Match($Info, '(?im)^\s*version\s*=\s*(.*?)\s*$').Groups[1].Value
            Write-ReportLine ('INSTALLED_VERSION: ' + $Version)
            $Release = [regex]::Match($Info, '(?im)^\s*release\s*=\s*(.*?)\s*$').Groups[1].Value
            if ($Release) { Write-ReportLine ('INSTALLED_RELEASE: ' + $Release) }
            foreach ($Entry in [regex]::Matches($Info, '(?im)^\s*lua_\d+\s*=\s*(.*?)\s*$')) {
                Write-ReportLine ('NATIVE_ENTRY: ' + $Entry.Groups[1].Value)
            }
        } else { Write-ReportLine 'MISSING: Interface/xMacro/info.ini' }
        $Checked = 0
        $Bad = 0
        foreach ($Member in $Expected.PSObject.Properties) {
            if (-not $Member.Name.StartsWith('Interface/xMacro/', [StringComparison]::OrdinalIgnoreCase)) { continue }
            $Checked++
            $Target = Join-Path $Root $Member.Name
            if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) {
                Write-ReportLine ('MISSING: ' + $Member.Name)
                $Bad++
            } elseif ((Get-PayloadHash $Target) -ne $Member.Value) {
                Write-ReportLine ('DIFFERENT: ' + $Member.Name)
                $Bad++
            }
        }
        if ($Checked -eq 0) { throw 'Expected manifest contains no addon payload.' }
        if ($Bad -eq 0) {
            Write-ReportLine ('FILES_MATCH: ' + $Checked + ' files match expected manifest; this does not prove game loaded Lua.')
        } else {
            Write-ReportLine ('FILES_MISMATCH: ' + $Bad + '/' + $Checked)
            $ResultCode = 2
        }
        $NativeChecker = Join-Path $PSScriptRoot 'Check-NativeLua.ps1'
        if (Test-Path -LiteralPath $NativeChecker -PathType Leaf) {
            $NativeOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $NativeChecker -GameRoot $Root)
            $NativeCode = $LASTEXITCODE
            foreach ($NativeLine in $NativeOutput) { Write-ReportLine ([string]$NativeLine) }
            if ($NativeCode -ne 0) { $ResultCode = 2 }
        }
        foreach ($ProbeName in @('load_probe.jx3dat', 'load_probe_end.jx3dat')) {
            $ProbePath = Join-Path $AddonRoot $ProbeName
            if (Test-Path -LiteralPath $ProbePath -PathType Leaf) {
                $ProbeFile = Get-Item -LiteralPath $ProbePath
                $ProbeBytes = [IO.File]::ReadAllBytes($ProbePath)
                $Offset = 0
                if ($ProbeBytes.Length -ge 16 -and [Text.Encoding]::ASCII.GetString($ProbeBytes,0,4) -eq 'CNDK') { $Offset = 16 }
                $ProbeText = [Text.Encoding]::UTF8.GetString($ProbeBytes,$Offset,[Math]::Min(2048,$ProbeBytes.Length-$Offset)) -replace '[\x00-\x1F]', ' '
                Write-ReportLine ('LOADER_MARKER: ' + $ProbeName + ' [' + $ProbeFile.LastWriteTime + '] ' + $ProbeText)
            } else { Write-ReportLine ('LOADER_MARKER_MISSING: ' + $ProbeName) }
        }
        if ($env:LOCALAPPDATA) {
            $RelativeRoot = $Root -replace '^[A-Za-z]:[\\/]', ''
            $VirtualAddon = Join-Path (Join-Path $env:LOCALAPPDATA 'VirtualStore') (Join-Path $RelativeRoot 'Interface\xMacro')
            if (Test-Path -LiteralPath $VirtualAddon) {
                Write-ReportLine ('VIRTUALSTORE_CANDIDATE: ' + $VirtualAddon + ' (not proof this copy is active)')
            }
        }
        $LogRoot = Join-Path $Root 'logs'
        if (Test-Path -LiteralPath $LogRoot) {
            $LogFiles = @(Get-ChildItem -LiteralPath $LogRoot -Filter '*.log' -File -Recurse -ErrorAction SilentlyContinue)
            $ClientLogs = @($LogFiles | Where-Object { $_.Name -match '(?i)(JX3Client|lua|script)' })
            if ($ClientLogs.Count -eq 0) {
                $ClientLogs = @($LogFiles | Where-Object { $_.FullName -notmatch '(?i)[\\/](Dumper|DumpReport)[\\/]' })
            }
            $Newest = $ClientLogs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($Newest) {
                Write-ReportLine ('LATEST_LOG: ' + $Newest.FullName + ' [' + $Newest.LastWriteTime + ']')
                $LogMatches = @(Select-String -LiteralPath $Newest.FullName -Pattern 'Runtime\.lua|xMacro|attempt to |syntax error|error loading|stack traceback|Lua.*(error|fail)' |
                    Select-Object -Last 20)
                if ($LogMatches.Count -eq 0) { Write-ReportLine 'LOG_MATCHES: none' }
                foreach ($LogMatch in $LogMatches) { Write-ReportLine ('LOG ' + $LogMatch.LineNumber + ': ' + $LogMatch.Line) }
            } else { Write-ReportLine 'LATEST_LOG: unavailable' }
        }
    }
} catch {
    Write-ReportLine ('CHECK_ERROR: ' + $_.Exception.Message)
    $ResultCode = 2
} finally {
    $Lines | Set-Content -LiteralPath $ReportPath -Encoding UTF8
    Write-Output ('REPORT: ' + $ReportPath)
}
exit $ResultCode
