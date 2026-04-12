# generate-audit-report.ps1
# Generates human-readable audit reports for stakeholders

param(
    [ValidateSet("weekly", "monthly", "executive")]
    [string]$Period = "weekly",
    [datetime]$StartDate,
    [datetime]$EndDate,
    [string]$OutputFormat = "markdown",
    [switch]$Silent
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$auditDir = Join-Path $projectRoot ".audit"
$metricsDir = Join-Path $auditDir "metrics"
$reportsDir = Join-Path $auditDir "reports"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Silent) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

if (-not $StartDate) {
    $EndDate = Get-Date
    switch ($Period) {
        "weekly" { $StartDate = $EndDate.AddDays(-7).Date }
        "monthly" { $StartDate = $EndDate.AddDays(-30).Date }
        "executive" { $StartDate = $EndDate.AddDays(-90).Date }
    }
}
if (-not $EndDate) { $EndDate = Get-Date }

function Get-SessionsInRange {
    param([datetime]$Start, [datetime]$End)
    
    $sessionsPath = Join-Path $auditDir "sessions"
    if (-not (Test-Path $sessionsPath)) { return @() }
    
    $sessions = @()
    Get-ChildItem -Path $sessionsPath -Filter "*.json" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $timestamp = [DateTime]::Parse($content.timestamp)
        if ($timestamp -ge $Start -and $timestamp -le $End) {
            $sessions += $content
        }
    }
    return $sessions
}

function Get-MetricFile {
    param([string]$Type)
    $path = Join-Path $metricsDir "$Type.json"
    if (Test-Path $path) {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    return $null
}

function Get-DailyBreakdown {
    param($Sessions)
    
    $daily = @{}
    foreach ($session in $Sessions) {
        $timestamp = [DateTime]::Parse($session.timestamp)
        $day = $timestamp.ToString("yyyy-MM-dd")
        
        if (-not $daily.ContainsKey($day)) {
            $daily[$day] = @{
                date = $day
                sessions = 0
                requests = 0
                linesAdded = 0
                linesRemoved = 0
            }
        }
        
        $daily[$day].sessions++
        
        foreach ($tool in $session.aiTools.PSObject.Properties) {
            $daily[$day].requests += $tool.Value.requests
        }
        
        $daily[$day].linesAdded += $session.activity.linesAdded
        $daily[$day].linesRemoved += $session.activity.linesRemoved
    }
    
    return ($daily.GetEnumerator() | Sort-Object Name | Select-Object -ExpandProperty Value)
}

function Format-PercentChange {
    param($Current, $Previous)
    if ($Previous -eq 0) { return "N/A" }
    $change = (($Current - $Previous) / $Previous) * 100
    $sign = if ($change -ge 0) { "+" } else { "" }
    return "$sign$([math]::Round($change, 1))%"
}

function Get-TrendIcon {
    param($Change)
    if ($Change -gt 5) { return "[OK]"; }
    if ($Change -lt -5) { return "[WARN]"; }
    return "[--]";
}

Write-Log "Generating $Period audit report..." "INFO"
Write-Log "Period: $($StartDate.ToString('yyyy-MM-dd')) - $($EndDate.ToString('yyyy-MM-dd'))" "INFO"

$sessions = Get-SessionsInRange -Start $StartDate -End $EndDate
$velocity = Get-MetricFile -Type "velocity"
$effectiveness = Get-MetricFile -Type "ai-effectiveness"
$costs = Get-MetricFile -Type "costs"
$daily = Get-DailyBreakdown -Sessions $sessions

if ($sessions.Count -eq 0) {
    Write-Warning "No data found for the specified period."
    exit 1
}

$projectName = Split-Path $projectRoot -Leaf

$totalRequests = 0
$totalTokens = 0
foreach ($session in $sessions) {
    foreach ($tool in $session.aiTools.PSObject.Properties) {
        $totalRequests += $tool.Value.requests
        if ($tool.Value.tokensEstimated) {
            $totalTokens += $tool.Value.tokensEstimated
        }
    }
}

$activeUsers = ($sessions | ForEach-Object { $_.user.userName } | Select-Object -Unique).Count

$totalLinesAdded = ($sessions | Measure-Object -Property activity -ExpandProperty activity | Measure-Object -Property linesAdded -Sum).Sum
$totalLinesRemoved = ($sessions | Measure-Object -Property activity -ExpandProperty activity | Measure-Object -Property linesRemoved -Sum).Sum

$periodDays = ($EndDate - $StartDate).Days + 1

$weeklyReport = @"
# AI Development $Period Report

**Project:** $projectName  
**Period:** $($StartDate.ToString('yyyy-MM-dd')) - $($EndDate.ToString('yyyy-MM-dd'))  
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---

## Executive Summary

> [!NOTE]
> This $Period shows **$(Get-TrendIcon $activeUsers)** activity with **$activeUsers active developer(s)**.

| Metric | This $Period | Change |
|--------|--------------|--------|
| Active Developers | $activeUsers | -- |
| Total AI Requests | $totalRequests | -- |
| Estimated Tokens | $([math]::Round($totalTokens / 1000, 1))K | -- |
| Lines Generated | $totalLinesAdded | -- |
| Lines Removed | $totalLinesRemoved | -- |
| Est. Cost | `$$([math]::Round($costs.summary.totalEstimatedCost, 2)) | -- |

---

## Activity Summary

### Sessions Breakdown

| Metric | Value |
|--------|-------|
| Total Sessions | $($sessions.Count) |
| Avg Session Duration | $([math]::Round(($sessions | Measure-Object -Property metrics -ExpandProperty metrics | Measure-Object -Property duration -Average).Average, 1)) min |
| Sessions per Day | $([math]::Round($sessions.Count / $periodDays, 1)) |

### AI Tool Usage

| Tool | Requests | Est. Tokens |
|------|----------|-------------|
"@

$toolUsage = @{}
foreach ($session in $sessions) {
    foreach ($tool in $session.aiTools.PSObject.Properties) {
        if (-not $toolUsage.ContainsKey($tool.Name)) {
            $toolUsage[$tool.Name] = @{ requests = 0; tokens = 0 }
        }
        $toolUsage[$tool.Name].requests += $tool.Value.requests
        $toolUsage[$tool.Name].tokens += $tool.Value.tokensEstimated
    }
}

foreach ($tool in $toolUsage.Keys | Sort-Object) {
    $weeklyReport += "| $($tool.ToUpper()) | $($toolUsage[$tool].requests) | $([math]::Round($toolUsage[$tool].tokens / 1000, 1))K |`n"
}

