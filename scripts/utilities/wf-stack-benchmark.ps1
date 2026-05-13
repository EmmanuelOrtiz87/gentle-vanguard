#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Full stack benchmark for coverage + performance baselines.

.DESCRIPTION
  Runs three layers:
  1) wf benchmark (command latency vs SLO)
  2) multilingual routing matrix (coverage/accuracy)
  3) agent-verify tests domain (structural quality gate)

  Writes consolidated output to reports/stack-benchmark.json

.PARAMETER AsJson
  Print consolidated JSON summary.

.PARAMETER Strict
  Exit non-zero if any layer fails.
#>

param(
    [switch]$AsJson,
    [switch]$Strict
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$wfBench = Join-Path $repoRoot 'scripts\utilities\wf-benchmark.ps1'
$routingEval = Join-Path $repoRoot 'scripts\utilities\routing-quality-eval.ps1'
$agentVerify = Join-Path $repoRoot 'scripts\utilities\agent-verify.ps1'
$outPath = Join-Path $repoRoot 'reports\stack-benchmark.json'

if (-not (Test-Path (Split-Path -Parent $outPath))) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $outPath) -Force | Out-Null
}

$result = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    layers = [ordered]@{}
    summary = [ordered]@{
        status = 'PASS'
        failed_layers = @()
    }
}

# Layer 1: wf benchmark
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
        $layer1.detail = "wf benchmark error: $($_.Exception.Message)"
    }
} else {
    $layer1.status = 'FAIL'
    $layer1.detail = 'wf-benchmark.ps1 not found'
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

# Summary
$failed = @()
foreach ($name in @('wf_benchmark', 'routing_matrix', 'agent_verify_tests')) {
    if ($result.layers.$name.status -ne 'PASS') {
        $failed += $name
    }
}
if ($failed.Count -gt 0) {
    $result.summary.status = 'FAIL'
    $result.summary.failed_layers = $failed
}

$result | ConvertTo-Json -Depth 12 | Set-Content -Path $outPath -Encoding UTF8

if ($AsJson) {
    $result | ConvertTo-Json -Depth 12
} else {
    Write-Host ''
    Write-Host '=== STACK BENCHMARK ===' -ForegroundColor Cyan
    Write-Host "Output: $outPath" -ForegroundColor Gray
    Write-Host "WF Benchmark:      $($result.layers.wf_benchmark.status) - $($result.layers.wf_benchmark.detail)"
    Write-Host "Routing Matrix:    $($result.layers.routing_matrix.status) - $($result.layers.routing_matrix.detail)"
    Write-Host "Agent Verify(Test): $($result.layers.agent_verify_tests.status) - $($result.layers.agent_verify_tests.detail)"
    Write-Host "Overall:           $($result.summary.status)"
    Write-Host ''
}

if ($Strict -and $result.summary.status -ne 'PASS') {
    exit 1
}

exit 0
