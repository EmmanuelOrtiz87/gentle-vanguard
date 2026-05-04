<#
.SYNOPSIS
    Token, Consumption, and Context Report - On-Demand Process
    
.DESCRIPTION
    Generates comprehensive reports about:
    - Token usage (total, by task, by tool)
    - Consumption patterns (trends, spikes, efficiency)
    - Context structure (hot/warm/cold tiers)
    - Utility metrics (useful vs wasted tokens)
    
.PARAMETER OutputFormat
    Report format: markdown, json, csv
    
.PARAMETER Scope
    Report scope: session, daily, weekly, all
    
.PARAMETER IncludeContext
    Include context tier information in report
    
.PARAMETER IncludeUtility
    Include token utility analysis
    
.EXAMPLE
    .\token-consumption-report.ps1 -OutputFormat markdown -Scope weekly
    Generates weekly markdown report with charts
    
.EXAMPLE
    .\token-consumption-report.ps1 -IncludeContext -IncludeUtility
    Detailed report with context tiers and utility metrics
#>

param(
    [ValidateSet('markdown', 'json', 'csv')]
    [string]$OutputFormat = 'markdown',
    
    [ValidateSet('session', 'daily', 'weekly', 'all')]
    [string]$Scope = 'session',
    
    [switch]$IncludeContext,
    [switch]$IncludeUtility
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$metricsDir = Join-Path $repoRoot 'docs\sessions\metrics'
$telemetryDir = Join-Path $repoRoot '.runtime\telemetry'
$masterFile = Join-Path $repoRoot 'docs\management\telemetry-master.csv'

function Get-TokenData {
    $allData = @()
    
    # 1. Session token-guard-usage.csv
    $usageFile = Join-Path $metricsDir 'token-guard-usage.csv'
    if (Test-Path $usageFile) {
        $rows = Import-Csv -Path $usageFile -ErrorAction SilentlyContinue
        foreach ($row in $rows) {
            $tokens = 0
            if ($row.estimated_tokens -match '^\d+$') {
                $tokens = [int]$row.estimated_tokens
                $allData += [pscustomobject]@{
                    timestamp = $row.timestamp
                    task = $row.task
                    tokens = $tokens
                    source = 'token-guard'
                }
            }
        }
    }
    
    # 2. Telemetry master file
    if (Test-Path $masterFile) {
        $rows = Import-Csv -Path $masterFile -ErrorAction SilentlyContinue
        foreach ($row in $rows) {
            $tokens = 0
            if ($row.Tokens_Estimated -match '^\d+$') {
                $tokens = [int]$row.Tokens_Estimated
                $allData += [pscustomobject]@{
                    timestamp = $row.Timestamp
                    sessionId = $row.Session_ID
                    tokens = $tokens
                    source = 'telemetry-master'
                }
            }
        }
    }
    
    return $allData
}

function Get-ContextTierInfo {
    $tierInfo = @{
        hot = @{ retention = '100%'; compression = 'none'; description = 'Active session' }
        warm = @{ retention = '90%'; compression = 'light'; description = 'Recent (1 day)' }
        cold = @{ retention = '70%'; compression = 'aggressive'; description = 'Archive (7 days)' }
        archive = @{ retention = '40%'; compression = 'extreme'; description = 'Old sessions' }
    }
    
    $configPath = Join-Path $repoRoot 'config\context-efficiency.json'
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($config.memoryTiering) {
                $tierInfo = $config.memoryTiering
            }
        } catch { }
    }
    
    return $tierInfo
}

function Get-TokenUtility {
    param($tokenData)
    
    $totalTokens = ($tokenData | Measure-Object -Property tokens -Sum).Sum
    $taskCount = ($tokenData | Group-Object task | Measure-Object).Count
    
    # Estimate useful tokens (non-redundant, actually used)
    $usefulTokens = [math]::Round($totalTokens * 0.85)  # Assume 85% efficiency
    $wastedTokens = $totalTokens - $usefulTokens
    
    return @{
        totalTokens = $totalTokens
        usefulTokens = $usefulTokens
        wastedTokens = $wastedTokens
        efficiencyRatio = if ($totalTokens -gt 0) { [math]::Round(($usefulTokens / $totalTokens) * 100, 2) } else { 0 }
    }
}

function Filter-ByScope {
    param($data, $scope)
    
    $now = Get-Date
    switch ($scope) {
        'session' { 
            $cutoff = $now.AddHours(-2)
            return $data | Where-Object { (Get-Date $_.timestamp) -gt $cutoff }
        }
        'daily' { 
            $cutoff = $now.Date
            return $data | Where-Object { (Get-Date $_.timestamp) -ge $cutoff }
        }
        'weekly' { 
            $cutoff = $now.AddDays(-7)
            return $data | Where-Object { (Get-Date $_.timestamp) -ge $cutoff }
        }
        default { return $data }
    }
}

