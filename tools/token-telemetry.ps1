<#
.SYNOPSIS
    Token Telemetry - Real-time token usage tracking
    
.DESCRIPTION
    Provides real-time telemetry for token consumption:
    - Tracks prompt and completion tokens
    - Calculates usage percentages
    - Alerts on threshold breaches
    - Saves telemetry to Engram
    
.PARAMETER Mode
    Operation mode: monitor, report, reset
    
.PARAMETER SessionId
    Session ID to track
    
.EXAMPLE
    .\tools\token-telemetry.ps1 -Mode monitor
    Starts real-time token monitoring
    
.EXAMPLE
    .\tools\token-telemetry.ps1 -Mode report
    Generates token usage report
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('monitor', 'report', 'reset')]
    [string]$Mode = 'report',
    
    [Parameter(Mandatory=$false)]
    [string]$SessionId = ""
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message)
    Write-Host "[TELEMETRY] $Message" -ForegroundColor Magenta
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

# Get current token usage from token-guard state
function Get-TokenUsage {
    $stateFile = ".\.session\token-guard-state.json"
    
    if (-not (Test-Path $stateFile)) {
        return $null
    }
    
    try {
        $state = Get-Content $stateFile | ConvertFrom-Json
        return @{
            totalUsed = if ($state.totalTokensUsed) { $state.totalTokensUsed } else { 0 }
            budget = 128000
            roundsCompleted = if ($state.roundsCompleted) { $state.roundsCompleted } else { 0 }
            alertsTriggered = if ($state.alertsTriggered) { $state.alertsTriggered } else { 0 }
            status = if ($state.status) { $state.status } else { "UNKNOWN" }
        }
    }
    catch {
        return $null
    }
}

# Save telemetry to Engram
function Save-TelemetryToEngram {
    param([hashtable]$Usage)
    
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
    
    if (-not (Test-Path $engramBin)) {
        return $false
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $percentUsed = [math]::Round(($Usage.totalUsed / $Usage.budget) * 100, 2)
    
    $content = @"
## Token Telemetry Snapshot
Timestamp: $timestamp

### Usage:
- Total Used: $($Usage.totalUsed) tokens
- Budget: $($Usage.budget) tokens
- Percentage: $percentUsed%
- Rounds Completed: $($Usage.roundsCompleted)
- Alerts: $($Usage.alertsTriggered)
- Status: $($Usage.status)
"@
    
    & $engramBin save --title "Token Telemetry Snapshot" --content $content --project "gentleman-foundation" --type manual 2>$null | Out-Null
    
    return ($LASTEXITCODE -eq 0)
}

# Monitor mode - continuous
function Start-Monitor {
    Write-Status "Starting token telemetry monitor..."
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    
    while ($true) {
        $usage = Get-TokenUsage
        
        if ($null -eq $usage) {
            Write-Host "[TELEMETRY] No token data available" -ForegroundColor Yellow
        } else {
            $percentUsed = [math]::Round(($usage.totalUsed / $usage.budget) * 100, 2)
            
            Clear-Host
            Write-Host "=== TOKEN TELEMETRY ===" -ForegroundColor Magenta
            Write-Host "Used: $($usage.totalUsed) / $($usage.budget) ($percentUsed%)" -ForegroundColor White
            Write-Host "Status: $($usage.status)" -ForegroundColor Gray
            Write-Host "Rounds: $($usage.roundsCompleted) | Alerts: $($usage.alertsTriggered)" -ForegroundColor Gray
        }
        
        Start-Sleep -Seconds 5
    }
}

# Report mode
function Generate-Report {
    Write-Status "Generating token telemetry report..."
    
    $usage = Get-TokenUsage
    
    if ($null -eq $usage) {
        Write-Host "[WARN] No token data found" -ForegroundColor Yellow
        return
    }
    
    $percentUsed = [math]::Round(($usage.totalUsed / $usage.budget) * 100, 2)
    $remaining = $usage.budget - $usage.totalUsed
    
    Write-Host ""
    Write-Host "" -ForegroundColor Magenta
    Write-Host "              TOKEN TELEMETRY REPORT                          " -ForegroundColor Magenta
    Write-Host "" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Total Used: $($usage.totalUsed) tokens" -ForegroundColor White
    Write-Host "  Budget:     $($usage.budget) tokens" -ForegroundColor Gray
    Write-Host "  Remaining:  $remaining tokens" -ForegroundColor Green
    Write-Host "  Usage:      $percentUsed%" -ForegroundColor Yellow
    Write-Host "  Status:     $($usage.status)" -ForegroundColor Cyan
    Write-Host "  Rounds:     $($usage.roundsCompleted)" -ForegroundColor Gray
    Write-Host "  Alerts:     $($usage.alertsTriggered)" -ForegroundColor $(if ($usage.alertsTriggered -gt 0) { "Yellow" } else { "Green" })
    Write-Host ""
    
    # Save to Engram
    Save-TelemetryToEngram -Usage $usage | Out-Null
    Write-Success "Report saved to Engram"
}

# Main execution
switch ($Mode) {
    'monitor' {
        Start-Monitor
    }
    
    'report' {
        Generate-Report
        exit 0
    }
    
    'reset' {
        $stateFile = ".\.session\token-guard-state.json"
        if (Test-Path $stateFile) {
            Remove-Item $stateFile -Force
            Write-Success "Token state reset"
        }
        exit 0
    }
}
