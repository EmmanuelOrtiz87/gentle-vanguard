# start-session.ps1 - Initialize a new session with Engram integration
# Part of Foundation Workflow CLI

param(
    [string]$TaskName = '',
    [switch]$Force
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path (Join-Path $scriptDir '..') '..') '..')).Path } else { Get-Location }

# Ensure logs directory exists
$logsDir = Join-Path $repoRoot 'logs'
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Generate session ID
$sessionDate = Get-Date -Format 'yyyy-MM-dd'
$sessionTime = Get-Date -Format 'HHmmss'
$sessionId = "session-$sessionDate-$sessionTime"

# Create session brief
$sessionBrief = @{
    SessionId = $sessionId
    StartTime = Get-Date -Format 'o'
    TaskName = $TaskName
    Repository = $repoRoot
    Branch = (git rev-parse --abbrev-ref HEAD 2>$null) -or 'unknown'
    Status = 'ACTIVE'
}

# Save session brief
$sessionBriefPath = Join-Path $logsDir "$sessionId.json"
$sessionBrief | ConvertTo-Json | Set-Content -Path $sessionBriefPath -Force

# Mark session as active
$activeSessionPath = Join-Path $logsDir '.session-active'
@{
    SessionId = $sessionId
    StartTime = Get-Date -Format 'o'
    TaskName = $TaskName
} | ConvertTo-Json | Set-Content -Path $activeSessionPath -Force

Write-Host "`n=== Session Started ===" -ForegroundColor Green
Write-Host "Session ID: $sessionId" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
if ($TaskName) {
    Write-Host "Task: $TaskName" -ForegroundColor Cyan
}
Write-Host "Repository: $repoRoot" -ForegroundColor Cyan
Write-Host "`nSession brief saved to: $sessionBriefPath" -ForegroundColor Gray
Write-Host "Use 'end-session' to close this session." -ForegroundColor Gray
Write-Host ""

exit 0