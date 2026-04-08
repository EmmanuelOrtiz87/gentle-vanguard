# validate-project.ps1 (Foundation Core)
# Agnostic and self-contained script to validate the integrity of the current project.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectName = Split-Path $projectRoot -Leaf
Set-Location $projectRoot

function Write-Check { param([string]$msg) Write-Host ">> $msg" -ForegroundColor Cyan }

Write-Check "1. Verifying Quality and Security..."
if (Get-Command gga -ErrorAction SilentlyContinue) {
    & gga check
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   OK: Security check passed." -ForegroundColor Green
    }
} else {
    Write-Host "   INFO: Security tool not detected. Skipping security validation." -ForegroundColor Gray
}

Write-Check "2. Validating Local AI Resources..."
if (Test-Path "tools/ai-skills") {
    Write-Host "   OK: Base skills library present." -ForegroundColor Green
}

Write-Check "3. Generating Session Report..."
$reviewScript = Join-Path $scriptDir "generate-session-review.ps1"
if (Test-Path $reviewScript) {
    & $reviewScript
}

Write-Check "4. Repository Status (Git)..."
$status = git status --short
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "   OK: Clean for push." -ForegroundColor Green
} else {
    Write-Host "   Pending changes detected:" -ForegroundColor Yellow
    Write-Host $status
}

Write-Host "`n====================================================" -ForegroundColor Gray
if ($LASTEXITCODE -eq 0) {
    Write-Host " VALIDATION OF [$projectName] COMPLETED" -ForegroundColor Green -BackgroundColor Black
} else {
    Write-Host " VALIDATION ERROR" -ForegroundColor Red
}
Write-Host "====================================================`n" -ForegroundColor Gray

exit $LASTEXITCODE