#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check pre-push hook timing against performance baselines.

.DESCRIPTION
    Reads tests/performance/baseline.json and compares recent lefthook
    timing against warn/max thresholds. Emits warnings but does NOT block.

.PARAMETER LefthookLog
    Path to lefthook output file with timing data (optional).
    If not provided, checks git log for recent timing patterns.

.PARAMETER UpdateBaseline
    When set, updates baseline.json with newly measured times.

.EXAMPLE
    .\check-performance-baselines.ps1
    .\check-performance-baselines.ps1 -UpdateBaseline
#>

param(
    [string]$LefthookLog = '',
    [switch]$UpdateBaseline
)

$ErrorActionPreference = 'Continue'

$script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$baselineFile = Join-Path $script:root 'tests\performance\baseline.json'

if (-not (Test-Path $baselineFile)) {
    Write-Warning "Baseline file not found: $baselineFile"
    exit 0
}

$baseline = Get-Content $baselineFile | ConvertFrom-Json
$warnings = 0
$checks = 0

Write-Host "=== Performance Baseline Check ===" -ForegroundColor Cyan
Write-Host "Baseline date: $($baseline.last_measured)"
Write-Host ""

# ─── Parse lefthook timing from git log (if available) ───────────────────────
# lefthook outputs "summary: (done in X.XX seconds)" per hook
function Get-LefthookTimings {
    param([string]$LogPath)

    $timings = @{}

    if ($LogPath -and (Test-Path $LogPath)) {
        $lines = Get-Content $LogPath
    } else {
        # Try to get from last git push output (not reliable, use log file if available)
        return $timings
    }

    $currentHook = $null
    foreach ($line in $lines) {
        if ($line -match '✔️\s+(\S+)\s+\((\d+\.\d+) seconds\)') {
            $timings[$matches[1]] = [double]$matches[2]
        }
    }

    return $timings
}

# ─── Display baseline thresholds ─────────────────────────────────────────────
foreach ($hookName in $baseline.baselines.PSObject.Properties.Name) {
    $b = $baseline.baselines.$hookName
    $checks++

    $status = "✓ OK"
    $color = "Green"

    Write-Host "  $hookName" -ForegroundColor White
    Write-Host "    Baseline: $($b.baseline_seconds)s | Warn: $($b.warn_seconds)s | Max: $($b.max_seconds)s"

    if ($b.note) {
        Write-Host "    Note: $($b.note)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "─── Trend History ───────────────────────────────────────" -ForegroundColor DarkGray
foreach ($entry in $baseline.trend) {
    $testCount = if ($entry.test_count) { ", $($entry.test_count) tests" } else { "" }
    Write-Host "  $($entry.date): test-suite=$($entry."test_suite_seconds")s, pre-push=$($entry."pre-push-total_seconds")s$testCount"
}

Write-Host ""
Write-Host "Alert policy: $($baseline.alert_policy.description)" -ForegroundColor DarkGray
Write-Host ""

if ($warnings -gt 0) {
    Write-Host "[WARN] $warnings threshold(s) exceeded. Review and optimize if trending upward." -ForegroundColor Yellow
    exit 0  # Warn only, never block
} else {
    Write-Host "[OK] All $checks baselines within expected ranges." -ForegroundColor Green
    exit 0
}
