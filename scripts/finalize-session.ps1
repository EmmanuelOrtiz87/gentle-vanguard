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

# Verificar e informar sobre el remoto actual
$currentRemote = git remote get-url origin 2>$null
if ($currentRemote) {
    Write-Host "[INFO] Remoto 'origin' actual: $currentRemote" -ForegroundColor Gray
    $changeRemote = Read-Host "¿Deseas cambiar la URL del remoto? (s/n)"
    if ($changeRemote -eq 's') {
        git remote remove origin
        Write-Host "Remoto eliminado. Se solicitara uno nuevo." -ForegroundColor Yellow
    }
}

# Verificar existencia de remoto origin
if (-not (git remote | Select-String "origin")) {
    Write-Host "[!] No se encontro el remoto 'origin'." -ForegroundColor Yellow
    Write-Host "Si no has creado el repositorio en la nube, hazlo ahora en GitHub o Bitbucket." -ForegroundColor Gray
    
    $remoteUrl = ""
    while ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        $input = Read-Host "Ingresa la URL del repositorio (ej. https://github.com/usuario/repo.git) o solo el NOMBRE del repo"
        if ($input -eq "skip") { $remoteUrl = "skip"; break }
        
        # Inteligencia: Si no hay '/' o ':', asumimos que es un nombre de repo y sugerimos URL basada en el usuario actual
        if ($input -notmatch "/" -and $input -notmatch ":") {
            $gitUser = git config user.name 2>$null
            if ([string]::IsNullOrWhiteSpace($gitUser)) { $gitUser = "usuario" }
            $remoteUrl = "https://github.com/$gitUser/$input.git"
            Write-Host "Sugerencia de URL generada: $remoteUrl" -ForegroundColor Gray
            $confirm = Read-Host "¿Es esta la URL correcta? (s/n)"
            if ($confirm -ne 's') { $remoteUrl = ""; continue }
        } else {
            $remoteUrl = $input
        }

        if ($remoteUrl -notmatch "\.git$" -and $remoteUrl -notmatch "git@" -and $remoteUrl -ne "skip") {
            Write-Warning "La URL no parece un repositorio Git valido (deberia terminar en .git)."
            $confirm = Read-Host "¿Deseas usarla de todos modos? (s/n)"
            if ($confirm -ne 's') { $remoteUrl = "" }
        }
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

# Realizar commit solo si hay cambios detectados
$hasChanges = git status --porcelain
if ($hasChanges) {
    git commit -m $msg 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "No se pudo realizar el commit. Verifica la configuracion de Git."
        exit 1
    }

    # Crear tag solo si el commit fue exitoso y hay un HEAD valido
    if (git rev-parse HEAD 2>$null) {
        git tag -a $tagName -m "Release $tagName - Session $timestamp" 2>$null
        Write-Host "[OK] Commit y Tag ($tagName) creados exitosamente." -ForegroundColor Green
    }
} else {
    Write-Host "[INFO] No hay cambios para confirmar en esta sesion." -ForegroundColor Gray
}

Write-Host "`n>> Sincronizando con Repositorio Remoto..." -ForegroundColor Cyan

$pushSuccess = $false
while (-not $pushSuccess) {
    if (git remote | Select-String "origin") {
        # Determinar si necesitamos --set-upstream para el primer push
        $upstream = git config "branch.$targetBranch.remote" 2>$null
        if (-not $upstream) {
            Write-Host "[INFO] Upstream branch no configurada para '$targetBranch'. Intentando con '--set-upstream'." -ForegroundColor Yellow
            git push -u origin $targetBranch --tags 2>$null
        } else {
            git push origin $targetBranch --tags 2>$null
        }

        if ($LASTEXITCODE -eq 0) {
            $pushSuccess = $true
        } else {
            Write-Warning "Error al hacer push. La URL es invalida, el repositorio no existe o no tienes permisos."
            Write-Host "URL actual detectada: $(git remote get-url origin)" -ForegroundColor Gray
            $action = Read-Host "¿Que deseas hacer? (r) Reintentar con otra URL, (s) Saltar sincronizacion, (c) Cancelar"
            
            if ($action -eq 'r') {
                git remote remove origin
                $newUrl = Read-Host "Ingresa la URL correcta del repositorio (.git)"
                if (-not [string]::IsNullOrWhiteSpace($newUrl)) { git remote add origin $newUrl }
            } elseif ($action -eq 's') {
                Write-Warning "Sincronizacion saltada por el usuario."
                break
            } else {
                exit 1
            }
        }
    }
} else {
    Write-Warning "Sincronizacion saltada: No hay un remoto 'origin' configurado."
}

Write-Host ""
Write-Host "[OK] Sesion finalizada y guardada con exito en Foundation." -ForegroundColor Green