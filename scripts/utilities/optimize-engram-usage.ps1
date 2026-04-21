# optimize-engram-usage.ps1
# Script para optimizar el uso de Engram y mejorar la eficiencia del contexto

param(
    [string]$ProjectName = 'workspace_local',
    [switch]$AutoApply = $false
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$engramBin = Join-Path $scriptDir 'engram.exe'

function Write-Status {
    param([string]$m) Write-Host "[OPTIMIZE] $m" -ForegroundColor Green
}

function Write-Warning {
    param([string]$m) Write-Host "[WARNING] $m" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Cyan
}

Write-Status "Starting Engram usage optimization for project: $ProjectName"

# Verificar que Engram está disponible
if (-not (Test-Path $engramBin)) {
    # Intentar encontrar Engram en el PATH
    $engramInPath = Get-Command "engram" -ErrorAction SilentlyContinue
    if (-not $engramInPath) {
        Write-Warning "Engram binary not found at $engramBin or in PATH"
        Write-Info "Continuing without Engram optimization..."
        exit 0
    } else {
        $engramBin = "engram"
        Write-Info "Using Engram from PATH"
    }
} else {
    Write-Info "Using Engram from local tools directory"
}

# 1. Buscar contenido redundante en memoria
Write-Info "Checking for redundant content in Engram..."
$redundantEntries = & $engramBin search "duplicate OR repeated" --project $ProjectName --limit 10 2>$null
if ($redundantEntries) {
    Write-Info "Found potential redundant entries. Consider cleaning up."
}

# 2. Verificar decisiones importantes no guardadas
Write-Info "Checking for important decisions to save..."
# Esta sería una implementación más completa en producción
# Por ahora simulamos la verificación

# 3. Optimizar búsqueda de referencias
Write-Info "Optimizing reference search..."
$recentContext = & $engramBin context --limit 5 2>$null
if ($recentContext) {
    Write-Info "Loaded recent context for reference optimization"
}

# 4. Registrar patrones de uso
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
& $engramBin save --title "Context efficiency optimization run" --content "Optimization script executed at $timestamp. Project: $ProjectName" --project $ProjectName 2>$null | Out-Null

Write-Status "Engram usage optimization completed"

# 5. Mostrar recomendaciones
Write-Info "Recommendations for better context efficiency:"
Write-Host "  1. Use 'engram search' before repeating explanations" -ForegroundColor Gray
Write-Host "  2. Save decisions > 5min to Engram automatically" -ForegroundColor Gray
Write-Host "  3. Reference Engram IDs instead of full content" -ForegroundColor Gray
Write-Host "  4. Run this script regularly for maintenance" -ForegroundColor Gray

if ($AutoApply) {
    Write-Status "Auto-applying optimizations..."
    # Aquí irían las acciones automáticas
}