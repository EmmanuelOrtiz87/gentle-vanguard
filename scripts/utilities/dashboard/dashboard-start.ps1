#Requires -Version 7.0
<#
.SYNOPSIS
Start the React LLM observability dashboard with dynamic port allocation
.DESCRIPTION
Detects free ports, launches WS server (watchdog) + Vite dev server,
opens Chrome. Handles port conflicts gracefully.
#>

param(
    [switch]$ViteOnly,
    [switch]$WSOnly,
    [switch]$Quiet,
    [switch]$NoBrowser,
    [int]$WsPort = 0,
    [int]$ViteDevPort = 0
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
$webAppDir = Join-Path $repoRoot 'apps' 'web-dashboard'

# Source common functions
. (Join-Path $PSScriptRoot 'dashboard-common.ps1')

function Show-Header {
    if (-not $Quiet) {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GENTLE-VANGUARD LLM OBSERVABILITY DASHBOARD         ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

function Start-WSServer {
    param([int]$Port)
    $wsScript = Join-Path $PSScriptRoot 'dashboard-ws-autostart.ps1'
    if (Test-Path $wsScript) {
        if (-not $Quiet) { Write-Host "[DASHBOARD] Starting WS server on port $Port..." -ForegroundColor Yellow }
        $psParams = @("-NoProfile", "-File", "`"$wsScript`"", "-Quiet", "-Port", "$Port")
        Start-Process -FilePath "pwsh" -ArgumentList $psParams -WindowStyle Hidden
        Start-Sleep -Seconds 4
    } else {
        if (-not $Quiet) { Write-Host "[DASHBOARD] Starting WS directly on port $Port..." -ForegroundColor Yellow }
        $wsEntry = Join-Path $webAppDir 'server\websocket-server.ts'
        if (Test-Path $wsEntry) {
            $env:WS_PORT = "$Port"
            Start-Process -FilePath "npx.cmd" -ArgumentList "tsx", "`"$wsEntry`"" -WorkingDirectory $webAppDir -WindowStyle Hidden
            Start-Sleep -Seconds 4
        } else {
            Write-Warning "[DASHBOARD] websocket-server.ts not found at $wsEntry"
        }
    }
}

function Start-ViteDev {
    param([int]$WsPort, [int]$VitePort)
    $vitePidFile = Join-Path $repoRoot '.runtime' 'dashboard-vite.pid'

    # Kill any stale Vite on target port before starting
    $existing = Get-ProcessIdByPort -Port $VitePort
    if ($existing) {
        $proc = Get-Process -Id $existing -ErrorAction SilentlyContinue
        if ($proc -and $proc.ProcessName -eq 'node') {
            if (-not $Quiet) { Write-Host "[DASHBOARD] Port $VitePort in use by PID $existing — reusing" -ForegroundColor Yellow }
        }
    }

    if (-not $Quiet) { Write-Host "[DASHBOARD] Starting Vite on port $VitePort (WS backend → localhost:$WsPort)..." -ForegroundColor Yellow }
    $env:WS_PORT = "$WsPort"
    $env:VITE_DEV_PORT = "$VitePort"
    Start-Process -FilePath "npx.cmd" -ArgumentList "vite", "--host", "--port", "$VitePort" -WorkingDirectory $webAppDir -WindowStyle Hidden -PassThru | ForEach-Object {
        $_.Id | Out-File -FilePath $vitePidFile -Force
    }

    # Wait for Vite
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 1
        try {
            $req = Invoke-WebRequest -Uri "http://localhost:$VitePort/" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($req.StatusCode -eq 200) { break }
        } catch {}
    }
}

function Open-Browser {
    param([int]$VitePort)
    $url = "http://localhost:$VitePort/"
    if (-not $Quiet) { Write-Host "[DASHBOARD] Opening $url" -ForegroundColor Green }
    Start-Process "chrome.exe" -ArgumentList "--new-window", $url -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -ne 0) {
        Start-Process $url
    }
}

# ── Main ──
Show-Header

# Resolve ports
$preferredWs = if ($WsPort -gt 0) { $WsPort } else { 8080 }
$preferredVite = if ($ViteDevPort -gt 0) { $ViteDevPort } else { 5173 }

$selectedWs = Get-FreePort -Preferred $preferredWs
$selectedVite = Get-FreePort -Preferred $preferredVite

# Persist chosen ports
Save-DashboardPorts -WsPort $selectedWs -VitePort $selectedVite

if ($selectedWs -ne $preferredWs -and -not $Quiet) {
    Write-Host "[DASHBOARD] WS port $preferredWs busy → using $selectedWs" -ForegroundColor Yellow
}
if ($selectedVite -ne $preferredVite -and -not $Quiet) {
    Write-Host "[DASHBOARD] Vite port $preferredVite busy → using $selectedVite" -ForegroundColor Yellow
}

if (-not $WSOnly) {
    $nodeModules = Join-Path $webAppDir 'node_modules'
    if (-not (Test-Path $nodeModules)) {
        Write-Host "[DASHBOARD] Installing dependencies..." -ForegroundColor Yellow
        Push-Location $webAppDir
        npm install --silent 2>&1 | Out-Null
        Pop-Location
    }
    Start-ViteDev -WsPort $selectedWs -VitePort $selectedVite
    if (-not $NoBrowser) {
        Open-Browser -VitePort $selectedVite
    }
}

if (-not $ViteOnly) {
    Start-WSServer -Port $selectedWs
}

if (-not $Quiet) {
    Write-Host ""
    Write-Host "✅ Dashboard ready!" -ForegroundColor Green
    Write-Host "   Web:       http://localhost:$selectedVite/" -ForegroundColor White
    Write-Host "   WS API:    http://localhost:$selectedWs/api/metrics" -ForegroundColor White
    Write-Host "   Persisted: .runtime/dashboard-ports.json" -ForegroundColor White
    Write-Host ""
    Write-Host "   Stop with: .\scripts\utilities\dashboard\dashboard-stop.ps1" -ForegroundColor Yellow
}
