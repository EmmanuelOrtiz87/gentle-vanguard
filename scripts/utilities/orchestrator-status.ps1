# orchestrator-status.ps1
# Verifica el estado del Project Orchestrator y la integración con Engram.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path $scriptDir
if ($projectRoot.Path -like '*\utilities') {
    $projectRoot = Resolve-Path (Join-Path $projectRoot '..\..')
} else {
    $projectRoot = Resolve-Path (Join-Path $projectRoot '..')
}

$activationFile = Join-Path $projectRoot '.orchestrator-active'
$configFile = Join-Path $projectRoot 'config\orchestrator.json'
$skillCandidates = @(
    Join-Path $projectRoot '.skills\project-orchestrator-skill'
    Join-Path $projectRoot '.workspace-foundation\skills\project-orchestrator-skill'
    Join-Path $projectRoot 'skills\project-orchestrator-skill'
)
$skillDir = $skillCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $skillDir) { $skillDir = $skillCandidates[0] }
$engramData = Join-Path $projectRoot '.engram-data'
$runEngramScript = Join-Path $projectRoot 'scripts\utilities\run-engram.ps1'

function Write-Step { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Step "Orchestrator Status Check"

if (Test-Path $activationFile) {
    Write-Success "Orchestrator activation file found"
    $activation = Get-Content $activationFile | ConvertFrom-Json
    Write-Host "  skill: $($activation.skill)" -ForegroundColor White
    Write-Host "  project: $($activation.project)" -ForegroundColor White
    Write-Host "  auto_active: $($activation.auto_active)" -ForegroundColor White
} else {
    Write-Warning "Orchestrator activation file not found: $activationFile"
}

if (Test-Path $configFile) {
    Write-Success "Orchestrator config found"
    $config = Get-Content $configFile | ConvertFrom-Json
    Write-Host "  active: $($config.active)" -ForegroundColor White
    Write-Host "  workflow_mode: $($config.workflow_mode)" -ForegroundColor White
    Write-Host "  memory_integration: $($config.memory_integration)" -ForegroundColor White
    Write-Host "  auto_detect: $($config.auto_detect)" -ForegroundColor White
} else {
    Write-Warning "Orchestrator config not found: $configFile"
}

if (Test-Path $skillDir) {
    Write-Success "Project orchestrator skill available"
} else {
    Write-Warning "Project orchestrator skill not found: $skillDir"
}

function Resolve-EngramCommand {
    if ($env:ENGRAM_CMD) {
        return $env:ENGRAM_CMD
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd) { return $engramCmd.Source }

    $pathsToCheck = @()
    if ($env:GOBIN) { $pathsToCheck += Join-Path $env:GOBIN 'engram.exe'; $pathsToCheck += Join-Path $env:GOBIN 'engram' }
    if ($env:GOPATH) { $pathsToCheck += Join-Path $env:GOPATH 'bin\engram.exe'; $pathsToCheck += Join-Path $env:GOPATH 'bin\engram' }
    if ($env:USERPROFILE) { $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram.exe'; $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram' }
    if ($env:HOME) { $pathsToCheck += Join-Path $env:HOME 'go/bin/engram' }

    foreach ($path in $pathsToCheck) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

$engramPath = Resolve-EngramCommand
$engramInstalled = [bool]$engramPath
if ($engramPath) {
    Write-Success "Engram CLI is available: $engramPath"
} else {
    Write-Warning "Engram CLI not found in PATH or configured Go bin locations"
}

if (Test-Path $engramData) {
    Write-Success "Engram data directory exists"
    $entries = Get-ChildItem -Path $engramData -Force | Select-Object -ExpandProperty Name
    Write-Host "  Entries: $($entries -join ', ')" -ForegroundColor White
} else {
    Write-Warning "Engram data directory not found: $engramData"
}

if (Test-Path $runEngramScript) {
    Write-Success "Engram launcher script exists"
} else {
    Write-Warning "Engram launcher script not found: $runEngramScript"
}

Write-Step "Conclusion"
if ((Test-Path $activationFile) -and (Test-Path $configFile) -and (Test-Path $skillDir)) {
    Write-Success "El Orquestador está configurado y activo."
} else {
    Write-Warning "La configuración del orquestador tiene elementos faltantes. Revise los avisos anteriores."
}
if ($engramInstalled -and (Test-Path $runEngramScript)) {
    Write-Success "Engram está disponible para iniciar memoria persistente."
    Write-Host "Para iniciar una sesión con memoria persistente, use: .\scripts\utilities\run-engram.ps1" -ForegroundColor Cyan
} else {
    Write-Warning "Engram no está completamente disponible en el entorno actual."
}

exit 0
