#Requires -Version 7.0
<#
.SYNOPSIS
    Cost Tracker — Track, attribute, and report AI token costs per agent/task/model

.DESCRIPTION
    Implements Cost Attribution from rules/COST-ATTRIBUTION.md.
    Logs token consumption and generates cost reports.

.PARAMETER Action
    log — Log a token consumption event
    status — Show current cost status
    report — Generate cost report
    reset — Reset daily counters

.PARAMETER Agent
    Agent name (BA, SAD, DEV, QA, OPS, GOV, etc.)

.PARAMETER TaskType
    Task type (feature, bugfix, refactor, etc.)

.PARAMETER Model
    Model used (gpt-4o, claude-3.5-sonnet, etc.)

.PARAMETER InputTokens
    Number of input tokens

.PARAMETER OutputTokens
    Number of output tokens

.EXAMPLE
    .\cost-tracker.ps1 -Action log -Agent DEV -TaskType feature -Model claude-3.5-sonnet -InputTokens 5000 -OutputTokens 2000
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('log', 'status', 'report', 'reset')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Agent = 'unknown',

    [Parameter(Mandatory = $false)]
    [string]$TaskType = 'unknown',

    [Parameter(Mandatory = $false)]
    [string]$Model = 'claude-3.5-sonnet',

    [Parameter(Mandatory = $false)]
    [int]$InputTokens = 0,

    [Parameter(Mandatory = $false)]
    [int]$OutputTokens = 0,

    [Parameter(Mandatory = $false)]
    [switch]$AsJson,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))

# === Paths ===
$costDir = Join-Path $root '.session/cost-tracking'
$dailyFile = Join-Path $costDir 'daily.json'
$logFile = Join-Path $costDir 'cost-log.jsonl'
$budgetFile = Join-Path $root 'config/token-budget-limits.json'

# === Model Pricing (per 1M tokens) ===
$modelPricing = @{
    'gpt-4o'            = @{ input = 2.50; output = 10.00 }
    'claude-3.5-sonnet' = @{ input = 3.00; output = 15.00 }
    'gpt-4o-mini'       = @{ input = 0.15; output = 0.60 }
    'claude-3-haiku'    = @{ input = 0.25; output = 1.25 }
    'gemini-2.0-flash'  = @{ input = 0.10; output = 0.40 }
}

# === Budget Limits ===
$budgetLimits = @{
    daily_cost_usd     = 5.00
    daily_tokens       = 500000
    per_task_cost_usd  = 0.80
    per_task_tokens    = 80000
    agent_limits       = @{
        'BA'  = @{ tokens = 50000; cost = 0.50 }
        'SAD' = @{ tokens = 80000; cost = 0.80 }
        'DEV' = @{ tokens = 100000; cost = 1.00 }
        'QA'  = @{ tokens = 40000; cost = 0.40 }
        'OPS' = @{ tokens = 30000; cost = 0.30 }
        'GOV' = @{ tokens = 20000; cost = 0.20 }
    }
}

function Ensure-Directory {
    if (-not (Test-Path $costDir)) {
        New-Item -ItemType Directory -Path $costDir -Force | Out-Null
    }
}

function Calculate-Cost {
    param([string]$Model, [int]$InputTokens, [int]$OutputTokens)

    $pricing = $modelPricing[$Model]
    if (-not $pricing) { $pricing = $modelPricing['claude-3.5-sonnet'] }

    $inputCost = ($InputTokens / 1000000) * $pricing.input
    $outputCost = ($OutputTokens / 1000000) * $pricing.output
    return [math]::Round($inputCost + $outputCost, 6)
}

function Get-TodayKey {
    return Get-Date -Format 'yyyy-MM-dd'
}

function Get-DailyData {
    Ensure-Directory
    if (Test-Path $dailyFile) {
        return Get-Content $dailyFile -Raw | ConvertFrom-Json
    }
    return @{
        date            = Get-TodayKey
        total_tokens    = 0
        total_cost_usd  = 0.0
        by_agent        = @{}
        by_model        = @{}
        by_task_type    = @{}
        entries         = @()
    }
}

