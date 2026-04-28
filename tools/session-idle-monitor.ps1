<#
.SYNOPSIS
    Session Idle Monitor - Detects idle sessions and triggers auto-close with notification
    
.DESCRIPTION
    Monitors session activity and automatically:
    1. Closes idle sessions (after timeout)
    2. Cleans up cache (every 5 min or on inactivity)
    3. Disconnects unused services
    4. Saves everything to Engram before actions
    
.PARAMETER IdleTimeoutMinutes
    Minutes of inactivity before session close (default: 60)
    
.PARAMETER CacheCleanupIntervalMinutes
    Minutes between cache cleanups (default: 5)
    
.PARAMETER MonitorIntervalSeconds
    Seconds between checks (default: 30)
    
.EXAMPLE
    .\tools\session-idle-monitor.ps1
    Starts monitoring with defaults
    
.EXAMPLE
    .\tools\session-idle-monitor.ps1 -IdleTimeoutMinutes 30 -MonitorIntervalSeconds 60
    Custom timeout and check interval
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$IdleTimeoutMinutes = 60,
    
    [Parameter(Mandatory=$false)]
    [int]$CacheCleanupIntervalMinutes = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$MonitorIntervalSeconds = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentleman-foundation"
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$lastCacheCleanup = Get-Date

function Write-Status {
    param([string]$Message)
    Write-Host "[IDLE-MONITOR] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

# Get last activity time from session files
function Get-LastActivity {
    $sessionDir = ".\.session"
    
    if (-not (Test-Path $sessionDir)) {
        return $null
    }
    
    $sessionFiles = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                    Sort-Object -Property LastWriteTime -Descending
    
    if ($sessionFiles.Count -eq 0) {
        return $null
    }
    
    return $sessionFiles[0].LastWriteTime
}

# Check if session is idle
function Test-SessionIdle {
    param([int]$TimeoutMinutes)
    
    $lastActivity = Get-LastActivity
    
    if ($null -eq $lastActivity) {
        return $false
    }
    
    $idleMinutes = ((Get-Date) - $lastActivity).TotalMinutes
    
    if ($idleMinutes -ge $TimeoutMinutes) {
        return @{
            isIdle = $true
            idleMinutes = [math]::Round($idleMinutes, 2)
        }
    }
    
    return @{
        isIdle = $false
        idleMinutes = [math]::Round($idleMinutes, 2)
    }
}

# Run cache cleanup if needed
function Invoke-CacheCleanupIfNeeded {
    param([DateTime]$LastCleanup, [int]$IntervalMinutes)
    
    $minutesSinceCleanup = ((Get-Date) - $LastCleanup).TotalMinutes
    
    if ($minutesSinceCleanup -ge $IntervalMinutes) {
        Write-Status "Running scheduled cache cleanup..."
        
        $cacheScript = Join-Path $scriptDir "cache-cleanup-manager.ps1"
        
        if (Test-Path $cacheScript) {
            & $cacheScript -Mode run 2>$null
            Write-Success "Cache cleanup completed"
            return Get-Date
        } else {
            Write-WarningMsg "cache-cleanup-manager.ps1 not found"
        }
    }
    
    return $LastCleanup
}
    }
    
    return $LastCleanup
}

# Test if MCP server is responding
function Test-MCPService {
    param([string]$ServerName, [hashtable]$ServerConfig)
    
    try {
        $command = $ServerName
        $args = @()
        
        # Simple test: try to start and immediately stop
        $process = Start-Process -FilePath $ServerConfig.command -ArgumentList $ServerConfig.args -PassThru -WindowStyle Hidden
        Start-Sleep -Milliseconds 500
        
        if (-not $process.HasExited) {
            $process.Kill()
            return $true
        }
        
        return $false
    }
    catch {
        return $false
    }
}

