<#
.SYNOPSIS
    Token Monitor - Real-time token consumption display
    
.DESCRIPTION
    Displays real-time token usage metrics in a clean, organized dashboard format.
    No files are generated - output is displayed directly to the console.
    
.PARAMETER RefreshInterval
    Refresh interval in seconds (default: 3)
    
.PARAMETER Continuous
    Run continuously, refreshing at the specified interval
    
.PARAMETER SessionId
    Specific session ID to monitor (default: auto-detect latest)
    
.EXAMPLE
    .\tools\token-monitor.ps1
    Shows current token usage once
    
.EXAMPLE
    .\tools\token-monitor.ps1 -Continuous -RefreshInterval 5
    Continuously monitors tokens, refreshing every 5 seconds
    
.NOTES
    Author: gentleman-programming
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$RefreshInterval = 3,
    
    [Parameter(Mandatory=$false)]
    [switch]$Continuous,
    
    [Parameter(Mandatory=$false)]
    [string]$SessionId = ""
)

$ErrorActionPreference = 'Continue'
$sessionDir = '.\.session'

# Funcin para obtener datos de Engram
function Get-EngramTokenData {
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
    
    if (-not (Test-Path $engramBin)) {
        return $null
    }
    
    try {
        $result = & $engramBin context --project "gentleman-foundation" 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        return $result
    } catch {
        return $null
    }
}

# Funcin para leer estado de token-guard
function Get-TokenGuardData {
    $stateFile = Join-Path $sessionDir "token-guard-state.json"
    
    if (-not (Test-Path $stateFile)) {
        return $null
    }
    
    try {
        $data = Get-Content $stateFile | ConvertFrom-Json
        return $data
    } catch {
        return $null
    }
}

# Funcin para detectar sesin actual
function Get-CurrentSession {
    param([string]$ProvidedSessionId)
    
    if ($ProvidedSessionId -ne "") {
        return $ProvidedSessionId
    }
    
    $sessionFiles = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                    Sort-Object -Property LastWriteTime -Descending
    
    if ($sessionFiles.Count -eq 0) {
        return $null
    }
    
    $latestSession = $sessionFiles | Select-Object -First 1
    $sessionData = Get-Content -Path $latestSession.FullName | ConvertFrom-Json
    return $sessionData.sessionId
}

# Funcin para obtener mtricas de sesin
function Get-SessionMetrics {
    param([string]$SessionId)
    
    $metricsDir = Join-Path $sessionDir "metrics"
    if (-not (Test-Path $metricsDir)) {
        return $null
    }
    
    $metricsFile = Get-ChildItem -Path $metricsDir -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                   Sort-Object -Property LastWriteTime -Descending | 
                   Select-Object -First 1
    
    if ($null -eq $metricsFile) {
        return $null
    }
    
    try {
        return Get-Content -Path $metricsFile.FullName | ConvertFrom-Json
    } catch {
        return $null
    }
}

