# get-session-id.ps1
# Obtiene el Session ID activo/reciente y lo devuelve

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) {
    $env:GV_BASE_DIR
} else {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        Get-Location
    }
    $root = Split-Path -Parent $scriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) {
        $root = Split-Path -Parent $root
    }
    if (-not $root) { $root = $scriptRoot }
    $root
}

$logsActiveFile = Join-Path $repoRoot 'logs\.session-active'
if (Test-Path $logsActiveFile) {
    try {
        $activeData = Get-Content -Path $logsActiveFile -Raw | ConvertFrom-Json
        if ($activeData.SessionId) {
            Write-Output $activeData.SessionId
            exit 0
        }
    }
    catch {
    }
}

$sessionDirs = @(
    (Join-Path $repoRoot 'session'),
    (Join-Path $repoRoot '.session')
) | Where-Object { Test-Path $_ }

foreach ($sessionDir in $sessionDirs) {
    $sessionFile = Get-ChildItem (Join-Path $sessionDir 'session-*.json') -File -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending |
                   Select-Object -First 1

    if ($sessionFile) {
        Write-Output $sessionFile.BaseName
        exit 0
    }
}
