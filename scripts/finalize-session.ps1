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

Write-Host ">> Iniciando cierre de sesion para Foundation..." -ForegroundColor Cyan

# 1. Aplicar identidad inmediatamente si se pasan parametros (globalmente)
if (-not [string]::IsNullOrWhiteSpace($GitUser)) { git config --global user.name "$GitUser" }
if (-not [string]::IsNullOrWhiteSpace($GitEmail)) { git config --global user.email "$GitEmail" }

# 2. Verificar/Solicitar si falta configuracion y asegurar que este configurado localmente
$currentLocalUser = git config user.name 2>$null
$currentLocalEmail = git config user.email 2>$null

if ([string]::IsNullOrWhiteSpace($currentLocalUser)) {
    $globalUser = git config --global user.name 2>$null
    if ([string]::IsNullOrWhiteSpace($globalUser)) {
        $globalUser = Read-Host "Git user.name no configurado (global). Ingresa tu nombre completo"
        if (-not [string]::IsNullOrWhiteSpace($globalUser)) { git config --global user.name "$globalUser" }
    }
    # Asegurar que la configuracion local este establecida si la global esta ahora disponible
    if (-not [string]::IsNullOrWhiteSpace($globalUser)) { git config user.name "$globalUser" }
    $currentLocalUser = $globalUser # Actualizar para comprobaciones posteriores
}

# Similar para el email
if ([string]::IsNullOrWhiteSpace($currentLocalEmail)) {
    $globalEmail = git config --global user.email 2>$null
    if ([string]::IsNullOrWhiteSpace($globalEmail)) {
        $globalEmail = Read-Host "Git user.email no configurado (global). Ingresa tu correo electronico"
        if (-not [string]::IsNullOrWhiteSpace($globalEmail)) { git config --global user.email "$globalEmail" }
    }
    # Asegurar que la configuracion local este establecida si la global esta ahora disponible
    if (-not [string]::IsNullOrWhiteSpace($globalEmail)) { git config user.email "$globalEmail" }
    $currentLocalEmail = $globalEmail # Actualizar para comprobaciones posteriores
}

# Validacion de Identidad Git
if ([string]::IsNullOrWhiteSpace($currentLocalUser) -or [string]::IsNullOrWhiteSpace($currentLocalEmail)) {
    Write-Error "Git identity is required to perform commits. Please configure it or pass as parameters."
    exit 1
}

# 1. Validar e integrar cambios en la memoria de Engram
& (Join-Path $scriptDir "validate-project.ps1")

# 2. Git Workflow
Write-Host "`n>> Versionando en Git (Branch: foundation-base)..." -ForegroundColor Cyan

# Asegurar que estamos en la rama correcta (incluso en repos nuevos)
$targetBranch = "foundation-base"
if (git branch --list $targetBranch) {
    git checkout -q $targetBranch
} else {
    # Si es un repo nuevo sin commits, intentamos crearla
    # Si falla porque no hay HEAD, git lo manejara en el commit inicial
    git checkout -q -b $targetBranch 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "Preparando rama inicial: $targetBranch" -ForegroundColor Yellow }
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

# Determinar si necesitamos --set-upstream para el primer push
$pushOptions = "$targetBranch --tags"
$upstream = git config "branch.$targetBranch.remote" 2>$null
if (-not $upstream) {
    Write-Host "[INFO] Upstream branch no configurada para '$targetBranch'. Intentando con '--set-upstream'." -ForegroundColor Yellow
    $pushOptions = "-u $targetBranch --tags"
}

git push origin $pushOptions 2>$null
if ($LASTEXITCODE -ne 0) { Write-Warning "Error al hacer push. Verifica que el remoto 'origin' este configurado y tengas permisos." }

Write-Host ""
Write-Host "[OK] Sesion finalizada y guardada con exito en Foundation." -ForegroundColor Green