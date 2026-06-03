#Requires -Version 7.0
<#
.SYNOPSIS
    Dashboard Launcher - Menú unificado para todos los dashboards
.DESCRIPTION
    Lanza el dashboard web, el dashboard de consola, o el monitor de estado
.NOTES
    Version: 1.0.0
#>

param(
    [ValidateSet('web', 'console', 'monitor', 'server', 'all')]
    [string]$Mode = 'web'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Show-Menu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           GENTLE-VANGUARD DASHBOARD LAUNCHER                 ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Dashboard Web (HTML)      - 9 secciones interactivas" -ForegroundColor White
    Write-Host "  [2] Dashboard Consola         - Reporte ejecutivo en texto" -ForegroundColor White
    Write-Host "  [3] Monitor de Estado         - Monitoreo continuo" -ForegroundColor White
    Write-Host "  [4] Servidor Web              - Servidor con live feed" -ForegroundColor White
    Write-Host "  [5] Weekly Metrics            - Métricas semanales" -ForegroundColor White
    Write-Host "  [6] Cross-Workspace Validator - Validación multi-workspace" -ForegroundColor White
    Write-Host ""
    Write-Host "  [Q] Salir" -ForegroundColor Gray
    Write-Host ""
}

function Launch-WebDashboard {
    Write-Host "`n[1] Abriendo Dashboard Web..." -ForegroundColor Cyan
    $dashboardPath = Join-Path $repoRoot 'reports' 'dashboard.html'
    if (Test-Path $dashboardPath) {
        Start-Process $dashboardPath
        Write-Host "✅ Dashboard abierto: $dashboardPath" -ForegroundColor Green
    } else {
        Write-Host "❌ Dashboard no encontrado. Generando..." -ForegroundColor Red
        $renderScript = Join-Path $repoRoot 'scripts' 'metrics' 'dashboard-render.ps1'
        if (Test-Path $renderScript) {
            & $renderScript
            Start-Process $dashboardPath
        }
    }
}

function Launch-ConsoleDashboard {
    Write-Host "`n[2] Ejecutando Dashboard de Consola..." -ForegroundColor Cyan
    $execScript = Join-Path $repoRoot 'scripts' 'monitoring' 'executive-dashboard.ps1'
    if (Test-Path $execScript) {
        & $execScript -Mode report -OutputFormat executive -IncludeTokenDetails -IncludeAuditStatus -IncludeGovernance
    } else {
        Write-Host "❌ Script no encontrado: $execScript" -ForegroundColor Red
    }
}

function Launch-StatusMonitor {
    Write-Host "`n[3] Iniciando Monitor de Estado..." -ForegroundColor Cyan
    $monitorScript = Join-Path $repoRoot 'scripts' 'monitoring' 'continuous-status-monitor.ps1'
    if (Test-Path $monitorScript) {
        & $monitorScript
    } else {
        Write-Host "❌ Script no encontrado: $monitorScript" -ForegroundColor Red
    }
}

function Launch-WebServer {
    Write-Host "`n[4] Iniciando Servidor Web..." -ForegroundColor Cyan
    $serverScript = Join-Path $repoRoot 'scripts' 'metrics' 'metrics-server.ps1'
    if (Test-Path $serverScript) {
        Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", $serverScript, "-Port", "8090" -WindowStyle Hidden
        Start-Sleep -Seconds 2
        Start-Process "http://localhost:8090/"
        Write-Host "✅ Servidor iniciado en http://localhost:8090/" -ForegroundColor Green
    } else {
        Write-Host "❌ Script no encontrado: $serverScript" -ForegroundColor Red
    }
}

function Launch-WeeklyMetrics {
    Write-Host "`n[5] Ejecutando Weekly Metrics..." -ForegroundColor Cyan
    $weeklyScript = Join-Path $repoRoot 'scripts' 'monitoring' 'weekly-metrics.ps1'
    if (Test-Path $weeklyScript) {
        & $weeklyScript
    } else {
        Write-Host "❌ Script no encontrado: $weeklyScript" -ForegroundColor Red
    }
}

function Launch-CrossWorkspaceValidator {
    Write-Host "`n[6] Ejecutando Cross-Workspace Validator..." -ForegroundColor Cyan
    $validatorScript = Join-Path $repoRoot 'scripts' 'monitoring' 'cross-workspace-validator.ps1'
    if (Test-Path $validatorScript) {
        & $validatorScript
    } else {
        Write-Host "❌ Script no encontrado: $validatorScript" -ForegroundColor Red
    }
}

# Main execution
switch ($Mode) {
    'web' { Launch-WebDashboard }
    'console' { Launch-ConsoleDashboard }
    'monitor' { Launch-StatusMonitor }
    'server' { Launch-WebServer }
    'all' {
        Show-Menu
        $choice = Read-Host "Selecciona una opción (1-6, Q)"
        switch ($choice) {
            '1' { Launch-WebDashboard }
            '2' { Launch-ConsoleDashboard }
            '3' { Launch-StatusMonitor }
            '4' { Launch-WebServer }
            '5' { Launch-WeeklyMetrics }
            '6' { Launch-CrossWorkspaceValidator }
            'Q' { exit }
            default { Write-Host "Opción no válida" -ForegroundColor Red }
        }
    }
}

Write-Host "`nPresiona cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
