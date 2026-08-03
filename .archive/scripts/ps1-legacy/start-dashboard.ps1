#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Inicia el dashboard Gentle-Vanguard completo (WebSocket + Vite)
.DESCRIPTION
    Script unificado que inicia ambos servicios del dashboard
#>

$ErrorActionPreference = "Stop"

$WS_PORT = "8080"
$VITE_PORT = "5173"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  DASHBOARD GENTLE-VANGUARD" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar directorio
$dashboardDir = Join-Path $PSScriptRoot "."
if (-not (Test-Path (Join-Path $dashboardDir "package.json"))) {
    Write-Error "Ejecutar desde apps/web-dashboard"
    exit 1
}

Write-Host "[1/3] Matando procesos anteriores..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CommandLine -like "*websocket*" -or $_.CommandLine -like "*vite*" } | 
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "[2/3] Iniciando WebSocket Server en puerto $WS_PORT..." -ForegroundColor Green
$wsJob = Start-Job -ScriptBlock {
    param($dir, $port)
    Set-Location $dir
    $env:WS_PORT = $port
    & npx tsx server/websocket-server.ts
} -ArgumentList $dashboardDir, $WS_PORT

Write-Host "[3/3] Iniciando Vite Frontend en puerto $VITE_PORT..." -ForegroundColor Green
$viteJob = Start-Job -ScriptBlock {
    param($dir)
    Set-Location $dir
    Start-Sleep -Seconds 3
    & npx vite
} -ArgumentList $dashboardDir

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  DASHBOARD INICIADO" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "WebSocket:  http://localhost:$WS_PORT" -ForegroundColor Cyan
Write-Host "Dashboard:  http://localhost:$VITE_PORT" -ForegroundColor Cyan
Write-Host ""
Write-Host "Logs:" -ForegroundColor Yellow
Write-Host "  WebSocket: Get-Job $($wsJob.Id) | Receive-Job" -ForegroundColor Gray
Write-Host "  Vite:      Get-Job $($viteJob.Id) | Receive-Job" -ForegroundColor Gray
Write-Host ""
Write-Host "Para detener: Get-Job | Stop-Job" -ForegroundColor Yellow
Write-Host ""

# Mantener los jobs en foreground
while ($true) {
    Start-Sleep -Seconds 5
    $wsStatus = Get-Job -Id $wsJob.Id -ErrorAction SilentlyContinue
    $viteStatus = Get-Job -Id $viteJob.Id -ErrorAction SilentlyContinue
    
    if (-not $wsStatus -or -not $viteStatus) {
        Write-Host "Un proceso ha terminado. Presiona Ctrl+C para salir."
        break
    }
}
