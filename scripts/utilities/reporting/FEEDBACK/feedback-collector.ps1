<#
.SYNOPSIS
    Collects explicit user feedback on system decisions and actions.

.DESCRIPTION
    Captures user ratings (1-5), comments, and contextual metadata about any
    system action (healing, learning proposal, routing, code review, etc.).
    Feedback is persisted to .session/feedback.jsonl for pattern analysis.

    Usage:
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Rate 4 -Action healing -Comment "Fixed config but missed permission"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Action learning -Comment "Good proposal"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Status
#>

param(
    [ValidateRange(1,5)]
    [int]$Rate = 0,
    [ValidateSet('healing', 'learning', 'routing', 'code-review', 'digest', 'general')]
    [string]$Action = 'general',
    [string]$Comment = '',
    [string]$Context = '',
    [switch]$Status,
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

$feedbackDir = Join-Path (Join-Path $repoRoot '.session') 'feedback'
if (-not (Test-Path $feedbackDir)) { New-Item -ItemType Directory -Path $feedbackDir -Force | Out-Null }
$feedbackFile = Join-Path $feedbackDir 'feedback.jsonl'

function Write-Message  { param([string]$M) Write-Host $M -ForegroundColor Cyan }
function Write-Ok      { param([string]$M) Write-Host "[OK] $M" -ForegroundColor Green }
function Write-Warn    { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }

function Complete-Script {
    param([int]$ExitCode = 0)
    if ($NoExit) { return $ExitCode }
    exit $ExitCode
}

if ($Status) {
    if (-not (Test-Path $feedbackFile)) {
        Write-Message "No feedback records yet. Be the first!"
        Complete-Script 0
        return
    }
    $entries = Get-Content $feedbackFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '.' }
    $total = $entries.Count
    $rated = $entries | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction SilentlyContinue } | Where-Object { $_ -and $_.rate -gt 0 }
    $totalRated = $rated.Count
    $avg = if ($totalRated -gt 0) { [math]::Round(($rated | Measure-Object -Property rate -Average).Average, 1) } else { 0 }
    Write-Message "=== Feedback Status ==="
    Write-Ok "Total entries: $total"
    Write-Ok "Rated entries: $totalRated"
    if ($avg -gt 0) { Write-Ok "Average rating: $avg/5" }
    $byAction = $rated | Group-Object -Property action | Sort-Object Count -Descending
    foreach ($g in $byAction) {
        $gAvg = [math]::Round(($g.Group | Measure-Object -Property rate -Average).Average, 1)
        Write-Ok "  $($g.Name): $($g.Count) entries, avg $gAvg/5"
    }
    Complete-Script 0
    return
}

