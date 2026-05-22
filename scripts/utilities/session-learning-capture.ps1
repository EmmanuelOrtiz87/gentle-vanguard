# session-learning-capture.ps1
# Autonomous learning capture — runs at session close and on-demand
# Scans session artifacts for patterns, failures, and decisions to save as Engram lessons

param(
    [string]$WorkspaceRoot = "",
    [string]$SessionId = "",
    [ValidateSet("auto", "manual", "close")]
    [string]$Trigger = "auto",
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        Get-Location
    }
    $root = Split-Path -Parent $scriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) {
        $root = Split-Path -Parent $root
    }
    if (-not $root) { $root = $scriptRoot }
    $root
}

if (-not $WorkspaceRoot) { $WorkspaceRoot = $repoRoot }
if (-not $SessionId) { $SessionId = "session-$(Get-Date -Format 'yyyy-MM-dd-HH')" }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Silent) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "Cyan" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

$lessonsFound = 0
$lessonsSaved = 0

$sessionDir = Join-Path $WorkspaceRoot ".session"
$sessionFile = Join-Path $sessionDir "current-session.json"
$metricsFile = Join-Path $sessionDir "metrics\current-session.json"

Write-Log "Session Learning Capture (trigger: $Trigger, session: $SessionId)"

$gitStatus = & git -C $WorkspaceRoot status --porcelain 2>&1
$changedFiles = @($gitStatus | Where-Object { $_ -and $_.Trim() })
if ($changedFiles.Count -gt 0) {
    Write-Log "Detected $($changedFiles.Count) changed files in workspace" "OK"
}

$recentCommits = & git -C $WorkspaceRoot log --oneline -5 2>&1
if ($recentCommits) {
    Write-Log "Recent commits:" "INFO"
    foreach ($line in $recentCommits) {
        Write-Log "  $line" "INFO"
    }
}

$failurePatterns = @(
    @{ Pattern = 'FAIL|ERROR|CRITICAL|ABORT'; Type = "bugfix"; Title = "Failure detected in session" }
    @{ Pattern = 'fix|bugfix|hotfix|patch'; Type = "bugfix"; Title = "Bug fix committed" }
    @{ Pattern = 'refactor|restructure|migrate'; Type = "architecture"; Title = "Refactoring performed" }
    @{ Pattern = 'feat|feature|add|implement'; Type = "pattern"; Title = "New feature implemented" }
    @{ Pattern = 'config|setting|orchestrator|routing'; Type = "config"; Title = "Configuration changed" }
)

foreach ($commit in $recentCommits) {
    foreach ($fp in $failurePatterns) {
        if ($commit -match $fp.Pattern) {
            $lessonsFound++
            Write-Log "Lesson candidate: $($fp.Title) — $($commit.Trim())" "WARN"
            break
        }
    }
}

$logsDir = Join-Path $WorkspaceRoot "logs"
if (Test-Path $logsDir) {
    $recentLogs = Get-ChildItem -Path $logsDir -Filter "*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 3

    foreach ($log in $recentLogs) {
        try {
            $content = Get-Content $log.FullName -Tail 50 -ErrorAction SilentlyContinue
            $errors = $content | Where-Object { $_ -match 'ERROR|FAIL|CRITICAL|exception' }
            if ($errors) {
                $lessonsFound++
                Write-Log "Errors found in $($log.Name): $($errors.Count) error lines" "WARN"
            }
        } catch { Write-Warning "Failed to read log entries from $($log.Name): $_" }
    }
}

$sessionMetrics = $null
if (Test-Path $metricsFile) {
    try {
        $sessionMetrics = Get-Content $metricsFile -Raw | ConvertFrom-Json
        Write-Log "Session metrics loaded: $($sessionMetrics.metrics.toolCalls) tool calls, $($sessionMetrics.metrics.filesEdited) files edited" "OK"
    } catch { Write-Warning "Failed to parse session metrics: $_" }
}

$learningFile = Join-Path $sessionDir "learning-capture.json"
$learningData = @{
    sessionId = $SessionId
    trigger = $Trigger
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    changedFiles = $changedFiles.Count
    lessonsFound = $lessonsFound
    lessonsSaved = $lessonsSaved
    recentCommits = @($recentCommits | Where-Object { $_ })
    metrics = if ($sessionMetrics) { $sessionMetrics.metrics } else { $null }
}

$learningData | ConvertTo-Json -Depth 4 | Out-File -FilePath $learningFile -Encoding UTF8

Write-Log "Learning capture complete: $lessonsFound candidates found, $lessonsSaved saved to Engram" "OK"
Write-Log "Saved capture data to: $learningFile" "OK"

if ($Trigger -eq "close" -and $lessonsFound -gt 0) {
    Write-Log "REMINDER: Review session lessons and save significant ones to Engram via mem_save" "WARN"
}

exit 0