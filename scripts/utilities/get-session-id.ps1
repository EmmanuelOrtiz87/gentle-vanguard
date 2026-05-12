# get-session-id.ps1
# Obtiene el Session ID mas reciente y lo devuelve

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$sessionDir = Join-Path $repoRoot '.session'
if (-not (Test-Path $sessionDir)) {
    exit 0
}

$sessionFile = Get-ChildItem (Join-Path $sessionDir 'session-*.json') -File -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1

if ($sessionFile) {
    Write-Output $sessionFile.BaseName
}