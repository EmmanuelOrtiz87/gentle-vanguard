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

$args = @("judgment-day")
if ($Target) {
    $args += "--target"; $args += $Target
}
$args += "--MaxIterations"; $args += $MaxIterations

Write-Host "Starting Judgment Day..." -ForegroundColor Magenta
Write-Host " Target: $Target" -ForegroundColor Gray
Write-Host " Max Iterations: $MaxIterations" -ForegroundColor Gray
Write-Host ""

& $reviewScript @args
exit $LASTEXITCODE
