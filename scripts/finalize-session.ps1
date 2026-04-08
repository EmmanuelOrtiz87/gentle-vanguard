# finalize-session.ps1 (Foundation)
# Automatiza la validacion, persistencia en Engram, versionado y publicacion.
# Soporta flujos interactivos para:
# 1. Configuracion de identidad Git (user/email).
# 2. Inicializacion de repositorio Git si no existe.
# 3. Creacion de repositorio remoto via GitHub CLI (gh).
# 4. Sincronizacion con reintentos inteligentes y creacion de Pull Requests.

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
        # Intentar inicializar con la rama especificada directamente (Git moderno)
        git init -b $targetBranch 2>$null
        if ($LASTEXITCODE -ne 0) {
            git init
            git checkout -b $targetBranch
        }
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
$currentBranch = git branch --show-current
if ($currentBranch -ne $targetBranch) {
    if (git branch --list $targetBranch) {
        git checkout -q $targetBranch
    } else {
        # En repos nuevos o si la rama no existe, intentamos crearla o renombrar la actual
        git checkout -q -b $targetBranch 2>$null
        if ($LASTEXITCODE -ne 0) { git branch -m $targetBranch 2>$null }
        Write-Host "[INFO] Operando en rama: $targetBranch" -ForegroundColor Yellow
    }
}

# Verificar e informar sobre el remoto actual
if (git remote | Select-String -Quiet "^origin$") {
    $currentRemote = git remote get-url origin 2>$null
    Write-Host "[INFO] Remoto 'origin' actual: $currentRemote" -ForegroundColor Gray
    $changeRemote = Read-Host "El remoto actual podria ser invalido. ¿Deseas eliminarlo para configurar uno nuevo o crearlo en la nube? (s/n)"
    if ($changeRemote -eq 's') {
        git remote remove origin
        Write-Host "Remoto eliminado. Se solicitara uno nuevo." -ForegroundColor Yellow
    }
}