function Generate-MarkdownReport {
    param($tokenData, $contextInfo, $utilityInfo, $scope)
    
    $report = @"
# Token Consumption & Context Report

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Scope**: $scope  
**Total Records**: $($tokenData.Count)

---

## Token Usage Summary

| Metric | Value |
|--------|-------|
| **Total Tokens** | $(($tokenData | Measure-Object -Property tokens -Sum).Sum.ToString('N0')) |
| **Average per Task** | $([math]::Round(($tokenData | Measure-Object -Property tokens -Average).Average, 0).ToString('N0')) |
| **Max Single Task** | $(($tokenData | Measure-Object -Property tokens -Maximum).Maximum.ToString('N0')) |
| **Tasks Executed** | $(($tokenData | Group-Object task | Measure-Object).Count) |

---

## Token Usage by Task (Top 10)

"@
    
    $topTasks = $tokenData | Group-Object task | 
        ForEach-Object { [pscustomobject]@{
            task = $_.Name
            totalTokens = ($_.Group | Measure-Object -Property tokens -Sum).Sum
            count = $_.Count
        }} | Sort-Object -Property totalTokens -Descending | Select-Object -First 10
    
    $report += "| Task | Total Tokens | Executions |`r`n"
    $report += "|------|--------------|------------|`r`n"
    foreach ($task in $topTasks) {
        $report += "| $($task.task) | $($task.totalTokens.ToString('N0')) | $($task.count) |`r`n"
    }
    
    if ($IncludeContext) {
        $report += @"

---

## Context Tier Structure

| Tier | Retention | Compression | Description |
|------|-----------|------------|-------------|
"@
        foreach ($tier in $contextInfo.Keys) {
            $info = $contextInfo[$tier]
            $report += "| **$tier** | $($info.retention) | $($info.compression) | $($info.description) |`r`n"
        }
    }
    
    if ($IncludeUtility) {
        $report += @"

---

## Token Utility Analysis

| Metric | Value |
|--------|-------|
| **Useful Tokens** | $($utilityInfo.usefulTokens.ToString('N0')) |
| **Wasted Tokens** | $($utilityInfo.wastedTokens.ToString('N0')) |
| **Efficiency Ratio** | $($utilityInfo.efficiencyRatio)% |

**Note**: Utility estimation assumes 85% efficiency baseline. Actual may vary.
"@
    }
    
    $report += @"

---

## Data Sources

- `docs/sessions/metrics/token-guard-usage.csv`
- `docs/management/telemetry-master.csv`
- `config/context-efficiency.json`

---

**End of Report**
"@
    
    return $report
}

function Generate-JsonReport {
    param($tokenData, $contextInfo, $utilityInfo, $scope)
    
    $report = @{
        generatedAt = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        scope = $scope
        summary = @{
            totalTokens = ($tokenData | Measure-Object -Property tokens -Sum).Sum
            totalRecords = $tokenData.Count
            avgPerTask = [math]::Round(($tokenData | Measure-Object -Property tokens -Average).Average, 0)
        }
        topTasks = @()
        contextTiers = $contextInfo
        utility = $utilityInfo
    }
    
    $topTasks = $tokenData | Group-Object task | 
        ForEach-Object { [pscustomobject]@{
            task = $_.Name
            totalTokens = ($_.Group | Measure-Object -Property tokens -Sum).Sum
            count = $_.Count
        }} | Sort-Object -Property totalTokens -Descending | Select-Object -First 10
    
    $report.topTasks = $topTasks
    
    return $report | ConvertTo-Json -Depth 10
}

function Generate-CsvReport {
    param($tokenData)
    
    $outputFile = Join-Path $metricsDir "token-consumption-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $tokenData | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    
    return $outputFile
}

# MAIN EXECUTION

Write-Host "=== Token Consumption Report ===" -ForegroundColor Cyan
Write-Host "Scope: $Scope" -ForegroundColor Gray
Write-Host "Format: $OutputFormat" -ForegroundColor Gray
Write-Host ""

# 1. Get token data
Write-Host "[INFO] Collecting token data..." -ForegroundColor Gray
$tokenData = Get-TokenData
$filteredData = Filter-ByScope -data $tokenData -scope $Scope

if ($filteredData.Count -eq 0) {
    Write-Host "[WARN] No token data found for scope: $Scope" -ForegroundColor Yellow
    exit 0
}

Write-Host "[OK] Found $($filteredData.Count) records" -ForegroundColor Green

# 2. Get context tier info
$contextInfo = if ($IncludeContext) { Get-ContextTierInfo } else { @{} }

# 3. Get utility info
$utilityInfo = if ($IncludeUtility) { Get-TokenUtility -tokenData $filteredData } else { @{} }

# 4. Generate report
Write-Host "[INFO] Generating report..." -ForegroundColor Gray

switch ($OutputFormat) {
    'markdown' {
        $report = Generate-MarkdownReport -tokenData $filteredData -contextInfo $contextInfo -utilityInfo $utilityInfo -scope $Scope
        Write-Host $report
    }
    'json' {
        $report = Generate-JsonReport -tokenData $filteredData -contextInfo $contextInfo -utilityInfo $utilityInfo -scope $Scope
        Write-Host $report
    }
    'csv' {
        $outputFile = Generate-CsvReport -tokenData $filteredData
        Write-Host "[OK] CSV report: $outputFile" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Report Complete ===" -ForegroundColor Cyan
