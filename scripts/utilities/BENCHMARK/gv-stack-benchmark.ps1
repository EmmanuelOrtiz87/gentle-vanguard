#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Full stack benchmark for coverage + performance baselines.

.DESCRIPTION
  Runs four quality layers:
  1) gv benchmark (command latency vs SLO)
  2) multilingual routing matrix (coverage/accuracy)
  3) agent-verify tests domain (structural quality gate)
  4) baseline regression check (historical trend guard)

  Writes reports:
  - reports/stack-benchmark.json
  - reports/stack-benchmark-history.json
  - reports/stack-benchmark-history.jsonl
  - reports/stack-benchmark-baseline.json

  Optional auto-remediation writes:
  - reports/incidents/stack-benchmark-remediation-<timestamp>.md

.PARAMETER AsJson
  Print consolidated JSON summary.

.PARAMETER Strict
  Exit non-zero if any layer fails.

.PARAMETER AutoRemediate
  Run local remediation playbook and write an incident report when benchmark fails.

.PARAMETER UpdateBaseline
  Force baseline update with current run metrics.

.PARAMETER RegressionWarnPct
  Warn threshold for gv latency regression (% above baseline).

.PARAMETER RegressionFailPct
  Fail threshold for gv latency regression (% above baseline).
#>

param(
    [switch]$AsJson,
    [switch]$Strict,
    [switch]$AutoRemediate,
    [switch]$UpdateBaseline,
    [double]$RegressionWarnPct = 15,
    [double]$RegressionFailPct = 30,
    [double]$RoutingAccuracyDropWarn = 0.5,
    [double]$RoutingAccuracyDropFail = 1.5
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$wfBench = Join-Path $repoRoot 'scripts\utilities\gv-benchmark.ps1'
$routingEval = Join-Path $repoRoot 'scripts\utilities\routing-quality-eval.ps1'
$agentVerify = Join-Path $repoRoot 'scripts\utilities\agent-verify.ps1'

$reportsDir = Join-Path $repoRoot 'reports'
$outPath = Join-Path $reportsDir 'stack-benchmark.json'
$historyPath = Join-Path $reportsDir 'stack-benchmark-history.json'
$historyJsonlPath = Join-Path $reportsDir 'stack-benchmark-history.jsonl'
$baselinePath = Join-Path $reportsDir 'stack-benchmark-baseline.json'

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try {
        return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-CurrentMetrics {
    param($Result)

    $wfRows = @($Result.layers.wf_benchmark.data.results)
    $wfElapsed = @($wfRows | ForEach-Object { [double]$_.elapsed_s } | Where-Object { $_ -ge 0 })
    $wfAvg = if ($wfElapsed.Count -gt 0) { [math]::Round((($wfElapsed | Measure-Object -Average).Average), 3) } else { 0.0 }

    $routingAccuracy = 0.0
    $routingLowConfidence = 0
    if ($Result.layers.routing_matrix.data) {
        $routingAccuracy = [double]$Result.layers.routing_matrix.data.accuracy
        $routingLowConfidence = [int]$Result.layers.routing_matrix.data.lowConfidenceRoutings
    }

    return [ordered]@{
        wf_avg_elapsed_s = $wfAvg
        routing_accuracy_pct = [math]::Round($routingAccuracy, 2)
        routing_low_confidence = $routingLowConfidence
        benchmark_status = [string]$Result.summary.status
    }
}

function Compare-Baseline {
    param(
        $Current,
        $Baseline,
        [double]$WarnPct,
        [double]$FailPct,
        [double]$AccDropWarn,
        [double]$AccDropFail
    )

    if (-not $Baseline -or -not $Baseline.metrics) {
        return [ordered]@{
            status = 'WARN'
            detail = 'No baseline found. Initial baseline will be created from current run.'
            deltas = [ordered]@{
                wf_latency_pct = 0
                routing_accuracy_drop_pct = 0
                routing_low_confidence_delta = 0
            }
        }
    }

    $baseLatency = [double]$Baseline.metrics.wf_avg_elapsed_s
    $baseRouting = [double]$Baseline.metrics.routing_accuracy_pct
    $baseLowConf = [int]$Baseline.metrics.routing_low_confidence

    $latencyDeltaPct = 0.0
    if ($baseLatency -gt 0) {
        $latencyDeltaPct = [math]::Round((($Current.wf_avg_elapsed_s - $baseLatency) * 100.0) / $baseLatency, 2)
    }

    $routingDrop = [math]::Round(($baseRouting - $Current.routing_accuracy_pct), 2)
    $lowConfDelta = [int]$Current.routing_low_confidence - $baseLowConf

    $status = 'PASS'
    $notes = @()

    if ($latencyDeltaPct -ge $FailPct) {
        $status = 'FAIL'
        $notes += "gv latency regression ${latencyDeltaPct}% >= fail threshold ${FailPct}%"
    } elseif ($latencyDeltaPct -ge $WarnPct) {
        if ($status -ne 'FAIL') { $status = 'WARN' }
        $notes += "gv latency regression ${latencyDeltaPct}% >= warn threshold ${WarnPct}%"
    }

    if ($routingDrop -ge $AccDropFail) {
        $status = 'FAIL'
        $notes += "routing accuracy dropped ${routingDrop}pp >= fail threshold ${AccDropFail}pp"
    } elseif ($routingDrop -ge $AccDropWarn) {
        if ($status -ne 'FAIL') { $status = 'WARN' }
        $notes += "routing accuracy dropped ${routingDrop}pp >= warn threshold ${AccDropWarn}pp"
    }

    if ($lowConfDelta -gt 3 -and $status -eq 'PASS') {
        $status = 'WARN'
        $notes += "low-confidence routes increased by $lowConfDelta"
    }

    $detail = if ($notes.Count -gt 0) { $notes -join '; ' } else { 'within historical baseline thresholds' }

    return [ordered]@{
        status = $status
        detail = $detail
        deltas = [ordered]@{
            wf_latency_pct = $latencyDeltaPct
            routing_accuracy_drop_pct = $routingDrop
            routing_low_confidence_delta = $lowConfDelta
        }
    }
}

function Update-Baseline {
    param(
        [string]$Path,
        $Current,
        $Existing,
        [switch]$ForceUpdate
    )

    if (-not $Existing -or -not $Existing.metrics) {
        $baseline = [ordered]@{
            created_at = (Get-Date).ToString('o')
            updated_at = (Get-Date).ToString('o')
            sample_count = 1
            metrics = $Current
        }
        $baseline | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
        return $baseline
    }

    # Update using EWMA to keep baseline stable while adapting to normal drift.
    $alpha = 0.20
    $samples = [int]$Existing.sample_count
    if ($samples -lt 1) { $samples = 1 }

    $newLatency = [math]::Round(((1 - $alpha) * [double]$Existing.metrics.wf_avg_elapsed_s) + ($alpha * [double]$Current.wf_avg_elapsed_s), 3)
    $newAccuracy = [math]::Round(((1 - $alpha) * [double]$Existing.metrics.routing_accuracy_pct) + ($alpha * [double]$Current.routing_accuracy_pct), 2)
    $newLowConf = [int][math]::Round(((1 - $alpha) * [double]$Existing.metrics.routing_low_confidence) + ($alpha * [double]$Current.routing_low_confidence), 0)

    $updated = [ordered]@{
        created_at = if ($Existing.created_at) { [string]$Existing.created_at } else { (Get-Date).ToString('o') }
        updated_at = (Get-Date).ToString('o')
        sample_count = ($samples + 1)
        metrics = [ordered]@{
            wf_avg_elapsed_s = $newLatency
            routing_accuracy_pct = $newAccuracy
            routing_low_confidence = $newLowConf
            benchmark_status = [string]$Current.benchmark_status
        }
    }

    $updated | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
    return $updated
}

function Append-History {
    param(
        [string]$JsonPath,
        [string]$JsonlPath,
        $Entry
    )

    $history = @()
    if (Test-Path $JsonPath) {
        try {
            $existing = Get-Content -Path $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $history = @($existing)
        } catch {
            $history = @()
        }
    }

    $history += [pscustomobject]$Entry
    if ($history.Count -gt 240) {
        $history = @($history | Select-Object -Last 240)
    }

    $history | ConvertTo-Json -Depth 12 | Set-Content -Path $JsonPath -Encoding UTF8

    $jsonlLine = ($Entry | ConvertTo-Json -Depth 12 -Compress)
    Add-Content -Path $JsonlPath -Value $jsonlLine -Encoding UTF8
}

function Invoke-AutoRemediation {
    param(
        [string[]]$FailedLayers,
        [string]$RepoRoot,
        [string]$WfBenchScript,
        [string]$RoutingEvalScript,
        [string]$AgentVerifyScript
    )

    $incidentDir = Join-Path $RepoRoot 'reports\incidents'
    if (-not (Test-Path $incidentDir)) {
        New-Item -ItemType Directory -Path $incidentDir -Force | Out-Null
    }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $incidentPath = Join-Path $incidentDir "stack-benchmark-remediation-$stamp.md"
    $actions = @()

    if ($FailedLayers -contains 'wf_benchmark' -and (Test-Path $WfBenchScript)) {
        $output = & $WfBenchScript -Commands @('status', 'health', 'verify') -AsJson 2>&1
        $actions += [ordered]@{
            layer = 'wf_benchmark'
            action = 'Re-run gv benchmark for triage'
            result = ([string]($output | Out-String)).Trim()
        }
    }

    if ($FailedLayers -contains 'routing_matrix' -and (Test-Path $RoutingEvalScript)) {
        & $RoutingEvalScript -WorkspaceRoot $RepoRoot -DatasetPath 'tests/e2e/routing-language-matrix.json' 2>&1 | Out-Null
        $routingReportPath = Join-Path $RepoRoot '.session\routing-quality-last.json'
        $routingSummary = 'routing report unavailable'
        if (Test-Path $routingReportPath) {
            try {
                $rr = Get-Content -Path $routingReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $routingSummary = "accuracy=$($rr.summary.accuracy)% failed=$($rr.summary.failed) lowConfidence=$($rr.summary.lowConfidenceRoutings)"
            } catch { }
        }

        $actions += [ordered]@{
            layer = 'routing_matrix'
            action = 'Re-run routing quality matrix and collect latest summary'
            result = $routingSummary
        }
    }

    if ($FailedLayers -contains 'agent_verify_tests' -and (Test-Path $AgentVerifyScript)) {
        $output = & $AgentVerifyScript -Domain tests 2>&1
        $actions += [ordered]@{
            layer = 'agent_verify_tests'
            action = 'Re-run agent-verify tests domain'
            result = ([string]($output | Out-String)).Trim()
        }
    }

    $md = @()
    $md += '# Stack Benchmark Auto-Remediation Report'
    $md += ''
    $md += "- timestamp: $((Get-Date).ToString('o'))"
    $md += "- failed_layers: $($FailedLayers -join ', ')"
    $md += ''
    $md += '## Actions Executed'
    if ($actions.Count -eq 0) {
        $md += '- No remediation action executed (scripts unavailable or no eligible failed layers).'
    } else {
        foreach ($a in $actions) {
            $md += "### [$($a.layer)] $($a.action)"
            $md += '```text'
            $md += [string]$a.result
            $md += '```'
            $md += ''
        }
    }

    $md -join "`n" | Set-Content -Path $incidentPath -Encoding UTF8

    return [ordered]@{
        executed = $true
        report_path = $incidentPath
        actions = $actions
    }
}

$result = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    layers = [ordered]@{}
    summary = [ordered]@{
        status = 'PASS'
        failed_layers = @()
    }
}

# Layer 1: gv benchmark
$layer1 = [ordered]@{ status = 'UNKNOWN'; detail = '' }
if (Test-Path $wfBench) {
    try {
        $l1out = & $wfBench -Commands @('status', 'health', 'verify') -AsJson
        $l1 = $l1out | ConvertFrom-Json
        $rows = @($l1.results)
        $fails = @($rows | Where-Object { $_.status -in @('FAIL', 'ERROR') }).Count
        $layer1.status = if ($fails -gt 0) { 'FAIL' } else { 'PASS' }
        $layer1.detail = "commands=$($rows.Count),failures=$fails"
        $layer1.data = $l1
    } catch {
        $layer1.status = 'FAIL'
        $layer1.detail = "gv benchmark error: $($_.Exception.Message)"
    }
} else {
    $layer1.status = 'FAIL'
    $layer1.detail = 'gv-benchmark.ps1 not found'
}
$result.layers.wf_benchmark = $layer1

# Layer 2: routing matrix
$layer2 = [ordered]@{ status = 'UNKNOWN'; detail = '' }
if (Test-Path $routingEval) {
    try {
        & $routingEval -WorkspaceRoot $repoRoot -DatasetPath 'tests/e2e/routing-language-matrix.json' -FailOnMismatch | Out-Null
        $exit = $LASTEXITCODE
        $reportPath = Join-Path $repoRoot '.session\routing-quality-last.json'
        $report = $null
        if (Test-Path $reportPath) {
            $report = Get-Content -Path $reportPath -Raw -Encoding UTF8 | ConvertFrom-Json
        }

        if ($exit -eq 0) {
            $layer2.status = 'PASS'
            $layer2.detail = if ($report) { "accuracy=$($report.summary.accuracy)%" } else { 'routing matrix pass' }
        } else {
            $layer2.status = 'FAIL'
            $layer2.detail = if ($report) { "accuracy=$($report.summary.accuracy)% failed=$($report.summary.failed)" } else { 'routing matrix failed' }
        }
        if ($report) { $layer2.data = $report.summary }
    } catch {
        $layer2.status = 'FAIL'
        $layer2.detail = "routing eval error: $($_.Exception.Message)"
    }
} else {
    $layer2.status = 'FAIL'
    $layer2.detail = 'routing-quality-eval.ps1 not found'
}
$result.layers.routing_matrix = $layer2

# Layer 3: agent verify (tests domain only)
$layer3 = [ordered]@{ status = 'UNKNOWN'; detail = '' }
if (Test-Path $agentVerify) {
    try {
        $l3out = & $agentVerify -Domain tests 2>&1
        $exit3 = $LASTEXITCODE
        $line = ($l3out | Select-String 'RESULT:' | Select-Object -Last 1)
        $layer3.status = if ($exit3 -eq 0) { 'PASS' } else { 'FAIL' }
        $layer3.detail = if ($line) { [string]$line } else { "exit=$exit3" }
    } catch {
        $layer3.status = 'FAIL'
        $layer3.detail = "agent-verify tests error: $($_.Exception.Message)"
    }
} else {
    $layer3.status = 'FAIL'
    $layer3.detail = 'agent-verify.ps1 not found'
}
$result.layers.agent_verify_tests = $layer3

$failed = @()
foreach ($name in @('wf_benchmark', 'routing_matrix', 'agent_verify_tests')) {
    if ($result.layers.$name.status -ne 'PASS') {
        $failed += $name
    }
}

# Layer 4: baseline regression
$currentMetrics = Get-CurrentMetrics -Result $result
$baseline = Read-JsonFile -Path $baselinePath
$regression = Compare-Baseline -Current $currentMetrics -Baseline $baseline -WarnPct $RegressionWarnPct -FailPct $RegressionFailPct -AccDropWarn $RoutingAccuracyDropWarn -AccDropFail $RoutingAccuracyDropFail

$result.layers.baseline_regression = [ordered]@{
    status = $regression.status
    detail = $regression.detail
    data = [ordered]@{
        baseline = if ($baseline) { $baseline.metrics } else { $null }
        current = $currentMetrics
        deltas = $regression.deltas
    }
}

if ($regression.status -eq 'FAIL') {
    $failed += 'baseline_regression'
}

if ($failed.Count -gt 0) {
    $result.summary.status = 'FAIL'
    $result.summary.failed_layers = $failed
} elseif ($regression.status -eq 'WARN') {
    $result.summary.status = 'PASS_WITH_WARNINGS'
}

$historyEntry = [ordered]@{
    timestamp = $result.timestamp
    status = $result.summary.status
    failed_layers = $result.summary.failed_layers
    metrics = $currentMetrics
    regression = [ordered]@{
        status = $regression.status
        deltas = $regression.deltas
    }
}
Append-History -JsonPath $historyPath -JsonlPath $historyJsonlPath -Entry $historyEntry

$shouldUpdateBaseline = $UpdateBaseline -or (-not $baseline) -or ($result.summary.status -in @('PASS', 'PASS_WITH_WARNINGS'))
if ($shouldUpdateBaseline) {
    $updatedBaseline = Update-Baseline -Path $baselinePath -Current $currentMetrics -Existing $baseline -ForceUpdate:$UpdateBaseline
    $result.baseline = [ordered]@{
        updated = $true
        path = $baselinePath
        sample_count = [int]$updatedBaseline.sample_count
    }
} else {
    $result.baseline = [ordered]@{
        updated = $false
        path = $baselinePath
        sample_count = if ($baseline -and $baseline.sample_count) { [int]$baseline.sample_count } else { 0 }
    }
}

if ($AutoRemediate -and $result.summary.status -ne 'PASS') {
    $remediation = Invoke-AutoRemediation -FailedLayers @($result.summary.failed_layers) -RepoRoot $repoRoot -WfBenchScript $wfBench -RoutingEvalScript $routingEval -AgentVerifyScript $agentVerify
    $result.remediation = $remediation
}

$result | ConvertTo-Json -Depth 16 | Set-Content -Path $outPath -Encoding UTF8

if ($AsJson) {
    $result | ConvertTo-Json -Depth 16
} else {
    Write-Host ''
    Write-Host '=== STACK BENCHMARK ===' -ForegroundColor Cyan
    Write-Host "Output: $outPath" -ForegroundColor Gray
    Write-Host "GV Benchmark:        $($result.layers.wf_benchmark.status) - $($result.layers.wf_benchmark.detail)"
    Write-Host "Routing Matrix:      $($result.layers.routing_matrix.status) - $($result.layers.routing_matrix.detail)"
    Write-Host "Agent Verify(Test):  $($result.layers.agent_verify_tests.status) - $($result.layers.agent_verify_tests.detail)"
    Write-Host "Baseline Regression: $($result.layers.baseline_regression.status) - $($result.layers.baseline_regression.detail)"
    Write-Host "Overall:             $($result.summary.status)"
    if ($result.remediation -and $result.remediation.report_path) {
        Write-Host "Remediation report:  $($result.remediation.report_path)" -ForegroundColor Yellow
    }
    Write-Host ''
}

if ($Strict -and $result.summary.status -ne 'PASS') {
    exit 1
}

exit 0

