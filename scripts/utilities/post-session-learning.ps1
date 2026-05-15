<#
.SYNOPSIS
    Post-session learning analysis — detects patterns, identifies gaps, proposes improvements.

.DESCRIPTION
    Analyzes session artifacts (startup-summary, engram summary, git log) to identify:
    - Missing skills (user requests not covered)
    - Repeated errors / token waste
    - Configuration gaps
    - Pattern opportunities (repetitive manual steps)
    Generates structured improvement proposals and saves for review.

    Usage:
        pwsh ./scripts/utilities/post-session-learning.ps1
        pwsh ./scripts/utilities/post-session-learning.ps1 -SessionId "session-2026-05-14-02"
        pwsh ./scripts/utilities/post-session-learning.ps1 -AutoApplyLow
#>

param(
    [string]$SessionId = '',
    [switch]$AutoApplyLow,
    [string]$ProjectName = 'foundation',
    [switch]$NoExit
)

$ErrorActionPreference = 'Continue'
$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$proposalsDir = Join-Path (Join-Path $repoRoot '.local') 'improvement-proposals'
$logFile = Join-Path $proposalsDir 'learning-log.jsonl'
$summaryFile = Join-Path (Join-Path (Join-Path $repoRoot 'scripts') '.session') 'startup-summary.json'

# Ensure directories
if (-not (Test-Path $proposalsDir)) { New-Item -ItemType Directory -Path $proposalsDir -Force | Out-Null }

function Write-Step { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Hit  { param([string]$Message) Write-Host "[HIT] $Message" -ForegroundColor Magenta }

function Complete-Script {
    param([int]$ExitCode = 0)

    if ($NoExit) {
        return $ExitCode
    }

    exit $ExitCode
}

function Get-EngramBinary {
    $candidatePaths = @(
        (Join-Path $repoRoot 'tools\engram.exe'),
        (Join-Path ($env:USERPROFILE ? $env:USERPROFILE : $env:HOME) 'bin\engram.exe'),
        (Join-Path ($env:GOPATH ? $env:GOPATH : (Join-Path $env:USERPROFILE 'go')) 'bin\engram.exe')
    )

    foreach ($candidate in $candidatePaths) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd) {
        return $engramCmd.Source
    }

    return $null
}

function Save-ToEngram {
    param(
        [string]$Title,
        [string]$Content,
        [string]$Type = 'learning'
    )

    $engramBin = Get-EngramBinary
    if (-not $engramBin) {
        Write-Info "Engram not available, skipping knowledge-base save"
        return $false
    }

    $result = & $engramBin save $Title $Content --project foundation --type $Type 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Saved to Engram: $Title"
        return $true
    }

    Write-Warn "Engram save skipped: $($result | Out-String)"
    return $false
}

# --- Phase 1: Collect session data ---
Write-Step "Phase 1: Collecting session data"

$sessionData = @{
    timestamp   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    sessionId   = $SessionId
    platform    = 'unknown'
    tool        = 'unknown'
    workspaceClean = $false
    gitLog      = @()
    changes     = @()
    summary     = $null
}

# Read startup-summary.json
if (Test-Path $summaryFile) {
    try {
        $s = Get-Content $summaryFile -Raw | ConvertFrom-Json
        $sessionData.platform = $s.platform
        $sessionData.tool = $s.tool
        $sessionData.workspaceClean = $s.workspaceClean
        if (-not $SessionId -and $s.sessionId) { $sessionData.sessionId = $s.sessionId }
        Write-Ok "Startup summary: $($s.tool) on $($s.platform), peak=$($s.isPeakHour)"
    } catch { Write-Warn "Could not read startup-summary.json: $_" }
} else { Write-Info "No startup-summary.json found (fresh workspace)" }

# Get recent git log for this session
$sinceDate = (Get-Date).AddHours(-12).ToString('yyyy-MM-ddTHH:mm:ss')
try {
    $gitLog = git -C $repoRoot log --oneline --since=$sinceDate 2>$null
    if ($gitLog) {
        $sessionData.gitLog = @($gitLog)
        Write-Ok "Git log: $($gitLog.Count) commits since $sinceDate"
    } else {
        Write-Info "No commits in the last 12 hours"
    }
} catch { Write-Warn "Git log failed: $_" }

