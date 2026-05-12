<#
.SYNOPSIS
    Cache Cleanup Manager - Smart cleanup based on time or inactivity
    
.DESCRIPTION
    Manages cache cleanup with two triggers:
    1. Time-based: Every 5 minutes
    2. Inactivity-based: When no activity detected
    
    Cleans old cache while preserving recent files needed for recovery.
    
.PARAMETER Mode
    Operation mode: check, run, monitor
    
.PARAMETER InactivityMinutes
    Minutes of inactivity to trigger cleanup (default: 5)
    
.PARAMETER MaxCacheAge
    Maximum age in minutes for cache files (default: 5)
    
.EXAMPLE
    .\tools\cache-cleanup-manager.ps1 -Mode run
    Runs cleanup once
    
.EXAMPLE
    .\tools\cache-cleanup-manager.ps1 -Mode monitor -InactivityMinutes 5
    Monitors and cleans every 5 minutes or on inactivity
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('check', 'run', 'monitor')]
    [string]$Mode = 'check',
    
    [Parameter(Mandatory=$false)]
    [int]$InactivityMinutes = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxCacheAge = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "foundation"
)

$ErrorActionPreference = 'Continue'
$cacheDirs = @(
    ".\.session\cache",
    ".\.session\temp",
    ".\.session\metrics"
)

function Write-Status {
    param([string]$Message)
    Write-Host "[CACHE] $Message" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

# Check if cleanup should run based on time or inactivity
function Test-CleanupTrigger {
    param([int]$InactivityMin)
    
    $shouldClean = $false
    $reason = ""
    
    # Check cache age (time-based trigger)
    foreach ($dir in $cacheDirs) {
        if (-not (Test-Path $dir)) { continue }
        
        $oldFiles = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | 
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddMinutes(-$MaxCacheAge) }
        
        if ($oldFiles.Count -gt 0) {
            $shouldClean = $true
            $reason = "Cache files older than $MaxCacheAge minutes found"
            break
        }
    }
    
    # Check inactivity (inactivity-based trigger)
    if (-not $shouldClean) {
        $sessionFiles = Get-ChildItem -Path ".\.session" -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                        Sort-Object -Property LastWriteTime -Descending | 
                        Select-Object -First 1
        
        if ($sessionFiles) {
            $lastActivity = $sessionFiles.LastWriteTime
            $minutesSinceActivity = (Get-Date) - $lastActivity | Select-Object -ExpandProperty TotalMinutes
            
            if ($minutesSinceActivity -ge $InactivityMin) {
                $shouldClean = $true
                $reason = "Inactivity detected ($($minutesSinceActivity.ToString('F1')) minutes)"
            }
        }
    }
    
    return @{
        shouldClean = $shouldClean
        reason = $reason
    }
}

# Run cache cleanup
function Invoke-CacheCleanup {
    param([string]$Reason)
    
    Write-Status "Running cache cleanup..."
    Write-Host "  Reason: $Reason" -ForegroundColor Gray
    
    $cleaned = 0
    $preserved = 0
    
    foreach ($dir in $cacheDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            continue
        }
        
        $files = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            # Skip recent files (needed for recovery)
            if ($file.LastWriteTime -gt (Get-Date).AddMinutes(-$MaxCacheAge)) {
                $preserved++
                continue
            }
            
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $cleaned++
            }
            catch {
                Write-WarningMsg "Could not delete: $($file.Name)"
            }
        }
    }
    
    Write-Host "  Cleaned: $cleaned files" -ForegroundColor Green
    Write-Host "  Preserved: $preserved recent files" -ForegroundColor Cyan
    
    # Notify user
    $notifyScript = Join-Path $PSScriptRoot "notify-user.ps1"
    if (Test-Path $notifyScript) {
        & $notifyScript -Action "cache-clean" -Reason $Reason -RecoveryCommand ".\tools\session-quick-restart.ps1 -Components cache" 2>$null
    }
    
    return $cleaned
}

# Monitor mode - runs continuously
function Start-CacheMonitor {
    param([int]$InactivityMin)
    
    Write-Status "Starting cache monitor (interval: $InactivityMin min)..."
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        $trigger = Test-CleanupTrigger -InactivityMin $InactivityMin
        
        if ($trigger.shouldClean) {
            Invoke-CacheCleanup -Reason $trigger.reason
            Write-Host ""
        } else {
            Write-Host "[CACHE] No cleanup needed ($(Get-Date -Format 'HH:mm:ss'))" -ForegroundColor Gray
        }
        
        Start-Sleep -Seconds ($InactivityMin * 60)
    }
}

# Check mode - report status
function Get-CacheStatus {
    Write-Status "Checking cache status..."
    
    $totalFiles = 0
    $oldFiles = 0
    $recentFiles = 0
    
    foreach ($dir in $cacheDirs) {
        if (-not (Test-Path $dir)) { continue }
        
        $files = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue
        $totalFiles += $files.Count
        
        foreach ($file in $files) {
            if ($file.LastWriteTime -lt (Get-Date).AddMinutes(-$MaxCacheAge)) {
                $oldFiles++
            } else {
                $recentFiles++
            }
        }
    }
    
    Write-Host "  Total cache files: $totalFiles" -ForegroundColor White
    Write-Host "  Old (will clean): $oldFiles" -ForegroundColor Yellow
    Write-Host "  Recent (preserve): $recentFiles" -ForegroundColor Green
    
    $trigger = Test-CleanupTrigger -InactivityMin $InactivityMin
    Write-Host "  Cleanup needed: $($trigger.shouldClean)" -ForegroundColor $(if ($trigger.shouldClean) { "Yellow" } else { "Green" })
    
    if ($trigger.shouldClean) {
        Write-Host "  Reason: $($trigger.reason)" -ForegroundColor Gray
    }
}

# Main execution
switch ($Mode) {
    'check' {
        Get-CacheStatus
        exit 0
    }
    
    'run' {
        $trigger = Test-CleanupTrigger -InactivityMin $InactivityMinutes
        
        if ($trigger.shouldClean) {
            $cleaned = Invoke-CacheCleanup -Reason $trigger.reason
            exit 0
        } else {
            Write-Host "[CACHE] No cleanup needed at this time" -ForegroundColor Green
            exit 0
        }
    }
    
    'monitor' {
        Start-CacheMonitor -InactivityMin $InactivityMinutes
    }
}
