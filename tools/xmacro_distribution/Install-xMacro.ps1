[CmdletBinding()]
param([string]$GameRoot, [switch]$ValidateOnly)
$ErrorActionPreference = 'Stop'
# Dot-source exposes path validation for isolated tests without opening a picker.
function Get-ValidatedGameRoot([string]$Selected) {
    if ([string]::IsNullOrWhiteSpace($Selected)) { throw 'Chua chon thu muc game.' }
    $Resolved = (Resolve-Path -LiteralPath $Selected).ProviderPath
    if (-not (Test-Path -LiteralPath $Resolved -PathType Container)) { throw 'Can chon thu muc.' }
    if (-not ((Test-Path -LiteralPath (Join-Path $Resolved 'jx3client.exe') -PathType Leaf) -or
              (Test-Path -LiteralPath (Join-Path $Resolved 'game.exe') -PathType Leaf))) {
        throw 'Thu muc phai chua jx3client.exe hoac game.exe.'
    }
    return $Resolved.TrimEnd('\', '/')
}
if ($MyInvocation.InvocationName -eq '.') { return }
if (-not $GameRoot) {
    Add-Type -AssemblyName System.Windows.Forms
    $Picker = New-Object System.Windows.Forms.FolderBrowserDialog
    $Picker.Description = 'Chon thu muc chua jx3client.exe hoac game.exe'
    if ($Picker.ShowDialog() -ne 'OK') { exit 1 }
    $GameRoot = $Picker.SelectedPath
}
try {
    $TargetRoot = Get-ValidatedGameRoot $GameRoot
    if ($ValidateOnly) { Write-Output "VALID: $TargetRoot"; exit 0 }
    $Source = Join-Path $PSScriptRoot 'Interface\xMacro'
    if (-not (Test-Path -LiteralPath (Join-Path $Source 'info.ini'))) { throw 'Giai nen day du goi cai truoc.' }
    $Destination = Join-Path $TargetRoot 'Interface\xMacro'
    # Reject junctions/symlinks on both existing destination components.
    foreach ($Candidate in @((Join-Path $TargetRoot 'Interface'), $Destination, (Join-Path $TargetRoot 'xMacro-backups'))) {
        if ((Test-Path -LiteralPath $Candidate) -and
            ((Get-Item -LiteralPath $Candidate -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Khong cai qua junction/symlink. Hay chon thu muc game truc tiep.'
        }
    }
    # Copy a recoverable backup before overlay; never delete existing files/state.
    if (Test-Path -LiteralPath $Destination) {
        $Backup = Join-Path $TargetRoot ('xMacro-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-ffff'))
        New-Item -ItemType Directory -Path $Backup -Force | Out-Null
        Copy-Item -LiteralPath $Destination -Destination $Backup -Recurse
        Write-Output "Ban sao luu: $Backup"
    }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -File -Recurse | ForEach-Object {
        if ($_.Extension -eq '.jx3dat') { throw 'Goi cai khong duoc chua du lieu ca nhan.' }
        $Relative = $_.FullName.Substring($Source.Length).TrimStart('\', '/')
        $Output = Join-Path $Destination $Relative
        # Existing child reparse points could redirect the overlay outside the addon.
        $Current = Split-Path -Parent $Output
        while ($Current.Length -ge $Destination.Length) {
            if ((Test-Path -LiteralPath $Current) -and
                ((Get-Item -LiteralPath $Current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw 'Khong ghi qua junction/symlink trong addon.'
            }
            $Current = Split-Path -Parent $Current
        }
        if ((Test-Path -LiteralPath $Output) -and
            ((Get-Item -LiteralPath $Output -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Khong ghi de symlink.'
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $Output) -Force | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $Output -Force
    }
    Write-Output 'Da cai xMacro. Chay Interface\xMacro\start_xmacro.bat, roi vao lai game.'
} catch {
    Write-Error $_
    exit 1
}
