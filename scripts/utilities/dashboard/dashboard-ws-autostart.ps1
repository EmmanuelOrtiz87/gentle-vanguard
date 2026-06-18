#Requires -Version 7.0
param(
    [switch]$Quiet,
    [int]$Port = 0
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))

# Source common functions
. (Join-Path $PSScriptRoot 'dashboard-common.ps1')

$logFile = Join-Path $repoRoot '.runtime' 'dashboard-ws.log'
$pidFile = Join-Path $repoRoot '.runtime' 'dashboard-ws.pid'
$wsServerDir = Join-Path $repoRoot 'apps' 'web-dashboard'
$wsScript = Join-Path $wsServerDir 'server' 'websocket-server.ts'
$runtimeDir = Join-Path $repoRoot '.runtime'

if (-not (Test-Path $runtimeDir)) { New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null }

"$(Get-Date -Format 'o') | [BOOT] Started dashboard-ws-autostart.ps1" | Out-File -FilePath $logFile -Force

# Store watchdog own PID for clean shutdown by stop script
$watchdogPidFile = Join-Path $repoRoot '.runtime' 'dashboard-ws-watchdog.pid'
$PID | Out-File -FilePath $watchdogPidFile -Force

if (-not (Test-Path $wsScript)) {
    $err = "websocket-server.ts not found at $wsScript"
    "$(Get-Date -Format 'o') | [ERR] $err" | Out-File -FilePath $logFile -Append
    Write-Warning "[DASHBOARD-WS] $err"
    exit 1
}

# Detect available port
$preferredPort = if ($Port -gt 0) { $Port } else {
    $ports = Read-DashboardPorts
    if ($ports -and $ports.wsPort) { $ports.wsPort } else { 8080 }
}
$selectedPort = Get-FreePort -Preferred $preferredPort

if ($selectedPort -ne $preferredPort -and -not $Quiet) {
    Write-Warning "[DASHBOARD-WS] Port $preferredPort in use, using $selectedPort instead"
}
"$(Get-Date -Format 'o') | [PORT] selected=$selectedPort (preferred=$preferredPort)" | Out-File -FilePath $logFile -Append

# Persist ports
Save-DashboardPorts -WsPort $selectedPort -VitePort 0

if (-not $Quiet) {
    Write-Host "[DASHBOARD-WS] Starting WS server on port $selectedPort (watchdog)..." -ForegroundColor Cyan
}

$restartCount = 0
$maxRestarts = 10

while ($restartCount -lt $maxRestarts) {
    # Use cmd /c to ensure batch file (npx.cmd) works and env vars propagate correctly
    $cmdLine = "set WS_PORT=$selectedPort && npx.cmd tsx `"$wsScript`""
    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmdLine -WorkingDirectory $wsServerDir -WindowStyle Hidden -PassThru
    $procId = $proc.Id
    $proc.Id | Out-File -FilePath $pidFile -Force

    "$(Get-Date -Format 'o') | [START] PID=$procId port=$selectedPort restart=$restartCount" | Out-File -FilePath $logFile -Append

    if (-not $Quiet) {
        Write-Host "[DASHBOARD-WS] Started PID $procId on port $selectedPort (restart #$restartCount)" -ForegroundColor Green
    }

    do {
        Start-Sleep -Seconds 5
        $alive = Get-Process -Id $procId -ErrorAction SilentlyContinue
        $portOpen = $false
        try {
            $portCheck = Test-NetConnection -ComputerName localhost -Port $selectedPort -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $portOpen = $portCheck.TcpTestSucceeded
        } catch {}

        "$(Get-Date -Format 'o') | [BEAT] PID=$procId alive=$($alive -ne $null) port=$selectedPort`:$portOpen" | Out-File -FilePath $logFile -Append

        if (-not $alive -and -not $portOpen) {
            Write-Warning "[DASHBOARD-WS] Process $procId died on port $selectedPort. Restarting..."
            $restartCount++
            break
        }
        if (-not $alive) {
            Write-Warning "[DASHBOARD-WS] Process $procId exited. Restarting..."
            $restartCount++
            break
        }
    } while ($alive)

    if ($restartCount -ge $maxRestarts) {
        $errMsg = "Max restarts ($maxRestarts) reached on port $selectedPort. Giving up."
        "$(Get-Date -Format 'o') | [FATAL] $errMsg" | Out-File -FilePath $logFile -Append
        Write-Warning "[DASHBOARD-WS] $errMsg"
        Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $watchdogPidFile -Force -ErrorAction SilentlyContinue
        Clear-DashboardPorts
        exit 2
    }
}

# Cleanup watchdog pidfile on normal exit (shouldn't reach here normally due to while loop)
Remove-Item -Path $watchdogPidFile -Force -ErrorAction SilentlyContinue
