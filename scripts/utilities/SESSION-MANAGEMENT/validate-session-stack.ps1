param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$wf = Join-Path $root 'workspace-foundation\scripts\utilities\wf.ps1'

if (-not (Test-Path $wf)) {
    Write-Error "wf.ps1 not found at expected path: $wf"
    exit 1
}

if (-not $Quiet) {
    Write-Host "Validating workspace stack..." -ForegroundColor Cyan
}

& $wf health
$healthCode = $LASTEXITCODE
if ($healthCode -ne 0) {
    if (-not $Quiet) {
        Write-Host "[FAIL] wf health returned exit $healthCode" -ForegroundColor Red
    }
    exit $healthCode
}

& $wf orchestrator-status
$orchestratorCode = $LASTEXITCODE
if ($orchestratorCode -ne 0) {
    if (-not $Quiet) {
        Write-Host "[FAIL] wf orchestrator-status returned exit $orchestratorCode" -ForegroundColor Red
    }
    exit $orchestratorCode
}

if (-not $Quiet) {
    Write-Host "[OK] Session stack validation passed." -ForegroundColor Green
}

exit 0