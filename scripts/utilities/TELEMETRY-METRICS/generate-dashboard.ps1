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

  function Build-RecentDailySeries {
    param(
      [array]$Rows,
      [int]$Days = 14
    )

    $daysSafe = [Math]::Max(1, $Days)
    $endDate = (Get-Date).Date
    $startDate = $endDate.AddDays(-($daysSafe - 1))
    $map = @{}

    foreach ($row in $Rows) {
      $dateRef = $null
      if ($row.PSObject.Properties['DateRef']) {
        $dateRef = $row.DateRef
      }
      if (-not $dateRef) {
        continue
      }

      $dayKey = ([datetime]$dateRef).ToString('yyyy-MM-dd')
      if (-not $map.ContainsKey($dayKey)) {
        $map[$dayKey] = 0
      }
      $map[$dayKey] += (Get-IntValue $row.Tokens)
    }

    $result = @()
    for ($i = 0; $i -lt $daysSafe; $i++) {
      $day = $startDate.AddDays($i)
      $key = $day.ToString('yyyy-MM-dd')
      $tokens = if ($map.ContainsKey($key)) { [int]$map[$key] } else { 0 }

      $result += [pscustomobject]@{
        Day = $key
        Tokens = $tokens
      }
    }

    return $result
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

$budgetMonthTokens = [int]($dailyBudget * $daysInMonth)
$budgetMonthCost = [math]::Round(($budgetMonthTokens / 1000000.0) * $costPer1M, 2)
$budgetConsumedPct = if ($budgetMonthCost -gt 0) { [math]::Round(($costMTD * 100.0) / $budgetMonthCost, 1) } else { 0 }
$budgetForecastPct = if ($budgetMonthCost -gt 0) { [math]::Round(($projectedMonthCost * 100.0) / $budgetMonthCost, 1) } else { 0 }
$forecastVarianceUsd = [math]::Round($projectedMonthCost - $budgetMonthCost, 2)
$forecastVariancePct = if ($budgetMonthCost -gt 0) { [math]::Round((($projectedMonthCost - $budgetMonthCost) * 100.0) / $budgetMonthCost, 1) } else { 0 }

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

$roiStatus = 'GREEN'
$roiStatusClass = 'ok'
if ($budgetForecastPct -ge 90) {
  $roiStatus = 'RED'
  $roiStatusClass = 'err'
}
elseif ($budgetForecastPct -ge 70) {
  $roiStatus = 'YELLOW'
  $roiStatusClass = 'warn'
}

$netModeledBenefitMtd = [math]::Round($modeledMtdSavingsCost - $costMTD, 2)
$netModeledBenefitYtd = [math]::Round($modeledYtdSavingsCost - $costYTD, 2)
$roiLabels = "'Budget','MTD Actual','Forecast','MTD Saved'"
$roiValues = @(
  ('{0}' -f $budgetMonthCost.ToString([System.Globalization.CultureInfo]::InvariantCulture)),
  ('{0}' -f $costMTD.ToString([System.Globalization.CultureInfo]::InvariantCulture)),
  ('{0}' -f $projectedMonthCost.ToString([System.Globalization.CultureInfo]::InvariantCulture)),
  ('{0}' -f $modeledMtdSavingsCost.ToString([System.Globalization.CultureInfo]::InvariantCulture))
) -join ','

# Monthly historical ROI context (current + previous + 3-month trend)
$monthTokenMap = @{}
foreach ($row in $tokenTimeRows) {
  $monthKey = ([datetime]$row.DateRef).ToString('yyyy-MM')
  if (-not $monthTokenMap.ContainsKey($monthKey)) {
    $monthTokenMap[$monthKey] = 0
  }
  $monthTokenMap[$monthKey] += [int]$row.Tokens
}

$roiMonthRows = @()
for ($i = 2; $i -ge 0; $i--) {
  $monthDate = (Get-Date -Day 1).AddMonths(-$i)
  $monthKey = $monthDate.ToString('yyyy-MM')
  $monthLabel = $monthDate.ToString('MMM yyyy', [System.Globalization.CultureInfo]::InvariantCulture)
  $monthTokens = if ($monthTokenMap.ContainsKey($monthKey)) { [int]$monthTokenMap[$monthKey] } else { 0 }
  $monthCost = [math]::Round(($monthTokens / 1000000.0) * $costPer1M, 2)

  $roiMonthRows += [pscustomobject]@{
    Month = $monthLabel
    Tokens = [string]::Format('{0:N0}', $monthTokens)
    Cost_USD = ('{0:N2}' -f $monthCost)
    CostRaw = $monthCost
  }
}

$currentMonthCostHist = if ($roiMonthRows.Count -gt 0) { [double]$roiMonthRows[-1].CostRaw } else { 0.0 }
$previousMonthCostHist = if ($roiMonthRows.Count -gt 1) { [double]$roiMonthRows[-2].CostRaw } else { 0.0 }
$monthOverMonthPct = if ($previousMonthCostHist -gt 0) { [math]::Round((($currentMonthCostHist - $previousMonthCostHist) * 100.0) / $previousMonthCostHist, 1) } else { 0 }
$monthOverMonthLabel = if ($monthOverMonthPct -gt 0) { '+' + $monthOverMonthPct + '%' } else { $monthOverMonthPct.ToString() + '%' }

$roiHistoryLabels = ($roiMonthRows | ForEach-Object { "'" + $_.Month + "'" }) -join ','
$roiHistoryValues = ($roiMonthRows | ForEach-Object { [double]$_.CostRaw } | ForEach-Object { $_.ToString([System.Globalization.CultureInfo]::InvariantCulture) }) -join ','
$roiHistoryTableRows = @($roiMonthRows | ForEach-Object {
  [pscustomobject]@{
    Month = $_.Month
    Tokens = $_.Tokens
    Cost_USD = $_.Cost_USD
  }
})
$roiHistoryTable = Build-TableHtml -Rows $roiHistoryTableRows -Columns @('Month','Tokens','Cost_USD') -MaxRows 12

$latestTokenDate = $null
if ($tokenTimeRows.Count -gt 0) {
  $latestTokenDate = ($tokenTimeRows | Sort-Object DateRef -Descending | Select-Object -First 1).DateRef
}

$tokenDataFreshness = 'no token data'
if ($latestTokenDate) {
  $staleDays = [int]((Get-Date).Date.Subtract(([datetime]$latestTokenDate).Date).TotalDays)
  if ($staleDays -le 1) {
    $tokenDataFreshness = "fresh (last data: $(([datetime]$latestTokenDate).ToString('yyyy-MM-dd')) )"
  }
  else {
    $tokenDataFreshness = "stale by $staleDays days (last data: $(([datetime]$latestTokenDate).ToString('yyyy-MM-dd')) )"
  }
}

# ── Proactive Alerts / Anomaly Detection ───────────────────────────────────────
$alerts = @()   # each entry: [severity, code, title, detail, recommendation]

# 1. Data freshness alert
if ($staleDays -gt 3) {
  $alerts += [pscustomobject]@{
    Severity = 'warn'
    Code     = 'DATA_STALE'
    Title    = 'Stale Token Data'
    Detail   = "Last token record is $staleDays days old."
    Recommendation = 'Run a session or push new telemetry to refresh the dashboard data.'
  }
}

# 2. Budget forecast alert (RED / YELLOW)
if ($budgetForecastPct -ge 90) {
  $alerts += [pscustomobject]@{
    Severity = 'err'
    Code     = 'BUDGET_CRITICAL'
    Title    = 'Budget Critical'
    Detail   = "Month-end forecast at $budgetForecastPct% of budget (USD $projectedMonthCost vs budget USD $budgetMonthCost)."
    Recommendation = 'Review task volume and apply stricter token-guard thresholds immediately.'
  }
} elseif ($budgetForecastPct -ge 70) {
  $alerts += [pscustomobject]@{
    Severity = 'warn'
    Code     = 'BUDGET_WARNING'
    Title    = 'Budget Warning'
    Detail   = "Month-end forecast at $budgetForecastPct% of budget (USD $projectedMonthCost)."
    Recommendation = 'Monitor daily token consumption closely for the remainder of the month.'
  }
}

# 3. Token spike anomaly (any single day > 2x daily avg over 14-day window)
$nonZeroDays = @($tokenTrendRows | Where-Object { $_.Tokens -gt 0 })
if ($nonZeroDays.Count -gt 1) {
  $avgDailyTokens = ($nonZeroDays | ForEach-Object { [double]$_.Tokens } | Measure-Object -Average).Average
  $spikeThreshold = $avgDailyTokens * 2.0
  $spikedDays = @($nonZeroDays | Where-Object { [double]$_.Tokens -gt $spikeThreshold })
  if ($spikedDays.Count -gt 0) {
    $spikeDay = $spikedDays | Sort-Object Tokens -Descending | Select-Object -First 1
    $spikePct = [math]::Round(([double]$spikeDay.Tokens / $avgDailyTokens) * 100.0 - 100.0, 0)
    $alerts += [pscustomobject]@{
      Severity = 'warn'
      Code     = 'TOKEN_SPIKE'
      Title    = 'Token Spike Detected'
      Detail   = "Day $($spikeDay.Day) was ${spikePct}% above the 14-day daily average ($([string]::Format('{0:N0}', [int]$spikeDay.Tokens)) tokens)."
      Recommendation = 'Investigate what task or agent drove the spike on that date.'
    }
  }
}

# 4. Runtime error rate alert
$runtimeErrorRate = if ($runtimeRequests -gt 0) { [math]::Round(($runtimeErrors * 100.0) / $runtimeRequests, 1) } else { 0 }
if ($runtimeErrorRate -ge 20) {
  $alerts += [pscustomobject]@{
    Severity = 'err'
    Code     = 'RUNTIME_ERRORS_HIGH'
    Title    = 'High Runtime Error Rate'
    Detail   = "Error rate is ${runtimeErrorRate}% ($runtimeErrors errors out of $runtimeRequests requests)."
    Recommendation = 'Review cloud-agent-telemetry.csv ErrorMessage column to identify the failing provider or model.'
  }
} elseif ($runtimeErrorRate -ge 10) {
  $alerts += [pscustomobject]@{
    Severity = 'warn'
    Code     = 'RUNTIME_ERRORS_MODERATE'
    Title    = 'Elevated Runtime Error Rate'
    Detail   = "Error rate is ${runtimeErrorRate}% ($runtimeErrors errors out of $runtimeRequests requests)."
    Recommendation = 'Monitor runtime errors; check provider status if the trend continues.'
  }
}

# 5. High latency alert
if ($runtimeLatencyAvg -gt 0) {
  if ($runtimeLatencyAvg -gt 8000) {
    $alerts += [pscustomobject]@{
      Severity = 'err'
      Code     = 'LATENCY_HIGH'
      Title    = 'High Runtime Latency'
      Detail   = "Average latency is ${runtimeLatencyAvg} ms."
      Recommendation = 'Check provider health or switch to a lower-latency model.'
    }
  } elseif ($runtimeLatencyAvg -gt 4000) {
    $alerts += [pscustomobject]@{
      Severity = 'warn'
      Code     = 'LATENCY_ELEVATED'
      Title    = 'Elevated Latency'
      Detail   = "Average latency is ${runtimeLatencyAvg} ms (threshold: 4000 ms)."
      Recommendation = 'Consider reviewing provider selection or request concurrency.'
    }
  }
}

# 6. Month-over-month cost regression
if ($monthOverMonthPct -gt 20) {
  $alerts += [pscustomobject]@{
    Severity = 'warn'
    Code     = 'COST_REGRESSION'
    Title    = 'Cost Regression MoM'
    Detail   = "Current month cost is ${monthOverMonthLabel} vs previous month."
    Recommendation = 'Verify whether new agents or expanded task scope are driving the increase.'
  }
}

# 7. Low efficiency alert
if ($avgEfficiency -gt 0 -and $avgEfficiency -lt 0.5) {
  $alerts += [pscustomobject]@{
    Severity = 'warn'
    Code     = 'LOW_EFFICIENCY'
    Title    = 'Low Avg Efficiency Score'
    Detail   = "Average efficiency score is $avgEfficiency (threshold: 0.5)."
    Recommendation = 'Review recent telemetry for tasks with low Efficiency_Score and identify patterns.'
  }
}

# Build alerts HTML panel
function Build-AlertBadge {
  param([string]$Severity, [string]$Code, [string]$Title, [string]$Detail, [string]$Recommendation)
  return @"
<div class="alert-badge alert-$Severity">
  <div class="alert-header">
    <span class="alert-icon">$(if ($Severity -eq 'err') { '&#9888;' } else { '&#9654;' })</span>
    <strong class="alert-title">$Title</strong>
    <code class="alert-code">$Code</code>
  </div>
  <p class="alert-detail">$Detail</p>
  <p class="alert-rec"><em>Recommendation:</em> $Recommendation</p>
</div>
"@
}

$alertBadgesHtml = ''
if ($alerts.Count -eq 0) {
  $alertBadgesHtml = '<p class="alert-ok">&#10003; All systems nominal &mdash; no active alerts.</p>'
} else {
  foreach ($a in $alerts) {
    $alertBadgesHtml += Build-AlertBadge -Severity $a.Severity -Code $a.Code -Title $a.Title -Detail $a.Detail -Recommendation $a.Recommendation
  }
}
$alertCount = $alerts.Count
$alertSummaryClass = if (($alerts | Where-Object { $_.Severity -eq 'err' }).Count -gt 0) { 'err' } elseif ($alertCount -gt 0) { 'warn' } else { 'ok' }
$alertSummaryLabel = if ($alertCount -eq 0) { 'No alerts' } elseif ($alertCount -eq 1) { '1 alert' } else { "$alertCount alerts" }
# ── End Alert Computation ───────────────────────────────────────────────────────

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
$trendWindowDays = 14
$tokenTrendRows = Build-RecentDailySeries -Rows $tokenTimeRows -Days $trendWindowDays
$tokenLabels = ($tokenTrendRows | ForEach-Object { "'" + $_.Day + "'" }) -join ','
$tokenValues = ($tokenTrendRows | ForEach-Object { [int]$_.Tokens }) -join ','

$costLabels = ($tokenTrendRows | ForEach-Object { "'" + $_.Day + "'" }) -join ','
$costValues = ($tokenTrendRows | ForEach-Object { [math]::Round(([double]$_.Tokens / 1000000.0) * $costPer1M, 4).ToString([System.Globalization.CultureInfo]::InvariantCulture) }) -join ','

$eventTypeRows = @($eventByType.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 8)
$eventTypeLabels = ($eventTypeRows | ForEach-Object { "'" + $_.Name + "'" }) -join ','
$eventTypeValues = ($eventTypeRows | ForEach-Object { [int]$_.Value }) -join ','

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

$textSavingsShare = '0%'
if ($costMTD -gt 0) {
  $textSavingsShare = [math]::Round(($simplificationSavedCost * 100.0) / $costMTD, 1).ToString() + '%'
}

$cardsRoi = @()
$cardsRoi += Build-MetricCard -Title 'Monthly Budget (USD)' -Value ('$' + $budgetMonthCost) -Label "daily budget x $daysInMonth days"
$cardsRoi += Build-MetricCard -Title 'Budget Consumed' -Value "$budgetConsumedPct%" -Label "MTD actual vs monthly budget"
$cardsRoi += Build-MetricCard -Title 'Forecast vs Budget' -Value "$budgetForecastPct%" -Label "projected month-end utilization"
$cardsRoi += Build-MetricCard -Title 'Forecast Variance' -Value ('$' + $forecastVarianceUsd) -Label "$forecastVariancePct% vs budget"
$cardsRoi += Build-MetricCard -Title 'ROI Status' -Value $roiStatus -Label "thresholds: 70/90"
$cardsRoi += Build-MetricCard -Title 'Prev Month Cost' -Value ('$' + ('{0:N2}' -f $previousMonthCostHist)) -Label 'historical reference'
$cardsRoi += Build-MetricCard -Title 'MoM Cost Trend' -Value $monthOverMonthLabel -Label 'current vs previous month'
$cardsRoi += Build-MetricCard -Title 'Net Benefit MTD' -Value ('$' + $netModeledBenefitMtd) -Label 'modeled savings - actual cost'
$cardsRoi += Build-MetricCard -Title 'Net Benefit YTD' -Value ('$' + $netModeledBenefitYtd) -Label 'modeled savings - actual cost'
$cardsRoi += Build-MetricCard -Title 'Text Savings Share' -Value $textSavingsShare -Label 'of MTD actual cost'

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
  canvas { width: 100%; height: 240px; max-height: 320px; }
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
  /* Proactive alerts */
  .alerts-panel {
    margin-top: 16px;
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 14px;
    background: rgba(8, 16, 24, 0.75);
  }
  .alerts-panel h3 {
    margin: 0 0 10px;
    font-size: 0.95rem;
    color: var(--accent-2);
  }
  .alert-ok {
    color: var(--ok);
    margin: 0;
    font-weight: 600;
  }
  .alert-badge {
    border-radius: 8px;
    padding: 10px 14px;
    margin-bottom: 8px;
    border-left: 4px solid;
  }
  .alert-warn {
    background: rgba(240, 177, 58, 0.08);
    border-color: var(--warn);
  }
  .alert-err {
    background: rgba(242, 100, 100, 0.08);
    border-color: var(--err);
  }
  .alert-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 4px;
  }
  .alert-icon { font-size: 1rem; }
  .alert-title { font-size: 0.92rem; }
  .alert-code {
    font-size: 10px;
    background: rgba(255,255,255,0.07);
    border-radius: 4px;
    padding: 1px 5px;
    color: var(--muted);
  }
  .alert-detail, .alert-rec {
    margin: 3px 0 0 20px;
    font-size: 12px;
    color: var(--muted);
  }
  .alert-rec em { color: #9fd8ff; font-style: normal; font-weight: 600; }
  .alerts-summary-badge {
    display: inline-block;
    padding: 2px 10px;
    border-radius: 999px;
    font-size: 12px;
    font-weight: 700;
    margin-left: 8px;
    vertical-align: middle;
  }
</style>
</head>
<body>
  <h1>Gentleman Foundation - Full Metrics Dashboard</h1>
  <p class="subtitle">Generated: $generated | Orchestrator: $orchVersion | Daily budget: $dailyBudget tokens</p>

  <div class="nav">
    <button class="active" data-target="overview">Overview</button>
    <button data-target="costs">Costs & Savings</button>
    <button data-target="roi">Executive ROI</button>
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
        <h3>Token Trend (last $trendWindowDays days)</h3>
        <p class="muted">Data freshness: $tokenDataFreshness</p>
        <canvas id="tokenChart"></canvas>
      </div>
      <div class="panel">
        <h3>Event Distribution</h3>
        <canvas id="eventChart"></canvas>
      </div>
    </div>
    <div class="alerts-panel" style="margin-top:12px;">
      <h3>Proactive Alerts <span class="alerts-summary-badge $alertSummaryClass">$alertSummaryLabel</span></h3>
      $alertBadgesHtml
    </div>
  </section>

  <section id="roi" class="section">
    <h2>Executive ROI and Budget Control</h2>
    <div class="grid">
      $($cardsRoi -join "`n")
    </div>
    <div class="two-col" style="margin-top:12px;">
      <div class="panel">
        <h3>Monthly ROI Comparison (USD)</h3>
        <canvas id="roiChart"></canvas>
      </div>
      <div class="panel">
        <h3>Governance Signal</h3>
        <p>Current executive status: <strong class="$roiStatusClass">$roiStatus</strong></p>
        <ul>
          <li><strong>GREEN</strong>: forecast under 70% of monthly budget.</li>
          <li><strong>YELLOW</strong>: forecast between 70% and 90% of monthly budget.</li>
          <li><strong>RED</strong>: forecast at or above 90% of monthly budget.</li>
          <li>Variance is computed as <strong>forecast - budget</strong>.</li>
          <li>Net benefit is a modeled indicator, not accounting P&amp;L.</li>
        </ul>
      </div>
    </div>
    <div class="two-col" style="margin-top:12px;">
      <div class="panel">
        <h3>3-Month Cost Trend (USD)</h3>
        <canvas id="roiHistoryChart"></canvas>
      </div>
      <div class="panel">
        <h3>Recent Monthly Breakdown</h3>
        <p class="muted">Current month and two previous months.</p>
        $roiHistoryTable
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
function resizeCanvasForDpi(canvas, targetHeight) {
  const dpr = window.devicePixelRatio || 1;
  const cssWidth = Math.max(320, (canvas.parentElement ? canvas.parentElement.clientWidth : 640) - 12);
  const cssHeight = targetHeight || 240;
  canvas.style.width = cssWidth + 'px';
  canvas.style.height = cssHeight + 'px';
  canvas.width = Math.floor(cssWidth * dpr);
  canvas.height = Math.floor(cssHeight * dpr);
  const ctx = canvas.getContext('2d');
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  return { ctx, W: cssWidth, H: cssHeight };
}

function fmtShort(value) {
  const abs = Math.abs(value);
  if (abs >= 1000000) return (value / 1000000).toFixed(1) + 'M';
  if (abs >= 1000) return (value / 1000).toFixed(1) + 'k';
  if (abs >= 1) return value.toFixed(0);
  return value.toFixed(2);
}

function drawBarChart(canvasId, labels, values, color, yFormatter) {
  const canvas = document.getElementById(canvasId);
  if (!canvas || !labels || labels.length === 0) return;
  const resized = resizeCanvasForDpi(canvas, 240);
  const ctx = resized.ctx;
  const W = resized.W;
  const H = resized.H;
  const pad = { top: 16, right: 14, bottom: 54, left: 62 };
  const chartW = W - pad.left - pad.right;
  const chartH = H - pad.top - pad.bottom;
  const max = Math.max(...values, 1);
  const step = chartW / labels.length;
  const barW = Math.max(8, step - 8);

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
    ctx.font = '11px Segoe UI';
    ctx.textAlign = 'right';
    const yValue = (max * i / 4);
    ctx.fillText(yFormatter ? yFormatter(yValue) : fmtShort(yValue), pad.left - 6, y + 4);
  }

  labels.forEach((label, i) => {
    const x = pad.left + i * step + 2;
    const val = Number(values[i] || 0);
    const h = (val / max) * chartH;
    const y = pad.top + chartH - h;

    ctx.fillStyle = color;
    ctx.fillRect(x, y, barW, h);

    ctx.fillStyle = '#87a8bb';
    ctx.font = '10px Segoe UI';
    ctx.textAlign = 'center';
    const shortLabel = String(label).length > 10 ? String(label).slice(5) : String(label);
    ctx.fillText(shortLabel, x + barW / 2, H - 28);
  });
}

