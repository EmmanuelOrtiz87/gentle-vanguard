<#
.SYNOPSIS
    Session Quick Restart - Restarts only what's needed without full stack
    
.DESCRIPTION
    Lightweight restart that recovers from automatic closures/cleanups/disconnections.
    Does NOT re-initialize everything like "inicia sesion" does.
    
.PARAMETER Components
    What to restart: session, cleanup, disconnect, all
    
.EXAMPLE
    .\tools\session-quick-restart.ps1 -Components session
    Restarts only the session tracking
    
.EXAMPLE
    .\tools\session-quick-restart.ps1 -Components all
    Restarts all components that might have been auto-closed
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('session', 'cleanup', 'disconnect', 'cache', 'all')]
    [string]$Components = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentleman-foundation"
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message)
    Write-Host "[QUICK-RESTART] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

# Restart session tracking only
function Restart-Session {
    Write-Status "Restarting session tracking..."
    
    $sessionScript = Join-Path $PSScriptRoot "session-manager.ps1"
    
    if (-not (Test-Path $sessionScript)) {
        Write-WarningMsg "session-manager.ps1 not found"
        return $false
    }
    
    & $sessionScript -Mode Manual -ProjectName $ProjectName
    Write-Success "Session tracking restarted"
    return $true
}

# Recover from cleanup
function Recover-Cleanup {
    Write-Status "Recovering from cleanup..."
    
    # Restore any cleared context from Engram
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
    
    if (Test-Path $engramBin) {
        Write-Status "Retrieving context from Engram..."
        & $engramBin context --project $ProjectName 2>$null
        Write-Success "Context recovered from Engram"
    }
    
    return $true
}

# Reconnect disconnected services
function Reconnect-Services {
    Write-Status "Reconnecting services..."
    
    # Check MCP servers
    $mcpConfig = ".\config\mcp-servers.json"
    if (Test-Path $mcpConfig) {
        Write-Status "MCP servers configuration found"
        # MCP reconnection would happen automatically on next use
        Write-Success "Services will reconnect on next use"
    }
    
    return $true
}

# Clear cache selectively
function Restart-Cache {
    Write-Status "Managing cache..."
    
    # Clear only old cache, keep recent
    $cacheDirs = @(".\.session\cache", ".\.session\temp")
    
    foreach ($dir in $cacheDirs) {
        if (Test-Path $dir) {
            $oldFiles = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | 
                        Where-Object { $_.LastWriteTime -lt (Get-Date).AddMinutes(-5) }
            
            foreach ($file in $oldFiles) {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Write-Success "Cache cleaned (keeping recent)"
    return $true
}

# Main execution
try {
    Write-Host ""
    Write-Host "" -ForegroundColor Green
    Write-Host "          SESSION QUICK RESTART - LIGHTWEIGHT RECOVERY         " -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host ""
    
    $success = $true
    
    if ($Components -eq 'all' -or $Components -eq 'session') {
        $success = $success -and (Restart-Session)
    }
    
    if ($Components -eq 'all' -or $Components -eq 'cleanup') {
        $success = $success -and (Recover-Cleanup)
    }
    
    if ($Components -eq 'all' -or $Components -eq 'disconnect') {
        $success = $success -and (Reconnect-Services)
    }
    
    if ($Components -eq 'all' -or $Components -eq 'cache') {
        $success = $success -and (Restart-Cache)
    }
    
    Write-Host ""
    if ($success) {
        Write-Host "" -ForegroundColor Green
        Write-Host "                    READY TO CONTINUE                         " -ForegroundColor Green
        Write-Host "" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Some components failed to restart" -ForegroundColor Yellow
        Write-Host "Run full restart: .\tools\session-autostart.cmd" -ForegroundColor Cyan
    }
    
    exit 0
}
catch {
    Write-Host "[ERROR] Quick restart failed: $_" -ForegroundColor Red
    exit 1
}
