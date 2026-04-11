# update-all.ps1
# Wrapper for the foundation update workflow.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$updateScript = Join-Path $scriptDir 'validation\update-all.ps1'

if (-not (Test-Path $updateScript)) {
    Write-Host "[ERROR] Update script not found: $updateScript" -ForegroundColor Red
    exit 1
}

Write-Host "Running foundation update..." -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateScript -All -Force
exit $LASTEXITCODE