# Funcin para mostrar el dashboard
function Show-TokenDashboard {
    param(
        [string]$SessionId,
        [hashtable]$TokenGuardData,
        [hashtable]$SessionMetrics,
        [hashtable]$EngramData
    )
    
    Clear-Host
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Header
    Write-Host "" -ForegroundColor Cyan
    Write-Host "              TOKEN MONITOR - REAL-TIME DASHBOARD               " -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Last Update: $timestamp" -ForegroundColor Gray
    Write-Host "  Session ID:  $SessionId" -ForegroundColor Gray
    Write-Host ""
    
    # Token Budget Section
    Write-Host "" -ForegroundColor Green
    Write-Host " TOKEN BUDGET & CONSUMPTION                                  " -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    
    $budget = 128000  # Default
    $used = 0
    $alertThreshold = 0.80
    $pauseThreshold = 0.95
    
    if ($TokenGuardData) {
        $budget = if ($TokenGuardData.budget) { $TokenGuardData.budget } else { 128000 }
        $used = if ($TokenGuardData.totalTokensUsed) { $TokenGuardData.totalTokensUsed } else { 0 }
        $alertThreshold = if ($TokenGuardData.alertThreshold) { $TokenGuardData.alertThreshold } else { 0.80 }
        $pauseThreshold = if ($TokenGuardData.pauseThreshold) { $TokenGuardData.pauseThreshold } else { 0.95 }
    } elseif ($SessionMetrics) {
        $used = if ($SessionMetrics.totalTokens) { $SessionMetrics.totalTokens } else { 0 }
    }
    
    $remaining = $budget - $used
    $percentUsed = if ($budget -gt 0) { [math]::Round(($used / $budget) * 100, 2) } else { 0 }
    $percentRemaining = 100 - $percentUsed
    
    # Color based on usage
    $percentColor = "Green"
    if ($percentUsed -ge ($pauseThreshold * 100)) {
        $percentColor = "Red"
    } elseif ($percentUsed -ge ($alertThreshold * 100)) {
        $percentColor = "Yellow"
    }
    
    Write-Host "  Budget:        $budget tokens" -ForegroundColor White
    Write-Host "  Used:          $used tokens" -ForegroundColor $percentColor
    Write-Host "  Remaining:     $remaining tokens" -ForegroundColor Cyan
    Write-Host "  Usage:         " -NoNewline -ForegroundColor Gray
    Write-Host "$percentUsed%" -ForegroundColor $percentColor
    Write-Host "  Available:     " -NoNewline -ForegroundColor Gray
    Write-Host "$percentRemaining%" -ForegroundColor Green
    
    # Progress bar
    $barWidth = 50
    $filled = [math]::Round(($percentUsed / 100) * $barWidth)
    $empty = $barWidth - $filled
    $bar = "[" + ("" * $filled) + ("" * $empty) + "]"
    Write-Host "  $bar" -ForegroundColor $percentColor
    Write-Host ""
    
    # Session Status Section
    Write-Host "" -ForegroundColor Magenta
    Write-Host " SESSION STATUS                                            " -ForegroundColor Magenta
    Write-Host "" -ForegroundColor Magenta
    
    $status = "UNKNOWN"
    $statusColor = "Gray"
    $roundsCompleted = 0
    $currentRound = 1
    $alertsTriggered = 0
    $dispatchPaused = $false
    
    if ($TokenGuardData) {
        $status = if ($TokenGuardData.status) { $TokenGuardData.status } else { "UNKNOWN" }
        $roundsCompleted = if ($TokenGuardData.roundsCompleted) { $TokenGuardData.roundsCompleted } else { 0 }
        $currentRound = if ($TokenGuardData.currentRound) { $TokenGuardData.currentRound } else { 1 }
        $alertsTriggered = if ($TokenGuardData.alertsTriggered) { $TokenGuardData.alertsTriggered } else { 0 }
        $dispatchPaused = if ($TokenGuardData.dispatchPaused) { $TokenGuardData.dispatchPaused } else { $false }
    }
    
    switch ($status) {
        "READY" { $statusColor = "Green" }
        "ALERT" { $statusColor = "Yellow" }
        "PAUSED" { $statusColor = "Red" }
        "ACTIVE" { $statusColor = "Cyan" }
        "COMPLETED" { $statusColor = "Green" }
        default { $statusColor = "Gray" }
    }
    
    Write-Host "  Status:            " -NoNewline -ForegroundColor Gray
    Write-Host "$status" -ForegroundColor $statusColor
    Write-Host "  Rounds Completed:  $roundsCompleted" -ForegroundColor White
    Write-Host "  Current Round:     $currentRound" -ForegroundColor White
    Write-Host "  Alerts Triggered:  $alertsTriggered" -ForegroundColor $(if ($alertsTriggered -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  Dispatch Paused:   " -NoNewline -ForegroundColor Gray
    Write-Host "$dispatchPaused" -ForegroundColor $(if ($dispatchPaused) { "Red" } else { "Green" })
    Write-Host ""
    
    # Thresholds Section
    Write-Host "" -ForegroundColor Yellow
    Write-Host " THRESHOLDS                                                " -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    
    $alertPercent = [math]::Round($alertThreshold * 100, 0)
    $pausePercent = [math]::Round($pauseThreshold * 100, 0)
    
    Write-Host "  Alert Threshold:   $alertPercent%" -ForegroundColor Yellow
    Write-Host "  Pause Threshold:   $pausePercent%" -ForegroundColor Red
    
    $alertTokens = [math]::Round($budget * $alertThreshold)
    $pauseTokens = [math]::Round($budget * $pauseThreshold)
    
    Write-Host "  Alert at:          $alertTokens tokens" -ForegroundColor Yellow
    Write-Host "  Pause at:          $pauseTokens tokens" -ForegroundColor Red
    Write-Host ""
    
    # Engram Integration Section
    if ($EngramData) {
        Write-Host "" -ForegroundColor Cyan
        Write-Host " ENGRAM MEMORY STATUS                                      " -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan
        
        $observationCount = if ($EngramData.observations) { $EngramData.observations.Count } else { 0 }
        $sessionCount = if ($EngramData.sessions) { $EngramData.sessions.Count } else { 0 }
        
        Write-Host "  Observations:     $observationCount" -ForegroundColor White
        Write-Host "  Sessions:         $sessionCount" -ForegroundColor White
        Write-Host ""
    }
    
    # Footer
    Write-Host "" -ForegroundColor Cyan
    if ($Continuous) {
        Write-Host "  Press Ctrl+C to exit | Refreshing every $RefreshInterval seconds" -ForegroundColor Gray
    }
    Write-Host ""
}

# Main execution
try {
    $sessionId = Get-CurrentSession -ProvidedSessionId $SessionId
    
    if ($null -eq $sessionId) {
        Write-Host "[TOKEN-MONITOR] No active session found" -ForegroundColor Yellow
        exit 1
    }
    
    do {
        $tokenGuardData = Get-TokenGuardData
        $sessionMetrics = Get-SessionMetrics -SessionId $sessionId
        $engramData = Get-EngramTokenData
        
        Show-TokenDashboard -SessionId $sessionId -TokenGuardData $tokenGuardData -SessionMetrics $sessionMetrics -EngramData $engramData
        
        if ($Continuous) {
            Start-Sleep -Seconds $RefreshInterval
        }
    } while ($Continuous)
    
    exit 0
}
catch {
    Write-Host "[TOKEN-MONITOR] Error: $_" -ForegroundColor Red
    exit 1
}