$weeklyReport += @"

### Code Changes

| Category | Count |
|----------|-------|
| Files Created | $($velocity.files.created) |
| Files Modified | $($velocity.files.modified) |
| Files Deleted | $($velocity.files.deleted) |
| PRs Opened | $($velocity.pullRequests.opened) |
| PRs Merged | $($velocity.pullRequests.merged) |

---

## Quality Metrics

### AI Effectiveness

| Metric | Value |
|--------|-------|
| Total Requests | $totalRequests |
| Success Rate | $($effectiveness.overall.successRate)% |
| Avg Response Time | $($effectiveness.overall.avgResponseTime)ms |

### Action Breakdown

| Action | Count |
|--------|-------|
| Code Generation | $($effectiveness.actionBreakdown.codeGeneration.count) |
| Code Review | $($effectiveness.actionBreakdown.codeReview.count) |
| Refactoring | $($effectiveness.actionBreakdown.refactoring.count) |
| Testing | $($effectiveness.actionBreakdown.testing.count) |
| Documentation | $($effectiveness.actionBreakdown.documentation.count) |

---

## Cost Analysis

| Category | Amount | % of Total |
|----------|--------|------------|
| Claude API | `$$([math]::Round($costs.byTool.claude.estimatedCost, 2)) | $($costs.byTool.claude.estimatedCost / $costs.summary.totalEstimatedCost * 100)% |
| OpenAI API | `$$([math]::Round($costs.byTool.opencode.estimatedCost, 2)) | $($costs.byTool.opencode.estimatedCost / $costs.summary.totalEstimatedCost * 100)% |
| **Total** | **`$$([math]::Round($costs.summary.totalEstimatedCost, 2))** | 100% |

### Cost Projections

| Projection | Amount |
|------------|--------|
| Daily Average | `$$($costs.forecasting.dailyAverage) |
| Weekly | `$$($costs.forecasting.weeklyProjected) |
| Monthly | `$$($costs.forecasting.monthlyProjected) |
| Quarterly | `$$($costs.forecasting.quarterlyProjected) |

---

## Daily Activity

| Date | Sessions | Requests | Lines Added | Lines Removed |
|------|----------|----------|-------------|---------------|
"@

foreach ($day in $daily) {
    $weeklyReport += "| $($day.date) | $($day.sessions) | $($day.requests) | $($day.linesAdded) | $($day.linesRemoved) |`n"
}

$weeklyReport += @"

---

## Insights

$(if ($activeUsers -gt 3) { "- Good team adoption with $activeUsers active developers" } else { "- Consider promoting AI tool usage among the team" })
$(if ($totalRequests / $sessions.Count -gt 10) { "- High AI engagement with average $([math]::Round($totalRequests / $sessions.Count, 1)) requests per session" } else { "- Consider more AI-assisted workflows" })
$(if ($costs.summary.totalEstimatedCost -gt 100) { "- Cost is notable at `$$([math]::Round($costs.summary.totalEstimatedCost, 2)) - review for optimization opportunities" })

---

## Recommendations

1. Continue tracking metrics to establish baseline patterns
2. Review high-value AI use cases for team sharing
3. Monitor cost trends and optimize token usage where possible

---

## Appendix

- Detailed session logs: \`.audit/sessions/\`
- Metrics data: \`.audit/metrics/\`
- Code reviews: \`.audit/code-reviews/\`

---
*Generated by Workspace Foundation Audit System*
"

$reportFileName = "$Period-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').md"
$reportPath = Join-Path $reportsDir $reportFileName
$weeklyReport | Out-File -FilePath $reportPath -Encoding UTF8

Write-Log "Report generated: $reportPath" "OK"

if (-not $Silent) {
    Write-Host ""
    Write-Log "Summary:" "INFO"
    Write-Host "  Sessions: $($sessions.Count)" -ForegroundColor White
    Write-Host "  Active developers: $activeUsers" -ForegroundColor White
    Write-Host "  Total requests: $totalRequests" -ForegroundColor White
    Write-Host "  Estimated cost: `$$([math]::Round($costs.summary.totalEstimatedCost, 2))" -ForegroundColor White
}

return $reportPath