function drawLineChart(canvasId, labels, values, color, yFormatter) {
  const canvas = document.getElementById(canvasId);
  if (!canvas || !labels || labels.length === 0) return;
  const rotateLabels = labels.length > 7;
  const bottomPad = rotateLabels ? 80 : 54;
  const canvasHeight = rotateLabels ? 290 : 240;
  const resized = resizeCanvasForDpi(canvas, canvasHeight);
  canvas.style.height = canvasHeight + 'px';
  const ctx = resized.ctx;
  const W = resized.W;
  const H = resized.H;
  const pad = { top: 16, right: 14, bottom: bottomPad, left: 62 };
  const chartW = W - pad.left - pad.right;
  const chartH = H - pad.top - pad.bottom;
  const max = Math.max(...values, 1);

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
    ctx.font = '11px Segoe UI';
    ctx.textAlign = 'right';
    const yValue = (max * i / 4);
    ctx.fillText(yFormatter ? yFormatter(yValue) : fmtShort(yValue), pad.left - 6, y + 4);
  }

  const points = values.map((val, i) => {
    const x = pad.left + (i * chartW / Math.max(1, values.length - 1));
    const y = pad.top + chartH - ((Number(val || 0) / max) * chartH);
    return { x, y, v: Number(val || 0) };
  });

  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  points.forEach((p) => ctx.lineTo(p.x, p.y));
  ctx.strokeStyle = color;
  ctx.lineWidth = 2.5;
  ctx.stroke();

  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  points.forEach((p) => ctx.lineTo(p.x, p.y));
  ctx.lineTo(points[points.length - 1].x, pad.top + chartH);
  ctx.lineTo(points[0].x, pad.top + chartH);
  ctx.closePath();
  ctx.fillStyle = color + '33';
  ctx.fill();

  points.forEach((p) => {
    ctx.beginPath();
    ctx.arc(p.x, p.y, 2.5, 0, Math.PI * 2);
    ctx.fillStyle = color;
    ctx.fill();
  });

  labels.forEach((label, i) => {
    // Skip every other label only when not rotating and many labels present
    if (!rotateLabels && i % 2 !== 0 && labels.length > 8) return;
    const x = pad.left + (i * chartW / Math.max(1, labels.length - 1));
    // For dates like "2026-04-22" shorten to "MM-DD"
    const raw = String(label);
    const shortLabel = raw.length === 10 && raw[4] === '-' ? raw.slice(5) : (raw.length > 8 ? raw.slice(-8) : raw);
    ctx.save();
    ctx.fillStyle = '#87a8bb';
    ctx.font = '10px Segoe UI';
    if (rotateLabels) {
      ctx.translate(x, pad.top + chartH + 8);
      ctx.rotate(-Math.PI / 4);
      ctx.textAlign = 'right';
      ctx.fillText(shortLabel, 0, 0);
    } else {
      ctx.textAlign = 'center';
      ctx.fillText(shortLabel, x, H - 28);
    }
    ctx.restore();
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
  drawLineChart('tokenChart', [$tokenLabels], [$tokenValues], '#37b8a8', (v) => fmtShort(v));
  drawBarChart('eventChart', [$eventTypeLabels], [$eventTypeValues], '#f5b800');
  drawLineChart('costChart', [$costLabels], [$costValues], '#6ea8ff', (v) => '$' + Number(v).toFixed(3));
  drawBarChart('roiChart', [$roiLabels], [$roiValues], '#fd8f4d', (v) => '$' + Number(v).toFixed(2));
  drawLineChart('roiHistoryChart', [$roiHistoryLabels], [$roiHistoryValues], '#6ed4a7', (v) => '$' + Number(v).toFixed(2));
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
