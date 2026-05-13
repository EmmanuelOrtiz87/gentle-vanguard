#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Evaluate routing quality against a multilingual dataset.

.DESCRIPTION
  Runs pre-process-input.ps1 against dataset cases and computes routing quality metrics.
  Produces a session-local report in .session/routing-quality-last.json.
  Optionally updates tests/logs/routing-metrics.json for historical tracking.

.PARAMETER DatasetPath
  Path to matrix JSON with input/expected cases.

.PARAMETER WorkspaceRoot
  Workspace root path.

.PARAMETER UpdateMetrics
  When set, updates tests/logs/routing-metrics.json cumulatively.

.PARAMETER FailOnMismatch
  Exit with code 1 if any case fails.
#>

param(
    [string]$DatasetPath = "tests/e2e/routing-language-matrix.json",
    [string]$WorkspaceRoot = ".",
    [switch]$UpdateMetrics,
    [switch]$FailOnMismatch
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path $WorkspaceRoot
$datasetFull = Join-Path $root $DatasetPath
$preProcess = Join-Path $root "scripts/utilities/pre-process-input.ps1"
$sessionReportPath = Join-Path $root ".session/routing-quality-last.json"
$metricsPath = Join-Path $root "tests/logs/routing-metrics.json"

if (-not (Test-Path $datasetFull)) {
    Write-Error "Dataset not found: $datasetFull"
}
if (-not (Test-Path $preProcess)) {
    Write-Error "pre-process-input.ps1 not found: $preProcess"
}

$dataset = Get-Content $datasetFull -Raw | ConvertFrom-Json
$cases = @($dataset.cases)
if ($cases.Count -eq 0) {
    Write-Error "Dataset has no cases"
}

$results = @()
$total = 0
$passed = 0
$lowConfidence = 0
$confidenceSum = 0
$falsePositives = 0
$falseNegatives = 0
$languageStats = @{}

foreach ($case in $cases) {
    $total++

    $output = & $preProcess -UserInput $case.input -WorkspaceRoot $root
    $summary = $output | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

    if (-not $summary) {
        $summary = @{ HasMatch = $false; Skill = $null; AgentCode = $null; PlanMode = $false; Confidence = 0 }
    }

    $confidence = [int]$summary.Confidence
    $confidenceSum += $confidence
    if ($confidence -lt 60) { $lowConfidence++ }

    $expected = $case.expected
    $checks = @()

    if ($null -ne $expected.hasMatch) {
        $checks += ([bool]$summary.HasMatch -eq [bool]$expected.hasMatch)
    }
    if ($expected.skill) {
        $checks += ($summary.Skill -eq $expected.skill)
    }
    if ($expected.agentCode) {
        $checks += ($summary.AgentCode -eq $expected.agentCode)
    }
    if ($null -ne $expected.planMode) {
        $checks += ([bool]$summary.PlanMode -eq [bool]$expected.planMode)
    }
    if ($expected.minConfidence) {
        $checks += ($confidence -ge [int]$expected.minConfidence)
    }

    $casePassed = $true
    foreach ($ok in $checks) {
        if (-not $ok) { $casePassed = $false; break }
    }

    if ($casePassed) {
        $passed++
    } else {
        if ($expected.hasMatch -eq $false -and $summary.HasMatch -eq $true) { $falsePositives++ }
        if ($expected.hasMatch -eq $true -and $summary.HasMatch -eq $false) { $falseNegatives++ }
    }

    $lang = if ($case.language) { $case.language } else { "unknown" }
    if (-not $languageStats.ContainsKey($lang)) {
        $languageStats[$lang] = @{ total = 0; passed = 0; confidenceSum = 0 }
    }
    $languageStats[$lang].total++
    if ($casePassed) { $languageStats[$lang].passed++ }
    $languageStats[$lang].confidenceSum += $confidence

    $results += [PSCustomObject]@{
        id = $case.id
        language = $lang
        input = $case.input
        passed = $casePassed
        expectedSkill = $expected.skill
        actualSkill = $summary.Skill
        expectedAgentCode = $expected.agentCode
        actualAgentCode = $summary.AgentCode
        expectedPlanMode = $expected.planMode
        actualPlanMode = $summary.PlanMode
        confidence = $confidence
        trigger = $summary.Trigger
    }
}

$accuracy = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 2) } else { 0 }
$avgConfidence = if ($total -gt 0) { [math]::Round($confidenceSum / $total, 2) } else { 0 }