# Verificar existencia de remoto origin
if (-not (git remote | Select-String "origin")) {
    Write-Host "[!] No se encontro el remoto 'origin'." -ForegroundColor Yellow
    
    $remoteUrl = ""

    # Inteligencia: Integracion con GitHub CLI (gh) para creacion automatica
    $ghCli = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCli) {
        $ghStatus = & gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            if ((Read-Host "¿Deseas crear el repositorio automaticamente en GitHub? (s/n)") -eq 's') {
                $repoDefault = Split-Path -Leaf $projectRoot
                $repoName = Read-Host "Nombre del repositorio [$repoDefault]"
                if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = $repoDefault }
                $vis = Read-Host "¿Privacidad? (1) Publico, (2) Privado [Predeterminado: Privado]"
                $visFlag = if ($vis -eq "1") { "--public" } else { "--private" }
                
                Write-Host "[INFO] Creando repositorio '$repoName' en GitHub..." -ForegroundColor Cyan
                & gh repo create $repoName $visFlag --source=. --remote=origin
                if ($LASTEXITCODE -eq 0) { $remoteUrl = "created_by_cli" }
            }
        } else {
            Write-Host "[!] GitHub CLI detectado pero no autenticado." -ForegroundColor Yellow
            if ((Read-Host "¿Deseas iniciar sesion en GitHub ahora para habilitar la creacion automatica? (s/n)") -eq 's') {
                & gh auth login
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Autenticacion exitosa. Reinicia el script para usar la creacion automatica o ingresa la URL manualmente." -ForegroundColor Cyan
                }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        Write-Host "Si no has creado el repositorio en la nube, hazlo ahora en GitHub o Bitbucket." -ForegroundColor Gray
    }

    while ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        $userInput = Read-Host "Ingresa la URL del repositorio (ej. https://github.com/usuario/repo.git) o solo el NOMBRE del repo"
        
        if ($userInput -eq "skip") { $remoteUrl = "skip"; break }
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            Write-Warning "La entrada no puede estar vacia. Intenta de nuevo o escribe 'skip'."
            continue
        }

        # Inteligencia: Si no hay '/' o ':', asumimos que es un nombre de repo y sugerimos URL basada en el usuario actual
        if ($userInput -notmatch "/" -and $userInput -notmatch ":") {
            $gitUser = git config user.name 2>$null
            if ([string]::IsNullOrWhiteSpace($gitUser)) { $gitUser = "usuario" }
            $suggestedUrl = "https://github.com/$gitUser/$userInput.git"
            Write-Host "Sugerencia generada: $suggestedUrl" -ForegroundColor Gray
            $confirm = Read-Host "¿Usar esta URL? (s/n)"
            if ($confirm -eq 's') { $remoteUrl = $suggestedUrl; break }
            continue
        } else {
            # Validacion basica de formato Git (HTTPS o SSH)
            if ($userInput -match "^(https?://|git@|ssh://).+\.git$") {
                $remoteUrl = $userInput
                break
            } else {
                Write-Warning "La URL '$userInput' no parece valida (debe empezar con http/git/ssh y terminar en .git)."
                $confirm = Read-Host "¿Deseas usarla de todos modos? (s/n)"
                if ($confirm -eq 's') { $remoteUrl = $userInput; break }
            }
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

if (git remote | Select-String "origin") {
    $pushSuccess = $false
    $skippedPush = $false
    while (-not $pushSuccess) {
        # Temporariamente permitimos errores para que el bucle de reintento funcione
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'

        # Determinar si necesitamos --set-upstream para el primer push
        $upstream = git config "branch.$targetBranch.remote" 2>$null
        if (-not $upstream) {
            Write-Host "[INFO] Upstream branch no configurada para '$targetBranch'. Intentando con '--set-upstream'." -ForegroundColor Yellow
            git push -u origin $targetBranch --tags
        } else {
            git push origin $targetBranch --tags
        }

        $pushExitCode = $LASTEXITCODE
        $ErrorActionPreference = $oldEAP

        if ($pushExitCode -eq 0) {
            $pushSuccess = $true
        } else {
            Write-Warning "Error al hacer push. El repositorio no existe en la nube, la URL es incorrecta o falta autenticacion."
            Write-Host "IMPORTANTE: Asegurate de haber creado el repositorio en la WEB (GitHub/Bitbucket) antes de subirlo." -ForegroundColor Yellow
            Write-Host "URL actual detectada: $(git remote get-url origin)" -ForegroundColor Gray
            $action = Read-Host "¿Que deseas hacer? (r) Reintentar URL, (g) Crear en GitHub ahora, (s) Saltar, (x) Salir"
            
            if ($action -eq 'r') {
                git remote remove origin
                $newUrl = Read-Host "Ingresa la URL correcta del repositorio (.git)"
                if (-not [string]::IsNullOrWhiteSpace($newUrl)) { git remote add origin $newUrl }
            } elseif ($action -eq 'g') {
                if (Get-Command gh -ErrorAction SilentlyContinue) {
                    git remote remove origin 2>$null
                    $repoDefault = Split-Path -Leaf $projectRoot
                    $repoName = Read-Host "Nombre del repositorio [$repoDefault]"
                    if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = $repoDefault }
                    $vis = Read-Host "¿Privacidad? (1) Publico, (2) Privado [Predeterminado: Privado]"
                    $visFlag = if ($vis -eq "1") { "--public" } else { "--private" }
                    
                    Write-Host "[INFO] Creando repositorio '$repoName' en GitHub..." -ForegroundColor Cyan
                    & gh repo create $repoName $visFlag --source=. --remote=origin
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "No se pudo crear el repositorio. Asegurate de estar autenticado con 'gh auth login'."
                    }
                } else {
                    Write-Error "GitHub CLI (gh) no instalado. No se puede crear automaticamente."
                }
            } elseif ($action -eq 's') {
                Write-Warning "Sincronizacion saltada por el usuario."
                $skippedPush = $true
                break
            } elseif ($action -eq 'x') {
                exit 1
            } else {
                Write-Host "Opcion no valida."
            }
        }
    }

    if ($pushSuccess) {
        Write-Host ""
        Write-Host "[OK] Sesion finalizada y subida con exito a la rama '$targetBranch' en GitHub." -ForegroundColor Green
        
        # Automatizacion de Pull Request
        $prScript = Join-Path $scriptDir "create-pull-request.ps1"
        if (Test-Path $prScript) { & $prScript -BaseBranch "main" }
    } elseif ($skippedPush) {
        Write-Host ""
        Write-Host "[OK] Sesion finalizada localmente, pero la subida fue saltada." -ForegroundColor Yellow
    }
} else {
    Write-Warning "Sincronizacion saltada: No hay un remoto 'origin' configurado."
    Write-Host ""
    Write-Host "[OK] Sesion finalizada localmente." -ForegroundColor Yellow
}