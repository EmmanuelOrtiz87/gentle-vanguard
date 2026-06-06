<#
.SYNOPSIS
    Analyzes feedback patterns and generates improvement proposals.

.DESCRIPTION
    Reads .session/feedback/feedback.jsonl, computes satisfaction trends,
    detects negative patterns, and generates structured improvement proposals.
    Also suggests new normativas when recurring issues are detected.

    Usage:
        pwsh ./scripts/utilities/FEEDBACK/feedback-analyzer.ps1
        pwsh ./scripts/utilities/FEEDBACK/feedback-analyzer.ps1 -AutoPropose
        pwsh ./scripts/utilities/FEEDBACK/feedback-analyzer.ps1 -TrendDays 14
#>

param(
    [int]$TrendDays = 30,
    [switch]$AutoPropose,
    [switch]$AutoApplyLow,
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
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $scriptRoot }
    $root
}

$feedbackFile = Join-Path (Join-Path (Join-Path $repoRoot '.session') 'feedback') 'feedback.jsonl'
$proposalsDir = Join-Path (Join-Path $repoRoot '.local') 'improvement-proposals'
if (-not (Test-Path $proposalsDir)) { New-Item -ItemType Directory -Path $proposalsDir -Force | Out-Null }
$ts = (Get-Date -Format 'yyyy-MM-dd')
$cutoff = (Get-Date).AddDays(-$TrendDays)

function Write-Step { param([string]$M) Write-Host "`n=== $M ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$M) Write-Host "[OK] $M" -ForegroundColor Green }
function Write-Warn { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }
function Write-Hit  { param([string]$M) Write-Host "[HIT] $M" -ForegroundColor Magenta }

function Complete-Script {
    param([int]$ExitCode = 0)
    if ($NoExit) { return $ExitCode }
    exit $ExitCode
}

if (-not (Test-Path $feedbackFile)) {
    Write-Warn "No feedback data found at $feedbackFile"
    Complete-Script 0
    return
}

$rawEntries = Get-Content $feedbackFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '.' }
if ($rawEntries.Count -eq 0) {
    Write-Warn "Feedback file is empty"
    Complete-Script 0
    return
}

Write-Step "Feedback Analysis"
$entries = $rawEntries | ForEach-Object {
    try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { $null }
} | Where-Object { $_ -ne $null }

Write-Ok "Total feedback entries: $($entries.Count)"

$recent = $entries | Where-Object { [DateTime]$_.timestamp -ge $cutoff }

Write-Step "Satisfaction by Action"
$rated = $recent | Where-Object { $_.rate -gt 0 }
$byAction = $rated | Group-Object -Property action
foreach ($g in $byAction) {
    $avg = [math]::Round(($g.Group | Measure-Object -Property rate -Average).Average, 1)
    $signal = if ($avg -ge 4) { 'GREEN' } elseif ($avg -ge 3) { 'YELLOW' } else { 'RED' }
    Write-Ok "[$signal] $($g.Name): $($g.Count) ratings, avg $avg/5"
}

$lowRated = $rated | Where-Object { $_.rate -le 2 }
if ($lowRated.Count -gt 0) {
    Write-Step "Low-Rated Items (<=2)"
    foreach ($e in $lowRated) {
        $stars = '★' * $e.rate
        Write-Hit "$stars $($e.action): $($e.comment)"
    }
}

$proposals = @()
$proposalIdx = 0

$redActions = $byAction | Where-Object {
    $avg = [math]::Round(($_.Group | Measure-Object -Property rate -Average).Average, 1)
    $avg -lt 3
}
foreach ($g in $redActions) {
    $proposalIdx++
    $desc = "Feedback indicates low satisfaction ($($g.Count) entries, avg < 3/5) for action: $($g.Name)"
    $proposals += @{
        id = "feedback-prop-$ts-$( '{0:D3}' -f $proposalIdx )"
        date = $ts
        category = 'feedback-improvement'
        severity = 'medium'
        description = $desc
        action = $g.Name
        sampleCount = $g.Count
        proposedAction = "Review $($g.Name) logic and address recurring complaints"
        autoApply = $false
        applied = $false
    }
}

$comments = $recent | Where-Object { -not [string]::IsNullOrWhiteSpace($_.comment) }
if ($comments.Count -gt 0) {
    $keywords = @()
    foreach ($e in $comments) {
        $words = $e.comment -split '\s+' | ForEach-Object { $_.Trim().ToLower() }
        $keywords += $words
    }
    $freq = $keywords | Group-Object | Sort-Object Count -Descending | Select-Object -First 5
    Write-Step "Top Keywords in Comments"
    foreach ($k in $freq) {
        Write-Ok "  $($k.Name): $($k.Count) occurrences"
    }
}

if ($proposals.Count -gt 0) {
    Write-Step "Generated Proposals"
    foreach ($p in $proposals) {
        Write-Hit "[$($p.severity)] $($p.description)"
        Write-Ok "  -> $($p.proposedAction)"
        $propFile = Join-Path $proposalsDir "$($p.id).json"
        $p | ConvertTo-Json -Depth 3 | Out-File -FilePath $propFile -Encoding UTF8 -Force
        Write-Ok "  Saved: $propFile"
    }
    } else {
        Write-Ok "No improvement proposals generated — all feedback patterns are healthy"
}

# Auto-apply low-severity proposals
if ($AutoApplyLow -and $proposals.Count -gt 0) {
    Write-Step "Auto-Applying Low/Medium Severity Proposals"
    $executorScript = Join-Path $repoRoot 'scripts' 'utilities' 'proposal-executor.ps1'
    foreach ($p in $proposals) {
        if ($p.severity -in @('low', 'medium')) {
            $propFile = Join-Path $proposalsDir "$($p.id).json"
            if (Test-Path $propFile) {
                $p.autoApply = $true
                $p | ConvertTo-Json -Depth 3 | Out-File -FilePath $propFile -Encoding UTF8 -Force
                if (Test-Path $executorScript) {
                    Write-Ok "Auto-applying: $($p.description)"
                    & $executorScript -ProposalFile $propFile -AutoApply -Quiet 2>&1 | Out-Null
                } else {
                    Write-Ok "Queued for apply: $($p.description)"
                }
            }
        }
    }
}

Complete-Script 0
