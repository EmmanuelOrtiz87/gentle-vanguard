# consolidate-metrics.ps1
# Consolidates metrics at end of day or on demand
# Part of Phase 2: Automatic consolidation

param(
    [ValidateSet("daily", "weekly", "monthly", "on-demand")]
    [string]$Period = "daily",
    [string]$ProjectRoot = "",
    [switch]$Silent,
    [switch]$GenerateReport
)

$ErrorActionPreference = 'Continue'

if (-not $ProjectRoot) {
    $ProjectRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) {
        $env:GV_BASE_DIR
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
}

$metricsDir = Join-Path $ProjectRoot "docs\sessions\metrics"
$telemetryDir = Join-Path $ProjectRoot ".telemetry"
$sessionDir = Join-Path $ProjectRoot "session"
$engineDir = Join-Path $ProjectRoot "scripts\utilities\TELEMETRY-METRICS"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Silent) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Get-CostEstimate {
    param([int]$Tokens)
    $costPer1M = 10.0
    return [math]::Round(($Tokens / 1000000) * $costPer1M, 4)
}

function Save-ConsolidatedMetrics {
    param($Sessions, [string]$Period, [string]$OutputFile)
    
    $dateRange = switch ($Period) {
        "daily" { (Get-Date).AddDays(-1).Date }
        "weekly" { (Get-Date).AddDays(-7).Date }
        "monthly" { (Get-Date).AddDays(-30).Date }
        "on-demand" { (Get-Date).Date.AddDays(-1) }
    }
    
    $metrics = @{
        generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        period = $Period
        dateRange = $dateRange.ToString("yyyy-MM-dd")
        summary = @{
            totalSessions = 0
            completedSessions = 0
            activeSessions = 0
            totalTokens = 0
            totalCostUsd = 0.0
            avgTokensPerSession = 0
        }
        sessionsByDay = @{}
        systemHealth = @{
            tokenGuard = "active"
            contextEfficiency = "active"
            distributedTracing = "active"
            autoDelegation = "active"
        }
    }
    
    foreach ($session in $Sessions) {
        $metrics.summary.totalSessions++
        if ($session.status -eq "completed") {
            $metrics.summary.completedSessions++
        } else {
            $metrics.summary.activeSessions++
        }
        
        $date = if ($session.startTime) { [DateTime]::Parse($session.startTime).ToString("yyyy-MM-dd") } else { "unknown" }
        if (-not $metrics.sessionsByDay.ContainsKey($date)) {
            $metrics.sessionsByDay[$date] = @{
                count = 0
                tokens = 0
                cost = 0
            }
        }
        $metrics.sessionsByDay[$date].count++
    }
    
    $metrics.summary.avgTokensPerSession = if ($metrics.summary.totalSessions -gt 0) {
        [math]::Round($metrics.summary.totalTokens / $metrics.summary.totalSessions, 0)
    } else { 0 }
    
    $metrics | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Log "Saved consolidated metrics: $OutputFile" "OK"
    
    return $metrics
}

function Save-TelemetryMaster {
    param($Sessions, [string]$OutputFile)
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    
    if (-not (Test-Path $OutputFile)) {
        "Timestamp,User_ID,Session_ID,Task_Scope,Tokens_Estimated,Judgment_Result,Review_Issues,Duration_Min,Efficiency_Score" | 
            Out-File -FilePath $OutputFile -Encoding UTF8
    }
    
    foreach ($session in $Sessions) {
        $userId = "workspace"
        $duration = if ($session.durationSeconds) { [math]::Round($session.durationSeconds / 60, 0) } else { 0 }
        $tokens = if ($session.metrics) { $session.metrics.totalTokens } else { 0 }
        $judgment = "PENDING"
        
        "$timestamp,$userId,$($session.sessionId),,$tokens,$judgment,0,$duration," | 
            Out-File -FilePath $OutputFile -Append -Encoding UTF8
    }
    
    Write-Log "Updated telemetry master: $OutputFile" "OK"
}

if (-not (Test-Path $metricsDir)) {
    New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
}

$periodStart = switch ($Period) {
    "daily" { (Get-Date).Date.AddDays(-1) }
    "weekly" { (Get-Date).Date.AddDays(-7) }
    "monthly" { (Get-Date).Date.AddDays(-30) }
    "on-demand" { (Get-Date).Date.AddDays(-1) }
}

$sessionFiles = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue
$sessions = @()

foreach ($file in $sessionFiles) {
    try {
        $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $startTime = if ($content.startTime) { [DateTime]::Parse($content.startTime) } else { [DateTime]::MinValue }
        
        if ($startTime -ge $periodStart) {
            $sessions += $content
        }
    } catch { }
}

Write-Log "Found $($sessions.Count) sessions for period: $Period"

$consolidatedFile = Join-Path $metricsDir "consolidated-$Period-$(Get-Date -Format 'yyyy-MM-dd').json"
$metrics = Save-ConsolidatedMetrics -Sessions $sessions -Period $Period -OutputFile $consolidatedFile

$telemetryMaster = Join-Path $ProjectRoot "docs\management\telemetry-master.csv"
Save-TelemetryMaster -Sessions $sessions -OutputFile $telemetryMaster

# Refresh dashboard with consolidated data
$dashboardScript = Join-Path $engineDir "generate-dashboard.ps1"
if (Test-Path $dashboardScript) {
    Write-Log "Refreshing dashboard..." "INFO"
    & $dashboardScript
}

if ($GenerateReport) {
    $reportScript = Join-Path $ProjectRoot "scripts\utilities\generate-executive-summary.ps1"
    if (Test-Path $reportScript) {
        Write-Log "Generating report..." "INFO"
        & $reportScript -Period $Period
    }
}

Write-Host ""
Write-Host "=== Consolidation Summary ===" -ForegroundColor Cyan
Write-Host "Period: $Period" -ForegroundColor White
Write-Host "Sessions: $($metrics.summary.totalSessions)" -ForegroundColor White
Write-Host "  Active: $($metrics.summary.activeSessions)" -ForegroundColor Yellow
Write-Host "  Completed: $($metrics.summary.completedSessions)" -ForegroundColor Green

exit 0
