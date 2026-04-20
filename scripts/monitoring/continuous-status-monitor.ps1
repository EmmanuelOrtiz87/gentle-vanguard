#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Monitoreo continuo del estado del workspace.

.DESCRIPTION
    Ejecuta wf.ps1 status periódicamente y genera reportes de estado.
    Puede ejecutarse como tarea programada o en modo continuo.

.PARAMETER OutputPath
    Ruta del archivo de reporte. Por defecto: logs/status-report.txt

.PARAMETER Interval
    Intervalo en minutos entre ejecuciones (solo en modo continuo). Por defecto: 60

.PARAMETER Continuous
    Ejecutar en modo continuo (loop infinito)

.PARAMETER Once
    Ejecutar una sola vez y salir

.EXAMPLE
    .\continuous-status-monitor.ps1 -Once
    Ejecuta una vez y genera reporte

.EXAMPLE
    .\continuous-status-monitor.ps1 -Continuous -Interval 30
    Ejecuta cada 30 minutos en modo continuo
#>

param(
    [string]$OutputPath = "logs/status-report.txt",
    [int]$Interval = 60,
    [switch]$Continuous,
    [switch]$Once
)

$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $OutputPath -Value $logMessage
}

function Get-WorkspaceStatus {
    Write-Log "Ejecutando verificacion de estado del workspace..."
    
    $statusOutput = & ".\scripts\utilities\wf.ps1" status 2>&1
    
    return $statusOutput
}

function Generate-StatusReport {
    $reportPath = $OutputPath
    $reportDir = Split-Path -Parent $reportPath
    
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Log "=== Reporte de Estado del Workspace ===" "REPORT"
    Write-Log "Timestamp: $timestamp" "REPORT"
    Write-Log "" "REPORT"
    
    try {
        $status = Get-WorkspaceStatus
        
        foreach ($line in $status) {
            Add-Content -Path $reportPath -Value $line
        }
        
        Write-Log "" "REPORT"
        Write-Log "Reporte generado exitosamente en: $reportPath" "SUCCESS"
        
        return $true
    }
    catch {
        Write-Log "Error al generar reporte: $_" "ERROR"
        return $false
    }
}

function Register-ScheduledTask {
    Write-Log "Registrando tarea programada..." "INFO"
    
    $taskName = "WorkspaceStatusMonitor"
    $scriptPath = $PSCommandPath
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -Once"
    $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Log "Tarea programada existente eliminada" "INFO"
        }
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Monitoreo continuo del estado del workspace"
        Write-Log "Tarea programada registrada: $taskName" "SUCCESS"
        Write-Log "Se ejecutara diariamente a las 09:00" "INFO"
    }
    catch {
        Write-Log "Error al registrar tarea programada: $_" "ERROR"
    }
}

Write-Host "`n=== Monitor de Estado Continuo del Workspace ===" -ForegroundColor Cyan
Write-Host "Ruta de reporte: $OutputPath" -ForegroundColor Gray

if ($Once) {
    Write-Host "Modo: Ejecucion unica" -ForegroundColor Yellow
    Generate-StatusReport
}
elseif ($Continuous) {
    Write-Host "Modo: Continuo (intervalo: $Interval minutos)" -ForegroundColor Yellow
    Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Gray
    
    while ($true) {
        Generate-StatusReport
        Write-Host "`nProxima ejecucion en $Interval minutos..." -ForegroundColor Gray
        Start-Sleep -Seconds ($Interval * 60)
    }
}
else {
    Write-Host "Modo: Configuracion de tarea programada" -ForegroundColor Yellow
    Register-ScheduledTask
    Write-Host "`nPara ejecutar manualmente:" -ForegroundColor Yellow
    Write-Host "  .\scripts\monitoring\continuous-status-monitor.ps1 -Once" -ForegroundColor Cyan
}

Write-Host "`nMonitoreo configurado exitosamente" -ForegroundColor Green