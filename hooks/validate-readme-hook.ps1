#!/usr/bin/env pwsh
# validate-readme-hook.ps1
# Pre-commit hook that validates README.md files against governance policy
# Called by lefthook or git hooks when README.md files are staged

$ErrorActionPreference = 'Stop'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $candidate = $PSScriptRoot
    while ($candidate) {
        if (Test-Path (Join-Path $candidate 'config/orchestrator.json')) {
            $candidate
            break
        }
        $parent = Split-Path $candidate -Parent
        if ($parent -eq $candidate) { break }
        $candidate = $parent
    }
}

if (-not $repoRoot) {
    Write-Host "[SKIP] Cannot determine repo root for README validation" -ForegroundColor Yellow
    exit 0
}

$stagedFiles = git diff --cached --name-only --diff-filter=ACM 2>$null
if (-not $stagedFiles) { exit 0 }

$readmeChanged = $false
foreach ($file in $stagedFiles -split "`n") {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    $fileName = Split-Path $file -Leaf
    if ($fileName -eq 'README.md') {
        $readmeChanged = $true
        break
    }
}

if (-not $readmeChanged) {
    exit 0
}

Write-Host ""
Write-Host "=== README Governance Check ===" -ForegroundColor Cyan
Write-Host "README.md changes detected - running governance validation..." -ForegroundColor Gray
Write-Host ""

$validateScript = Join-Path $repoRoot 'scripts/utilities/validate-readme.ps1'
if (-not (Test-Path $validateScript)) {
    Write-Host "[WARN] validate-readme.ps1 not found - skipping governance check" -ForegroundColor Yellow
    exit 0
}

& pwsh -NoProfile -ExecutionPolicy Bypass -File $validateScript -Repo both
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host " COMMIT BLOCKED - README governance validation failed!" -ForegroundColor Red
    Write-Host " See rules/README-GOVERNANCE.md for policy details" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "To bypass (emergency only):" -ForegroundColor Yellow
    Write-Host "  git commit --no-verify" -ForegroundColor Yellow
    Write-Host ""
}

exit $exitCode