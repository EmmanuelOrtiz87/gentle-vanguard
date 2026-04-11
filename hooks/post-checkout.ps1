param(
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

$GitRoot = git rev-parse --show-toplevel 2>$null
if (-not $GitRoot) {
    exit 0
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Gentleman Foundation - Post-Checkout Health Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

# Find diagnostics script
$diagnosticsScript = $null
$candidate = $GitRoot
while ($candidate) {
    $tested = Join-Path $candidate 'scripts\diagnostics\system-diagnostics.ps1'
    if (Test-Path $tested) {
        $diagnosticsScript = $tested
        break
    }
    $parent = Split-Path -Parent $candidate
    if (-not $parent -or $parent -eq $candidate) { break }
    $candidate = $parent
}

# Find auto-init script
$autoInitScript = $null
$candidate = $GitRoot
while ($candidate) {
    $tested = Join-Path $candidate 'scripts\utilities\auto-init-dev-environment.ps1'
    if (Test-Path $tested) {
        $autoInitScript = $tested
        break
    }
    $parent = Split-Path -Parent $candidate
    if (-not $parent -or $parent -eq $candidate) { break }
    $candidate = $parent
}

# Run diagnostics
if ($diagnosticsScript) {
    Write-Host "Running system diagnostics..." -ForegroundColor Yellow
    $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $diagnosticsScript -Quiet -AutoRepair
} else {
    Write-Host "[WARN] Diagnostics script not found" -ForegroundColor Yellow
}

# Run auto-init if available
if ($autoInitScript) {
    Write-Host "Verifying environment..." -ForegroundColor Yellow
    $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $autoInitScript -Quiet -Force
} else {
    Write-Host "[WARN] Auto-init script not found" -ForegroundColor Yellow
}

Write-Host "✓ Post-checkout completion check finished" -ForegroundColor Green
Write-Host ""

exit 0
