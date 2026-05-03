<#
.SYNOPSIS
    Clear Context - Limpia el contexto entre tareas sin cerrar sesin
    
.DESCRIPTION
    Guarda un resumen de la tarea actual en Engram y limpia el estado
    para evitar que el contexto anterior viaje a la siguiente tarea.
    
    Similar a cerrar sesin pero sin terminar la sesin actual.
    
.PARAMETER TaskSummary
    Resumen breve de la tarea que se est cerrando
    
.PARAMETER ProjectName
    Nombre del proyecto (default: workspace_local)
    
.EXAMPLE
    .\tools\clear-context.ps1 -TaskSummary "Corregidas inconsistencias de inicio"
    
.NOTES
    Author: gentleman-programming
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$TaskSummary = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentleman-foundation"
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Funcin para logging coloreado
function Write-Step {
    param([string]$Message)
    Write-Host "[CLEAR] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

Write-Step "Iniciando limpieza de contexto..."
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray

# 1. Guardar resumen de la tarea en Engram (persistir aprendizajes)
if ($TaskSummary -ne "") {
    Write-Step "Guardando resumen de tarea en Engram..."
    $engramBin = Join-Path $scriptDir "engram.exe"
    
    if (Test-Path $engramBin) {
        $summaryContent = @"
## Task Completed
$TaskSummary

## Timestamp
$timestamp

## Context Cleared
Context cleared for next task. Previous context preserved in Engram.
"@
        
        & $engramBin save --title "Context Clear: $TaskSummary" --content $summaryContent --project $ProjectName --type manual 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Resumen guardado en Engram"
        } else {
            Write-WarningMsg "No se pudo guardar en Engram (cdigo: $LASTEXITCODE)"
        }
    } else {
        Write-WarningMsg "Engram no encontrado en: $engramBin"
    }
}

# 2. Limpiar archivos de estado de sesin temporal
Write-Step "Limpiando archivos de estado temporal..."
$sessionFiles = @(
    ".\.session\.context-clear-requested",
    ".\logs\.session-active",
    ".\.session\token-guard-state.json"
)

foreach ($file in $sessionFiles) {
    if (Test-Path $file) {
        try {
            Remove-Item $file -Force -ErrorAction Stop
            Write-Host "  Eliminado: $file" -ForegroundColor Gray
        } catch {
            Write-WarningMsg "No se pudo eliminar: $file"
        }
    }
}

# 3. Ejecutar handoff-compress para preparar transferencia limpia
Write-Step "Ejecutando compresin de transferencia..."
$handoffScript = Join-Path $scriptDir "handoff-compress.ps1"
if (Test-Path $handoffScript) {
    & $handoffScript -ProjectName $ProjectName -CompressionRatio 0.30 2>$null
    Write-Success "Compresin de transferencia completada"
} else {
    Write-WarningMsg "handoff-compress.ps1 no encontrado"
}

# 4. Limpiar mtricas de sesin actual (opcional)
Write-Step "Limpiando mtricas de sesin actual..."
$metricsDir = ".\.session\metrics"
if (Test-Path $metricsDir) {
    $currentMetrics = Get-ChildItem $metricsDir -Filter "session-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    # Mantener las ltimas 3 mtricas, eliminar el resto
    # (opcional - comentado por seguridad)
    # $currentMetrics | ForEach-Object { Remove-Item $_.FullName -Force }
}

# 5. Marcar contexto como limpio
$cleanMarker = ".\.session\.context-cleared"
$timestamp | Out-File -FilePath $cleanMarker -Force
Write-Success "Marcador de contexto limpio creado"

# 6. Mostrar resumen
Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "CONTEXTO LIMPIO EXITOSAMENTE" -ForegroundColor Green -NoNewline
Write-Host " " -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "Contexto anterior guardado en Engram" -ForegroundColor Gray
Write-Host "Nueva tarea puede iniciar sin contexto heredado" -ForegroundColor Gray
Write-Host "Sesin actual sigue activa: " -NoNewline -ForegroundColor Yellow
Write-Host $env:SESSION_ID -ForegroundColor White

if ($TaskSummary -ne "") {
    Write-Host "`nTarea completada: $TaskSummary" -ForegroundColor Cyan
}

exit 0

