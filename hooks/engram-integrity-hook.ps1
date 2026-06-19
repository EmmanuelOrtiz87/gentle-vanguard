#!/usr/bin/env pwsh
# engram-integrity-hook.ps1
# Pre-commit hook to verify and auto-repair Engram integrity
# Prevents commits with corrupted/mismatched Engram checksums
# Integrates with gentle-vanguard pre-commit pipeline

param(
    [ValidateSet("check", "repair", "quiet")]
    [string]$Mode = "check",
    [switch]$AutoFix = $false
)

$ErrorActionPreference = "Continue"

# Detect repo root
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Host "[ENGRAM-HOOK] Not in git repository" -ForegroundColor Yellow
    exit 0
}

$integrityScript = Join-Path $repoRoot "scripts\utilities\memory\ENGRAM\engram-integrity-check.ps1"
if (-not (Test-Path $integrityScript)) {
    Write-Host "[ENGRAM-HOOK] Integrity script not found" -ForegroundColor Yellow
    exit 0
}

$engramDataDir = Join-Path $repoRoot ".engram-data"
$dbPath = Join-Path $engramDataDir "engram.db"

# Only run if .engram-data exists and has engram.db
if (-not (Test-Path $dbPath)) {
    exit 0
}

Write-Host "[ENGRAM-HOOK] Checking Engram integrity..." -ForegroundColor Cyan

# Run integrity check
$checkResult = & $integrityScript -Mode check -Quiet
$checkExitCode = $LASTEXITCODE

if ($checkExitCode -eq 0) {
    Write-Host "[ENGRAM-HOOK] ✓ Integrity verified" -ForegroundColor Green
    exit 0
}

# Integrity check failed
Write-Host "[ENGRAM-HOOK] ⚠ Integrity check FAILED" -ForegroundColor Yellow

if ($AutoFix) {
    Write-Host "[ENGRAM-HOOK] Auto-fixing checksums..." -ForegroundColor Cyan
    
    # Regenerate checksums
    & $integrityScript -Mode checksums -Quiet
    $fixExitCode = $LASTEXITCODE
    
    # Verify fix
    $verifyResult = & $integrityScript -Mode check -Quiet
    $verifyExitCode = $LASTEXITCODE
    
    if ($verifyExitCode -eq 0) {
        Write-Host "[ENGRAM-HOOK] ✓ Fixed! Checksums regenerated" -ForegroundColor Green
        
        # Stage the fixed checksums file if it changed
        $checksumPath = Join-Path $repoRoot ".engram\checksums.sha256"
        if (Test-Path $checksumPath) {
            git add $checksumPath 2>$null
            Write-Host "[ENGRAM-HOOK] Staged: .engram/checksums.sha256" -ForegroundColor Green
        }
        exit 0
    } else {
        Write-Host "[ENGRAM-HOOK] ✗ Fix failed - manual repair needed" -ForegroundColor Red
        Write-Host "              Run: pwsh -File scripts\utilities\memory\ENGRAM\engram-integrity-check.ps1 -Mode repair" -ForegroundColor Yellow
        exit 1
    }
} else {
    # Report failure in strict mode
    Write-Host "[ENGRAM-HOOK] ✗ Cannot commit with corrupted Engram" -ForegroundColor Red
    Write-Host "              Run: pwsh -File scripts\utilities\memory\ENGRAM\engram-integrity-check.ps1 -Mode repair" -ForegroundColor Yellow
    Write-Host "              Or: git commit --no-verify (not recommended)" -ForegroundColor Gray
    exit 1
}