function Save-DailyData {
    param([object]$Data)
    Ensure-Directory
    $Data | ConvertTo-Json -Depth 10 | Set-Content $dailyFile -Force
}

function Log-Entry {
    $cost = Calculate-Cost -Model $Model -InputTokens $InputTokens -OutputTokens $OutputTokens
    $totalTokens = $InputTokens + $OutputTokens
    $today = Get-TodayKey

    # Load daily data
    $daily = Get-DailyData
    if ($daily.date -ne $today) {
        # New day — archive old data
        $daily = @{
            date            = $today
            total_tokens    = 0
            total_cost_usd  = 0.0
            by_agent        = @{}
            by_model        = @{}
            by_task_type    = @{}
            entries         = @()
        }
    }

    # Update totals
    $daily.total_tokens += $totalTokens
    $daily.total_cost_usd = [math]::Round($daily.total_cost_usd + $cost, 6)

    # Update by agent
    if (-not $daily.by_agent.ContainsKey($Agent)) {
        $daily.by_agent[$Agent] = @{ tokens = 0; cost = 0.0; count = 0 }
    }
    $daily.by_agent[$Agent].tokens += $totalTokens
    $daily.by_agent[$Agent].cost = [math]::Round($daily.by_agent[$Agent].cost + $cost, 6)
    $daily.by_agent[$Agent].count++

    # Update by model
    if (-not $daily.by_model.ContainsKey($Model)) {
        $daily.by_model[$Model] = @{ tokens = 0; cost = 0.0; count = 0 }
    }
    $daily.by_model[$Model].tokens += $totalTokens
    $daily.by_model[$Model].cost = [math]::Round($daily.by_model[$Model].cost + $cost, 6)
    $daily.by_model[$Model].count++

    # Update by task type
    if (-not $daily.by_task_type.ContainsKey($TaskType)) {
        $daily.by_task_type[$TaskType] = @{ tokens = 0; cost = 0.0; count = 0 }
    }
    $daily.by_task_type[$TaskType].tokens += $totalTokens
    $daily.by_task_type[$TaskType].cost = [math]::Round($daily.by_task_type[$TaskType].cost + $cost, 6)
    $daily.by_task_type[$TaskType].count++

    # Add entry
    $daily.entries += @{
        timestamp    = Get-Date -Format 'o'
        agent        = $Agent
        task_type    = $TaskType
        model        = $Model
        input_tokens = $InputTokens
        output_tokens = $OutputTokens
        total_tokens = $totalTokens
        cost_usd     = $cost
    }

    # Keep only last 100 entries in memory
    if ($daily.entries.Count -gt 100) {
        $daily.entries = $daily.entries[-100..-1]
    }

    Save-DailyData $daily

    # Append to JSONL log
    $logEntry = @{
        timestamp    = Get-Date -Format 'o'
        agent        = $Agent
        task_type    = $TaskType
        model        = $Model
        input_tokens = $InputTokens
        output_tokens = $OutputTokens
        cost_usd     = $cost
    }
    $logEntry | ConvertTo-Json -Compress | Add-Content $logFile

    # Check budget alerts
    Check-BudgetAlerts $daily

    if (-not $Quiet) {
        Write-Host "[COST] Logged: $Agent/$TaskType | $Model | ${totalTokens} tokens | `$$cost" -ForegroundColor Green
    }
}

