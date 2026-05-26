# token-usage-auto.ps1
# Token usage display + context logging — ejecutar tras cada respuesta del agente
# Integra token-usage-notifier + session-context-log

param(
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [int]$ContextChars = 0,
    [string]$SessionId = "",
    [string]$TurnLabel = "",
    [string]$InputSummary = "",
    [string]$OutputSummary = "",
    [string]$ToolCalls = "",
    [string]$Model = ""
)

$ErrorActionPreference = 'Continue'

# Repo root — busca config/orchestrator.json para evitar falsos positivos
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $root = Get-Location
    $found = $false
    $maxDepth = 10; $depth = 0
    while ($root -and -not $found -and $depth -lt $maxDepth) {
        if ((Test-Path (Join-Path $root 'config\orchestrator.json'))) { $found = $true; break }
        $parent = Split-Path -Parent $root
        if ($parent -eq $root) { break }
        $root = $parent; $depth++
    }
    if (-not $found) { $root = Get-Location }
    $root
}

# Auto-detect session ID if not provided
if (-not $SessionId) {
    $tokenFile = Join-Path $repoRoot ".session\token-usage.json"
    if (Test-Path $tokenFile) {
        try {
            $td = Get-Content $tokenFile -Raw | ConvertFrom-Json
            if ($td.sessionId) { $SessionId = $td.sessionId }
        } catch {}
    }
}
if (-not $SessionId) {
    $sFile = Get-ChildItem (Join-Path $repoRoot ".session\session-*.json") -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($sFile) {
        try {
            $sd = Get-Content $sFile.FullName -Raw | ConvertFrom-Json
            $SessionId = $sd.sessionId
        } catch {}
    }
}

# 1. Token notifier display
$notifierScript = Join-Path $repoRoot "scripts/utilities/token-usage-notifier.ps1"
if (Test-Path $notifierScript) {
    if ($InputTokens -eq 0 -and $OutputTokens -eq 0) {
        $estimatedInput = [math]::Max(1, [math]::Floor($ContextChars / 4))
        $estimatedOutput = [math]::Max(1, [math]::Floor(500 / 4))
        $InputTokens = $estimatedInput
        $OutputTokens = $estimatedOutput
    }
    & $notifierScript -Action accumulate -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars -SessionId $SessionId -Model $Model
}

# 2. Context logging — auto-init if dir missing, then log
$ctxLog = Join-Path $repoRoot "scripts/utilities/session-context-log.ps1"
if (Test-Path $ctxLog) {
    $ctxDir = Join-Path $repoRoot ".session\context-log"
    if (-not (Test-Path $ctxDir)) {
        & $ctxLog -Action init -SessionId $SessionId -Model $Model -Silent
    }
    & $ctxLog -Action log -SessionId $SessionId -TurnLabel $TurnLabel `
        -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars `
        -InputSummary $InputSummary -OutputSummary $OutputSummary -ToolCalls $ToolCalls -Model $Model -Silent
}

exit 0
