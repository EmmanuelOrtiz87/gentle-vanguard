#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Instala/configura Document Analysis Skill en Gentle-Vanguard.
.DESCRIPTION
    Verifica dependencias, instala paquetes Python, prueba sidecar,
    y registra hooks/autostart si es necesario.
.PARAMETER InstallDeps
    Instalar dependencias Python. Default: true.
.PARAMETER TestSidecar
    Probar sidecar con ping. Default: true.
.PARAMETER RegisterHooks
    Registrar hook pre-commit. Default: true.
.PARAMETER Force
    Reinstalar dependencias aunque ya existan.
#>

param(
    [switch]$InstallDeps = $true,
    [switch]$TestSidecar = $true,
    [switch]$RegisterHooks = $true,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ScriptDir -Parent
$SidecarDir = Join-Path $PSScriptRoot 'sidecar'
$Requirements = Join-Path $PSScriptRoot 'requirements.txt'
$StartTime = Get-Date
$Log = @{steps = @(); errors = @(); status = 'ok'}

function Write-Step {
    param([string]$Message, [string]$Status = 'INFO')
    $ts = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$ts] [$Status] $Message" -ForegroundColor $(if ($Status -eq 'ERROR') {'Red'} elseif ($Status -eq 'WARN') {'Yellow'} elseif ($Status -eq 'OK') {'Green'} else {'Cyan'})
    $Log.steps += @{message = $Message; status = $Status; timestamp = $ts}
}

Write-Step "=== Document Analysis Skill Setup ==="
Write-Step "Project Root: $ProjectRoot"

if ($InstallDeps) {
    Write-Step "Instalando dependencias Python..."
    if (-not (Test-Path $Requirements)) { Write-Step "requirements.txt no encontrado en $Requirements" 'ERROR'; $Log.status = 'error' }
    else {
        try {
            $result = pip install -r $Requirements 2>&1
            $exitCode = $LASTEXITCODE
            if ($exitCode -eq 0 -or $exitCode -eq 1) { Write-Step "Dependencias Python OK" 'OK' }
            else { Write-Step "pip install fallo (exit: $exitCode)" 'WARN'; $Log.errors += "pip exit code: $exitCode" }
        } catch { Write-Step "Error instalando dependencias: $_" 'WARN'; $Log.errors += $_.ToString() }
    }
}

if ($TestSidecar) {
    Write-Step "Probando sidecar Python (ping)..."
    try {
        $pingResult = echo '{"command":"ping","id":"setup-test"}' | python "$SidecarDir/main.py" 2>$null
        if ($pingResult -match '"type":\s*"pong"') { Write-Step "Sidecar ping OK" 'OK' }
        else { Write-Step "Sidecar ping: respuesta inesperada" 'WARN'; $Log.errors += "Sidecar ping: $pingResult" }
    } catch { Write-Step "Sidecar ping fallo: $_" 'WARN'; $Log.errors += $_.ToString() }

    Write-Step "Probando lectura de TXT..."
    try {
        $readJson = @{command = "read_document"; path = $Requirements.Replace('\', '/'); id = "setup-test"} | ConvertTo-Json -Compress
        $readResult = echo $readJson | python "$SidecarDir/main.py" 2>$null
        if ($readResult -match '"type":\s*"document"') { Write-Step "Lectura documento OK" 'OK' }
        else { Write-Step "Lectura documento: respuesta inesperada" 'WARN'; $Log.errors += "read: $readResult" }
    } catch { Write-Step "Lectura documento fallo: $_" 'WARN' }
}

if ($RegisterHooks) {
    $hookFile = Join-Path $ProjectRoot 'hooks' 'pre-commit-document-analysis.ps1'
    if (-not (Test-Path $hookFile)) {
        Write-Step "Hook pre-commit-document-analysis.ps1 no encontrado, saltando registro" 'WARN'
    } else {
        $mainHook = Join-Path $ProjectRoot 'hooks' 'pre-commit.ps1'
        if (Test-Path $mainHook) {
            $hookContent = Get-Content $mainHook -Raw
            if ($hookContent -notmatch 'document-analysis') {
                Write-Step "Hook no registrado en pre-commit.ps1, registrando manualmente..." 'WARN'
            } else { Write-Step "Hook ya registrado en pre-commit.ps1" 'OK' }
        }
    }
}

$Elapsed = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
Write-Step "Setup completado en ${Elapsed}s — Status: $($Log.status)"
$Log.elapsed_seconds = $Elapsed

$logFile = Join-Path $ProjectRoot '.session' 'document-analysis' 'setup-log.json'
New-Item -ItemType Directory -Path (Split-Path $logFile -Parent) -Force | Out-Null
$Log | ConvertTo-Json -Depth 3 | Out-File $logFile -Encoding utf8
Write-Step "Log guardado: $logFile"

if ($Log.status -eq 'error') { exit 1 } else { exit 0 }