# Get changed files (git diff from last 5 commits)
try {
    $changes = git -C $repoRoot diff --name-only HEAD~5..HEAD 2>$null
    if ($changes) {
        $sessionData.changes = @($changes)
        Write-Ok "Files changed in last 5 commits: $($changes.Count)"
    }
} catch { $sessionData.changes = @() }

# --- Phase 2: Analyze for gaps ---
Write-Step "Phase 2: Analyzing for gaps"

$proposals = @()
$runId = "learn-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
$ts = (Get-Date -Format 'yyyy-MM-dd')

# Check 1: Missing skills detection
Write-Step "Check 1: Missing skills detection"
$knownSkills = @()
$skillsIndex = Join-Path (Join-Path $repoRoot 'skills') 'SKILL_INDEX.md'
if (Test-Path $skillsIndex) {
    $content = Get-Content $skillsIndex -Raw
    $skillMatches = [regex]::Matches($content, '(?<=`)[^`]+(?=`)')
    $knownSkills = @($skillMatches.Value | Where-Object { $_ -like '*skill*' })
}
Write-Ok "Known skills: $($knownSkills.Count)"

# Check 2: Pattern detection from git log
Write-Step "Check 2: Pattern detection"
$patterns = @{
    featCount   = 0
    fixCount    = 0
    docsCount   = 0
    testCount   = 0
    choreCount  = 0
    refactorCount = 0
}
foreach ($commit in $sessionData.gitLog) {
    if ($commit -match '^feat')  { $patterns.featCount++ }
    if ($commit -match '^fix')   { $patterns.fixCount++ }
    if ($commit -match '^docs')  { $patterns.docsCount++ }
    if ($commit -match '^test')  { $patterns.testCount++ }
    if ($commit -match '^chore') { $patterns.choreCount++ }
    if ($commit -match '^refactor') { $patterns.refactorCount++ }
}
$totalCommits = $sessionData.gitLog.Count
Write-Ok "Commit patterns: $totalCommits total (feat=$($patterns.featCount), fix=$($patterns.fixCount), docs=$($patterns.docsCount), test=$($patterns.testCount))"

