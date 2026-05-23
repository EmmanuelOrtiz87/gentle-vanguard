# session-context-log.ps1
# Session context logger — registra input/output del agente por turno
# Archivos temporales en .session/context-log/<session-id>/
# Archivos permanentes locales (opcional) en .local/session-artifacts/

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("init", "reinit", "log", "close", "status")]
    [string]$Action,

    [string]$SessionId = "",
    [string]$TurnLabel = "",
    [string]$InputSummary = "",
    [string]$OutputSummary = "",
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [int]$ContextChars = 0,
    [string]$ToolCalls = "",
    [string]$Model = "",
    [switch]$PromoteToPermanent,
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

# Repo root detection — busca config/orchestrator.json para evitar falsos positivos
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $root = $scriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = (Get-Location).Path }
    $root
}

$sessionDir = Join-Path $repoRoot ".session"
$contextLogRoot = Join-Path $sessionDir "context-log"
$localArtifacts = Join-Path $repoRoot ".local" "session-artifacts"

# Cost estimation: ~$0.15/M input, ~$0.60/M output (OpenRouter GLM-5 approx)
$costPerInputToken = 0.15 / 1e6
$costPerOutputToken = 0.60 / 1e6

function Get-SessionId {
    if ($SessionId) { return $SessionId }
    $tokenFile = Join-Path $sessionDir "token-usage.json"
    if (Test-Path $tokenFile) {
        try {
            $data = Get-Content $tokenFile -Raw | ConvertFrom-Json
            if ($data.sessionId) { return $data.sessionId }
        } catch {}
    }
    $sFile = Get-ChildItem (Join-Path $sessionDir "session-*.json") -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($sFile) {
        try {
            $d = Get-Content $sFile.FullName -Raw | ConvertFrom-Json
            return $d.sessionId
        } catch {}
    }
    return "session-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
}

function Get-CostString {
    param([int]$InTokens, [int]$OutTokens)
    $inCost = $InTokens * $costPerInputToken
    $outCost = $OutTokens * $costPerOutputToken
    $total = $inCost + $outCost
    return "$("{0:N4}" -f $total) USD (in: {0:N4}, out: {1:N4})" -f $inCost, $outCost
}

function Get-SafePath {
    param([string]$Sid)
    $safe = $Sid -replace '[^\w\-]', '_'
    if ($safe.Length -gt 80) { $safe = $safe.Substring(0, 80) }
    return $safe
}

$safeSid = Get-SafePath -Sid (Get-SessionId)
$logDir = Join-Path $contextLogRoot $safeSid
$summaryFile = Join-Path $logDir "context-summary.md"
$stateFile = Join-Path $logDir ".state.json"

function Write-Log {
    param([string]$Msg, [string]$Level = "INFO")
    if (-not $Silent) {
        $c = switch ($Level) { "OK" { "Green" } "WARN" { "Yellow" } "ERROR" { "Red" } default { "Cyan" } }
        Write-Host "[CTXLOG] $Msg" -ForegroundColor $c
    }
}

function Initialize-Log {
    if (Test-Path $logDir) {
        Write-Log "Context log dir already exists: $logDir" "WARN"
        return
    }
    Initialize-LogInner
}

function Reinitialize-Log {
    if (Test-Path $logDir) {
        Write-Log "Removing existing context log: $logDir" "WARN"
        Remove-Item -Path $logDir -Recurse -Force
    }
    Initialize-LogInner
    Write-Log "Reinitialized context log: $logDir" "OK"
}

function Initialize-LogInner {
    $null = New-Item -ItemType Directory -Path $logDir -Force
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
    $state = @{
        sessionId = $safeSid
        startedAt = $ts
        turnCount = 0
        totalInputTokens = 0
        totalOutputTokens = 0
        totalContextChars = 0
        totalCost = 0.0
        model = $Model
        turns = @()
    }
    $state | ConvertTo-Json | Set-Content $stateFile -Encoding UTF8

    # Create summary markdown header
    $header = @"
# Session Context Log

## Session: $safeSid
**Started**: $ts
**Model**: $(if ($Model) { $Model } else { "auto-detect" })
**Status**: ACTIVE

---

## Turn Log

"@
    $header | Set-Content $summaryFile -Encoding UTF8
    Write-Log "Initialized context log: $logDir" "OK"
}

