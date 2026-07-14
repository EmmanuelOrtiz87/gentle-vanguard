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

$watchdogPidFile = Join-Path $repoRoot '.runtime' 'dashboard-ws-watchdog.pid'

foreach ($f in @($pidFile, $watchdogPidFile, (Join-Path $repoRoot '.runtime' 'dashboard-ports.json'))) {
    if (Test-Path $f) {
        $c = (Get-Content $f -Raw -ErrorAction SilentlyContinue).Trim()
        if ($c -match '^\d+$') { if (-not (Get-Process -Id ([int]$c) -ErrorAction SilentlyContinue)) { Remove-Item $f -Force -ErrorAction SilentlyContinue } }
        elseif ($c -match '"wsPort"') {
            try { $p = ($c | ConvertFrom-Json).wsPort; if ($p -and -not (Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue)) { Remove-Item $f -Force -ErrorAction SilentlyContinue } } catch {}
        }
        else { Remove-Item $f -Force -ErrorAction SilentlyContinue }
    }
}

"$(Get-Date -Format 'o') | [BOOT] Started dashboard-ws-autostart.ps1" | Out-File -FilePath $logFile -Append

$PID | Out-File -FilePath $watchdogPidFile -Force

if (-not (Test-Path $wsScript)) {
    $err = "websocket-server.ts not found at $wsScript"
    "$(Get-Date -Format 'o') | [ERR] $err" | Out-File -FilePath $logFile -Append
    Write-Warning "[DASHBOARD-WS] $err"
    exit 1
}

# Check if WS server is already running on any port
$existingWsOk = $false
$existingPort = 0
foreach ($testPort in @(8080, 8082, 8083)) {
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:${testPort}/api/health" -TimeoutSec 2 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            $existingWsOk = $true
            $existingPort = $testPort
            break
        }
    } catch {}
}

if ($existingWsOk) {
    "$(Get-Date -Format 'o') | [SKIP] WS already running on port $existingPort" | Out-File -FilePath $logFile -Append
    Save-DashboardPorts -WsPort $existingPort -VitePort 0
    if (-not $Quiet) {
        Write-Host "[DASHBOARD-WS] WS already running on port $existingPort — skipping start" -ForegroundColor Green
    }
    exit 0
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
    Write-Host "[DASHBOARD-WS] Starting WS server on port $selectedPort..." -ForegroundColor Cyan
}

# Start WS server detached (fire-and-forget)
$cmdLine = "set WS_PORT=$selectedPort && npx.cmd tsx `"$wsScript`""
$proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmdLine -WorkingDirectory $wsServerDir -WindowStyle Hidden -PassThru
$procId = $proc.Id
$proc.Id | Out-File -FilePath $pidFile -Force

"$(Get-Date -Format 'o') | [START] PID=$procId port=$selectedPort" | Out-File -FilePath $logFile -Append

# Wait up to 15s for the server to become healthy
$started = $false
for ($i = 0; $i -lt 3; $i++) {
    Start-Sleep -Seconds 5
    $alive = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if (-not $alive) {
        "$(Get-Date -Format 'o') | [ERR] Process $procId exited prematurely" | Out-File -FilePath $logFile -Append
        break
    }
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:${selectedPort}/api/health" -TimeoutSec 3 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            $started = $true
            break
        }
    } catch {}
}

if ($started) {
    "$(Get-Date -Format 'o') | [OK] WS healthy on port $selectedPort (PID=$procId)" | Out-File -FilePath $logFile -Append
    if (-not $Quiet) {
        Write-Host "[DASHBOARD-WS] WS server healthy on port $selectedPort (PID $procId)" -ForegroundColor Green
    }
    exit 0
} else {
    "$(Get-Date -Format 'o') | [WARN] WS process started but health check inconclusive (PID=$procId port=$selectedPort)" | Out-File -FilePath $logFile -Append
    if (-not $Quiet) {
        Write-Warning "[DASHBOARD-WS] WS process started but health check inconclusive"
    }
    exit 0
}
