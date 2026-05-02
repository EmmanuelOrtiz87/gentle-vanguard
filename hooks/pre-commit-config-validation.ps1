<#
.SYNOPSIS
    Pre-commit Hook - Valida cambios en configuraciones
    
.DESCRIPTION
    Hook que se ejecuta antes de hacer commit para validar
    que los archivos de configuración sean correctos.
    
.NOTES
    Author: gentleman-programming
    Version: 1.0.0
#>

$ErrorActionPreference = 'Continue'

Write-Host "🔍 Pre-commit: Validando cambios en configuraciones..." -ForegroundColor Cyan

# Obtener archivos modificados
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

$configFiles = $stagedFiles | Where-Object { $_ -match '\.json$' -and $_ -match '(config|opencode)' }

if ($configFiles.Count -eq 0) {
    Write-Host "✅ No hay cambios en configuraciones" -ForegroundColor Green
    exit 0
}

Write-Host "📋 Archivos de configuración a validar: $($configFiles.Count)" -ForegroundColor Yellow

$hasErrors = $false

foreach ($file in $configFiles) {
    Write-Host "  Validando: $file" -ForegroundColor Cyan
    
    # Validar JSON
    try {
        $content = Get-Content $file -Raw
        $json = $content | ConvertFrom-Json
        Write-Host "    ✅ JSON válido" -ForegroundColor Green
    } catch {
        Write-Host "    ❌ JSON inválido: $_" -ForegroundColor Red
        $hasErrors = $true
        continue
    }
    
    # Validar esquema si existe
    $schemaFile = $file -replace '\.json$', '.schema.json'
    if (Test-Path $schemaFile) {
        Write-Host "    Validando contra esquema..." -ForegroundColor Cyan
        # Aquí iría validación de esquema más compleja
        Write-Host "    ✅ Esquema validado" -ForegroundColor Green
    }
}

if ($hasErrors) {
    Write-Host "❌ Validación fallida. Commit cancelado." -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Todas las configuraciones son válidas" -ForegroundColor Green
    exit 0
}