if ($Rate -eq 0 -and [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Warn "Provide at least -Rate (1-5) or -Comment to submit feedback"
    Write-Message "Usage: feedback-collector.ps1 -Rate 4 -Action healing -Comment 'text' [-Context 'scope']"
    Write-Message "       feedback-collector.ps1 -Status"
    Complete-Script 1
    return
}

$sessionFile = Join-Path (Join-Path $repoRoot '.session') 'session.json'
$sessionId = ''
if (Test-Path $sessionFile) {
    try { $sessionId = (Get-Content $sessionFile -Raw | ConvertFrom-Json).sessionId } catch { Write-Debug "Exception caught: <#
.SYNOPSIS
    Collects explicit user feedback on system decisions and actions.

.DESCRIPTION
    Captures user ratings (1-5), comments, and contextual metadata about any
    system action (healing, learning proposal, routing, code review, etc.).
    Feedback is persisted to .session/feedback.jsonl for pattern analysis.

    Usage:
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Rate 4 -Action healing -Comment "Fixed config but missed permission"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Action learning -Comment "Good proposal"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Status
#>

param(
    [ValidateRange(1,5)]
    [int]$Rate = 0,
    [ValidateSet('healing', 'learning', 'routing', 'code-review', 'digest', 'general')]
    [string]$Action = 'general',
    [string]$Comment = '',
    [string]$Context = '',
    [switch]$Status,
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

$feedbackDir = Join-Path (Join-Path $repoRoot '.session') 'feedback'
if (-not (Test-Path $feedbackDir)) { New-Item -ItemType Directory -Path $feedbackDir -Force | Out-Null }
$feedbackFile = Join-Path $feedbackDir 'feedback.jsonl'

function Write-Message  { param([string]$M) Write-Host $M -ForegroundColor Cyan }
function Write-Ok      { param([string]$M) Write-Host "[OK] $M" -ForegroundColor Green }
function Write-Warn    { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }

function Complete-Script {
    param([int]$ExitCode = 0)
    if ($NoExit) { return $ExitCode }
    exit $ExitCode
}

if ($Status) {
    if (-not (Test-Path $feedbackFile)) {
        Write-Message "No feedback records yet. Be the first!"
        Complete-Script 0
        return
    }
    $entries = Get-Content $feedbackFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '.' }
    $total = $entries.Count
    $rated = $entries | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction SilentlyContinue } | Where-Object { $_ -and $_.rate -gt 0 }
    $totalRated = $rated.Count
    $avg = if ($totalRated -gt 0) { [math]::Round(($rated | Measure-Object -Property rate -Average).Average, 1) } else { 0 }
    Write-Message "=== Feedback Status ==="
    Write-Ok "Total entries: $total"
    Write-Ok "Rated entries: $totalRated"
    if ($avg -gt 0) { Write-Ok "Average rating: $avg/5" }
    $byAction = $rated | Group-Object -Property action | Sort-Object Count -Descending
    foreach ($g in $byAction) {
        $gAvg = [math]::Round(($g.Group | Measure-Object -Property rate -Average).Average, 1)
        Write-Ok "  $($g.Name): $($g.Count) entries, avg $gAvg/5"
    }
    Complete-Script 0
    return
}

if ($Rate -eq 0 -and [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Warn "Provide at least -Rate (1-5) or -Comment to submit feedback"
    Write-Message "Usage: feedback-collector.ps1 -Rate 4 -Action healing -Comment 'text' [-Context 'scope']"
    Write-Message "       feedback-collector.ps1 -Status"
    Complete-Script 1
    return
}

$sessionFile = Join-Path (Join-Path $repoRoot '.session') 'session.json'
$sessionId = ''
if (Test-Path $sessionFile) {
    try { $sessionId = (Get-Content $sessionFile -Raw | ConvertFrom-Json).sessionId } catch { Write-Debug "Exception caught: <#
.SYNOPSIS
    Collects explicit user feedback on system decisions and actions.

.DESCRIPTION
    Captures user ratings (1-5), comments, and contextual metadata about any
    system action (healing, learning proposal, routing, code review, etc.).
    Feedback is persisted to .session/feedback.jsonl for pattern analysis.

    Usage:
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Rate 4 -Action healing -Comment "Fixed config but missed permission"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Action learning -Comment "Good proposal"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Status
#>

param(
    [ValidateRange(1,5)]
    [int]$Rate = 0,
    [ValidateSet('healing', 'learning', 'routing', 'code-review', 'digest', 'general')]
    [string]$Action = 'general',
    [string]$Comment = '',
    [string]$Context = '',
    [switch]$Status,
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

$feedbackDir = Join-Path (Join-Path $repoRoot '.session') 'feedback'
if (-not (Test-Path $feedbackDir)) { New-Item -ItemType Directory -Path $feedbackDir -Force | Out-Null }
$feedbackFile = Join-Path $feedbackDir 'feedback.jsonl'

function Write-Message  { param([string]$M) Write-Host $M -ForegroundColor Cyan }
function Write-Ok      { param([string]$M) Write-Host "[OK] $M" -ForegroundColor Green }
function Write-Warn    { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }

function Complete-Script {
    param([int]$ExitCode = 0)
    if ($NoExit) { return $ExitCode }
    exit $ExitCode
}

if ($Status) {
    if (-not (Test-Path $feedbackFile)) {
        Write-Message "No feedback records yet. Be the first!"
        Complete-Script 0
        return
    }
    $entries = Get-Content $feedbackFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '.' }
    $total = $entries.Count
    $rated = $entries | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction SilentlyContinue } | Where-Object { $_ -and $_.rate -gt 0 }
    $totalRated = $rated.Count
    $avg = if ($totalRated -gt 0) { [math]::Round(($rated | Measure-Object -Property rate -Average).Average, 1) } else { 0 }
    Write-Message "=== Feedback Status ==="
    Write-Ok "Total entries: $total"
    Write-Ok "Rated entries: $totalRated"
    if ($avg -gt 0) { Write-Ok "Average rating: $avg/5" }
    $byAction = $rated | Group-Object -Property action | Sort-Object Count -Descending
    foreach ($g in $byAction) {
        $gAvg = [math]::Round(($g.Group | Measure-Object -Property rate -Average).Average, 1)
        Write-Ok "  $($g.Name): $($g.Count) entries, avg $gAvg/5"
    }
    Complete-Script 0
    return
}

if ($Rate -eq 0 -and [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Warn "Provide at least -Rate (1-5) or -Comment to submit feedback"
    Write-Message "Usage: feedback-collector.ps1 -Rate 4 -Action healing -Comment 'text' [-Context 'scope']"
    Write-Message "       feedback-collector.ps1 -Status"
    Complete-Script 1
    return
}

$sessionFile = Join-Path (Join-Path $repoRoot '.session') 'session.json'
$sessionId = ''
if (Test-Path $sessionFile) {
    try { $sessionId = (Get-Content $sessionFile -Raw | ConvertFrom-Json).sessionId } catch { Write-Debug "Exception caught: <#
.SYNOPSIS
    Collects explicit user feedback on system decisions and actions.

.DESCRIPTION
    Captures user ratings (1-5), comments, and contextual metadata about any
    system action (healing, learning proposal, routing, code review, etc.).
    Feedback is persisted to .session/feedback.jsonl for pattern analysis.

    Usage:
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Rate 4 -Action healing -Comment "Fixed config but missed permission"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Action learning -Comment "Good proposal"
        pwsh ./scripts/utilities/FEEDBACK/feedback-collector.ps1 -Status
#>

param(
    [ValidateRange(1,5)]
    [int]$Rate = 0,
    [ValidateSet('healing', 'learning', 'routing', 'code-review', 'digest', 'general')]
    [string]$Action = 'general',
    [string]$Comment = '',
    [string]$Context = '',
    [switch]$Status,
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

$feedbackDir = Join-Path (Join-Path $repoRoot '.session') 'feedback'
if (-not (Test-Path $feedbackDir)) { New-Item -ItemType Directory -Path $feedbackDir -Force | Out-Null }
$feedbackFile = Join-Path $feedbackDir 'feedback.jsonl'

function Write-Message  { param([string]$M) Write-Host $M -ForegroundColor Cyan }
function Write-Ok      { param([string]$M) Write-Host "[OK] $M" -ForegroundColor Green }
function Write-Warn    { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }

function Complete-Script {
    param([int]$ExitCode = 0)
    if ($NoExit) { return $ExitCode }
    exit $ExitCode
}

if ($Status) {
    if (-not (Test-Path $feedbackFile)) {
        Write-Message "No feedback records yet. Be the first!"
        Complete-Script 0
        return
    }
    $entries = Get-Content $feedbackFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '.' }
    $total = $entries.Count
    $rated = $entries | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction SilentlyContinue } | Where-Object { $_ -and $_.rate -gt 0 }
    $totalRated = $rated.Count
    $avg = if ($totalRated -gt 0) { [math]::Round(($rated | Measure-Object -Property rate -Average).Average, 1) } else { 0 }
    Write-Message "=== Feedback Status ==="
    Write-Ok "Total entries: $total"
    Write-Ok "Rated entries: $totalRated"
    if ($avg -gt 0) { Write-Ok "Average rating: $avg/5" }
    $byAction = $rated | Group-Object -Property action | Sort-Object Count -Descending
    foreach ($g in $byAction) {
        $gAvg = [math]::Round(($g.Group | Measure-Object -Property rate -Average).Average, 1)
        Write-Ok "  $($g.Name): $($g.Count) entries, avg $gAvg/5"
    }
    Complete-Script 0
    return
}

if ($Rate -eq 0 -and [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Warn "Provide at least -Rate (1-5) or -Comment to submit feedback"
    Write-Message "Usage: feedback-collector.ps1 -Rate 4 -Action healing -Comment 'text' [-Context 'scope']"
    Write-Message "       feedback-collector.ps1 -Status"
    Complete-Script 1
    return
}

$sessionFile = Join-Path (Join-Path $repoRoot '.session') 'session.json'
$sessionId = ''
if (Test-Path $sessionFile) {
    try { $sessionId = (Get-Content $sessionFile -Raw | ConvertFrom-Json).sessionId } catch { $sessionId = '' }
}

$entry = @{
    timestamp  = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    sessionId  = $sessionId
    rate       = $Rate
    action     = $Action
    comment    = $Comment
    context    = $Context
    source     = 'feedback-collector'
}
$entry | ConvertTo-Json -Compress -Depth 3 | Out-File -FilePath $feedbackFile -Encoding UTF8 -Append -Force

if ($Rate -gt 0) {
    $stars = '★' * $Rate + '☆' * (5 - $Rate)
    Write-Ok "Feedback recorded: $stars ($Rate/5) for $Action"
} else {
    Write-Ok "Comment recorded for $Action"
}
if (-not [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Ok "  Comment: $Comment"
}

Complete-Script 0
" }
}

$entry = @{
    timestamp  = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    sessionId  = $sessionId
    rate       = $Rate
    action     = $Action
    comment    = $Comment
    context    = $Context
    source     = 'feedback-collector'
}
$entry | ConvertTo-Json -Compress -Depth 3 | Out-File -FilePath $feedbackFile -Encoding UTF8 -Append -Force

if ($Rate -gt 0) {
    $stars = '★' * $Rate + '☆' * (5 - $Rate)
    Write-Ok "Feedback recorded: $stars ($Rate/5) for $Action"
} else {
    Write-Ok "Comment recorded for $Action"
}
if (-not [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Ok "  Comment: $Comment"
}

Complete-Script 0

" }
}

$entry = @{
    timestamp  = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    sessionId  = $sessionId
    rate       = $Rate
    action     = $Action
    comment    = $Comment
    context    = $Context
    source     = 'feedback-collector'
}
$entry | ConvertTo-Json -Compress -Depth 3 | Out-File -FilePath $feedbackFile -Encoding UTF8 -Append -Force

if ($Rate -gt 0) {
    $stars = '★' * $Rate + '☆' * (5 - $Rate)
    Write-Ok "Feedback recorded: $stars ($Rate/5) for $Action"
} else {
    Write-Ok "Comment recorded for $Action"
}
if (-not [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Ok "  Comment: $Comment"
}

Complete-Script 0
" }
}

$entry = @{
    timestamp  = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    sessionId  = $sessionId
    rate       = $Rate
    action     = $Action
    comment    = $Comment
    context    = $Context
    source     = 'feedback-collector'
}
$entry | ConvertTo-Json -Compress -Depth 3 | Out-File -FilePath $feedbackFile -Encoding UTF8 -Append -Force

if ($Rate -gt 0) {
    $stars = '★' * $Rate + '☆' * (5 - $Rate)
    Write-Ok "Feedback recorded: $stars ($Rate/5) for $Action"
} else {
    Write-Ok "Comment recorded for $Action"
}
if (-not [string]::IsNullOrWhiteSpace($Comment)) {
    Write-Ok "  Comment: $Comment"
}

Complete-Script 0