function Log-Turn {
    $sid = Get-SessionId
    if (-not (Test-Path $stateFile)) { Initialize-Log }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    $turnNum = $state.turnCount + 1
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
    $label = if ($TurnLabel) { $TurnLabel } else { "Turn-$turnNum" }
    $totalTk = $InputTokens + $OutputTokens
    $costStr = Get-CostString -InTokens $InputTokens -OutTokens $OutputTokens

    # Sanitize summaries for markdown (truncate long lines)
    $inSummary = $InputSummary
    if ($inSummary.Length -gt 2000) { $inSummary = $inSummary.Substring(0, 2000) + "..." }
    $outSummary = $OutputSummary
    if ($outSummary.Length -gt 4000) { $outSummary = $outSummary.Substring(0, 4000) + "..." }

    # Individual turn detail file
    $turnFile = Join-Path $logDir ("turn-{0:D3}.md" -f $turnNum)
    $turnDetail = @"
# Turn ${turnNum}: $label

**Timestamp**: $ts
**Model**: $(if ($Model) { $Model } else { $state.model })

## Metrics
| Metric | Value |
|--------|-------|
| Input Tokens | $InputTokens |
| Output Tokens | $OutputTokens |
| Total Tokens | $totalTk |
| Context Chars | $ContextChars |
| Estimated Cost | $costStr |

## Context Input
\`\`\`
$inSummary
\`\`\`

## Agent Response
\`\`\`
$outSummary
\`\`\`

## Tool Calls
$(if ($ToolCalls) { $ToolCalls } else { "N/A" })

---
"@
    $turnDetail | Set-Content $turnFile -Encoding UTF8

    # Cost accumulation
    $inCost = $InputTokens * $costPerInputToken
    $outCost = $OutputTokens * $costPerOutputToken
    $turnCost = $inCost + $outCost

    $state.turnCount = $turnNum
    $state.totalInputTokens += $InputTokens
    $state.totalOutputTokens += $OutputTokens
    $state.totalContextChars += $ContextChars
    $state.totalCost = [math]::Round(($state.totalCost + $turnCost), 6)

    $turnEntry = @{
        turn = $turnNum
        label = $label
        timestamp = $ts
        inputTokens = $InputTokens
        outputTokens = $OutputTokens
        totalTokens = $totalTk
        contextChars = $ContextChars
        cost = [math]::Round($turnCost, 6)
    }
    $state.turns += $turnEntry
    $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Encoding UTF8

    # Append to summary
    $entry = @"

### Turn $turnNum — $label

| Field | Value |
|-------|-------|
| Timestamp | $ts |
| Input Tokens | $InputTokens |
| Output Tokens | $OutputTokens |
| Total Tokens | $totalTk |
| Context Chars | $ContextChars |
| Cost | $costStr |

#### Input Summary
\`\`\`
$inSummary
\`\`\`

#### Output Summary
\`\`\`
$outSummary
\`\`\`

---
"@
    Add-Content -Path $summaryFile -Value $entry -Encoding UTF8

    # Accumulated totals footer
    $acc = @"

**Accumulated**: $($state.turnCount) turns | $($state.totalInputTokens) in / $($state.totalOutputTokens) out / $($state.totalContextChars) chars | Cost: $("{0:N6}" -f $state.totalCost) USD
"@
    Add-Content -Path $summaryFile -Value $acc -Encoding UTF8

    Write-Log "Logged turn $turnNum ($label): in=$InputTokens out=$OutputTokens cost=$("{0:N6}" -f $turnCost) USD" "OK"

    # Show compact notification
    if (-not $Silent) {
        $bar = "─" * 40
        Write-Host "┌$bar┐" -ForegroundColor DarkGray
        Write-Host "│ Context Log: Turn $turnNum" -ForegroundColor DarkGray
        Write-Host "│ In: $InputTokens tk | Out: $OutputTokens tk | Cost: $("{0:N6}" -f $turnCost) USD" -ForegroundColor DarkGray
        Write-Host "└$bar┘" -ForegroundColor DarkGray
    }
}

function Close-Log {
    if (-not (Test-Path $stateFile)) {
        Write-Log "No active context log to close" "WARN"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
    $dur = $null
    try {
        $start = [DateTime]::Parse($state.startedAt)
        $dur = (Get-Date) - $start
    } catch { $dur = $null }

    $durStr = if ($dur) { "{0:dd}d {0:hh}h {0:mm}m" -f $dur } else { "N/A" }
    $avgIn = if ($state.turnCount -gt 0) { [math]::Round($state.totalInputTokens / $state.turnCount) } else { 0 }
    $avgOut = if ($state.turnCount -gt 0) { [math]::Round($state.totalOutputTokens / $state.turnCount) } else { 0 }

    # Finalize summary
    $footer = @"

---

## Session Closed

**Ended**: $ts
**Duration**: $durStr
**Total Turns**: $($state.turnCount)
**Final Totals**:
- Input Tokens: $($state.totalInputTokens)
- Output Tokens: $($state.totalOutputTokens)
- Grand Total: $($state.totalInputTokens + $state.totalOutputTokens)
- Context Chars: $($state.totalContextChars)
- Total Cost: $("{0:N6}" -f $state.totalCost) USD

**Averages per Turn**: $avgIn in / $avgOut out

---
*Generated by session-context-log.ps1 | Session context logs are local-only*
"@
    Add-Content -Path $summaryFile -Value $footer -Encoding UTF8

    Write-Log "Session closed. Total: $($state.turnCount) turns | Cost: $("{0:N6}" -f $state.totalCost) USD" "OK"

    # Show summary
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              SESSION CONTEXT SUMMARY                     ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Turns:   $($state.turnCount.ToString().PadRight(45)) ║" -ForegroundColor White
    Write-Host "║  Duration: $($durStr.PadRight(45)) ║" -ForegroundColor White
    Write-Host "║  Total In: $($state.totalInputTokens.ToString().PadRight(45)) ║" -ForegroundColor Green
    Write-Host "║  Total Out:$($state.totalOutputTokens.ToString().PadRight(45)) ║" -ForegroundColor Cyan
    Write-Host "║  Grand Tot:$((($state.totalInputTokens + $state.totalOutputTokens)).ToString().PadRight(45)) ║" -ForegroundColor Yellow
    Write-Host "║  Cost:     $("{0:N6}" -f $state.totalCost) USD".PadRight(49) + "║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  Log: $summaryFile" -ForegroundColor DarkGray
    Write-Host ""

    # Promote to permanent local storage if requested
    if ($PromoteToPermanent) {
        Promote-ToPermanent
    }

    # Update state
    $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Encoding UTF8
}

function Show-Status {
    if (-not (Test-Path $stateFile)) {
        Write-Host "[CTXLOG] No active context log" -ForegroundColor Yellow
        return
    }
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    $dur = $null
    try {
        $start = [DateTime]::Parse($state.startedAt)
        $dur = (Get-Date) - $start
    } catch { $dur = $null }
    $durStr = if ($dur) { "{0:hh}:{1:mm}:{2:ss}" -f $dur.Hours, $dur.Minutes, $dur.Seconds } else { "N/A" }

    Write-Host ""
    Write-Host "Session Context Log Status" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "Session:   $safeSid" -ForegroundColor White
    Write-Host "Dir:       $logDir" -ForegroundColor Gray
    Write-Host "Turns:     $($state.turnCount)" -ForegroundColor White
    Write-Host "Duration:  $durStr" -ForegroundColor Gray
    Write-Host "Total In:  $($state.totalInputTokens) tokens" -ForegroundColor Green
    Write-Host "Total Out: $($state.totalOutputTokens) tokens" -ForegroundColor Cyan
    Write-Host "Cost:      $("{0:N6}" -f $state.totalCost) USD" -ForegroundColor Magenta
    Write-Host ""
}

function Promote-ToPermanent {
    param([string]$TargetDir = "")
    if (-not $TargetDir) { $TargetDir = $localArtifacts }
    $null = New-Item -ItemType Directory -Path $TargetDir -Force
    $permDir = Join-Path $TargetDir "context-log-$safeSid"
    if (Test-Path $permDir) { Remove-Item -Path $permDir -Recurse -Force }
    Copy-Item -Path $logDir -Destination $permDir -Recurse -Force
    Write-Log "Promoted to permanent: $permDir" "OK"
    return $permDir
}

# Main dispatch
switch ($Action) {
    "init" { Initialize-Log }
    "log" { Log-Turn }
    "close" { Close-Log }
    "status" { Show-Status }
}