$languageBreakdown = @{}
foreach ($key in $languageStats.Keys) {
    $ls = $languageStats[$key]
    $langAcc = if ($ls.total -gt 0) { [math]::Round(($ls.passed / $ls.total) * 100, 2) } else { 0 }
    $langConf = if ($ls.total -gt 0) { [math]::Round($ls.confidenceSum / $ls.total, 2) } else { 0 }
    $languageBreakdown[$key] = @{
        total = $ls.total
        passed = $ls.passed
        accuracy = $langAcc
        averageConfidence = $langConf
    }
}

$report = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    datasetVersion = $dataset.version
    datasetPath = $DatasetPath
    summary = @{
        total = $total
        passed = $passed
        failed = ($total - $passed)
        accuracy = $accuracy
        averageConfidence = $avgConfidence
        lowConfidenceRoutings = $lowConfidence
        falsePositives = $falsePositives
        falseNegatives = $falseNegatives
    }
    languageBreakdown = $languageBreakdown
    results = $results
}

$sessionDir = Split-Path -Parent $sessionReportPath
if (-not (Test-Path $sessionDir)) {
    New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
}
$report | ConvertTo-Json -Depth 20 | Set-Content $sessionReportPath -Encoding UTF8

if ($UpdateMetrics) {
    $existing = $null
    if (Test-Path $metricsPath) {
        try { $existing = Get-Content $metricsPath -Raw | ConvertFrom-Json } catch { $existing = $null }
    }

    if (-not $existing) {
        $existing = [ordered]@{
            AgentDistribution = @{}
            SuccessfulRoutings = 0
            ManualOverrides = 0
            AverageConfidenceScore = 0
            LowConfidenceRoutings = 0
            TotalRoutings = 0
            FalsePositives = 0
            FalseNegatives = 0
            LanguageBreakdown = @{}
        }
    }

    $prevTotal = [int]$existing.TotalRoutings
    $prevAvg = [double]$existing.AverageConfidenceScore

    $existing.TotalRoutings = $prevTotal + $total
    $existing.SuccessfulRoutings = [int]$existing.SuccessfulRoutings + $passed
    $existing.LowConfidenceRoutings = [int]$existing.LowConfidenceRoutings + $lowConfidence
    $existing.FalsePositives = [int]$existing.FalsePositives + $falsePositives
    $existing.FalseNegatives = [int]$existing.FalseNegatives + $falseNegatives
    $existing.AverageConfidenceScore = if ($existing.TotalRoutings -gt 0) {
        [math]::Round((($prevAvg * $prevTotal) + $confidenceSum) / $existing.TotalRoutings, 2)
    } else { 0 }

    if (-not $existing.PSObject.Properties['LanguageBreakdown']) {
        $existing | Add-Member -NotePropertyName LanguageBreakdown -NotePropertyValue @{}
    }

    foreach ($lang in $languageBreakdown.Keys) {
        if (-not $existing.LanguageBreakdown.PSObject.Properties[$lang]) {
            $existing.LanguageBreakdown | Add-Member -NotePropertyName $lang -NotePropertyValue @{
                total = 0
                passed = 0
                accuracy = 0
                averageConfidence = 0
            }
        }

        $curr = $existing.LanguageBreakdown.$lang
        $lt = [int]$curr.total + [int]$languageBreakdown[$lang].total
        $lp = [int]$curr.passed + [int]$languageBreakdown[$lang].passed
        $lac = if ($lt -gt 0) { [math]::Round(($lp / $lt) * 100, 2) } else { 0 }

        $prevLangTotal = [int]$curr.total
        $prevLangAvg = [double]$curr.averageConfidence
        $newLangSum = [double]$languageBreakdown[$lang].averageConfidence * [int]$languageBreakdown[$lang].total
        $langAvg = if ($lt -gt 0) {
            [math]::Round((($prevLangAvg * $prevLangTotal) + $newLangSum) / $lt, 2)
        } else { 0 }

        $existing.LanguageBreakdown.$lang.total = $lt
        $existing.LanguageBreakdown.$lang.passed = $lp
        $existing.LanguageBreakdown.$lang.accuracy = $lac
        $existing.LanguageBreakdown.$lang.averageConfidence = $langAvg
    }

    $existing | Add-Member -NotePropertyName LastRun -NotePropertyValue (Get-Date).ToString('o') -Force
    $existing | ConvertTo-Json -Depth 20 | Set-Content $metricsPath -Encoding UTF8
}

Write-Output "Routing Quality Report"
Write-Output "  Dataset: $DatasetPath"
Write-Output "  Total: $total | Passed: $passed | Failed: $($total - $passed)"
Write-Output "  Accuracy: $accuracy% | AvgConfidence: $avgConfidence"
Write-Output "  Session report: .session/routing-quality-last.json"
if ($UpdateMetrics) {
    Write-Output "  Metrics updated: tests/logs/routing-metrics.json"
}

if ($FailOnMismatch -and $passed -lt $total) {
    exit 1
}

exit 0
