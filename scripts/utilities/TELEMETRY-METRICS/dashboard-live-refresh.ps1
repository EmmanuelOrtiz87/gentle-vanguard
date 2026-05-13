#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Continuously refreshes unified dashboard artifacts for live executive and developer visibility.

.DESCRIPTION
  This loop keeps data and dashboard HTML fresh by orchestrating:
  - stack-live-observability snapshot generation
  - optional full stack benchmark refresh at a slower cadence
  - dashboard HTML regeneration with browser auto-refresh metadata

.PARAMETER RefreshSeconds
  Interval in seconds between dashboard refresh cycles.

.PARAMETER BenchmarkEvery
  Run full benchmark every N cycles.

.PARAMETER OutputPath
  Dashboard HTML target path.

.PARAMETER Open
  Open dashboard in default browser on first cycle.

.PARAMETER Iterations
  Number of cycles to run. 0 means infinite.

.PARAMETER AutoRemediateOnFail
  Enable local auto-remediation when full benchmark fails.
#>

param(
    [int]$RefreshSeconds = 15,
    [int]$BenchmarkEvery = 4,
    [string]$OutputPath = '',
    [switch]$Open,
    [int]$Iterations = 0,
    [switch]$AutoRemediateOnFail
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

$generateDashboard = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\generate-dashboard.ps1'
$liveObs = Join-Path $repoRoot 'scripts\utilities\UTILITIES\stack-live-observability.ps1'
$stackBenchmark = Join-Path $repoRoot 'scripts\utilities\wf-stack-benchmark.ps1'

if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot 'reports\dashboard.html'
}

if (-not (Test-Path $generateDashboard)) {
    throw "generate-dashboard.ps1 not found: $generateDashboard"
}
if (-not (Test-Path $liveObs)) {
    throw "stack-live-observability.ps1 not found: $liveObs"
}
if (-not (Test-Path $stackBenchmark)) {
    throw "wf-stack-benchmark.ps1 not found: $stackBenchmark"
}

$refreshSafe = [Math]::Max(5, $RefreshSeconds)
$cycle = 0
$opened = $false

Write-Host ''
Write-Host '=== DASHBOARD LIVE REFRESH ===' -ForegroundColor Cyan
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host "RefreshSeconds: $refreshSafe | BenchmarkEvery: $BenchmarkEvery" -ForegroundColor Gray
Write-Host ''

while ($true) {
    $cycle++
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # 1) Refresh live observability snapshot artifact.
    & $liveObs -AsJson | Out-Null

    # 2) Run full benchmark periodically to keep baseline/trend data fresh.
    if ($BenchmarkEvery -gt 0 -and ($cycle % $BenchmarkEvery -eq 0)) {
        if ($AutoRemediateOnFail) {
            & $stackBenchmark -AsJson -AutoRemediate | Out-Null
        } else {
            & $stackBenchmark -AsJson | Out-Null
        }
    }

    # 3) Regenerate dashboard HTML with browser-side auto-refresh hint.
    & $generateDashboard -OutputPath $OutputPath -AutoRefreshSeconds $refreshSafe | Out-Null

    if ($Open -and -not $opened) {
        if ($IsWindows -or $env:OS -eq 'Windows_NT') {
            Start-Process $OutputPath
        } elseif ($IsMacOS) {
            & open $OutputPath
        } else {
            & xdg-open $OutputPath 2>$null
        }
        $opened = $true
    }

    Write-Host "[$ts] cycle=$cycle dashboard refreshed" -ForegroundColor Green

    if ($Iterations -gt 0 -and $cycle -ge $Iterations) {
        break
    }

    Start-Sleep -Seconds $refreshSafe
}

Write-Host ''
Write-Host 'Live refresh finished.' -ForegroundColor Cyan
exit 0
