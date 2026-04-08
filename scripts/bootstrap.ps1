# bootstrap.ps1
# Este script inicializa el entorno de trabajo completo en una maquina nueva.
# Está diseñado para ser agnóstico:
# Esta diseñado para ser agnostico:
# - OS: Funciona en Windows, Linux y macOS (vía PowerShell Core).
# - IDE: No depende de VSCode, IntelliJ o editores específicos.
# - IA: Configura la base para que cualquier modelo use el protocolo MCP.
# - Tech: Estructura proyectos y herramientas de forma aislada.

param(
    [string]$GitUser,
    [string]$GitEmail
)

$ErrorActionPreference = 'Stop'

# Configuración de Orígenes (Git Provider Agnostic)
$ENGRAM_REPO_URL = "https://github.com/Gentleman-Programming/engram.git"
$SKILLS_REPO_URL = "https://github.com/Gentleman-Programming/Gentleman-Skills.git"

function Write-Step { param([string]$msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Success { param([string]$msg) Write-Host "   OK: $msg" -ForegroundColor Green }
function Write-ErrorMsg { param([string]$msg) Write-Host "   ERROR: $msg" -ForegroundColor Red }
function Write-InfoMsg { param([string]$msg) Write-Host "   INFO: $msg" -ForegroundColor Gray }

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Write-Step "Paso 1: Creando Estructura de Directorios Agnostica..."
$dirs = @('projects', 'tools', 'config', '.engram-data', 'docs/code-reviews')
foreach ($dir in $dirs) {
    $path = Join-Path $workspaceRoot $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Success "Creado: $dir/"
    } else {
        Write-InfoMsg "Existente: $dir/"
    }
}

Write-Step "Paso 2: Verificando Dependencias Core..."

# 1. Git (Control de versiones agnóstico)
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Success "Git detectado: $(git --version | Select-Object -First 1)"
} else {
    Write-ErrorMsg "Git no encontrado. Instálalo en: https://git-scm.com/"
    exit 1
}

# 1.1 Verificación de Identidad Git
# Aplicar parametros si se proporcionan
if (-not [string]::IsNullOrWhiteSpace($GitUser)) { git config --global user.name "$GitUser" }
if (-not [string]::IsNullOrWhiteSpace($GitEmail)) { git config --global user.email "$GitEmail" }

$gitUserCheck = git config --get user.name 2>$null
$gitEmailCheck = git config --get user.email 2>$null

if ([string]::IsNullOrWhiteSpace($gitUserCheck) -or [string]::IsNullOrWhiteSpace($gitEmailCheck)) {
    Write-Step "Configuracion de Identidad Git..."
    if ([string]::IsNullOrWhiteSpace($gitUserCheck)) {
        $gitUserCheck = Read-Host "Ingresa tu nombre para Git (user.name)"
        if (-not [string]::IsNullOrWhiteSpace($gitUserCheck)) { git config --global user.name "$gitUserCheck" }
    }
    if ([string]::IsNullOrWhiteSpace($gitEmailCheck)) {
        $gitEmailCheck = Read-Host "Ingresa tu email para Git (user.email)"
        if (-not [string]::IsNullOrWhiteSpace($gitEmailCheck)) { git config --global user.email "$gitEmailCheck" }
    }
}

# 2. Go (Motor de herramientas y backend)
if (Get-Command go -ErrorAction SilentlyContinue) {
    Write-Success "Go detectado: $(go version)"
} else {
    Write-ErrorMsg "Go (Golang) no encontrado. Instálalo en: https://go.dev/"
    exit 1
}

# 3. Engram (Orquestador de IA)
if (Get-Command engram -ErrorAction SilentlyContinue) {
    Write-Success "Engram CLI detectado."
} else {
    Write-Step "Instalando Engram CLI desde el repositorio..."
    $engramToolDir = Join-Path $workspaceRoot "tools/engram"
    if (-not (Test-Path $engramToolDir)) {
        git clone $ENGRAM_REPO_URL "$engramToolDir"
    }
    Push-Location $engramToolDir
    & go install ./cmd/engram
    Pop-Location
    if (Get-Command engram -ErrorAction SilentlyContinue) {
        Write-Success "Engram CLI instalado correctamente."
    } else {
        Write-ErrorMsg "No se pudo instalar Engram. Asegúrate de que %GOPATH%\bin esté en tu PATH."
    }
}