# Check 3: Business skills gap — do we have real skills or just stubs?
Write-Step "Check 3: Business skills audit"
$businessSkillsRoot = Join-Path (Join-Path $repoRoot 'skills') 'business'
$businessListPath = Join-Path $businessSkillsRoot 'SKILL.md'
$businessDomains = @()
if (Test-Path $businessListPath) {
    $bizContent = Get-Content $businessListPath -Raw
    $domainMatches = [regex]::Matches($bizContent, '(?<=\*\*)[a-z-]+(?=\*\*)')
    $businessDomains = @($domainMatches.Value)
}
$existingBusinessDirs = @(Get-ChildItem -Directory $businessSkillsRoot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$stubDomains = $businessDomains | Where-Object { $_ -notin $existingBusinessDirs }
if ($stubDomains.Count -gt 0) {
    Write-Hit "Business domains without skill dirs: $($stubDomains -join ', ')"
    $severity = "medium"
    $autoApply = $AutoApplyLow -and ($severity -in @('low', 'medium'))
    $idx = 0
    foreach ($stubDomain in $stubDomains) {
        $idx++
        $proposals += @{
            id = "prop-$ts-$( '{0:D3}' -f $idx )"
            date = $ts
            category = "missing-skill"
            severity = $severity
            description = "Stub business domain needs real skill: $stubDomain"
            domain = $stubDomain
            evidence = "skills/business/SKILL.md lists $stubDomain but no directory exists"
            proposedAction = "Create SKILL.md for $stubDomain domain"
            autoApply = $autoApply
            applied = $false
        }
    }
} else {
    Write-Ok "All $($businessDomains.Count) business domains have skill directories"
}

# Check 4: Improvement proposals backlog
Write-Step "Check 4: Previous proposals audit"
$existingProposals = @(Get-ChildItem -Path $proposalsDir -Filter '*.json' -ErrorAction SilentlyContinue)
$pendingProposals = @($existingProposals | ForEach-Object {
    $p = Get-Content $_.FullName -Raw | ConvertFrom-Json
    if (-not $p.applied) { $_ }
})
if ($pendingProposals.Count -gt 0) {
    Write-Info "Pending proposals from previous sessions: $($pendingProposals.Count)"
} else {
    Write-Ok "No pending proposals"
}

# --- Phase 3: Generate report ---
Write-Step "Phase 3: Learning report"

$report = @{
    runId       = $runId
    timestamp   = $sessionData.timestamp
    sessionId   = $sessionData.sessionId
    platform    = $sessionData.platform
    tool        = $sessionData.tool
    commitCount = $totalCommits
    patterns    = $patterns
    proposals   = $proposals
    summary     = if ($totalCommits -gt 0) { "Session with $totalCommits commits on $($sessionData.platform)" } else { "Analysis session, no commits" }
}

# Print report
Write-Host "`n--- Learning Report ---" -ForegroundColor Green
Write-Host "Session: $($report.sessionId)" -ForegroundColor Gray
Write-Host "Platform: $($report.platform)" -ForegroundColor Gray
Write-Host "Commits: $($report.commitCount)" -ForegroundColor Gray
Write-Host "Proposals: $($report.proposals.Count)" -ForegroundColor Gray

if ($report.proposals.Count -gt 0) {
    Write-Host "`nProposals:" -ForegroundColor Yellow
    foreach ($p in $report.proposals) {
        Write-Host "  [$($p.severity)] $($p.category): $($p.description)" -ForegroundColor Magenta
        Write-Host "         -> $($p.proposedAction)" -ForegroundColor Gray
    }
} else {
    Write-Ok "No improvement gaps detected"
}

# Save proposals
foreach ($p in $proposals) {
    $propFile = Join-Path $proposalsDir "$($p.id).json"
    $p | ConvertTo-Json -Depth 3 | Out-File -FilePath $propFile -Encoding UTF8 -Force
    Write-Info "Saved proposal: $propFile"
}

# Append to learning-log.jsonl
$logEntry = @{
    runId     = $runId
    timestamp = $sessionData.timestamp
    sessionId = $sessionData.sessionId
    proposals = $proposals.Count
    commits   = $totalCommits
    patterns  = $patterns
}
$logEntry | ConvertTo-Json -Depth 3 -Compress | Out-File -FilePath $logFile -Encoding UTF8 -Append -Force

Write-Ok "Learning log appended to $logFile"
if ($report.proposals.Count -gt 0) {
    $proposalSummary = ($report.proposals | ForEach-Object { "[$($_.severity)] $($_.description) => $($_.proposedAction)" }) -join " | "
    $proposalContent = if ($report.sessionId) { "SessionId=$($report.sessionId) | $proposalSummary" } else { $proposalSummary }
    $null = Save-ToEngram -Title "Learning proposals: $($report.runId)" -Content $proposalContent -Type 'proposal'
} else {
    $summaryContent = if ($report.sessionId) { "SessionId=$($report.sessionId) | $($report.summary)" } else { $report.summary }
    $null = Save-ToEngram -Title "Learning summary: $($report.runId)" -Content $summaryContent -Type 'learning'
}
Write-Ok "Post-session learning complete!"

if ($proposals.Count -gt 0) {
    Write-Host "`n[HINT] Review proposals in: $proposalsDir" -ForegroundColor Yellow
    Write-Host "[HINT] Run 'foundation learning apply' to auto-execute pending proposals" -ForegroundColor Yellow
    Write-Host "[HINT] Run 'foundation learning auto' to analyze + auto-apply low-severity" -ForegroundColor Yellow
    Complete-Script -ExitCode 1
    return
}
Complete-Script -ExitCode 0
