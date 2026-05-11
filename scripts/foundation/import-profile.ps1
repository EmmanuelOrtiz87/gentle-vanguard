<#
.SYNOPSIS
    Importa un perfil exportado por export-profile.ps1 en una PC nueva.
.DESCRIPTION
    Restaura engram DB, config de opencode, binarios, y perfil de PowerShell
    desde un archivo ZIP. Luego ejecuta setup-multi-machine.ps1 para clonar
    repos y bootstrap.
.PARAMETER ZipPath
    Ruta al archivo ZIP generado por export-profile.ps1.
.PARAMETER SkipBootstrap
    Si se establece, omite la ejecucion de setup-multi-machine.ps1.
.PARAMETER ExternalDisk
    Letra de unidad del disco externo donde esta el ZIP (ej. 'E').
.EXAMPLE
    .\import-profile.ps1 -ZipPath C:\Users\emman\Downloads\foundation-profile-20260511.zip
    .\import-profile.ps1 -ExternalDisk E
#>
param(
    [string]$ZipPath = '',
    [switch]$SkipBootstrap,
    [string]$ExternalDisk = ''
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-Info  { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Gray }
function Write-OK    { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

# --- Resolver ruta del ZIP ---
if ($ExternalDisk -and -not $ZipPath) {
    $searchPath = "${ExternalDisk}:\"
    if (-not (Test-Path $searchPath)) { throw "Disco externo ${ExternalDisk}: no encontrado" }
    $zips = Get-ChildItem $searchPath -Filter 'foundation-profile-*.zip' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $zips) { throw "No se encontro ZIP en disco externo ${ExternalDisk}:" }
    $ZipPath = $zips.FullName
    Write-Info "ZIP encontrado: $ZipPath"
}

if (-not $ZipPath -or -not (Test-Path $ZipPath)) {
    throw "Especifica -ZipPath o -ExternalDisk. Ej: .\import-profile.ps1 -ExternalDisk E"
}

# --- Extraer ZIP ---
$tempBase = Join-Path $env:TEMP 'foundation-migration-import'
if (Test-Path $tempBase) { Remove-Item $tempBase -Recurse -Force }
New-Item -ItemType Directory -Path $tempBase -Force | Out-Null

Write-Step 'Extrayendo archivo ZIP'
Expand-Archive -Path $ZipPath -DestinationPath $tempBase -Force
Write-OK 'ZIP extraido'

# --- Validar manifiesto ---
$manifestPath = Join-Path $tempBase 'manifest.json'
if (-not (Test-Path $manifestPath)) {
    Write-Warn 'No se encontro manifest.json - continuando de todos modos'
}

# --- Restaurar Engram ---
Write-Step 'Restaurando Engram'

$engramSrc = Join-Path $tempBase 'engram'
$engramDest = Join-Path $HOME '.engram'

if (Test-Path $engramSrc) {
    if (-not (Test-Path $engramDest)) {
        New-Item -ItemType Directory -Path $engramDest -Force | Out-Null
    }

    Copy-Item (Join-Path $engramSrc 'engram.db') $engramDest -Force
    Write-OK 'engram.db restaurado'

    $wal = Join-Path $engramSrc 'engram.db-wal'
    if (Test-Path $wal) {
        Copy-Item $wal $engramDest -Force
        Copy-Item (Join-Path $engramSrc 'engram.db-shm') $engramDest -Force
        Write-OK 'WAL restaurado'
    }

    $instances = Join-Path $engramSrc 'instances.json'
    if (Test-Path $instances) {
        Copy-Item $instances $engramDest -Force
        Write-OK 'instances.json restaurado'
    }

    $globalDir = Join-Path $engramSrc 'global'
    if (Test-Path $globalDir) {
        $destGlobal = Join-Path $engramDest 'global'
        if (Test-Path $destGlobal) { Remove-Item $destGlobal -Recurse -Force }
        Copy-Item $globalDir $destGlobal -Recurse -Force
        Write-OK 'global/ restaurado'
    }

    $masterKey = Join-Path $engramSrc 'master.key'
    if (Test-Path $masterKey) {
        Copy-Item $masterKey $engramDest -Force
        Write-OK 'master.key (engram) restaurado'
    }
} else {
    Write-Err 'No se encontro directorio engram/ en el ZIP'
}

# --- Restaurar master.key del repo ---
Write-Step 'Restaurando master.key del repo'

$keysSrc = Join-Path $tempBase 'keys\master.key'
if (Test-Path $keysSrc) {
    $repoRoot = if (Test-Path (Join-Path $PSScriptRoot '..\..')) {
        (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    } else {
        Join-Path $HOME 'source\foundation'
    }

    $keysDest = Join-Path $repoRoot 'keys'
    if (-not (Test-Path $keysDest)) {
        New-Item -ItemType Directory -Path $keysDest -Force | Out-Null
    }

    if (Test-Path (Join-Path $keysDest 'master.key')) {
        $backup = Join-Path $keysDest "master.key.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item (Join-Path $keysDest 'master.key') $backup -Force
        Write-Warn "master.key existente respaldado: $backup"
    }

    Copy-Item $keysSrc (Join-Path $keysDest 'master.key') -Force
    Write-OK "master.key restaurado a $keysDest"
} else {
    Write-Warn 'No se encontro keys/master.key en el ZIP - scripts protegidos no podran desencriptarse'
}

# --- Restaurar OpenCode config ---
Write-Step 'Restaurando OpenCode config'

$ocSrc = Join-Path $tempBase 'opencode-config'
$ocDest = Join-Path $HOME '.config\opencode'

if (Test-Path $ocSrc) {
    if (-not (Test-Path $ocDest)) {
        New-Item -ItemType Directory -Path $ocDest -Force | Out-Null
    }

    Copy-Item (Join-Path $ocSrc 'opencode.json') $ocDest -Force
    Write-OK 'opencode.json restaurado'

    Copy-Item (Join-Path $ocSrc 'tui.json') $ocDest -Force
    Write-OK 'tui.json restaurado'

    $pluginsSrc = Join-Path $ocSrc 'plugins'
    if (Test-Path $pluginsSrc) {
        $pluginsDest = Join-Path $ocDest 'plugins'
        if (Test-Path $pluginsDest) { Remove-Item $pluginsDest -Recurse -Force }
        Copy-Item $pluginsSrc $pluginsDest -Recurse -Force
        Write-OK 'plugins/ restaurado'
    }

    $gitignore = Join-Path $ocSrc '.gitignore'
    if (Test-Path $gitignore) {
        Copy-Item $gitignore $ocDest -Force
    }
} else {
    Write-Err 'No se encontro directorio opencode-config/ en el ZIP'
}

# --- Restaurar binarios ---
Write-Step 'Restaurando binarios'

$binSrc = Join-Path $tempBase 'bin'
$binDest = Join-Path $HOME 'bin'

if (Test-Path $binSrc) {
    if (-not (Test-Path $binDest)) {
        New-Item -ItemType Directory -Path $binDest -Force | Out-Null
    }

    $engramExe = Join-Path $binSrc 'engram.exe'
    if (Test-Path $engramExe) {
        Copy-Item $engramExe $binDest -Force
        Write-OK 'engram.exe restaurado'
    }

    $engramBackup = Join-Path $binSrc 'engram.exe.backup'
    if (Test-Path $engramBackup) {
        Copy-Item $engramBackup $binDest -Force
    }

    $opencodeExe = Join-Path $binSrc 'opencode'
    if (Test-Path $opencodeExe) {
        Copy-Item $opencodeExe $binDest -Force
        Write-OK 'opencode restaurado'
    }

    $gga = Join-Path $binSrc 'gga.ps1'
    if (Test-Path $gga) {
        Copy-Item $gga $binDest -Force
        $ggaSh = Join-Path $binSrc 'gga'
        if (Test-Path $ggaSh) { Copy-Item $ggaSh $binDest -Force }
        Write-OK 'gga restaurado'
    }

    $libSrc = Join-Path $binSrc 'lib'
    if (Test-Path $libSrc) {
        $libDest = Join-Path $binDest 'lib'
        if (Test-Path $libDest) { Remove-Item $libDest -Recurse -Force }
        Copy-Item $libSrc $libDest -Recurse -Force
        Write-OK 'lib/ restaurado'
    }

    $goEngram = Join-Path $binSrc 'engram-go-bin.exe'
    if (Test-Path $goEngram) {
        $goBin = Join-Path $HOME 'go\bin'
        if (-not (Test-Path $goBin)) {
            New-Item -ItemType Directory -Path $goBin -Force | Out-Null
        }
        Copy-Item $goEngram (Join-Path $goBin 'engram.exe') -Force
        Write-OK 'engram.exe (go/bin) restaurado'
    }
} else {
    Write-Warn 'No se encontro directorio bin/ en el ZIP'
}

# --- Restaurar PowerShell profile ---
Write-Step 'Restaurando PowerShell profile'

$psSrc = Join-Path $tempBase 'powershell-profile\Microsoft.PowerShell_profile.ps1'
if (Test-Path $psSrc) {
    $psDir = Join-Path $HOME 'Documents\PowerShell'
    if (-not (Test-Path $psDir)) {
        New-Item -ItemType Directory -Path $psDir -Force | Out-Null
    }

    $psDest = Join-Path $psDir 'Microsoft.PowerShell_profile.ps1'

    if (Test-Path $psDest) {
        $backup = "$psDest.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $psDest $backup -Force
        Write-Warn "Profile existente respaldado: $backup"
    }

    Copy-Item $psSrc $psDest -Force
    Write-OK 'PowerShell profile restaurado'

    $oneDriveProfile = Join-Path $HOME 'OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    if (Test-Path (Split-Path $oneDriveProfile -Parent)) {
        if (Test-Path $oneDriveProfile) {
            $odBackup = "$oneDriveProfile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $oneDriveProfile $odBackup -Force
        }
        Copy-Item $psSrc $oneDriveProfile -Force
        Write-OK 'PowerShell profile (OneDrive) restaurado'
    }
}

# --- Agregar bin/ al PATH si no esta ---
Write-Step 'Configurando PATH'

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$binDirForPath = $binDest -replace '/', '\'

if ($userPath -notlike "*$binDirForPath*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDirForPath", 'User')
    Write-OK "$binDirForPath agregado al PATH del usuario"
    $env:Path += ";$binDirForPath"
} else {
    Write-Info "$binDirForPath ya esta en el PATH"
}

