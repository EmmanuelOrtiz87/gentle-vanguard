<#
.SYNOPSIS
    Generates proactive daily/status digests summarizing system activity.

.DESCRIPTION
    Collects health status, learning proposals, feedback trends, session
    metrics, and pending items into a concise markdown report. Designed to
    be shown at session start or on demand via gv digest.

    Usage:
        pwsh ./scripts/utilities/DIGEST/digest-generator.ps1
        pwsh ./scripts/utilities/DIGEST/digest-generator.ps1 -Mode daily
        pwsh ./scripts/utilities/DIGEST/digest-generator.ps1 -Mode status -JSON
#>

param(
    [ValidateSet('daily', 'status', 'weekly')]
    [string]$Mode = 'status',
    [switch]$JSON,
    [switch]$Show,
    [switch]$NoExit
)

$ErrorActionPreference = 'Continue'
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else { Get-Location }
    $root = Split-Path -Parent $scriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) {
        $root = Split-Path -Parent $root
    }
    if (-not $root) { $root = $scriptRoot }
    $root
}

$digestDir = Join-Path (Join-Path $repoRoot '.session') 'digests'
if (-not (Test-Path $digestDir)) { New-Item -ItemType Directory -Path $digestDir -Force | Out-Null }
$today = Get-Date -Format 'yyyy-MM-dd'
$digestFile = Join-Path $digestDir "$today.md"

$feedbackFile = Join-Path (Join-Path (Join-Path $repoRoot '.session') 'feedback') 'feedback.jsonl'
$proposalsDir = Join-Path (Join-Path $repoRoot '.local') 'improvement-proposals'
$sessionFile = Join-Path (Join-Path $repoRoot '.session') 'session.json'
$summaryFile = Join-Path (Join-Path (Join-Path $repoRoot 'scripts') '.session') 'startup-summary.json'

function Write-Step { param([string]$M) Write-Host "`n=== $M ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$M) Write-Host "[OK] $M" -ForegroundColor Green }
function Write-Warn { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }

function Complete-Script {
    param([int]$ExitCode = 0)
    if ($NoExit) { return $ExitCode }
    exit $ExitCode
}

# --- Collect data sources ---

$sessionId = ''
if (Test-Path $sessionFile) {
    try { $sessionId = (Get-Content $sessionFile -Raw | ConvertFrom-Json -ErrorAction Stop).sessionId } catch {}
}

$platform = ''
$tool = ''
if (Test-Path $summaryFile) {
    try {
        $s = Get-Content $summaryFile -Raw | ConvertFrom-Json -ErrorAction Stop
        $platform = $s.platform
        $tool = $s.tool
    } catch {}
}

# Git status
$branch = ''
$commitCount = 0
try {
    $branch = git -C $repoRoot rev-parse --abbrev-ref HEAD 2>$null
    $since = (Get-Date).AddHours(-24).ToString('yyyy-MM-ddTHH:mm:ss')
    $log = git -C $repoRoot log --oneline --since=$since 2>$null
    $commitCount = @($log).Count
} catch {}

# Health status
$healthStatus = 'unknown'
$healthScript = Join-Path $repoRoot 'scripts\utilities\SKILLS-TOOLS\ensure-tools-active.ps1'
if (Test-Path $healthScript) {
    try { & $healthScript -AutoStart -Quiet 2>&1 | Out-Null; $healthStatus = 'ok' } catch { $healthStatus = 'warn' }
}

# Feedback
$feedbackEntries = @()
if (Test-Path $feedbackFile) {
    $raw = Get-Content $feedbackFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '.' }
    $feedbackEntries = $raw | ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | Where-Object { $_ -ne $null }
}
$recentFeedback = $feedbackEntries | Where-Object {
    try { [DateTime]$_.timestamp -ge (Get-Date).AddDays(-7) } catch { $false }
}
$avgRating = 0
$rated = $recentFeedback | Where-Object { $_.rate -gt 0 }
if ($rated.Count -gt 0) { $avgRating = [math]::Round(($rated | Measure-Object -Property rate -Average).Average, 1) }

# Proposals
$pendingProposals = @()
if (Test-Path $proposalsDir) {
    $pendingProposals = Get-ChildItem -Path $proposalsDir -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object {
        try { $p = Get-Content $_.FullName -Raw | ConvertFrom-Json; if (-not $p.applied) { $_ } } catch { $null }
    } | Where-Object { $_ -ne $null }
}

# Token metrics
$tokenFile = Join-Path (Join-Path $repoRoot '.session') 'token-spend.json'
$tokenSpend = ''
if (Test-Path $tokenFile) {
    try {
        $t = Get-Content $tokenFile -Raw | ConvertFrom-Json
        $tokenSpend = if ($t.totalCost) { "`$$([math]::Round($t.totalCost, 2))" } else { 'N/A' }
    } catch {}
}

# --- Build digest ---

if ($JSON) {
    $digestData = @{
        date        = $today
        mode        = $Mode
        sessionId   = $sessionId
        platform    = $platform
        tool        = $tool
        branch      = $branch
        commits24h  = $commitCount
        health      = $healthStatus
        feedback    = @{ totalRecent = $recentFeedback.Count; avgRating = $avgRating }
        proposals   = @{ pending = $pendingProposals.Count }
        tokenSpend  = $tokenSpend
    }
    $digestData | ConvertTo-Json -Depth 3
    Complete-Script 0
    return
}

$lines = @()
$lines += "# Digest: $today"
$lines += "**Mode**: $Mode  |  **Session**: $sessionId  |  **Platform**: $platform  |  **Tool**: $tool"
if ($branch) { $lines += "**Branch**: $branch  |  **Commits (24h)**: $commitCount" }
$lines += ''
$lines += "## Health"
$lines += "- System: $((@{'ok'='OK';'warn'='Warning';'unknown'='Unknown'}[$healthStatus]))"
if ($tokenSpend) { $lines += "- Token spend: $tokenSpend" }
$lines += ''
if ($recentFeedback.Count -gt 0) {
    $lines += "## Feedback (7 days)"
    $lines += "- Entries: $($recentFeedback.Count), Avg rating: $avgRating/5"
    $lowRated = $rated | Where-Object { $_.rate -le 2 }
    foreach ($e in $lowRated) {
        $lines += "  - ★ $($e.rate)/5 ($($e.action)): '$($e.comment)'"
    }
    $lines += ''
}
if ($pendingProposals.Count -gt 0) {
    $lines += "## Pending Proposals"
    $lines += "- $($pendingProposals.Count) pending improvement(s)"
    $lines += "- Run `gv learning apply` or `gv digest` to review"
    $lines += ''
}
$lines += "## Next Steps"
$lines += '- Review digest: `gv digest`'
$lines += '- Submit feedback: `gv feedback rate 4 -Action <action> -Comment "..."`'
$lines += '- Apply learnings: `gv learning auto`'
$lines += '-'

$digest = $lines -join "`n"
$digest | Out-File -FilePath $digestFile -Encoding UTF8 -Force
Write-Ok "Digest saved to $digestFile"

if ($Mode -eq 'status' -or $Show) {
    Write-Host "`n$digest" -ForegroundColor Gray
}

Complete-Script 0