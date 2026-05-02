<#
.SYNOPSIS
    Post-merge synchronization hook
.DESCRIPTION
    Syncs workspace configuration after git merge
#>
param()

Write-Host "[INFO] Running post-merge sync..." -ForegroundColor Cyan

# Sync cross-workspace configurations
if (Test-Path "scripts/monitoring/cross-workspace-validator.ps1") {
    & "scripts/monitoring/cross-workspace-validator.ps1" -Fix
}

# Update engram if needed
$engramVersion = & engram --version 2>$null
if ($engramVersion -match "Update available") {
    Write-Host "[WARN] Engram update available" -ForegroundColor Yellow
}

Write-Host "[OK] Post-merge sync completed" -ForegroundColor Green
exit 0