$goBinForPath = Join-Path $HOME 'go\bin'
if ($userPath -notlike "*$goBinForPath*") {
    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    [Environment]::SetEnvironmentVariable('Path', "$currentPath;$goBinForPath", 'User')
    Write-OK "$goBinForPath agregado al PATH del usuario"
    $env:Path += ";$goBinForPath"
}

# --- Limpiar temporal ---
Remove-Item $tempBase -Recurse -Force

# --- Bootstrap de repos ---
if (-not $SkipBootstrap) {
    Write-Step 'Ejecutando setup-multi-machine.ps1'

    # Verificar prerequisitos minimos
    $prereqs = @('git', 'node')
    foreach ($cmd in $prereqs) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Err "$cmd no esta instalado. Instala los prerequisitos antes de continuar."
            Write-Host @'

Prerequisitos:
  1. Git:  winget install Git.Git
  2. Node: winget install OpenJS.NodeJS.LTS
  3. Go:   winget install GoLang.Go
  4. Bun:  powershell -c "irm bun.sh/install.ps1 | iex"

Luego ejecuta: .\import-profile.ps1 -SkipBootstrap
y finalmente:   .\scripts\foundation\setup-multi-machine.ps1
'@ -ForegroundColor Yellow
            throw "Prerequisito faltante: $cmd"
        }
    }
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Warn 'Go no esta instalado. Se requiere solo si Engram no fue restaurado del perfil.'
        $engramBin = Join-Path $HOME 'bin\engram.exe'
        if (Test-Path $engramBin) {
            Write-OK "engram.exe encontrado en $engramBin - continuando sin Go"
        } else {
            Write-Err 'Go no encontrado y engram.exe no esta en ~/bin/. Instala Go: winget install GoLang.Go'
            Write-Host @'

Prerequisitos:
  1. Git:  winget install Git.Git
  2. Node: winget install OpenJS.NodeJS.LTS
  3. Go:   winget install GoLang.Go
  4. Bun:  powershell -c "irm bun.sh/install.ps1 | iex"

Luego ejecuta: .\import-profile.ps1 -SkipBootstrap
y finalmente:   .\scripts\foundation\setup-multi-machine.ps1
'@ -ForegroundColor Yellow
            throw "Prerequisito faltante: go y engram.exe"
        }
    }

    $setupScript = Join-Path $PSScriptRoot 'setup-multi-machine.ps1'
    if (Test-Path $setupScript) {
        & $setupScript
        Write-OK 'setup-multi-machine completado'
    } else {
        Write-Warn "setup-multi-machine.ps1 no encontrado en $PSScriptRoot"
        Write-Host 'Ejecuta manualmente: .\scripts\foundation\setup-multi-machine.ps1' -ForegroundColor Yellow
    }
}

Write-Step 'Importacion completada'
Write-Host @'
Perfil restaurado exitosamente.

Siguientes pasos:
  1. Reinicia la terminal para que el PATH surta efecto
  2. Verifica: engram.exe health
  3. Verifica: opencode --version
  4. Si se omitio bootstrap, ejecuta:
     .\scripts\foundation\setup-multi-machine.ps1
  5. Inicia engram: engram serve
  6. Abre el repo: cd <ruta al repo> && opencode

Notas:
  - El profile de PowerShell se respaldo si ya existia uno
  - Los binarios se copiaron a ~/bin/ y ~/go/bin/
  - La DB de engram se restauro en ~/.engram/
  - OpenCode config se restauro en ~/.config/opencode/
'@ -ForegroundColor White