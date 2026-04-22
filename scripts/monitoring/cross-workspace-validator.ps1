#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Valida consistencia entre workspace local y foundation.

.DESCRIPTION
    Compara archivos de configuracin y scripts entre workspace-foundation
    y el workspace local para detectar inconsistencias.

.PARAMETER Fix
    Aplicar correcciones automticas cuando sea posible

.PARAMETER Detailed
    Mostrar diferencias detalladas

.EXAMPLE
    .\cross-workspace-validator.ps1
    Valida y muestra inconsistencias

.EXAMPLE
    .\cross-workspace-validator.ps1 -Fix
    Valida y corrige automticamente
#>

param(
    [switch]$Fix,
    [switch]$Detailed
)

$ErrorActionPreference = "Continue"

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    
    $color = switch ($Status) {
        "OK" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Compare-ConfigFiles {
    param(
        [string]$File1,
        [string]$File2,
        [string]$Description
    )
    
    Write-Host "`nValidando: $Description" -ForegroundColor Yellow
    
    if (-not (Test-Path $File1)) {
        Write-Status "Archivo no existe: $File1" "ERROR"
        return $false
    }
    
    if (-not (Test-Path $File2)) {
        Write-Status "Archivo no existe: $File2" "ERROR"
        return $false
    }
    
    $content1 = Get-Content $File1 -Raw
    $content2 = Get-Content $File2 -Raw
    
    if ($content1 -eq $content2) {
        Write-Status "Archivos identicos" "OK"
        return $true
    }
    
    Write-Status "Archivos difieren" "WARN"
    
    if ($Detailed) {
        Write-Host "`nDiferencias:" -ForegroundColor Gray
        $diff = Compare-Object (Get-Content $File1) (Get-Content $File2) -IncludeEqual
        $diff | Where-Object { $_.SideIndicator -ne "==" } | ForEach-Object {
            $indicator = if ($_.SideIndicator -eq "<=") { "LOCAL" } else { "FOUNDATION" }
            Write-Host "  [$indicator] $($_.InputObject)" -ForegroundColor Gray
        }
    }
    
    return $false
}

function Sync-ConfigFile {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    Write-Host "`nSincronizando: $Description" -ForegroundColor Yellow
    
    if (-not (Test-Path $Source)) {
        Write-Status "Archivo origen no existe: $Source" "ERROR"
        return $false
    }
    
    try {
        Copy-Item $Source $Destination -Force
        Write-Status "Sincronizado: $Destination" "OK"
        return $true
    }
    catch {
        Write-Status "Error al sincronizar: $_" "ERROR"
        return $false
    }
}

Write-Host "`n=== Validacion Cross-Workspace ===" -ForegroundColor Cyan
Write-Host "Comparando configuraciones entre local y foundation`n" -ForegroundColor Gray

$validations = @()
$issues = 0

# 1. Context Efficiency Config
$result = Compare-ConfigFiles `
    -File1 "tools/context-efficiency-config.json" `
    -File2 "workspace-foundation/tools/context-efficiency-config.json" `
    -Description "Context Efficiency Config"

$validations += @{
    Name = "Context Efficiency Config"
    Local = "tools/context-efficiency-config.json"
    Foundation = "workspace-foundation/tools/context-efficiency-config.json"
    Status = $result
}

if (-not $result) { $issues++ }

# 2. Session Autostart Config
$result = Compare-ConfigFiles `
    -File1 "tools/session-autostart.config.json" `
    -File2 "workspace-foundation/tools/session-autostart.config.json" `
    -Description "Session Autostart Config"

$validations += @{
    Name = "Session Autostart Config"
    Local = "tools/session-autostart.config.json"
    Foundation = "workspace-foundation/tools/session-autostart.config.json"
    Status = $result
}

if (-not $result) { $issues++ }

# 3. Adaptive Config
if (Test-Path "config/adaptive-config.json") {
    $result = Compare-ConfigFiles `
        -File1 "config/adaptive-config.json" `
        -File2 "workspace-foundation/config/adaptive-config.json" `
        -Description "Adaptive Config"
    
    $validations += @{
        Name = "Adaptive Config"
        Local = "config/adaptive-config.json"
        Foundation = "workspace-foundation/config/adaptive-config.json"
        Status = $result
    }
    
    if (-not $result) { $issues++ }
}

# 4. AGENTS.md
$result = Compare-ConfigFiles `
    -File1 "AGENTS.md" `
    -File2 "workspace-foundation/AGENTS.md" `
    -Description "AGENTS.md"

$validations += @{
    Name = "AGENTS.md"
    Local = "AGENTS.md"
    Foundation = "workspace-foundation/AGENTS.md"
    Status = $result
}

if (-not $result) { $issues++ }

# 5. WF.ps1 Script
if ((Test-Path "scripts/utilities/wf.ps1") -and (Test-Path "workspace-foundation/scripts/utilities/wf.ps1")) {
    $result = Compare-ConfigFiles `
        -File1 "scripts/utilities/wf.ps1" `
        -File2 "workspace-foundation/scripts/utilities/wf.ps1" `
        -Description "Workflow Script (wf.ps1)"
    
    $validations += @{
        Name = "Workflow Script"
        Local = "scripts/utilities/wf.ps1"
        Foundation = "workspace-foundation/scripts/utilities/wf.ps1"
        Status = $result
    }
    
    if (-not $result) { $issues++ }
}

# Summary
Write-Host "`n=== Resumen de Validacion ===" -ForegroundColor Cyan
Write-Host "Total validaciones: $($validations.Count)" -ForegroundColor Gray
Write-Host "Inconsistencias encontradas: $issues" -ForegroundColor $(if ($issues -eq 0) { "Green" } else { "Yellow" })

if ($issues -gt 0) {
    Write-Host "`nArchivos con diferencias:" -ForegroundColor Yellow
    foreach ($val in $validations) {
        if (-not $val.Status) {
            Write-Host "  - $($val.Name)" -ForegroundColor Red
            Write-Host "    Local:      $($val.Local)" -ForegroundColor Gray
            Write-Host "    Foundation: $($val.Foundation)" -ForegroundColor Gray
        }
    }
}

# Fix if requested
if ($Fix -and $issues -gt 0) {
    Write-Host "`n=== Aplicando Correcciones ===" -ForegroundColor Cyan
    Write-Host "Estrategia: Sincronizar desde foundation hacia local`n" -ForegroundColor Gray
    
    $fixed = 0
    foreach ($val in $validations) {
        if (-not $val.Status) {
            if (Sync-ConfigFile -Source $val.Foundation -Destination $val.Local -Description $val.Name) {
                $fixed++
            }
        }
    }
    
    Write-Host "`nArchivos sincronizados: $fixed/$issues" -ForegroundColor $(if ($fixed -eq $issues) { "Green" } else { "Yellow" })
}
elseif ($issues -gt 0) {
    Write-Host "`nPara corregir automaticamente, ejecuta:" -ForegroundColor Yellow
    Write-Host "  .\scripts\monitoring\cross-workspace-validator.ps1 -Fix" -ForegroundColor Cyan
}

if ($issues -eq 0) {
    Write-Host "`nTodos los archivos estan sincronizados" -ForegroundColor Green
}

exit $(if ($issues -eq 0) { 0 } else { 1 })