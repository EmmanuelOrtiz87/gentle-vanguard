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
    Write-Host "[!] GitHub CLI (gh) no detectado en el PATH." -ForegroundColor Yellow
    Write-Host "    Si lo acabas de instalar, por favor reinicia tu terminal o VS Code." -ForegroundColor Gray
    return
}

# 2. Verificar autenticacion
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$ghStatus = & gh auth status 2>&1
$ErrorActionPreference = $oldEAP
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] GitHub CLI no autenticado. Por favor, ejecuta: gh auth login" -ForegroundColor Red
    return
}

# 3. Verificar ramas
$currentBranch = git branch --show-current
if ($currentBranch -eq $BaseBranch) {
    Write-Host "[INFO] Estas en la rama '$BaseBranch'. No se puede crear un PR hacia si misma." -ForegroundColor Gray
    Write-Host "       Para crear un PR, debes trabajar en una rama de característica (feature branch)." -ForegroundColor Gray
    return
}

# 4. Verificar si la rama existe en el remoto
$remoteCheck = git ls-remote --heads origin $currentBranch
if (-not $remoteCheck) {
    Write-Host "[!] La rama '$currentBranch' no existe en el remoto 'origin'." -ForegroundColor Yellow
    Write-Host "    Realiza un 'git push' antes de intentar crear el Pull Request." -ForegroundColor Gray
    return
}

# 5. Verificar si ya existe un PR para esta rama
Write-Host "[INFO] Comprobando si ya existe un PR activo para '$currentBranch' a '$BaseBranch'..." -ForegroundColor Gray
# Usamos 'gh pr list' para evitar el mensaje de error "no pull requests found" en stderr.
# Este comando devuelve un array JSON vacío '[]' si no se encuentran PRs, y sale con código 0.
$existingPrsJson = & gh pr list --head $currentBranch --base $BaseBranch --state open --json url 2>$null

$existingPr = $null
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($existingPrsJson) -and $existingPrsJson -ne "[]") {
    try {
        $prObjects = $existingPrsJson | ConvertFrom-Json
        if ($prObjects.Count -gt 0) {
            $existingPr = $prObjects[0].url
        }
    } catch {
        Write-Warning "No se pudo analizar la salida de 'gh pr list': $_"
    }
}

if ($existingPr) {
    Write-Host "[OK] Ya existe un Pull Request para esta rama: $existingPr" -ForegroundColor Green
    if ((Read-Host "¿Deseas abrirlo en el navegador? (s/n)") -eq 's') {
        Start-Process $existingPr
    }
    return
}
Write-Host "[INFO] No se encontraron Pull Requests activos para '$currentBranch' a '$BaseBranch'." -ForegroundColor Gray

# 6. Proceso de creacion interactivo
$confirmation = Read-Host "¿Deseas crear un nuevo Pull Request para fusionar '$currentBranch' en '$BaseBranch'? (s/n)"
if ($confirmation -eq 's') {
    $title = "Session Update: $currentBranch -> $BaseBranch"
    $body = "Pull Request automatizado generado tras finalizar la sesion de desarrollo.`n`nBase Branch: $BaseBranch`nHead Branch: $currentBranch"
    
    Write-Host "[INFO] Enviando solicitud a GitHub..." -ForegroundColor Cyan
    & gh pr create --base $BaseBranch --head $currentBranch --title "$title" --body "$body"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Pull Request creado y disponible en la plataforma." -ForegroundColor Green
    } else {
        Write-Host "[!] Error al crear el Pull Request. Revisa los mensajes de arriba." -ForegroundColor Red
    }
}