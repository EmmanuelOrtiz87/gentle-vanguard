<#
.SYNOPSIS
    Actualiza engram al ultima version siguiendo el procedimiento oficial

.DESCRIPTION
    Procedimiento basado en la documentacion oficial de Engram (README.md):
    1. Detecta y detiene procesos engram (MCP subprocess)
    2. Actualiza binario (go install o copia desde scripts/utilities/)
    3. Reconfigura con `engram setup`
    4. Solicita reinicio del agente

.PARAMETER Source
    Fuente de actualizacion: 'go-install' (default), 'tools-folder', 'github-release'

.PARAMETER TargetPath
    Donde instalar el binario (default: $HOME\bin\engram.exe)

.EXAMPLE
    .\update-engram.ps1 -Source tools-folder
    Copia desde foundation/scripts/utilities/ a $HOME\bin\

.EXAMPLE
    .\update-engram.ps1 -Source go-install
    Usa go install para compilar desde fuente
#>
param(
    [ValidateSet('go-install', 'tools-folder', 'github-release')]
    [string]$Source = 'tools-folder',
    
    [string]$TargetPath = "$HOME\bin\engram.exe",
    
    [switch]$SkipSetup
)

$ErrorActionPreference = "Stop"

Write-Host "[ENGRAM UPDATE] Procedimiento oficial basado en README.md" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Paso 1: Detener procesos engram (MCP subprocesses)
Write-Host "`n[1/4] Deteniendo procesos engram..." -ForegroundColor Yellow

$processes = Get-Process -Name "engram" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "  Procesos encontrados: $($processes.Count)" -ForegroundColor Gray
    foreach ($p in $processes) {
        Write-Host "    PID $($p.Id) - $($p.Path)" -ForegroundColor Gray
    }
    
    $response = Read-Host "  ?Detener todos los procesos engram? (S/N)" 
    if ($response -match '^[Ss]') {
        foreach ($p in $processes) {
            try {
                Stop-Process -Id $p.Id -Force
                Write-Host "    [OK] Proceso $($p.Id) detenido" -ForegroundColor Green
            } catch {
                Write-Host "    [ERROR] No se pudo detener $($p.Id): $_" -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 2
    } else {
        Write-Host "  [WARN] Actualizacion cancelada - procesos activos pueden bloquear el archivo" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  [OK] No hay procesos engram corriendo" -ForegroundColor Green
}

# Paso 2: Actualizar binario
Write-Host "`n[2/4] Actualizando binario..." -ForegroundColor Yellow

$backupPath = "$TargetPath.backup"
$newBinary = $null

switch ($Source) {
    'go-install' {
        Write-Host "  Ejecutando: go install github.com/foundation/engram/cmd/engram@latest" -ForegroundColor Gray
        try {
            go install github.com/foundation/engram/cmd/engram@latest
            $newBinary = "$env:USERPROFILE\go\bin\engram.exe"
            if (Test-Path $newBinary) {
                Copy-Item $newBinary $TargetPath -Force
                Write-Host "  [OK] Binario actualizado via go install" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [ERROR] go install fallo: $_" -ForegroundColor Red
            exit 1
        }
    }
    
    'tools-folder' {
        $sourceBinary = ".\foundation\\tools\engram.exe"
        if (-not (Test-Path $sourceBinary)) {
            Write-Host "  [ERROR] No se encuentra: $sourceBinary" -ForegroundColor Red
            exit 1
        }
        
        if (Test-Path $TargetPath) {
            Copy-Item $TargetPath $backupPath -Force
            Write-Host "  [INFO] Backup creado: $backupPath" -ForegroundColor Gray
        }
        
        Copy-Item $sourceBinary $TargetPath -Force
        Write-Host "  [OK] Copiado desde scripts/utilities/engram.exe" -ForegroundColor Green
        $newBinary = $TargetPath
    }
    
    'github-release' {
        Write-Host "  [INFO] Descargando desde GitHub Releases..." -ForegroundColor Gray
        Write-Host "  Ve a: https://github.com/foundation/engram/releases" -ForegroundColor Cyan
        Write-Host "  Descarga engram_*_windows_amd64.zip y extrae engram.exe" -ForegroundColor Cyan
        Read-Host "  Presiona Enter cuando hayas copiado engram.exe a $TargetPath"
    }
}

# Verificar nueva version
if (Test-Path $TargetPath) {
    $version = & $TargetPath --version 2>&1 | Select-String -Pattern '\d+\.\d+\.\d+'
    Write-Host "  [OK] Nueva version: $version" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] No se encuentra el binario en: $TargetPath" -ForegroundColor Red
    exit 1
}

# Paso 3: Reconfigurar agente (engram setup)
if (-not $SkipSetup) {
    Write-Host "`n[3/4] Reconfigurando agente..." -ForegroundColor Yellow
    try {
        & $TargetPath setup opencode
        Write-Host "  [OK] Agente reconfigurado (engram setup opencode)" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] engram setup fallo (quizas OpenCode no esta instalado): $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[3/4] SkipSetup activado - omitiendo reconfiguracion" -ForegroundColor Gray
}

# Paso 4: Instrucciones finales
Write-Host "`n[4/4] !Actualizacion completa!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "`nPASOS FINALES REQUERIDOS:" -ForegroundColor Yellow
Write-Host "  1. Reinicia OpenCode (o tu cliente MCP)" -ForegroundColor White
Write-Host "  2. El nuevo binario se cargara automaticamente" -ForegroundColor White
Write-Host "  3. Verifica con: engram --version" -ForegroundColor White
Write-Host "`nSi usas otro agente (Claude Code, Gemini CLI, etc.):" -ForegroundColor Gray
Write-Host "  Ejecuta: engram setup <agente>" -ForegroundColor Cyan

exit 0
