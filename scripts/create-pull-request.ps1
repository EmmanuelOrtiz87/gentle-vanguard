# create-pull-request.ps1
# Automatiza la creacion de Pull Requests usando GitHub CLI (gh).
# Diseñado para ser invocado despues de un push exitoso en entornos agnosticos.

param(
    [string]$BaseBranch = "main"
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# El script opera sobre el repositorio donde se encuentre el usuario actualmente.

Write-Host "`n>> Validando automatizacion de Pull Request..." -ForegroundColor Cyan

# 1. Verificar herramienta gh
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] GitHub CLI no detectado. Saltando creacion automatica de PR." -ForegroundColor Gray
    return
}

# 2. Verificar autenticacion
$ghStatus = & gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[INFO] GitHub CLI no autenticado. Saltando creacion automatica de PR." -ForegroundColor Gray
    return
}

# 3. Verificar ramas
$currentBranch = git branch --show-current
if ($currentBranch -eq $BaseBranch) {
    Write-Host "[INFO] La rama actual ya es la rama base ($BaseBranch). No se requiere Pull Request." -ForegroundColor Gray
    return
}

# 4. Proceso de creacion interactivo
if ((Read-Host "¿Deseas crear un Pull Request para fusionar '$currentBranch' en '$BaseBranch'? (s/n)") -eq 's') {
    $title = "Session Update: $currentBranch -> $BaseBranch"
    $body = "Pull Request automatizado generado tras finalizar la sesion de desarrollo.`n`nBase Branch: $BaseBranch`nHead Branch: $currentBranch"
    
    Write-Host "[INFO] Enviando solicitud a GitHub..." -ForegroundColor Cyan
    & gh pr create --base $BaseBranch --head $currentBranch --title "$title" --body "$body"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Pull Request creado y disponible en la plataforma." -ForegroundColor Green
    }
}