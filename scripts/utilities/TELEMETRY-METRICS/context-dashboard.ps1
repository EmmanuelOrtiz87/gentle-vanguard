<#
.SYNOPSIS
    Unified Context Dashboard - shows prompt chars, adoption %, token budget, and blocked events.

.DESCRIPTION
    Aggregates live context health from:
    - config/cline-dify-optimized.config.json  (prompt thresholds, effective window)
    - config/orchestrator.json                 (token_budget_guard, response policy)
    - config/context-efficiency.json           (token autopilot policy)
    - .event-bus/history.json                  (blocked events in last 60s)
    - docs/sessions/metrics/token-guard-usage.csv (daily token consumption)

    Output: color-coded console table + optional JSON via -AsJson.

.PARAMETER PromptChars
    Current prompt size in characters. Pass from wf.ps1 or measure manually.

.PARAMETER AdoptionPct
    Current context adoption percentage (0-100). Pass from wf.ps1.

.PARAMETER AsJson
    Output as JSON for programmatic use.

.EXAMPLE
    .\context-dashboard.ps1 -PromptChars 950 -AdoptionPct 65
    .\context-dashboard.ps1 -AsJson
#>
param(
    [int]$PromptChars = 0,
    [int]$AdoptionPct = 0,
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot   = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

# ── Load configs ─────────────────────────────────────────────────────────────
function Read-JsonFile {
    param([string]$Path)
    if (Test-Path $Path) {
        try { return Get-Content -Path $Path -Raw | ConvertFrom-Json }
        catch { return $null }
    }
    return $null
}

$difyConfig  = Read-JsonFile (Join-Path $repoRoot 'config\cline-dify-optimized.config.json')
$orchConfig  = Read-JsonFile (Join-Path $repoRoot 'config\orchestrator.json')
$ctxConfig   = Read-JsonFile (Join-Path $repoRoot 'config\context-efficiency.json')
$historyPath = Join-Path $repoRoot '.event-bus\history.json'
$csvPath     = Join-Path $repoRoot 'docs\sessions\metrics\token-guard-usage.csv'

# ── Context window thresholds ────────────────────────────────────────────────
$effectiveWindow   = if ($difyConfig) { $difyConfig.tokenOptimization.effectiveWindow } else { 113000 }
$promptYellow      = if ($difyConfig) { $difyConfig.tokenOptimization.rules.promptChars.yellowThreshold } else { 1100 }
$promptRed         = if ($difyConfig) { $difyConfig.tokenOptimization.rules.promptChars.redThreshold    } else { 1600 }
$adoptYellow       = if ($difyConfig) { $difyConfig.tokenOptimization.rules.adoptionPercent.yellowMin   } else { 75 }
$adoptRed          = if ($difyConfig) { $difyConfig.tokenOptimization.rules.adoptionPercent.redMin      } else { 50 }

# ── Token budget guard settings ──────────────────────────────────────────────
$tbg = if ($orchConfig) { $orchConfig.subagent_orchestration.token_budget_guard } else { $null }
$dailyBudget     = if ($tbg) { $tbg.daily_budget_tokens     } else { 30000 }
$softPct         = if ($tbg) { $tbg.soft_threshold_pct      } else { 70 }
$hardPct         = if ($tbg) { $tbg.hard_threshold_pct      } else { 90 }
$charsPerToken   = if ($tbg) { $tbg.estimation.chars_per_token } else { 4 }

# ── Daily consumption from CSV ───────────────────────────────────────────────
$tokensUsedToday = 0
if (Test-Path $csvPath) {
    try {
        $today = (Get-Date).ToString('yyyy-MM-dd')
        $rows = Import-Csv -Path $csvPath | Where-Object { $_.date -like "$today*" }
        foreach ($r in $rows) {
            if ($r.tokens_estimated) {
                $tokensUsedToday += [int]$r.tokens_estimated
            }
        }
    } catch { }
}

# ── Token autopilot policy ───────────────────────────────────────────────────
$autopilotProfile = if ($ctxConfig) { $ctxConfig.tokenAutopilot.profile } else { 'unknown' }
$autopilotTrigger = if ($ctxConfig) { ($ctxConfig.tokenAutopilot.triggerStatuses -join ', ') } else { 'HARD_LIMIT' }

# ── Blocked events in last 60s ───────────────────────────────────────────────
$blockedRecent = 0
if (Test-Path $historyPath) {
    try {
        $history = Get-Content -Path $historyPath -Raw | ConvertFrom-Json
        $windowStart = (Get-Date).AddSeconds(-60)
        if ($history.events) {
            $blockedRecent = @($history.events | Where-Object {
                $_.status -like 'blocked*' -and $_.timestamp -and
                ([datetime]::Parse($_.timestamp)) -ge $windowStart
            }).Count
        }
    } catch { }
}

# ── Compute health statuses ──────────────────────────────────────────────────
$promptStatus = 'GREEN'
if ($PromptChars -ge $promptRed)    { $promptStatus = 'RED'    }
elseif ($PromptChars -ge $promptYellow) { $promptStatus = 'YELLOW' }

$adoptStatus = 'GREEN'
if ($AdoptionPct -gt 0) {
    if ($AdoptionPct -le $adoptRed)    { $adoptStatus = 'RED'    }
    elseif ($AdoptionPct -le $adoptYellow) { $adoptStatus = 'YELLOW' }
}

$budgetPct = if ($dailyBudget -gt 0) { [math]::Round(($tokensUsedToday / $dailyBudget) * 100, 1) } else { 0 }
$budgetStatus = 'GREEN'
if ($budgetPct -ge $hardPct)      { $budgetStatus = 'RED'    }
elseif ($budgetPct -ge $softPct)  { $budgetStatus = 'YELLOW' }

$eventStatus = if ($blockedRecent -gt 0) { 'YELLOW' } else { 'GREEN' }

# ── Projected tokens from current prompt ─────────────────────────────────────
$promptTokens    = if ($PromptChars -gt 0) { [math]::Ceiling($PromptChars / $charsPerToken) } else { 0 }
$windowUsedPct   = if ($effectiveWindow -gt 0 -and $promptTokens -gt 0) {
    [math]::Round(($promptTokens / $effectiveWindow) * 100, 1)
} else { 0 }

# ── Output ───────────────────────────────────────────────────────────────────
$dashboard = [ordered]@{
    timestamp          = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    prompt = [ordered]@{
        chars          = $PromptChars
        tokens_est     = $promptTokens
        yellow_at      = $promptYellow
        red_at         = $promptRed
        status         = $promptStatus
    }
    context_window = [ordered]@{
        effective_tokens = $effectiveWindow
        used_pct         = $windowUsedPct
        adoption_pct     = $AdoptionPct
        adoption_yellow  = $adoptYellow
        adoption_red     = $adoptRed
        adoption_status  = $adoptStatus
    }
    token_budget = [ordered]@{
        daily_budget     = $dailyBudget
        used_today       = $tokensUsedToday
        used_pct         = $budgetPct
        soft_threshold   = $softPct
        hard_threshold   = $hardPct
        status           = $budgetStatus
    }
    autopilot = [ordered]@{
        profile          = $autopilotProfile
        triggers_on      = $autopilotTrigger
    }
    events = [ordered]@{
        blocked_last_60s = $blockedRecent
        status           = $eventStatus
    }
}

if ($AsJson) {
    $dashboard | ConvertTo-Json -Depth 4
    return
}

# ── Console display ───────────────────────────────────────────────────────────
$colorMap = @{ GREEN = 'Green'; YELLOW = 'Yellow'; RED = 'Red' }

function Write-StatusRow {
    param([string]$Label, [string]$Value, [string]$Status)
    $color = $colorMap[$Status]
    if (-not $color) { $color = 'White' }
    $padLabel = $Label.PadRight(28)
    Write-Host "  $padLabel" -NoNewline -ForegroundColor Gray
    Write-Host $Value -ForegroundColor $color
}

Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       CONTEXT DASHBOARD              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "  [PROMPT]" -ForegroundColor White
Write-StatusRow "  Chars"          "$PromptChars / yellow=$promptYellow red=$promptRed"    $promptStatus
Write-StatusRow "  Tokens est."    "$promptTokens  (~$windowUsedPct% of effective window)" $promptStatus

Write-Host ""
Write-Host "  [CONTEXT WINDOW]" -ForegroundColor White
Write-StatusRow "  Effective window" "$effectiveWindow tokens"                    'GREEN'
Write-StatusRow "  Adoption %"       "$AdoptionPct%  (yellow<$adoptYellow red<$adoptRed)" $adoptStatus

Write-Host ""
Write-Host "  [TOKEN BUDGET (daily)]" -ForegroundColor White
Write-StatusRow "  Used today"     "$tokensUsedToday / $dailyBudget tokens ($budgetPct%)"  $budgetStatus
Write-StatusRow "  Soft limit"     "$softPct% (WARN)"   'GREEN'
Write-StatusRow "  Hard limit"     "$hardPct% (BLOCK)"  'GREEN'

Write-Host ""
Write-Host "  [TOKEN AUTOPILOT]" -ForegroundColor White
Write-StatusRow "  Profile"        $autopilotProfile     'GREEN'
Write-StatusRow "  Triggers on"    $autopilotTrigger     'GREEN'

Write-Host ""
Write-Host "  [EVENTS]" -ForegroundColor White
Write-StatusRow "  Blocked (60s)"  "$blockedRecent events blocked"   $eventStatus

Write-Host ""
