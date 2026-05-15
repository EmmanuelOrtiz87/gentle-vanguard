# start-session.ps1 - Initialize a new session with Engram integration
# Part of Foundation Workflow CLI

param(
    [string]$TaskName = '',
    [string]$SessionId = '',
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

function Resolve-CurrentSessionContext {
    param([string]$RepoRoot)

    $logsActivePath = Join-Path $RepoRoot 'logs\.session-active'
    if (Test-Path $logsActivePath) {
        try {
            $activeData = Get-Content -Path $logsActivePath -Raw | ConvertFrom-Json
            if ($activeData.SessionId) {
                return [pscustomobject]@{
                    SessionId = [string]$activeData.SessionId
                    StartTime = if ($activeData.StartTime) { [string]$activeData.StartTime } else { (Get-Date -Format 'o') }
                }
            }
        }
        catch {
        }
    }

    $sessionDir = Join-Path $RepoRoot 'session'
    if (Test-Path $sessionDir) {
        $latestSession = Get-ChildItem -Path $sessionDir -Filter 'session-*.json' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($latestSession) {
            try {
                $sessionData = Get-Content -Path $latestSession.FullName -Raw | ConvertFrom-Json
                if ($sessionData.sessionId -and $sessionData.status -eq 'active') {
                    return [pscustomobject]@{
                        SessionId = [string]$sessionData.sessionId
                        StartTime = if ($sessionData.startTime) { [string]$sessionData.startTime } else { (Get-Date -Format 'o') }
                    }
                }
            }
            catch {
            }
        }
    }

    return $null
}

$resolvedSessionContext = $null
if (-not [string]::IsNullOrWhiteSpace($SessionId)) {
    $resolvedSessionContext = [pscustomobject]@{
        SessionId = $SessionId
        StartTime = Get-Date -Format 'o'
    }
} elseif (-not $Force) {
    $envSessionId = @($env:FOUNDATION_SESSION_ID, $env:WFS_SESSION_ID, $env:SESSION_ID) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 1

    if ($envSessionId) {
        $resolvedSessionContext = [pscustomobject]@{
            SessionId = [string]$envSessionId
            StartTime = Get-Date -Format 'o'
        }
    } else {
        $resolvedSessionContext = Resolve-CurrentSessionContext -RepoRoot $repoRoot
    }
}

if ($null -eq $resolvedSessionContext) {
    $sessionDate = Get-Date -Format 'yyyy-MM-dd'
    $sessionTime = Get-Date -Format 'HHmmss'
    $resolvedSessionContext = [pscustomobject]@{
        SessionId = "session-$sessionDate-$sessionTime"
        StartTime = Get-Date -Format 'o'
    }
}

$sessionId = $resolvedSessionContext.SessionId
$startTime = $resolvedSessionContext.StartTime

# Create session brief
$sessionBrief = @{
    SessionId = $sessionId
    StartTime = $startTime
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
    StartTime = $startTime
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