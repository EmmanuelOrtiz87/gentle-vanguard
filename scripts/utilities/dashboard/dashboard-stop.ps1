#Requires -Version 7.0
<#
.SYNOPSIS
Stop all dashboard processes using persisted port state
.DESCRIPTION
Reads .runtime/dashboard-ports.json to find WS and Vite ports,
kills processes by PID file, port ownership, and process name.
#>

param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))

# Source common functions
. (Join-Path $PSScriptRoot 'dashboard-common.ps1')

# Read ports BEFORE clearing state (so we know what to kill)
$ports = Read-DashboardPorts
$wsPort = if ($ports -and $ports.wsPort) { $ports.wsPort } else { 8080 }
$vitePort = if ($ports -and $ports.vitePort) { $ports.vitePort } else { 5173 }

# Clear state files FIRST so even if something hangs, ports are cleaned
Clear-DashboardPorts
Remove-Item -Path (Join-Path $repoRoot '.runtime' 'dashboard-ws.pid') -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $repoRoot '.runtime' 'dashboard-vite.pid') -Force -ErrorAction SilentlyContinue

# Kill watchdog FIRST so it doesn't restart the WS server
$watchdogPidFile = Join-Path $repoRoot '.runtime' 'dashboard-ws-watchdog.pid'
if (Test-Path $watchdogPidFile) {
    $watchdogPid = Get-Content $watchdogPidFile -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
    if ($watchdogPid -and $watchdogPid -match '^\d+$') {
        Stop-Process -Id $watchdogPid -Force -ErrorAction SilentlyContinue
        if (-not $Quiet) { Write-Host "[DASHBOARD] Stopped watchdog (PID $watchdogPid)" -ForegroundColor Yellow }
    }
    Remove-Item -Path $watchdogPidFile -Force -ErrorAction SilentlyContinue
}

# Kill by PID files (processes might still be alive after watchdog dies)
function Stop-ByPidFile {
    param([string]$PidFile, [string]$Label)
    if (Test-Path $PidFile) {
        $procId = Get-Content $PidFile -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
        if ($procId -and $procId -match '^\d+$') {
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
            if (-not $Quiet) { Write-Host "[DASHBOARD] Stopped $Label (PID $procId)" -ForegroundColor Yellow }
        }
        Remove-Item -Path $PidFile -Force -ErrorAction SilentlyContinue
    }
}

Stop-ByPidFile -PidFile (Join-Path $repoRoot '.runtime' 'dashboard-ws.pid') -Label "WS server (pidfile)"
Stop-ByPidFile -PidFile (Join-Path $repoRoot '.runtime' 'dashboard-vite.pid') -Label "Vite (pidfile)"

# Kill by port ownership (uses Get-NetTCPConnection, safe and fast)
function Stop-ByPort {
    param([int]$Port, [string]$Label)
    $procId = Get-ProcessIdByPort -Port $Port
    if ($procId) {
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        if (-not $Quiet) { Write-Host "[DASHBOARD] Stopped $Label on port $Port (PID $procId)" -ForegroundColor Yellow }
    }
}

Stop-ByPort -Port $wsPort -Label "WS server"
Stop-ByPort -Port $vitePort -Label "Vite dev server"

# Clean up any remaining npx/node processes (with timeout to avoid hang on CommandLine access)
try {
    $nodeProcs = Get-Process -Name "node" -ErrorAction SilentlyContinue
    foreach ($np in $nodeProcs) {
        try {
            $cmd = $np.CommandLine
            if ($cmd -match 'tsx.*websocket-server|vite') {
                Stop-Process -Id $np.Id -Force -ErrorAction SilentlyContinue
                if (-not $Quiet) { Write-Host "[DASHBOARD] Stopped $($np.ProcessName) (PID $($np.Id))" -ForegroundColor Yellow }
            }
        } catch { continue }
    }
} catch {}

if (-not $Quiet) {
    Write-Host "[DASHBOARD] All dashboard processes stopped (WS:$wsPort, Vite:$vitePort)." -ForegroundColor Green
}
