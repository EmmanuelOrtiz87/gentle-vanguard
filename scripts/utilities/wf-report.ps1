# wf-report.ps1
# Unified reporting CLI - on-demand reports for management and analysis

param(
    [ValidateSet("sessions", "costs", "performance", "executive", "tokens", "telemetry", "all", "clarify")]
    [string]$Type = "clarify",
    [ValidateSet("today", "yesterday", "7days", "30days", "all")]
    [string]$Period = "7days",
    [ValidateSet("markdown", "json", "console")]
    [string]$Format = "markdown",
    [string]$ProjectRoot = "C:\Workspace_local\workspace-foundation"
)

$ErrorActionPreference = 'Continue'

function Get-ProjectRoot {
    $scriptRoot = $PSScriptRoot
    if ($scriptRoot -match 'scripts[\\]utilities$') {
        return "C:\Workspace_local\workspace-foundation"
    }
    return $scriptRoot
}

$ProjectRoot = Get-ProjectRoot

function Show-Clarification {
    Write-Host ""
    Write-Host "=== Report Types Available ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ./wf report sessions    - Session summary" -ForegroundColor Gray
    Write-Host "  ./wf report costs       - Cost analysis" -ForegroundColor Gray
    Write-Host "  ./wf report tokens     - Token metrics" -ForegroundColor Gray
    Write-Host "  ./wf report performance - Performance metrics" -ForegroundColor Gray
    Write-Host "  ./wf report executive  - Executive summary" -ForegroundColor Gray
    Write-Host "  ./wf report telemetry - System telemetry" -ForegroundColor Gray
    Write-Host "  ./wf report all        - Complete report" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=== Periods ===" -ForegroundColor White
    Write-Host "  -Period today     - Today only" -ForegroundColor Gray
    Write-Host "  -Period yesterday - Yesterday" -ForegroundColor Gray
    Write-Host "  -Period 7days    - Last 7 days" -ForegroundColor Gray
    Write-Host "  -Period 30days   - Last 30 days" -ForegroundColor Gray
    Write-Host "  -Period all      - All time" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=== Examples ===" -ForegroundColor White
    Write-Host "  ./wf report sessions -Period yesterday" -ForegroundColor Gray
    Write-Host "  ./wf report costs -Period 7days -Format json" -ForegroundColor Gray
    Write-Host "  ./wf report executive" -ForegroundColor Gray
}

function Get-SessionsReport {
    param([string]$Period)
    
    $sessionDir = Join-Path $ProjectRoot ".session"
    $periodStart = switch ($Period) {
        "today" { (Get-Date).Date }
        "yesterday" { (Get-Date).Date.AddDays(-1) }
        "7days" { (Get-Date).Date.AddDays(-7) }
        "30days" { (Get-Date).Date.AddDays(-30) }
        "all" { [DateTime]::MinValue }
    }
    
    Write-Host "Looking in: $sessionDir" -ForegroundColor Gray
    Write-Host "Period start: $periodStart" -ForegroundColor Gray
    
    $sessionFiles = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue
    Write-Host "Files found: $($sessionFiles.Count)" -ForegroundColor Gray
    
    $sessions = @()
    
    foreach ($file in $sessionFiles) {
        try {
            $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
            
            $startTime = [DateTime]::MinValue
            if ($content.startTime) {
                $startTime = [DateTime]::Parse($content.startTime)
            }
            
            Write-Host "  - $($content.sessionId): $startTime (>= $periodStart = $($startTime -ge $periodStart))" -ForegroundColor Gray
            
            if ($startTime -ge $periodStart) {
                $sessions += $content
            }
        } catch { 
            Write-Host "  Error: $($file.Name)" -ForegroundColor Red
        }
    }
    
    $byDay = $sessions | Group-Object { 
        if ($_.startTime) { [DateTime]::Parse($_.startTime).ToString("yyyy-MM-dd") } else { "unknown" }
    } | Sort-Object Name
    
    Write-Host ""
    Write-Host "=== Sessions Report ===" -ForegroundColor Cyan
    Write-Host "Period: $Period" -ForegroundColor White
    Write-Host "Total: $($sessions.Count) sessions" -ForegroundColor White
    foreach ($day in $byDay) {
        Write-Host "  $($day.Name): $($day.Count) sessions" -ForegroundColor Gray
    }
}

function Get-CostsReport {
    param([string]$Period)
    
    Write-Host ""
    Write-Host "=== Costs Report ===" -ForegroundColor Cyan
    Write-Host "Period: $Period" -ForegroundColor White
    Write-Host "Total Tokens: (not captured yet)" -ForegroundColor Yellow
    Write-Host "Est Cost: (not captured yet)" -ForegroundColor Yellow
    Write-Host "(Run consolidation to capture metrics)" -ForegroundColor Gray
}

function Get-ExecutiveReport {
    param([string]$Period)
    
    $script = Join-Path $ProjectRoot "scripts\utilities\generate-executive-summary.ps1"
    if (Test-Path $script) {
        & $script -Period $Period
    } else {
        Write-Host "Executive summary script not found" -ForegroundColor Yellow
    }
}

function Get-AllReport {
    param([string]$Period)
    
    Write-Host ""
    Write-Host "=== Complete Report ===" -ForegroundColor Cyan
    Write-Host "Period: $Period" -ForegroundColor White
    Write-Host ""
    Get-SessionsReport -Period $Period
    Write-Host ""
    Get-CostsReport -Period $Period
}

switch ($Type) {
    "clarify" { Show-Clarification }
    "sessions" { Get-SessionsReport -Period $Period }
    "costs" { Get-CostsReport -Period $Period }
    "tokens" { Get-SessionsReport -Period $Period }
    "performance" { Get-SessionsReport -Period $Period }
    "executive" { Get-ExecutiveReport -Period $Period }
    "telemetry" { Get-SessionsReport -Period $Period }
    "all" { Get-AllReport -Period $Period }
}

exit 0