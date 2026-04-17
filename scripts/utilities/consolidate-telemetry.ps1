# consolidate-telemetry.ps1
# Consolidates local session telemetry into the management master file.
# Usage: .\consolidate-telemetry.ps1 [-UserId <name>]

param(
    [string]$UserId
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$masterFile = Join-Path $repoRoot 'docs\management\telemetry-master.csv'
$sessionsDir = Join-Path $repoRoot 'docs\sessions'
$judgmentDir = Join-Path $repoRoot 'docs\judgment'

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }

# 1. Identify User
if ([string]::IsNullOrWhiteSpace($UserId)) {
    $UserId = git -C $repoRoot config user.name 2>$null
    if ([string]::IsNullOrWhiteSpace($UserId)) { $UserId = 'unknown' }
}
Write-Step "Consolidating telemetry for User: $UserId"

# 2. Ensure Master File Exists
if (-not (Test-Path $masterFile)) {
    New-Item -ItemType Directory -Path (Split-Path $masterFile) -Force | Out-Null
    "Timestamp,User_ID,Session_ID,Task_Scope,Tokens_Estimated,Judgment_Result,Review_Issues,Duration_Min,Efficiency_Score" | Out-File -FilePath $masterFile -Encoding UTF8BOM
}

# 3. Process Latest Session (Simplified for Demo)
# In production, this would iterate through unprocessed sessions
$latestSession = Get-ChildItem $sessionsDir -Filter "*-session-start.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$latestJudgment = Get-ChildItem $judgmentDir -Filter "dashboard.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($latestSession) {
    $sessionId = $latestSession.BaseName.Replace('-session-start', '')
    $taskScope = "General Session" # Could be parsed from file content
    
    # Mock Data for Demonstration (In production, parse actual logs)
    $tokens = 15000
    $judgmentRes = "PASS"
    $issues = 0
    $duration = 45
    $efficiency = "High"

    $csvLine = "$((Get-Date).ToString('o')),$UserId,$sessionId,$taskScope,$tokens,$judgmentRes,$issues,$duration,$efficiency"
    $csvLine | Add-Content -Path $masterFile -Encoding UTF8
    Write-Ok "Telemetry entry added for session $sessionId"
} else {
    Write-Host "[INFO] No recent sessions found to consolidate." -ForegroundColor Yellow
}

Write-Ok "Telemetry consolidation complete. Check $masterFile"
