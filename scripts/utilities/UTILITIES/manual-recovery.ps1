# manual-recovery.ps1
# Manual recovery script for when self-healing fails.
# Usage: .\manual-recovery.ps1

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

Write-Host "=== MANUAL RECOVERY MODE ===" -ForegroundColor Red
Write-Host "This script attempts to repair foundational tools when automatic self-healing fails." -ForegroundColor Yellow

function Repair-Tools {
    Write-Host "`n[1/3] Checking internet connectivity..." -ForegroundColor Cyan
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 5 -UseBasicParsing
        Write-Host "[OK] Internet connection available." -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] No internet connection. Please connect to the network and retry." -ForegroundColor Red
        return
    }

    Write-Host "`n[2/3] Reinstalling Engram..." -ForegroundColor Cyan
    try {
        go install github.com/foundation/engram@latest
        Write-Host "[OK] Engram reinstalled." -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Engram installation failed. Check Go environment." -ForegroundColor Red
    }

    Write-Host "`n[3/3] Updating Foundation Scripts..." -ForegroundColor Cyan
    try {
        git -C $repoRoot pull origin main
        Write-Host "[OK] Scripts updated." -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Git update failed. Check repository access." -ForegroundColor Red
    }
}

Repair-Tools
Write-Host "`nRecovery process finished. Run 'wf.ps1 health' to validate." -ForegroundColor Cyan
