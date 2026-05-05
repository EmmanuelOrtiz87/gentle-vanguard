<#
.SYNOPSIS
    Generates an extended static HTML dashboard from local telemetry and metrics sources.

.DESCRIPTION
    Reads from:
    - config/metrics-config.json
    - config/orchestrator.json
    - .event-bus/history.json
    - .event-bus/rate-limit-state.json
    - docs/management/telemetry-master.csv
    - docs/sessions/metrics/*.csv
    - .runtime/telemetry/cloud-agent-telemetry.csv

    Output: reports/dashboard.html

.PARAMETER OutputPath
    Path for the generated HTML file. Default: reports/dashboard.html

.PARAMETER Open
    Open the generated file in the default browser.
#>
param(
    [string]$OutputPath = '',
    [switch]$Open
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

if (-not $OutputPath) {
    $reportsDir = Join-Path $repoRoot 'reports'
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    $OutputPath = Join-Path $reportsDir 'dashboard.html'
}

function Read-JsonFile {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        catch {
            return $null
        }
    }
    return $null
}

function Import-CsvSafe {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return @()
    }
    try {
        return @(Import-Csv -Path $Path -Encoding UTF8)
    }
    catch {
        return @()
    }
}

function Get-IntValue {
    param($Value)
    $out = 0
    [void][int]::TryParse([string]$Value, [ref]$out)
    return $out
}

function Get-DoubleValue {
    param($Value)
    $out = 0.0
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return 0.0
    }

    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$out)) {
        return $out
    }

    $text = $text.Replace(',', '.')
    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$out)) {
        return $out
    }

    return 0.0
}

  function Get-DateValue {
    param($Value)
    if ($null -eq $Value) {
      return $null
    }

    try {
      return [datetime]$Value
    }
    catch {
      return $null
    }
  }

function ConvertTo-HtmlSafe {
    param([string]$Value)
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Build-TableHtml {
    param(
        [array]$Rows,
        [string[]]$Columns,
        [int]$MaxRows = 120
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return '<p class="muted">No data available.</p>'
    }

    $head = ($Columns | ForEach-Object { '<th>' + (ConvertTo-HtmlSafe $_) + '</th>' }) -join ''
    $body = ''

    $rowsToShow = $Rows | Select-Object -Last $MaxRows
    foreach ($row in $rowsToShow) {
        $cells = foreach ($col in $Columns) {
            $val = ''
            if ($row.PSObject.Properties[$col]) {
                $val = [string]$row.$col
            }
            '<td>' + (ConvertTo-HtmlSafe $val) + '</td>'
        }
        $body += '<tr>' + ($cells -join '') + '</tr>'
    }

    return "<table><thead><tr>$head</tr></thead><tbody>$body</tbody></table>"
}

function Build-MetricCard {
    param(
        [string]$Title,
        [string]$Value,
        [string]$Label
    )

    return @"
<div class="card">
  <h3>$Title</h3>
  <div class="value">$Value</div>
  <div class="label">$Label</div>
</div>
"@
}

# Load sources
$metricsCfg = Read-JsonFile (Join-Path $repoRoot 'config\metrics-config.json')
$orchCfg = Read-JsonFile (Join-Path $repoRoot 'config\orchestrator.json')
$eventHist = Read-JsonFile (Join-Path $repoRoot '.event-bus\history.json')
$rateLimit = Read-JsonFile (Join-Path $repoRoot '.event-bus\rate-limit-state.json')

$telemetryMasterPath = Join-Path $repoRoot 'docs\management\telemetry-master.csv'
$tokenGuardPath = Join-Path $repoRoot 'docs\sessions\metrics\token-guard-usage.csv'
$contextUsagePath = Join-Path $repoRoot 'docs\sessions\metrics\context-usage.csv'
$agentUsagePath = Join-Path $repoRoot 'docs\sessions\metrics\agent-usage.csv'
$judgmentPath = Join-Path $repoRoot 'docs\sessions\metrics\judgment-history.csv'
$textSimplificationPath = Join-Path $repoRoot 'docs\sessions\metrics\text-simplification.csv'
$runtimeTelemetryPath = Join-Path $repoRoot '.runtime\telemetry\cloud-agent-telemetry.csv'

$telemetryRows = Import-CsvSafe $telemetryMasterPath
$tokenGuardRows = Import-CsvSafe $tokenGuardPath
$contextRows = Import-CsvSafe $contextUsagePath
$agentRows = Import-CsvSafe $agentUsagePath
$judgmentRows = Import-CsvSafe $judgmentPath
$textRows = Import-CsvSafe $textSimplificationPath
$runtimeRows = Import-CsvSafe $runtimeTelemetryPath

# Core metrics
$generated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$orchVersion = if ($orchCfg -and $orchCfg.version) { $orchCfg.version } else { 'N/A' }
$dailyBudget = if ($orchCfg -and $orchCfg.subagent_orchestration -and $orchCfg.subagent_orchestration.token_budget_guard) { [int]$orchCfg.subagent_orchestration.token_budget_guard.daily_budget_tokens } else { 30000 }
$runtimeState = if ($metricsCfg -and $metricsCfg.runtime_state) { $metricsCfg.runtime_state } else { $null }

$sessionIds = @($telemetryRows | Where-Object { $_.Session_ID } | Select-Object -ExpandProperty Session_ID -Unique)
$sessionsTotal = if ($sessionIds.Count -gt 0) { $sessionIds.Count } else { if ($runtimeState -and $runtimeState.session_count) { [int]$runtimeState.session_count } else { 0 } }

$dispatchTotal = if ($runtimeState -and $runtimeState.total_delegations) { [int]$runtimeState.total_delegations } else { 0 }
if ($dispatchTotal -eq 0 -and $runtimeState -and $runtimeState.total_dispatches) {
    $dispatchTotal = [int]$runtimeState.total_dispatches
}

$tokensTelemetry = ($telemetryRows | ForEach-Object { Get-IntValue $_.Tokens_Estimated } | Measure-Object -Sum).Sum
$tokensGuard = ($tokenGuardRows | ForEach-Object { Get-IntValue $_.estimated_tokens } | Measure-Object -Sum).Sum
$tokensRuntime = ($runtimeRows | ForEach-Object { (Get-IntValue $_.InputTokens) + (Get-IntValue $_.OutputTokens) } | Measure-Object -Sum).Sum
$tokensAllTime = [int]([Math]::Max([Math]::Max($tokensTelemetry, $tokensGuard), $tokensRuntime))

$avgDuration = ($telemetryRows | ForEach-Object { Get-DoubleValue $_.Duration_Min } | Where-Object { $_ -gt 0 } | Measure-Object -Average).Average
if (-not $avgDuration) { $avgDuration = 0 }
$avgDuration = [math]::Round($avgDuration, 1)

$avgEfficiency = ($telemetryRows | ForEach-Object { Get-DoubleValue $_.Efficiency_Score } | Where-Object { $_ -gt 0 } | Measure-Object -Average).Average
if (-not $avgEfficiency) { $avgEfficiency = 0 }
$avgEfficiency = [math]::Round($avgEfficiency, 2)

# Events
$eventCount = 0
$eventEmitted = 0
$eventBlocked = 0
$eventByType = @{}
if ($eventHist -and $eventHist.events) {
    $eventCount = $eventHist.events.Count
    foreach ($e in $eventHist.events) {
        if ($e.status -eq 'emitted') { $eventEmitted++ } else { $eventBlocked++ }
        $eventName = if ($e.event) { [string]$e.event } else { 'unknown' }
        if (-not $eventByType.ContainsKey($eventName)) {
            $eventByType[$eventName] = 0
        }
        $eventByType[$eventName]++
    }
}

# Context metrics
$totalContextEvents = $contextRows.Count
$compactEvents = @($contextRows | Where-Object { $_.event -eq 'compact-start' }).Count
$contextPackEvents = @($contextRows | Where-Object { $_.event -eq 'context-pack' }).Count
$adoptionPct = if ($totalContextEvents -gt 0) { [math]::Round(($compactEvents * 100.0) / $totalContextEvents, 1) } else { 0 }
$avgPromptChars = [math]::Round((($contextRows | ForEach-Object { Get-IntValue $_.prompt_chars } | Where-Object { $_ -gt 0 } | Measure-Object -Average).Average), 1)
if (-not $avgPromptChars) { $avgPromptChars = 0 }

# Runtime telemetry summary
$runtimeRequests = $runtimeRows.Count
$runtimeErrors = @($runtimeRows | Where-Object { $_.Status -eq 'ERROR' }).Count
$runtimeSuccess = @($runtimeRows | Where-Object { $_.Status -eq 'SUCCESS' }).Count
$runtimeLatencyAvg = [math]::Round((($runtimeRows | ForEach-Object { Get-DoubleValue $_.LatencyMs } | Where-Object { $_ -gt 0 } | Measure-Object -Average).Average), 1)
if (-not $runtimeLatencyAvg) { $runtimeLatencyAvg = 0 }

# Cost and savings model
$costPer1M = 10.0
$actualCost = [math]::Round(($tokensAllTime / 1000000.0) * $costPer1M, 2)

$baselineTokensPerTask = 14000
$tasksObserved = if ($tokenGuardRows.Count -gt 0) { $tokenGuardRows.Count } else { [math]::Max(1, $sessionsTotal) }
$baselineModelTokens = $tasksObserved * $baselineTokensPerTask

$reductionPolicyPct = 40.0
$optimizedModelTokens = [math]::Round($baselineModelTokens * (1 - ($reductionPolicyPct / 100.0)), 0)
$modeledSavingsTokens = [int]($baselineModelTokens - $optimizedModelTokens)
$modeledSavingsCost = [math]::Round(($modeledSavingsTokens / 1000000.0) * $costPer1M, 2)

$simplificationSavedTokens = ($textRows | ForEach-Object { Get-IntValue $_.tokens_saved_estimate } | Measure-Object -Sum).Sum
$simplificationSavedCost = [math]::Round(($simplificationSavedTokens / 1000000.0) * $costPer1M, 4)
$avgReductionPct = [math]::Round((($textRows | ForEach-Object { Get-DoubleValue $_.reduction_pct } | Where-Object { $_ -ge 0 } | Measure-Object -Average).Average), 1)
if (-not $avgReductionPct) { $avgReductionPct = 0 }

# Financial cadence (MTD / YTD / projection)
$today = Get-Date
$currentYear = $today.Year
$currentMonth = $today.Month
$daysElapsedInMonth = [Math]::Max(1, $today.Day)
$daysInMonth = [DateTime]::DaysInMonth($currentYear, $currentMonth)

$tokenTimeRows = @()
foreach ($r in $tokenGuardRows) {
  $dateRef = $null
  if ($r.date) {
    $dateRef = Get-DateValue $r.date
  }
  if (-not $dateRef) {
    $dateRef = Get-DateValue $r.timestamp
  }
  if (-not $dateRef) {
    continue
  }

  $tokenTimeRows += [pscustomobject]@{
    DateRef = $dateRef
    Tokens = (Get-IntValue $r.estimated_tokens)
    Task = [string]$r.task
  }
}

$mtdRows = @($tokenTimeRows | Where-Object { $_.DateRef.Year -eq $currentYear -and $_.DateRef.Month -eq $currentMonth })
$ytdRows = @($tokenTimeRows | Where-Object { $_.DateRef.Year -eq $currentYear })

$tokensMTD = [int](($mtdRows | ForEach-Object { $_.Tokens } | Measure-Object -Sum).Sum)
$tokensYTD = [int](($ytdRows | ForEach-Object { $_.Tokens } | Measure-Object -Sum).Sum)
$costMTD = [math]::Round(($tokensMTD / 1000000.0) * $costPer1M, 2)
$costYTD = [math]::Round(($tokensYTD / 1000000.0) * $costPer1M, 2)

$projectedMonthTokens = [int][math]::Round(($tokensMTD / $daysElapsedInMonth) * $daysInMonth, 0)
$projectedMonthCost = [math]::Round(($projectedMonthTokens / 1000000.0) * $costPer1M, 2)

$mtdTaskCount = $mtdRows.Count
$ytdTaskCount = $ytdRows.Count
$baselineMtdTokens = $mtdTaskCount * $baselineTokensPerTask
$baselineYtdTokens = $ytdTaskCount * $baselineTokensPerTask
$optimizedMtdTokens = [math]::Round($baselineMtdTokens * (1 - ($reductionPolicyPct / 100.0)), 0)
$optimizedYtdTokens = [math]::Round($baselineYtdTokens * (1 - ($reductionPolicyPct / 100.0)), 0)
$modeledMtdSavingsTokens = [int]($baselineMtdTokens - $optimizedMtdTokens)
$modeledYtdSavingsTokens = [int]($baselineYtdTokens - $optimizedYtdTokens)
$modeledMtdSavingsCost = [math]::Round(($modeledMtdSavingsTokens / 1000000.0) * $costPer1M, 2)
$modeledYtdSavingsCost = [math]::Round(($modeledYtdSavingsTokens / 1000000.0) * $costPer1M, 2)

# Runtime cost by model
$modelCostMap = @{}
foreach ($r in $runtimeRows) {
  $modelName = [string]$r.Model
  if ([string]::IsNullOrWhiteSpace($modelName)) {
    $modelName = '(unknown)'
  }

  if (-not $modelCostMap.ContainsKey($modelName)) {
    $modelCostMap[$modelName] = [pscustomobject]@{
      Model = $modelName
      Requests = 0
      Tokens = 0
      CostUsd = 0.0
    }
  }

  $reqTokens = (Get-IntValue $r.InputTokens) + (Get-IntValue $r.OutputTokens)
  $entry = $modelCostMap[$modelName]
  $entry.Requests += 1
  $entry.Tokens += $reqTokens
  $entry.CostUsd = [math]::Round(($entry.Tokens / 1000000.0) * $costPer1M, 4)
}

$modelCostRows = @($modelCostMap.Values | Sort-Object CostUsd -Descending)
$modelCostRowsFormatted = @($modelCostRows | ForEach-Object {
  [pscustomobject]@{
    Model = $_.Model
    Requests = $_.Requests
    Tokens = [string]::Format('{0:N0}', $_.Tokens)
    Cost_USD = ('{0:N4}' -f $_.CostUsd)
  }
})
$modelCostTable = Build-TableHtml -Rows $modelCostRowsFormatted -Columns @('Model','Requests','Tokens','Cost_USD') -MaxRows 20

# Agent cost allocation (proportional by dispatch volume)
$agentCountMap = @{}
foreach ($r in $agentRows) {
  $agentName = [string]$r.agent
  if ([string]::IsNullOrWhiteSpace($agentName)) {
    $agentName = '(unknown)'
  }
  if (-not $agentCountMap.ContainsKey($agentName)) {
    $agentCountMap[$agentName] = 0
  }
  $agentCountMap[$agentName] += 1
}

$agentTotalInvocations = [int](($agentCountMap.Values | Measure-Object -Sum).Sum)
$agentCostRows = @()
foreach ($agentName in $agentCountMap.Keys) {
  $invocations = [int]$agentCountMap[$agentName]
  $sharePct = if ($agentTotalInvocations -gt 0) { ($invocations * 100.0) / $agentTotalInvocations } else { 0 }
  $allocatedTokens = [int][math]::Round(($tokensGuard * $sharePct) / 100.0, 0)
  $allocatedCost = [math]::Round(($allocatedTokens / 1000000.0) * $costPer1M, 4)

  $agentCostRows += [pscustomobject]@{
    Agent = $agentName
    Invocations = $invocations
    Share_Pct = ('{0:N1}%' -f $sharePct)
    Allocated_Tokens = [string]::Format('{0:N0}', $allocatedTokens)
    Allocated_Cost_USD = ('{0:N4}' -f $allocatedCost)
  }
}
$agentCostRows = @($agentCostRows | Sort-Object Invocations -Descending)
$agentCostTable = Build-TableHtml -Rows $agentCostRows -Columns @('Agent','Invocations','Share_Pct','Allocated_Tokens','Allocated_Cost_USD') -MaxRows 20

# Charts data
$tokenDaily = @{}
foreach ($r in $tokenGuardRows) {
    $day = if ($r.date) { [string]$r.date } else { '' }
    if (-not $day) {
        try {
            $day = ([datetime]$r.timestamp).ToString('yyyy-MM-dd')
        }
        catch {
            $day = 'unknown'
        }
    }
    if (-not $tokenDaily.ContainsKey($day)) {
        $tokenDaily[$day] = 0
    }
    $tokenDaily[$day] += Get-IntValue $r.estimated_tokens
}

$tokenDailyRows = @($tokenDaily.GetEnumerator() | Sort-Object Name | Select-Object -Last 30)
$tokenLabels = ($tokenDailyRows | ForEach-Object { "'" + $_.Name + "'" }) -join ','
$tokenValues = ($tokenDailyRows | ForEach-Object { [int]$_.Value }) -join ','

$costLabels = ($tokenDailyRows | ForEach-Object { "'" + $_.Name + "'" }) -join ','
$costValues = ($tokenDailyRows | ForEach-Object { [math]::Round(([double]$_.Value / 1000000.0) * $costPer1M, 4).ToString([System.Globalization.CultureInfo]::InvariantCulture) }) -join ','

$eventTypeLabels = ($eventByType.Keys | ForEach-Object { "'" + $_ + "'" }) -join ','
$eventTypeValues = ($eventByType.Values | ForEach-Object { [int]$_ }) -join ','

# Recent events table
$recentEventsHtml = ''
if ($eventHist -and $eventHist.events) {
    $recentEvents = $eventHist.events | Select-Object -Last 40
    foreach ($e in $recentEvents) {
        $statusClass = if ($e.status -eq 'emitted') { 'ok' } else { 'blocked' }
        $ts = ConvertTo-HtmlSafe ([string]$e.timestamp)
        $ev = ConvertTo-HtmlSafe ([string]$e.event)
        $st = ConvertTo-HtmlSafe ([string]$e.status)
        $recentEventsHtml += "<tr class='$statusClass'><td>$ts</td><td>$ev</td><td>$st</td></tr>`n"
    }
}

      $rateLimitLabel = ConvertTo-HtmlSafe ([string]$rateLimit.updated)

# Metrics explorer blocks
$telemetryTable = Build-TableHtml -Rows $telemetryRows -Columns @('Timestamp','User_ID','Session_ID','Task_Scope','Tokens_Estimated','Judgment_Result','Review_Issues','Duration_Min','Efficiency_Score')
$tokenGuardTable = Build-TableHtml -Rows $tokenGuardRows -Columns @('timestamp','date','task','risk','estimated_tokens','status','engram_available','notes')
$contextTable = Build-TableHtml -Rows $contextRows -Columns @('timestamp','event','repository','branch','objective_chars','changed_count','prompt_chars','output_file')
$agentTable = Build-TableHtml -Rows $agentRows -Columns @('timestamp','agent','skill','task','duration_ms')
$judgmentTable = Build-TableHtml -Rows $judgmentRows -Columns @('Timestamp','Failures','TotalChecks','Result')
$textTable = Build-TableHtml -Rows $textRows -Columns @('timestamp','metric','original_chars','simplified_chars','reduction_pct','tokens_saved_estimate')
$runtimeTable = Build-TableHtml -Rows $runtimeRows -Columns @('Timestamp','User_ID','Session_ID','Request_ID','Provider','Model','InputTokens','OutputTokens','LatencyMs','Status','ErrorMessage')

$cardsOverview = @()
$cardsOverview += Build-MetricCard -Title 'Sessions' -Value $sessionsTotal -Label 'unique sessions'
$cardsOverview += Build-MetricCard -Title 'Dispatches' -Value $dispatchTotal -Label 'agent delegations'
$cardsOverview += Build-MetricCard -Title 'Tokens' -Value ([string]::Format('{0:N0}', $tokensAllTime)) -Label 'all-time estimated'
$cardsOverview += Build-MetricCard -Title 'Events' -Value "$eventEmitted / $eventCount" -Label "emitted / total"
$cardsOverview += Build-MetricCard -Title 'Avg Duration' -Value $avgDuration -Label 'minutes'
$cardsOverview += Build-MetricCard -Title 'Avg Efficiency' -Value $avgEfficiency -Label 'telemetry score'
$cardsOverview += Build-MetricCard -Title 'Context Adoption' -Value "$adoptionPct%" -Label "compact-start share"
$cardsOverview += Build-MetricCard -Title 'Daily Budget' -Value ([string]::Format('{0:N0}', $dailyBudget)) -Label 'tokens/day'
$cardsOverview += Build-MetricCard -Title 'Runtime Requests' -Value $runtimeRequests -Label "ok=$runtimeSuccess err=$runtimeErrors"
$cardsOverview += Build-MetricCard -Title 'Runtime Latency' -Value "$runtimeLatencyAvg ms" -Label 'average'

$cardsCosts = @()
$cardsCosts += Build-MetricCard -Title 'Actual Cost' -Value ('$' + $actualCost) -Label 'using $10 / 1M tokens'
$cardsCosts += Build-MetricCard -Title 'MTD Cost' -Value ('$' + $costMTD) -Label 'month-to-date'
$cardsCosts += Build-MetricCard -Title 'YTD Cost' -Value ('$' + $costYTD) -Label 'year-to-date'
$cardsCosts += Build-MetricCard -Title 'Month-End Forecast' -Value ('$' + $projectedMonthCost) -Label "run-rate projection ($daysElapsedInMonth/$daysInMonth days)"
$cardsCosts += Build-MetricCard -Title 'Modeled Baseline' -Value ([string]::Format('{0:N0}', $baselineModelTokens)) -Label "tokens ($tasksObserved tasks x 14k)"
$cardsCosts += Build-MetricCard -Title 'Optimized Model' -Value ([string]::Format('{0:N0}', $optimizedModelTokens)) -Label "tokens (policy $reductionPolicyPct%)"
$cardsCosts += Build-MetricCard -Title 'Modeled Savings' -Value ([string]::Format('{0:N0}', $modeledSavingsTokens)) -Label 'tokens saved vs baseline'
$cardsCosts += Build-MetricCard -Title 'Modeled USD Saved' -Value ('$' + $modeledSavingsCost) -Label 'policy-based estimate'
$cardsCosts += Build-MetricCard -Title 'MTD USD Saved' -Value ('$' + $modeledMtdSavingsCost) -Label 'modeled month-to-date'
$cardsCosts += Build-MetricCard -Title 'YTD USD Saved' -Value ('$' + $modeledYtdSavingsCost) -Label 'modeled year-to-date'
$cardsCosts += Build-MetricCard -Title 'Text Saved Tokens' -Value ([string]::Format('{0:N0}', $simplificationSavedTokens)) -Label 'from simplification log'
$cardsCosts += Build-MetricCard -Title 'Text USD Saved' -Value ('$' + $simplificationSavedCost) -Label 'from simplification log'
$cardsCosts += Build-MetricCard -Title 'Avg Reduction' -Value "$avgReductionPct%" -Label 'text simplification'
$cardsCosts += Build-MetricCard -Title 'Avg Prompt Chars' -Value $avgPromptChars -Label 'context usage'
$cardsCosts += Build-MetricCard -Title 'Context Events' -Value $totalContextEvents -Label "packs=$contextPackEvents compact=$compactEvents"

$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gentleman Foundation - Metrics Dashboard</title>
<style>
  :root {
    --bg: #081016;
    --surface: #12202c;
    --surface-2: #0f1a24;
    --border: #274255;
    --text: #d7e4ed;
    --muted: #90a8b8;
    --accent: #37b8a8;
    --accent-2: #f5b800;
    --ok: #45c77a;
    --warn: #f0b13a;
    --err: #f26464;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 24px;
    color: var(--text);
    background: radial-gradient(circle at 10% 10%, #143041 0%, #081016 40%, #060d12 100%);
    font-family: 'Segoe UI', Tahoma, sans-serif;
    font-size: 14px;
  }
  h1 { margin: 0 0 4px; color: var(--accent); letter-spacing: 0.4px; }
  .subtitle { color: var(--muted); margin: 0 0 20px; }
  .nav {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    margin-bottom: 16px;
  }
  .nav button {
    border: 1px solid var(--border);
    background: var(--surface);
    color: var(--text);
    padding: 8px 12px;
    border-radius: 999px;
    cursor: pointer;
    font-weight: 600;
  }
  .nav button.active {
    background: linear-gradient(120deg, #1f7a71, #296d9e);
    border-color: #3baea0;
  }
  .section {
    display: none;
    background: linear-gradient(180deg, var(--surface), var(--surface-2));
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 18px;
    margin-bottom: 16px;
  }
  .section.active { display: block; }
  .section h2 {
    margin-top: 0;
    font-size: 1.05rem;
    color: var(--accent-2);
    border-bottom: 1px solid var(--border);
    padding-bottom: 8px;
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
    gap: 12px;
  }
  .card {
    background: rgba(8, 16, 24, 0.75);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 14px;
  }
  .card h3 {
    margin: 0 0 6px;
    font-size: 11px;
    text-transform: uppercase;
    color: var(--muted);
    letter-spacing: 0.6px;
  }
  .value {
    font-size: 1.65rem;
    color: var(--accent);
    font-weight: 700;
  }
  .label {
    margin-top: 6px;
    color: var(--muted);
    font-size: 12px;
  }
  .two-col {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }
  .panel {
    background: rgba(7, 14, 22, 0.72);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 14px;
  }
  .panel h3 { margin-top: 0; color: #9fd8ff; }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
    table-layout: fixed;
    word-break: break-word;
  }
  th, td {
    border-bottom: 1px solid #1f3444;
    text-align: left;
    padding: 6px;
  }
  th { color: #9fc0d3; }
  .muted { color: var(--muted); }
  details {
    margin-bottom: 12px;
    border: 1px solid var(--border);
    border-radius: 8px;
    background: rgba(8, 16, 24, 0.65);
    padding: 8px;
  }
  summary {
    cursor: pointer;
    color: #b0d2e5;
    font-weight: 600;
  }
  canvas { width: 100%; height: 240px; max-height: 240px; }
  .ok { color: var(--ok); }
  .warn { color: var(--warn); }
  .err { color: var(--err); }
  footer {
    color: var(--muted);
    text-align: center;
    margin-top: 20px;
    font-size: 12px;
  }
  @media (max-width: 900px) {
    .two-col { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>
  <h1>Gentleman Foundation - Full Metrics Dashboard</h1>
  <p class="subtitle">Generated: $generated | Orchestrator: $orchVersion | Daily budget: $dailyBudget tokens</p>

  <div class="nav">
    <button class="active" data-target="overview">Overview</button>
    <button data-target="costs">Costs & Savings</button>
    <button data-target="stack">Stack Metrics</button>
    <button data-target="explorer">Metrics Explorer</button>
    <button data-target="events">Events</button>
  </div>

  <section id="overview" class="section active">
    <h2>Executive Overview</h2>
    <div class="grid">
      $($cardsOverview -join "`n")
    </div>
    <div class="two-col" style="margin-top:12px;">
      <div class="panel">
        <h3>Token Trend (daily)</h3>
        <canvas id="tokenChart"></canvas>
      </div>
      <div class="panel">
        <h3>Event Distribution</h3>
        <canvas id="eventChart"></canvas>
      </div>
    </div>
  </section>

  <section id="costs" class="section">
    <h2>Costs and Savings</h2>
    <div class="grid">
      $($cardsCosts -join "`n")
    </div>
    <div class="two-col" style="margin-top:12px;">
      <div class="panel">
        <h3>Cost Allocation by Model</h3>
        $modelCostTable
      </div>
      <div class="panel">
        <h3>Estimated Cost Allocation by Agent</h3>
        <p class="muted">Estimated by dispatch share over token-guard total.</p>
        $agentCostTable
      </div>
    </div>
    <div class="two-col" style="margin-top:12px;">
      <div class="panel">
        <h3>Daily Cost Trend (USD)</h3>
        <canvas id="costChart"></canvas>
      </div>
      <div class="panel">
        <h3>Cost Model Notes</h3>
        <ul>
          <li>Actual cost uses token estimate and a default price of <strong>USD $costPer1M per 1M tokens</strong>.</li>
          <li>MTD and YTD use calendar grouping from token-guard timestamps/dates.</li>
          <li>Month-end forecast uses run-rate: current MTD normalized by elapsed days.</li>
          <li>Modeled baseline assumes <strong>$baselineTokensPerTask tokens/task</strong> across observed tasks.</li>
          <li>Optimized model applies stack policy reduction of <strong>$reductionPolicyPct%</strong>.</li>
          <li>Model allocation uses runtime telemetry tokens per model.</li>
          <li>Agent allocation is estimated proportionally by agent invocation count.</li>
          <li>Text simplification savings come from <strong>text-simplification.csv</strong> token_saved_estimate values.</li>
          <li>These values are estimates intended for executive trend visibility.</li>
        </ul>
      </div>
    </div>
  </section>

  <section id="stack" class="section">
    <h2>Stack Metrics Health</h2>
    <div class="two-col">
      <div class="panel">
        <h3>Token Guard</h3>
        <p>Rows: <strong>$($tokenGuardRows.Count)</strong></p>
        <p>Budget/day: <strong>$([string]::Format('{0:N0}', $dailyBudget))</strong></p>
        <p>Total estimated tokens: <strong>$([string]::Format('{0:N0}', $tokensGuard))</strong></p>
      </div>
      <div class="panel">
        <h3>Context Efficiency</h3>
        <p>Total events: <strong>$totalContextEvents</strong></p>
        <p>compact-start adoption: <strong>$adoptionPct%</strong></p>
        <p>Avg prompt chars: <strong>$avgPromptChars</strong></p>
      </div>
      <div class="panel">
        <h3>Runtime Telemetry</h3>
        <p>Requests: <strong>$runtimeRequests</strong></p>
        <p>Success: <strong class="ok">$runtimeSuccess</strong></p>
        <p>Errors: <strong class="err">$runtimeErrors</strong></p>
        <p>Avg latency: <strong>$runtimeLatencyAvg ms</strong></p>
      </div>
      <div class="panel">
        <h3>Governance Signals</h3>
        <p>Judgment checks: <strong>$($judgmentRows.Count)</strong></p>
        <p>Agent usage rows: <strong>$($agentRows.Count)</strong></p>
        <p>Telemetry master rows: <strong>$($telemetryRows.Count)</strong></p>
      </div>
    </div>
  </section>

  <section id="explorer" class="section">
    <h2>Metrics Explorer</h2>
    <p class="muted">Raw metrics tables from every available stack source. Each section shows the latest rows.</p>

    <details open>
      <summary>docs/management/telemetry-master.csv ($($telemetryRows.Count) rows)</summary>
      $telemetryTable
    </details>

    <details>
      <summary>docs/sessions/metrics/token-guard-usage.csv ($($tokenGuardRows.Count) rows)</summary>
      $tokenGuardTable
    </details>

    <details>
      <summary>docs/sessions/metrics/context-usage.csv ($($contextRows.Count) rows)</summary>
      $contextTable
    </details>

    <details>
      <summary>docs/sessions/metrics/agent-usage.csv ($($agentRows.Count) rows)</summary>
      $agentTable
    </details>

    <details>
      <summary>docs/sessions/metrics/judgment-history.csv ($($judgmentRows.Count) rows)</summary>
      $judgmentTable
    </details>

    <details>
      <summary>docs/sessions/metrics/text-simplification.csv ($($textRows.Count) rows)</summary>
      $textTable
    </details>

    <details>
      <summary>.runtime/telemetry/cloud-agent-telemetry.csv ($($runtimeRows.Count) rows)</summary>
      $runtimeTable
    </details>
  </section>

  <section id="events" class="section">
    <h2>Recent Event History</h2>
    <div class="panel">
      <table>
        <thead>
          <tr><th>Timestamp</th><th>Event</th><th>Status</th></tr>
        </thead>
        <tbody>
          $recentEventsHtml
        </tbody>
      </table>
      <p class="muted">Rate-limit state: $rateLimitLabel</p>
    </div>
  </section>

  <footer>
    Dashboard generated from local metrics stack sources. Sections include executive KPIs, costs/optimization estimates, and raw explorer tables.
  </footer>

<script>
function drawBarChart(canvasId, labels, values, color) {
  const canvas = document.getElementById(canvasId);
  if (!canvas || !labels || labels.length === 0) return;
  const ctx = canvas.getContext('2d');
  const W = canvas.width = canvas.parentElement.clientWidth - 16;
  const H = canvas.height = 240;
  const pad = { top: 12, right: 10, bottom: 54, left: 50 };
  const chartW = W - pad.left - pad.right;
  const chartH = H - pad.top - pad.bottom;
  const max = Math.max(...values, 1);
  const step = chartW / labels.length;
  const barW = Math.max(8, step - 4);

  ctx.clearRect(0, 0, W, H);
  ctx.fillStyle = '#0b161f';
  ctx.fillRect(0, 0, W, H);

  for (let i = 0; i <= 4; i++) {
    const y = pad.top + chartH * (1 - i / 4);
    ctx.strokeStyle = '#244256';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(pad.left, y);
    ctx.lineTo(W - pad.right, y);
    ctx.stroke();

    ctx.fillStyle = '#86a6ba';
    ctx.font = '10px Segoe UI';
    ctx.textAlign = 'right';
    ctx.fillText(Math.round(max * i / 4), pad.left - 4, y + 3);
  }

  labels.forEach((label, i) => {
    const x = pad.left + i * step + 2;
    const val = Number(values[i] || 0);
    const h = (val / max) * chartH;
    const y = pad.top + chartH - h;

    ctx.fillStyle = color;
    ctx.fillRect(x, y, barW, h);

    ctx.fillStyle = '#87a8bb';
    ctx.font = '9px Segoe UI';
    ctx.textAlign = 'center';
    const shortLabel = String(label).length > 10 ? String(label).slice(5) : label;
    ctx.fillText(shortLabel, x + barW / 2, H - 28);
  });
}

function initTabs() {
  const buttons = Array.from(document.querySelectorAll('.nav button'));
  const sections = Array.from(document.querySelectorAll('.section'));
  buttons.forEach((btn) => {
    btn.addEventListener('click', () => {
      buttons.forEach((b) => b.classList.remove('active'));
      sections.forEach((s) => s.classList.remove('active'));
      btn.classList.add('active');
      const target = document.getElementById(btn.dataset.target);
      if (target) target.classList.add('active');
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  });
}

window.addEventListener('load', () => {
  initTabs();
  drawBarChart('tokenChart', [$tokenLabels], [$tokenValues], '#37b8a8');
  drawBarChart('eventChart', [$eventTypeLabels], [$eventTypeValues], '#f5b800');
  drawBarChart('costChart', [$costLabels], [$costValues], '#6ea8ff');
});
</script>
</body>
</html>
"@

Set-Content -Path $OutputPath -Value $html -Encoding UTF8 -Force
Write-Host "[OK] Dashboard generated: $OutputPath" -ForegroundColor Green

if ($Open) {
    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        Start-Process $OutputPath
    }
    elseif ($IsMacOS) {
        & open $OutputPath
    }
    else {
        & xdg-open $OutputPath 2>$null
    }
}
