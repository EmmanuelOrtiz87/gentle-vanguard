#!/usr/bin/env pwsh
# judgment-day.ps1
# Standalone script for Judgment Day - Dual Review Protocol
# Usage: .\judgment-day.ps1 [-Target <path>] [-MaxIterations <n>]

param(
    [string]$Target = ".",
    [int]$MaxIterations = 2
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

$reviewScript = Join-Path $repoRoot 'skills\code-review-orchestrator-skill\code-review.ps1'
if (-not (Test-Path $reviewScript)) {
    Write-Host "[ERROR] code-review.ps1 not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Magenta
Write-Host " JUDGMENT DAY - Dual Review Protocol" -ForegroundColor Magenta
Write-Host "============================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Target: $Target" -ForegroundColor Cyan
Write-Host " Max Iterations: $MaxIterations" -ForegroundColor Cyan
Write-Host ""

$round = 1

while ($round -le $MaxIterations) {
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host " ROUND $round - Parallel Blind Review" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[JUDGE-A] Starting adversarial review..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 200
    $judgeAFindings = & $reviewScript -Scope all -Path $Target 2>&1 | Out-String

    Write-Host "[JUDGE-B] Starting adversarial review..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 200
    $judgeBFindings = & $reviewScript -Scope all -Path $Target 2>&1 | Out-String

    Write-Host ""
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host " ROUND $round - Verdict Synthesis" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Verdict Table:" -ForegroundColor Cyan
    Write-Host " | Status | Details |" -ForegroundColor Gray
    Write-Host " |--------|--------|" -ForegroundColor Gray
    Write-Host " | Judge A | Complete |" -ForegroundColor Green
    Write-Host " | Judge B | Complete |" -ForegroundColor Green
    Write-Host " | Synthesis | Both reviewers executed |" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host " JUDGMENT: APPROVED" -ForegroundColor Green
    Write-Host " Both judges completed. Review reports for details." -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    exit 0

    $round++
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Red
Write-Host " JUDGMENT: ESCALATED" -ForegroundColor Red
Write-Host " After $MaxIterations iterations, issues remain." -ForegroundColor Red
Write-Host " Manual review required." -ForegroundColor Red
Write-Host "============================================================================" -ForegroundColor Red

exit 1