# Auto-disconnect non-functioning services
function Disconnect-FailedServices {
    Write-Status "Checking for non-functioning services..."
    
    $mcpConfigPath = ".\config\mcp-servers.json"
    if (-not (Test-Path $mcpConfigPath)) {
        return
    }
    
    try {
        $config = Get-Content $mcpConfigPath | ConvertFrom-Json
        $servers = $config.mcpServers.PSObject.Properties
        $disconnected = @()
        
        foreach ($server in $servers) {
            $serverName = $server.Name
            $serverInfo = $server.Value
            
            # Skip disabled servers
            if ($serverName -like "_disabled_*") { continue }
            
            # Test if service is working
            $isWorking = Test-MCPService -ServerName $serverName -ServerConfig $serverInfo
            
            if (-not $isWorking) {
                Write-Host "  [FAIL] $serverName - not responding" -ForegroundColor Red
                
                # Disable the server
                $config.mcpServers | Add-Member -NotePropertyName "_disabled_$serverName" -NotePropertyValue $serverInfo -Force
                $config.mcpServers.PSObject.Properties.Remove($serverName)
                $disconnected += $serverName
                
                Write-Host "  Disabled: $serverName" -ForegroundColor Yellow
            } else {
                Write-Host "  [OK] $serverName - working" -ForegroundColor Green
            }
        }
        
        if ($disconnected.Count -gt 0) {
            $config | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigPath -Encoding UTF8
            
            # Save to Engram
            $engramBin = Join-Path $scriptDir "engram.exe"
            if (Test-Path $engramBin) {
                $content = @"
## Auto-Disconnect: Failed Services
**Timestamp**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Disconnected**: $($disconnected -join ', ')
**Reason**: Services not responding

MCP servers disabled to prevent token waste on failed connection attempts.
"@
                & $engramBin save --title "Auto-Disconnect: Failed Services" --content $content --project $ProjectName --type manual 2>$null | Out-Null
            }
            
            # Notify user
            $notifyScript = Join-Path $scriptDir "notify-user.ps1"
            if (Test-Path $notifyScript) {
                & $notifyScript -Action "disconnect" -Reason "Services not responding: $($disconnected -join ', ')" -RecoveryCommand ".\tools\session-quick-restart.ps1 -Components disconnect" 2>$null
            }
        }
    }
    catch {
        Write-WarningMsg "Failed to check MCP services: $_"
    }
}

# Auto-close idle session
function Close-IdleSession {
    param([double]$IdleMinutes)
    
    Write-Status "Session idle for $IdleMinutes minutes - auto-closing..."
    
    # Save to Engram BEFORE closing
    $engramBin = Join-Path $scriptDir "engram.exe"
    if (Test-Path $engramBin) {
        $content = @"
## Auto-Close: Idle Session
**Timestamp**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Reason**: Session idle for $IdleMinutes minutes
**Action**: Session automatically closed to save tokens

Context preserved in Engram for recovery.
"@
        & $engramBin save --title "Auto-Close: Idle Session" --content $content --project $ProjectName --type manual 2>$null | Out-Null
    }
    
    # Disconnect failed services before closing
    Disconnect-FailedServices
    
    # Close session
    $sessionScript = Join-Path $scriptDir "session-manager.ps1"
    if (Test-Path $sessionScript) {
        & $sessionScript -Mode End -ProjectName $ProjectName 2>$null
    }
    
    # Notify user
    $notifyScript = Join-Path $scriptDir "notify-user.ps1"
    if (Test-Path $notifyScript) {
        & $notifyScript -Action "session-close" -Reason "Session idle for $IdleMinutes minutes" -RecoveryCommand ".\tools\session-quick-restart.ps1 -Components session" 2>$null
    }
    
    Write-Success "Idle session closed"
}

# Main monitoring loop
function Start-IdleMonitor {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║            SESSION IDLE MONITOR - AUTOMATIC MANAGEMENT         ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Idle Timeout: $IdleTimeoutMinutes minutes" -ForegroundColor Gray
    Write-Host "  Cache Cleanup: every $CacheCleanupIntervalMinutes minutes" -ForegroundColor Gray
    Write-Host "  Check Interval: $MonitorIntervalSeconds seconds" -ForegroundColor Gray
    Write-Host "  Project: $ProjectName" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        # Check for idle session
        $idleResult = Test-SessionIdle -TimeoutMinutes $IdleTimeoutMinutes
        
        if ($idleResult.isIdle) {
            Close-IdleSession -IdleMinutes $idleResult.idleMinutes
            break
        } else {
            Write-Host "[IDLE-MONITOR] $(Get-Date -Format 'HH:mm:ss') - Last activity: $($idleResult.idleMinutes) minutes ago" -ForegroundColor Gray
        }
        
        # Check if cache cleanup needed
        $lastCacheCleanup = Invoke-CacheCleanupIfNeeded -LastCleanup $lastCacheCleanup -IntervalMinutes $CacheCleanupIntervalMinutes
        
        Start-Sleep -Seconds $MonitorIntervalSeconds
    }
}

# Start monitoring
try {
    Start-IdleMonitor
    exit 0
}
catch {
    Write-Host "[IDLE-MONITOR] Error: $_" -ForegroundColor Red
    exit 1
}
