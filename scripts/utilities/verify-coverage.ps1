<#
.SYNOPSIS
    Verify and report real code coverage from Pester tests.

.DESCRIPTION
    Runs Pester CodeCoverage over declared workflow targets from tests/coverage-config.json,
    writes JSON and text reports, and fails if the configured threshold is not met.
#>

param(
    [int]$MinimumCoverage = 85,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root) {
        if ((Test-Path (Join-Path $root 'tests')) -and (Test-Path (Join-Path $root 'config'))) {
            return $root
        }

        $parent = Split-Path -Parent $root
        if (-not $parent -or $parent -eq $root) {
            break
        }
        $root = $parent
    }

    return (Get-Location).Path
}

function Resolve-Paths {
    param(
        [string]$Root,
        [object[]]$Paths
    )

    return @($Paths | ForEach-Object {
        if ([System.IO.Path]::IsPathRooted($_)) {
            $_
        } else {
            Join-Path $Root $_
        }
    })
}

$repoRoot = Get-RepoRoot
$reportsDir = Join-Path $repoRoot 'reports'
$coverageConfigPath = Join-Path $repoRoot 'tests\coverage-config.json'
$coverageReportFile = Join-Path $reportsDir 'coverage-report.json'
$coverageSummaryFile = Join-Path $reportsDir 'coverage-summary.txt'

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

if (-not (Test-Path $coverageConfigPath)) {
    Write-Host "[FAIL] Coverage config not found: $coverageConfigPath" -ForegroundColor Red
    exit 1
}

$coverageConfig = Get-Content -Path $coverageConfigPath -Raw | ConvertFrom-Json
$targets = @($coverageConfig.coverageTargets)
if ($targets.Count -eq 0) {
    Write-Host "[FAIL] No coverage targets declared in $coverageConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "REAL CODE COVERAGE - Foundation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[PHASE 1] Declared Targets" -ForegroundColor Blue

$targetResults = @()
$aggregateAnalyzed = 0
$aggregateExecuted = 0
$aggregatePassed = 0
$aggregateFailed = 0

foreach ($target in $targets) {
    $targetName = [string]$target.name
    $targetThreshold = if ($target.threshold) { [int]$target.threshold } else { $MinimumCoverage }
    $testPaths = Resolve-Paths -Root $repoRoot -Paths $target.tests
    $scriptPaths = Resolve-Paths -Root $repoRoot -Paths $target.scripts

    Write-Host "[OK] $targetName" -ForegroundColor Green
    Write-Host "     Tests:   $($testPaths.Count)" -ForegroundColor Gray
    Write-Host "     Scripts: $($scriptPaths.Count)" -ForegroundColor Gray

    $result = Invoke-Pester -Path $testPaths -CodeCoverage $scriptPaths -PassThru
    $coverage = $result.CodeCoverage

    if (-not $coverage) {
        throw "No CodeCoverage data returned for target '$targetName'"
    }

    $analyzed = [int]$coverage.NumberOfCommandsAnalyzed
    $executed = [int]$coverage.NumberOfCommandsExecuted
    $percent = if ($analyzed -gt 0) { [math]::Round(($executed / $analyzed) * 100, 2) } else { 0 }

    $aggregateAnalyzed += $analyzed
    $aggregateExecuted += $executed
    $aggregatePassed += [int]$result.PassedCount
    $aggregateFailed += [int]$result.FailedCount

    $targetResults += [ordered]@{
        name = $targetName
        threshold = $targetThreshold
        tests = @($target.tests)
        scripts = @($target.scripts)
        passed = [int]$result.PassedCount
        failed = [int]$result.FailedCount
        analyzedCommands = $analyzed
        executedCommands = $executed
        coveragePercent = $percent
        status = if ($percent -ge $targetThreshold -and $result.FailedCount -eq 0) { 'PASS' } else { 'FAIL' }
    }
}

Write-Host "`n[PHASE 2] Aggregate Result" -ForegroundColor Blue

$aggregateCoverage = if ($aggregateAnalyzed -gt 0) {
    [math]::Round(($aggregateExecuted / $aggregateAnalyzed) * 100, 2)
} else {
    0
}

$hasTargetFailure = @($targetResults | Where-Object { $_.status -ne 'PASS' }).Count -gt 0
$overallStatus = if (-not $hasTargetFailure -and $aggregateCoverage -ge $MinimumCoverage -and $aggregateFailed -eq 0) { 'PASS' } else { 'FAIL' }

Write-Host "[OK] Passed tests: $aggregatePassed | Failed tests: $aggregateFailed" -ForegroundColor Cyan
Write-Host "[OK] Real coverage: $aggregateCoverage%" -ForegroundColor Cyan

$reportData = [ordered]@{
    timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    method = 'pester_codecoverage_declared_targets'
    scope = 'declared coverage targets'
    minimumThreshold = $MinimumCoverage
    aggregate = [ordered]@{
        coveragePercent = $aggregateCoverage
        analyzedCommands = $aggregateAnalyzed
        executedCommands = $aggregateExecuted
        testsPassed = $aggregatePassed
        testsFailed = $aggregateFailed
        status = $overallStatus
    }
    targets = $targetResults
}

$reportData | ConvertTo-Json -Depth 6 | Set-Content -Path $coverageReportFile -Encoding UTF8

$summary = @"
===============================================================
    REAL CODE COVERAGE REPORT - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
===============================================================

Scope:
  Method:       pester_codecoverage_declared_targets
  Targets:      $($targets.Count)

Aggregate:
  Passed:       $aggregatePassed
  Failed:       $aggregateFailed
  Coverage:     $aggregateCoverage%
  Minimum:      $MinimumCoverage%
  Status:       $overallStatus

Per Target:
$((@($targetResults | ForEach-Object { "  - $($_.name): $($_.coveragePercent)% (threshold $($_.threshold)%) -> $($_.status)" }) -join "`n"))

===============================================================
"@

$summary | Set-Content -Path $coverageSummaryFile -Encoding UTF8

Write-Host "`n[PHASE 3] Reports" -ForegroundColor Blue
Write-Host "[OK] Report: $coverageReportFile" -ForegroundColor Green
Write-Host "[OK] Summary: $coverageSummaryFile" -ForegroundColor Green

if ($Force) {
    Write-Host "[SKIP] Force mode: Threshold validation disabled" -ForegroundColor Yellow
    exit 0
}

if ($overallStatus -eq 'PASS') {
    Write-Host "[PASS] Coverage $aggregateCoverage% meets declared thresholds" -ForegroundColor Green
    exit 0
}

Write-Host "[FAIL] Real coverage validation failed" -ForegroundColor Red
exit 1
