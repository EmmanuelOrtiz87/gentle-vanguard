<#
.SYNOPSIS
    Notification System - User-friendly messages with Engram integration
    
.DESCRIPTION
    Handles all user notifications for automatic actions (closures, cleanups, disconnections).
    Saves to Engram before action and shows clear on-screen messages.
    
.PARAMETER Action
    Action type: session-close, cleanup, disconnect, block, cache-clean
    
.PARAMETER Reason
    Why the action occurred
    
.PARAMETER Details
    Additional details about the action
    
.PARAMETER RecoveryCommand
    Command user can run to recover without full restart
    
.EXAMPLE
    .\tools\notify-user.ps1 -Action "session-close" -Reason "Idle timeout" -RecoveryCommand ".\tools\session-quick-restart.ps1"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('session-close', 'cleanup', 'disconnect', 'block', 'cache-clean', 'fragmentation')]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [string]$Reason,
    
    [Parameter(Mandatory=$false)]
    [string]$Details = "",
    
    [Parameter(Mandatory=$false)]
    [string]$RecoveryCommand = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentle-vanguard"
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$engramSafeScript = Join-Path $repoRoot 'scripts\utilities\engram-safe.ps1'
if (Test-Path $engramSafeScript) {
    . $engramSafeScript
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Color scheme
$colors = @{
    'session-close' = "Yellow"
    'cleanup' = "Cyan"
    'disconnect' = "Magenta"
    'block' = "Red"
    'cache-clean' = "Green"
    'fragmentation' = "Blue"
}

$icons = @{
    'session-close' = "[SESSION]"
    'cleanup' = "[CLEANUP]"
    'disconnect' = "[DISCONNECT]"
    'block' = "[BLOCKED]"
    'cache-clean' = "[CACHE]"
    'fragmentation' = "[FRAGMENT]"
}

function Save-ToEngram {
    param([string]$Action, [string]$Reason, [string]$Details)

    if (-not (Get-Command Invoke-Gentle-VanguardEngram -ErrorAction SilentlyContinue)) {
        return $false
    }
    
    $content = @"
## Automatic Action: $Action
**Timestamp**: $timestamp
**Reason**: $Reason
**Details**: $Details

This action was performed automatically to optimize token usage and maintain system health.
"@
    
    try {
        $result = Invoke-Gentle-VanguardEngram -RepoRoot $repoRoot -Arguments @('save', "Auto-Action: $Action", $content, '--project', $ProjectName, '--type', 'manual')
        return $result.Success
    } catch {
        return $false
    }
}

function Show-Notification {
    param(
        [string]$Action,
        [string]$Reason,
        [string]$Details,
        [string]$RecoveryCommand
    )
    
    $color = $colors[$Action]
    $icon = $icons[$Action]
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor $color
    Write-Host "$icon ACTION PERFORMED" -ForegroundColor $color
    Write-Host ("=" * 60) -ForegroundColor $color
    Write-Host ""
    Write-Host "  Time: $timestamp" -ForegroundColor Gray
    Write-Host "  Action: $Action" -ForegroundColor White
    Write-Host "  Reason: $Reason" -ForegroundColor Yellow
    
    if ($Details -ne "") {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Show recovery option if available
    if ($RecoveryCommand -ne "") {
        Write-Host "  TO CONTINUE WITHOUT FULL RESTART:" -ForegroundColor Green
        Write-Host "  $RecoveryCommand" -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host ("-" * 60) -ForegroundColor $color
    Write-Host "  Context saved to Engram for reconstruction" -ForegroundColor Gray
    Write-Host ("=" * 60) -ForegroundColor $color
    Write-Host ""
}

# Main execution
try {
    # Save to Engram BEFORE action
    $engramSaved = Save-ToEngram -Action $Action -Reason $Reason -Details $Details
    
    # Show notification
    Show-Notification -Action $Action -Reason $Reason -Details $Details -RecoveryCommand $RecoveryCommand
    
    # Return status
    if ($engramSaved) {
        Write-Host "[OK] Action logged to Engram" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Could not save to Engram" -ForegroundColor Yellow
    }
    
    exit 0
}
catch {
    Write-Host "[ERROR] Notification failed: $_" -ForegroundColor Red
    exit 1
}