# 4. Gentleman Skills (Librería de habilidades base)
Write-Step "Sincronizando Gentleman Skills (Base de Conocimiento)..."
$skillsDir = Join-Path $workspaceRoot "tools/Gentleman-Skills"
if (-not (Test-Path $skillsDir)) {
    git clone $SKILLS_REPO_URL "$skillsDir"
    Write-Success "Gentleman-Skills clonado correctamente."
} else {
    Push-Location $skillsDir
    git pull --ff-only
    Pop-Location
    Write-Success "Gentleman-Skills actualizado."
}

# 5. GitHub CLI (Opcional pero recomendado para automatización de repos)
Write-Step "Verificando GitHub CLI (gh)..."
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[!] GitHub CLI no detectado." -ForegroundColor Yellow
    $confirmGh = Read-Host "¿Deseas intentar la instalacion automatizada? (s/n)"
    if ($confirmGh -eq 's') {
        try {
            if ($IsWindows) {
                Write-InfoMsg "Instalando gh via winget..."
                winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
            } elseif ($IsMacOS) {
                Write-InfoMsg "Instalando gh via brew..."
                brew install gh
            } elseif ($IsLinux) {
                Write-InfoMsg "Instalando gh via apt..."
                sudo apt update
                sudo apt install gh -y
                if ($?) { sudo apt install gh -y }
            }
            
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                Write-Success "GitHub CLI instalado exitosamente."
            }
        } catch {
            Write-ErrorMsg "Error durante la instalacion automatica. Por favor instalo manualmente: https://cli.github.com/"
        }
    }
} else {
    Write-Success "GitHub CLI detectado."
}

Write-Step "Paso 3: Desplegando Configuración por Defecto..."
$configPath = Join-Path $workspaceRoot "config/workspace.config.json"
if (-not (Test-Path $configPath)) {
    # Si el archivo no existe, creamos una base agnóstica de IA
    $defaultConfig = @{
        "workspaceRoot" = "{workspaceRoot}"
        "dataRoot"      = "{dataRoot}"
        "aiModelSettings" = @{
            "provider" = "generic"
            "model"    = "default"
            "protocol" = "mcp"
        }
    } | ConvertTo-Json -Depth 10
    $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8
    Write-Success "Configuración generada: config/workspace.config.json"
} else {
    Write-InfoMsg "Configuración existente respetada: config/workspace.config.json"
}

Write-Step "Paso 4: Reporte de Salud del Sistema (Health Check)..."
$report = @{
    Git = if (Get-Command git -ErrorAction SilentlyContinue) { "PASS" } else { "FAIL" }
    GitHubCLI = if (Get-Command gh -ErrorAction SilentlyContinue) { 
        "PASS" 
    } else { 
        if (Test-Path "$env:ProgramFiles\GitHub CLI\gh.exe") { "RESTART REQUIRED (Instalado pero no en PATH)" } else { "INFO: No instalado" }
    }
    Go  = if (Get-Command go -ErrorAction SilentlyContinue) { "PASS" } else { "FAIL" }
    Engram = if (Get-Command engram -ErrorAction SilentlyContinue) { "PASS" } else { "FAIL" }
    Skills = if (Test-Path $skillsDir) { "PASS" } else { "FAIL" }
    Config = if (Test-Path $configPath) { "PASS" } else { "FAIL" }
}

foreach ($item in $report.Keys) {
    $color = if ($report[$item] -eq "PASS") { "Green" } else { "Red" }
    Write-Host "   [Checking] $item : $($report[$item])" -ForegroundColor $color
}

Write-Host "`n[SUCCESS] Workspace Foundation Inicializado y Verificado!" -ForegroundColor Green
Write-Host "Ahora puedes ejecutar 'scripts/run-engram.ps1' para iniciar tu sesion de desarrollo asistida." -ForegroundColor Green