function Check-BudgetAlerts {
    param([object]$Daily)

    # Daily cost alert
    if ($Daily.total_cost_usd -gt $budgetLimits.daily_cost_usd) {
        Write-Warning "[BUDGET] Daily cost limit exceeded: `$$($Daily.total_cost_usd) / `$$($budgetLimits.daily_cost_usd)"
    }

    # Daily tokens alert
    if ($Daily.total_tokens -gt $budgetLimits.daily_tokens) {
        Write-Warning "[BUDGET] Daily token limit exceeded: $($Daily.total_tokens) / $($budgetLimits.daily_tokens)"
    }

    # Per-agent alert
    $agentLimit = $budgetLimits.agent_limits[$Agent]
    if ($agentLimit) {
        $agentData = $Daily.by_agent[$Agent]
        if ($agentData -and $agentData.cost -gt $agentLimit.cost) {
            Write-Warning "[BUDGET] Agent $Agent cost limit exceeded: `$$($agentData.cost) / `$$($agentLimit.cost)"
        }
    }
}

function Show-Status {
    $daily = Get-DailyData

    if ($AsJson) {
        $daily | ConvertTo-Json -Depth 5
        return
    }

    if (-not $Quiet) {
        Write-Host ""
        Write-Host "=== Cost Status — $($daily.date) ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Total Tokens:    $($daily.total_tokens) / $($budgetLimits.daily_tokens)" -ForegroundColor White
        Write-Host "Total Cost:      `$$($daily.total_cost_usd) / `$$($budgetLimits.daily_cost_usd)" -ForegroundColor White
        Write-Host ""

        if ($daily.by_agent.Count -gt 0) {
            Write-Host "--- By Agent ---" -ForegroundColor Cyan
            foreach ($agent in $daily.by_agent.Keys | Sort-Object { $daily.by_agent[$_].cost } -Descending) {
                $data = $daily.by_agent[$agent]
                Write-Host "  $agent`: $($data.count) calls | $($data.tokens) tokens | `$$($data.cost)" -ForegroundColor White
            }
            Write-Host ""
        }

        if ($daily.by_model.Count -gt 0) {
            Write-Host "--- By Model ---" -ForegroundColor Cyan
            foreach ($model in $daily.by_model.Keys | Sort-Object { $daily.by_model[$_].cost } -Descending) {
                $data = $daily.by_model[$model]
                Write-Host "  $model`: $($data.count) calls | $($data.tokens) tokens | `$$($data.cost)" -ForegroundColor White
            }
            Write-Host ""
        }

        # Budget utilization
        $costPct = if ($budgetLimits.daily_cost_usd -gt 0) { [math]::Round($daily.total_cost_usd / $budgetLimits.daily_cost_usd * 100) } else { 0 }
        $tokenPct = if ($budgetLimits.daily_tokens -gt 0) { [math]::Round($daily.total_tokens / $budgetLimits.daily_tokens * 100) } else { 0 }

        Write-Host "--- Budget Utilization ---" -ForegroundColor Cyan
        Write-Host "  Cost:   $costPct% $([char]0x2588) $(($costPct / 10))" -ForegroundColor $(if ($costPct -gt 80) { 'Red' } elseif ($costPct -gt 50) { 'Yellow' } else { 'Green' })
        Write-Host "  Tokens: $tokenPct% $([char]0x2588) $(($tokenPct / 10))" -ForegroundColor $(if ($tokenPct -gt 80) { 'Red' } elseif ($tokenPct -gt 50) { 'Yellow' } else { 'Green' })
        Write-Host ""
    }
}

function Show-Report {
    $daily = Get-DailyData
    Show-Status
}

function Reset-Counters {
    $today = Get-TodayKey
    $daily = @{
        date            = $today
        total_tokens    = 0
        total_cost_usd  = 0.0
        by_agent        = @{}
        by_model        = @{}
        by_task_type    = @{}
        entries         = @()
    }
    Save-DailyData $daily
    if (-not $Quiet) {
        Write-Host "[COST] Daily counters reset for $today" -ForegroundColor Green
    }
}

# === Main ===
switch ($Action) {
    'log'    { Log-Entry }
    'status' { Show-Status }
    'report' { Show-Report }
    'reset'  { Reset-Counters }
}
