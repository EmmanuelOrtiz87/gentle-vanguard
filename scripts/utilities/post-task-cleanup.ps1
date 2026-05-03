<#
.SYNOPSIS
    Post-Task Cleanup - Limpieza automtica al finalizar tareas de subagentes
    
.DESCRIPTION
    Se ejecuta automticamente cuando un subagente finaliza su tarea.
    Limpia el contexto y deja el sistema listo para una nueva peticin.
    
.PARAMETER TaskName
    Nombre de la tarea que finaliza
    
.PARAMETER AgentType
    Tipo de subagente que ejecut la tarea
    
.EXAMPLE
    .\tools\post-task-cleanup.ps1 -TaskName "Corregir bug" -AgentType "DEV"
    
.NOTES
    Author: gentleman-programming
    Version: 1.0
    Se invoca automticamente desde auto-delegation-router.ps1
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,
    
    [Parameter(Mandatory=$false)]
    [string]$AgentType = "GENERAL",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentleman-foundation"
)

$ErrorActionPreference = 'Continue'
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Step {
    param([string]$Message)
    Write-Host "[POST-TASK] $Message" -ForegroundColor Magenta
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

Write-Step "Iniciando limpieza post-tarea..."
Write-Host "Tarea: $TaskName" -ForegroundColor Cyan
Write-Host "Agente: $AgentType" -ForegroundColor Yellow
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray

# 1. Guardar resumen de tarea en Engram
Write-Step "Guardando resumen en Engram..."
$engramBin = Join-Path $PSScriptRoot "engram.exe"
if (Test-Path $engramBin) {
    $summary = @"
## Task Completed: $TaskName
## Agent Type: $AgentType
## Timestamp: $timestamp

Context cleared automatically after task completion.
Ready for next task.
"@
    & $engramBin save --title "Post-Task Cleanup: $TaskName" --content $summary --project $ProjectName --type manual 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Resumen guardado en Engram"
    }
}

# 2. Ejecutar clear-context.ps1 para limpieza completa
Write-Step "Ejecutando limpieza de contexto..."
$clearScript = Join-Path $PSScriptRoot "clear-context.ps1"
if (Test-Path $clearScript) {
    & $clearScript -TaskSummary "$TaskName (auto-cleanup)" -ProjectName $ProjectName 2>$null
    Write-Success "Contexto limpiado"
} else {
    Write-Host "[WARN] clear-context.ps1 no encontrado" -ForegroundColor Yellow
}

# 3. Limpiar mtricas temporales de la tarea
Write-Step "Limpiando mtricas temporales..."
$metricsFile = ".\.session\task-metrics-$AgentType.json"
if (Test-Path $metricsFile) {
    Remove-Item $metricsFile -Force -ErrorAction SilentlyContinue
    Write-Host "  Eliminado: $metricsFile" -ForegroundColor Gray
}

# 4. Notificar al orchestrator (si existe)
$orchestratorLog = ".\logs\orchestrator-tasks.log"
if (Test-Path (Split-Path $orchestratorLog)) {
    $logEntry = "[$timestamp] TASK_COMPLETED: $TaskName | AGENT: $AgentType | STATUS: CLEANED"
    Add-Content -Path $orchestratorLog -Value $logEntry -ErrorAction SilentlyContinue
}

Write-Host "`n" + ("-" * 50) -ForegroundColor Green
Write-Host "SUBAGENTE LISTO PARA NUEVA TAREA" -ForegroundColor Green
Write-Host ("-" * 50) -ForegroundColor Green

exit 0
