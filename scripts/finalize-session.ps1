# finalize-session.ps1 (Foundation)
# Automatiza la validacion, persistencia en Engram y subida a la rama foundation-base.

param(
    [string]$GitUser,
    [string]$GitEmail
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $projectRoot

$targetBranch = "foundation-base"

Write-Host ">> Iniciando cierre de sesion para Foundation..." -ForegroundColor Cyan

# 0. Verificar e inicializar repositorio Git si no existe
if (-not (Test-Path (Join-Path $projectRoot ".git"))) {
    Write-Host "[!] No se detecto un repositorio Git en la raiz del proyecto." -ForegroundColor Yellow
    $confirmInit = Read-Host "¿Deseas inicializar un nuevo repositorio Git ahora? (s/n)"
    if ($confirmInit -eq 's') {
        git init
        git checkout -b $targetBranch
        Write-Host "[OK] Repositorio Git inicializado en la rama '$targetBranch'." -ForegroundColor Green
    } else {
        Write-Error "No se puede continuar con la publicacion sin un repositorio Git."
        exit 1
    }
}

# 1. Aplicar identidad inmediatamente si se pasan parametros (globalmente)
if (-not [string]::IsNullOrWhiteSpace($GitUser)) { git config --global user.name "$GitUser" }
if (-not [string]::IsNullOrWhiteSpace($GitEmail)) { git config --global user.email "$GitEmail" }

# 2. Verificar/Solicitar si falta configuracion y asegurar que este configurado localmente
while ([string]::IsNullOrWhiteSpace($(git config user.name 2>$null))) {
    Write-Host "[!] Git user.name no detectado." -ForegroundColor Yellow
    $inputUser = Read-Host "Ingresa tu nombre completo para Git (o 'exit' para cancelar)"
    if ($inputUser -eq "exit") { exit 1 }
    if (-not [string]::IsNullOrWhiteSpace($inputUser)) {
        git config --global user.name "$inputUser"
        git config user.name "$inputUser"
    }
}

while ([string]::IsNullOrWhiteSpace($(git config user.email 2>$null))) {
    Write-Host "[!] Git user.email no detectado." -ForegroundColor Yellow
    $inputEmail = Read-Host "Ingresa tu correo electronico para Git (o 'exit' para cancelar)"
    if ($inputEmail -eq "exit") { exit 1 }
    if (-not [string]::IsNullOrWhiteSpace($inputEmail)) {
        git config --global user.email "$inputEmail"
        git config user.email "$inputEmail"
    }
}

# 1. Validar e integrar cambios en la memoria de Engram
& (Join-Path $scriptDir "validate-project.ps1")

# 2. Git Workflow
Write-Host "`n>> Versionando en Git (Branch: foundation-base)..." -ForegroundColor Cyan

# Asegurar que estamos en la rama correcta (incluso en repos nuevos)
if (git branch --list $targetBranch) {
    git checkout -q $targetBranch
} else {
    # Si es un repo nuevo sin commits, intentamos crearla
    # Si falla porque no hay HEAD, git lo manejara en el commit inicial
    git checkout -q -b $targetBranch 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "Preparando rama inicial: $targetBranch" -ForegroundColor Yellow }
}

# Verificar existencia de remoto origin
if (-not (git remote | Select-String "origin")) {
    Write-Host "[!] No se encontro el remoto 'origin'." -ForegroundColor Yellow
    $remoteUrl = Read-Host "Ingresa la URL de tu repositorio remoto (ej. https://github.com/user/repo.git)"
    while ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        $remoteUrl = Read-Host "La URL es obligatoria para sincronizar. Ingresala (o 'skip' para no subir nada)"
        if ($remoteUrl -eq "skip") { break }
    }
    if (-not [string]::IsNullOrWhiteSpace($remoteUrl) -and $remoteUrl -ne "skip") {
        git remote add origin $remoteUrl
        Write-Host "Remoto 'origin' configurado correctamente." -ForegroundColor Green
    }
}

git add .

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$tagName = "foundation-v$(Get-Date -Format 'yyyy.MM.dd-HHmm')"
$msg = "chore: foundation base update - session $timestamp"

git commit -m $msg 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "No se pudo realizar el commit (posiblemente no hay cambios o error de configuracion)."
    exit 1
}

# Crear tag solo si el commit fue exitoso y hay un HEAD valido
if ($LASTEXITCODE -eq 0 -and (git rev-parse HEAD 2>$null)) {
    git tag -a $tagName -m "Release $tagName - Session $timestamp" 2>$null
}

Write-Host "`n>> Sincronizando con Repositorio Remoto..." -ForegroundColor Cyan

if (git remote | Select-String "origin") {
    # Determinar si necesitamos --set-upstream para el primer push
    $upstream = git config "branch.$targetBranch.remote" 2>$null
    if (-not $upstream) {
        Write-Host "[INFO] Upstream branch no configurada para '$targetBranch'. Intentando con '--set-upstream'." -ForegroundColor Yellow
        git push -u origin $targetBranch --tags 2>$null
    } else {
        git push origin $targetBranch --tags 2>$null
    }

    if ($LASTEXITCODE -ne 0) { Write-Warning "Error al hacer push. Verifica que tengas permisos en el repositorio remoto." }
} else {
    Write-Warning "Sincronizacion saltada: No hay un remoto 'origin' configurado."
}

Write-Host ""
Write-Host "[OK] Sesion finalizada y guardada con exito en Foundation." -ForegroundColor Green