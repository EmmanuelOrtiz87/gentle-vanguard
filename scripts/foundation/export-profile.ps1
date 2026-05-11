<#
.SYNOPSIS
    Exporta perfiles de usuario para migrar a otra PC (engram, opencode, binarios, profile).
.DESCRIPTION
    Empaqueta engram DB, config de opencode, binarios (engram, opencode), perfil PS,
    y master.key en un archivo ZIP listo para transferir.
.PARAMETER OutputDir
    Directorio donde se guardara el archivo ZIP. Default: $HOME\Downloads
.PARAMETER ExternalDisk
    Letra de unidad del disco externo (ej. 'E'). Si se especifica, copia el ZIP al disco.
.EXAMPLE
    .\export-profile.ps1
    .\export-profile.ps1 -ExternalDisk E
#>
param(
    [string]$OutputDir = (Join-Path $HOME 'Downloads'),
    [string]$ExternalDisk = '',
    [string]$RepoRoot = ''
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-Info  { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Gray }
function Write-OK    { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }

$tempBase = Join-Path $env:TEMP 'foundation-migration-export'
if (Test-Path $tempBase) { Remove-Item $tempBase -Recurse -Force }
New-Item -ItemType Directory -Path $tempBase -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$zipName = "foundation-profile-$timestamp.zip"
$zipPath = Join-Path $OutputDir $zipName

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = if (Test-Path (Join-Path $PSScriptRoot '..\..')) {
        (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    } else {
        $PWD.Path
    }
}

Write-Step 'Exportando Engram DB'

$engramDir = Join-Path $HOME '.engram'
if (-not (Test-Path $engramDir)) { throw "No se encontro $engramDir" }

$engramDest = Join-Path $tempBase 'engram'
New-Item -ItemType Directory -Path $engramDest -Force | Out-Null

Copy-Item (Join-Path $engramDir 'engram.db') $engramDest -Force
Write-OK 'engram.db copiado'

if (Test-Path (Join-Path $engramDir 'engram.db-shm')) {
    Copy-Item (Join-Path $engramDir 'engram.db-shm') $engramDest -Force
    Copy-Item (Join-Path $engramDir 'engram.db-wal') $engramDest -Force
    Write-OK 'WAL files copiados'
}

if (Test-Path (Join-Path $engramDir 'instances.json')) {
    Copy-Item (Join-Path $engramDir 'instances.json') $engramDest -Force
    Write-OK 'instances.json copiado'
}

if (Test-Path (Join-Path $engramDir 'global')) {
    Copy-Item (Join-Path $engramDir 'global') $engramDest -Recurse -Force
    Write-OK 'Directorio global/ copiado'
} else {
    Write-Warn 'No se encontro directorio global/'
}

if (Test-Path (Join-Path $engramDir 'master.key')) {
    Copy-Item (Join-Path $engramDir 'master.key') $engramDest -Force
    Write-OK 'master.key (engram) copiado'
}

Write-Step 'Exportando master.key del repo'

$repoMasterKey = Join-Path $RepoRoot 'keys\master.key'
if (Test-Path $repoMasterKey) {
    $keysDest = Join-Path $tempBase 'keys'
    New-Item -ItemType Directory -Path $keysDest -Force | Out-Null
    Copy-Item $repoMasterKey (Join-Path $keysDest 'master.key') -Force
    Write-OK 'master.key (repo) copiado a keys/'
} else {
    Write-Warn 'No se encontro keys/master.key en el repo - los scripts protegidos no se podran desencriptar'
}

Write-Step 'Exportando OpenCode config'

$ocDir = Join-Path $HOME '.config\opencode'
if (-not (Test-Path $ocDir)) { throw "No se encontro $ocDir" }

$ocDest = Join-Path $tempBase 'opencode-config'
New-Item -ItemType Directory -Path $ocDest -Force | Out-Null

Copy-Item (Join-Path $ocDir 'opencode.json') $ocDest -Force
Write-OK 'opencode.json copiado'

Copy-Item (Join-Path $ocDir 'tui.json') $ocDest -Force
Write-OK 'tui.json copiado'

if (Test-Path (Join-Path $ocDir 'plugins')) {
    Copy-Item (Join-Path $ocDir 'plugins') $ocDest -Recurse -Force
    Write-OK 'plugins/ copiado'
}

Copy-Item (Join-Path $ocDir '.gitignore') $ocDest -Force -ErrorAction SilentlyContinue

Write-Step 'Exportando binarios'

$binDest = Join-Path $tempBase 'bin'
New-Item -ItemType Directory -Path $binDest -Force | Out-Null

$binDir = Join-Path $HOME 'bin'

$engramBin = Join-Path $binDir 'engram.exe'
if (Test-Path $engramBin) {
    Copy-Item $engramBin $binDest -Force
    Write-OK 'engram.exe copiado'
} else { Write-Warn 'engram.exe no encontrado en bin/' }

$engramBackup = Join-Path $binDir 'engram.exe.backup'
if (Test-Path $engramBackup) {
    Copy-Item $engramBackup $binDest -Force
    Write-OK 'engram.exe.backup copiado'
}

$opencodeBin = Join-Path $binDir 'opencode'
if (Test-Path $opencodeBin) {
    Copy-Item $opencodeBin $binDest -Force
    Write-OK 'opencode copiado'
} else { Write-Warn 'opencode no encontrado en bin/' }

$ggaPs1 = Join-Path $binDir 'gga.ps1'
if (Test-Path $ggaPs1) {
    Copy-Item $ggaPs1 $binDest -Force
    Copy-Item (Join-Path $binDir 'gga') $binDest -Force -ErrorAction SilentlyContinue
    Write-OK 'gga copiado'
}

if (Test-Path (Join-Path $binDir 'lib')) {
    Copy-Item (Join-Path $binDir 'lib') $binDest -Recurse -Force
    Write-OK 'lib/ copiado'
}

$goBinEngram = Join-Path $HOME 'go\bin\engram.exe'
if (Test-Path $goBinEngram) {
    Copy-Item $goBinEngram (Join-Path $binDest 'engram-go-bin.exe') -Force
    Write-OK 'engram.exe (go/bin) copiado'
}

Write-Step 'Exportando PowerShell profile'

$psProfilePaths = @(
    (Join-Path $HOME 'OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
)

$psDest = Join-Path $tempBase 'powershell-profile'
New-Item -ItemType Directory -Path $psDest -Force | Out-Null

$profileFound = $false
foreach ($p in $psProfilePaths) {
    if (Test-Path $p) {
        Copy-Item $p (Join-Path $psDest 'Microsoft.PowerShell_profile.ps1') -Force
        Write-OK "Profile copiado desde $p"
        $profileFound = $true
        break
    }
}
if (-not $profileFound) {
    Write-Warn 'No se encontro profile de PowerShell'
}

Write-Step 'Creando manifiesto'

$manifest = @{
    timestamp    = $timestamp
    exported_by  = $env:USERNAME
    machine      = $env:COMPUTERNAME
    engram_db    = $true
    opencode_cfg = $true
    master_key   = (Test-Path (Join-Path $RepoRoot 'keys\master.key'))
    binarios     = @()
    ps_profile   = $profileFound
}

$manifestPath = Join-Path $tempBase 'manifest.json'
$manifest | ConvertTo-Json -Depth 3 | Set-Content $manifestPath -Encoding UTF8
Write-OK 'manifest.json creado'

Write-Step 'Comprimiendo'

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path "$tempBase\*" -DestinationPath $zipPath -Force
Write-OK "ZIP creado: $zipPath"

$size = (Get-Item $zipPath).Length / 1MB
Write-Info "Tamano: $([math]::Round($size, 2)) MB"

if ($ExternalDisk -and (Test-Path "${ExternalDisk}:\")) {
    $destPath = "${ExternalDisk}:\$zipName"
    Copy-Item $zipPath $destPath -Force
    Write-OK "Copiado a disco externo: $destPath"
} elseif ($ExternalDisk) {
    Write-Warn "Disco externo ${ExternalDisk}: no encontrado"
}

Remove-Item $tempBase -Recurse -Force
Write-Step 'Exportacion completada'
Write-Host @"
Archivo: $zipPath
Tamano: $([math]::Round($size, 2)) MB

Contenido:
  - engram/          (DB + WAL + global/)
  - keys/            (master.key para desencriptar scripts protegidos)
  - opencode-config/ (opencode.json + tui.json + plugins/)
  - bin/             (engram.exe, opencode, gga, lib/)
  - powershell-profile/
  - manifest.json

Proximo paso: Copiar ZIP a nueva PC y ejecutar import-profile.ps1
"@ -ForegroundColor White