#Requires -Version 7.0
<#
.SYNOPSIS
    Dashboard Launcher - Unified menu for all dashboards
.DESCRIPTION
    Launches the React LLM observability dashboard (default), or legacy HTML/console dashboards
.NOTES
    Version: 2.0.0
#>

param(
    [ValidateSet('react', 'web', 'console', 'monitor', 'server', 'all')]
    [string]$Mode = 'react'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Show-Menu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           GENTLE-VANGUARD DASHBOARD LAUNCHER                 ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [0] Dashboard React (LLM Observability)  - RECOMENDADO" -ForegroundColor Green
    Write-Host "  [1] Dashboard Web (HTML legacy)          - 9 secciones (deprecated)" -ForegroundColor Gray
    Write-Host "  [2] Dashboard Consola                    - Reporte ejecutivo en texto" -ForegroundColor White
    Write-Host "  [3] Monitor de Estado                    - Monitoreo continuo" -ForegroundColor White
    Write-Host "  [4] Servidor Web (legacy)                - Servidor con live feed (deprecated)" -ForegroundColor Gray
    Write-Host "  [5] Weekly Metrics                       - Métricas semanales" -ForegroundColor White
    Write-Host "  [6] Cross-Workspace Validator            - Validación multi-workspace" -ForegroundColor White
    Write-Host ""
    Write-Host "  [Q] Salir" -ForegroundColor Gray
    Write-Host ""
}

function Launch-ReactDashboard {
    Write-Host "`n[0] Starting React LLM Observability Dashboard..." -ForegroundColor Cyan
    $startScript = Join-Path $repoRoot 'scripts\utilities\dashboard\dashboard-start.ps1'
    if (Test-Path $startScript) {
        & $startScript
    } else {
        Write-Host "❌ React dashboard script not found: $startScript" -ForegroundColor Red
        Write-Host "   Try: cd apps/web-dashboard && npx vite --host" -ForegroundColor Yellow
    }
}

function Launch-LegacyWebDashboard {
    Write-Host "`n[1] Opening Legacy HTML Dashboard..." -ForegroundColor Cyan
    $dashboardPath = Join-Path $repoRoot 'reports' 'dashboard.html'
    if (Test-Path $dashboardPath) {
        Start-Process $dashboardPath
        Write-Host "✅ Legacy dashboard opened: $dashboardPath" -ForegroundColor Green
    } else {
        Write-Host "❌ Legacy dashboard not found. Use [0] React dashboard instead." -ForegroundColor Yellow
    }
}

function Launch-ConsoleDashboard {
    Write-Host "`n[2] Running Console Dashboard..." -ForegroundColor Cyan
    $execScript = Join-Path $repoRoot 'scripts' 'monitoring' 'executive-dashboard.ps1'
    if (Test-Path $execScript) {
        & $execScript -Mode report -OutputFormat executive -IncludeTokenDetails -IncludeAuditStatus -IncludeGovernance
    } else {
        Write-Host "❌ Script not found: $execScript" -ForegroundColor Red
    }
}

function Launch-StatusMonitor {
    Write-Host "`n[3] Starting Status Monitor..." -ForegroundColor Cyan
    $monitorScript = Join-Path $repoRoot 'scripts' 'monitoring' 'continuous-status-monitor.ps1'
    if (Test-Path $monitorScript) {
        & $monitorScript
    } else {
        Write-Host "❌ Script not found: $monitorScript" -ForegroundColor Red
    }
}

function Launch-LegacyWebServer {
    Write-Host "`n[4] Starting Legacy Web Server..." -ForegroundColor Cyan
    $serverScript = Join-Path $repoRoot 'scripts' 'metrics' 'metrics-server.ps1'
    if (Test-Path $serverScript) {
        Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", $serverScript, "-Port", "8090" -WindowStyle Hidden
        Start-Sleep -Seconds 2
        Start-Process "http://localhost:8090/"
        Write-Host "✅ Legacy server started at http://localhost:8090/ (use [0] React dashboard instead)" -ForegroundColor Green
    } else {
        Write-Host "❌ Script not found: $serverScript" -ForegroundColor Red
    }
}

function Launch-WeeklyMetrics {
    Write-Host "`n[5] Running Weekly Metrics..." -ForegroundColor Cyan
    $weeklyScript = Join-Path $repoRoot 'scripts' 'monitoring' 'weekly-metrics.ps1'
    if (Test-Path $weeklyScript) {
        & $weeklyScript
    } else {
        Write-Host "❌ Script not found: $weeklyScript" -ForegroundColor Red
    }
}

function Launch-CrossWorkspaceValidator {
    Write-Host "`n[6] Running Cross-Workspace Validator..." -ForegroundColor Cyan
    $validatorScript = Join-Path $repoRoot 'scripts' 'monitoring' 'cross-workspace-validator.ps1'
    if (Test-Path $validatorScript) {
        & $validatorScript
    } else {
        Write-Host "❌ Script not found: $validatorScript" -ForegroundColor Red
    }
}

# Main execution
switch ($Mode) {
    'react' { Launch-ReactDashboard }
    'web' { Launch-LegacyWebDashboard }
    'console' { Launch-ConsoleDashboard }
    'monitor' { Launch-StatusMonitor }
    'server' { Launch-LegacyWebServer }
    'all' {
        Show-Menu
        $choice = Read-Host "Selecciona una opción (0-6, Q)"
        switch ($choice) {
            '0' { Launch-ReactDashboard }
            '1' { Launch-LegacyWebDashboard }
            '2' { Launch-ConsoleDashboard }
            '3' { Launch-StatusMonitor }
            '4' { Launch-LegacyWebServer }
            '5' { Launch-WeeklyMetrics }
            '6' { Launch-CrossWorkspaceValidator }
            'Q' { exit }
            default { Write-Host "Opción no válida" -ForegroundColor Red }
        }
    }
}
