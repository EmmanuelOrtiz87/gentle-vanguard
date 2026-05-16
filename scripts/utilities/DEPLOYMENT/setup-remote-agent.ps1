# setup-remote-agent.ps1
# Automatiza la configuracin segura de un agente remoto IA en Gentle-Vanguard/local

param(
    [Parameter(Mandatory=$true)]
    [string]$Endpoint,
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    [Parameter(Mandatory=$false)]
    [string]$ProviderName = "custom",
    [Parameter(Mandatory=$false)]
    [string]$ApiKeyEnv = "MY_AGENT_APIKEY"
)

$ErrorActionPreference = 'Stop'

# Paths
if ($env:GV_BASE_DIR) {
    $repoRoot = $env:GV_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
$configDir = Join-Path $repoRoot 'config'
$localConfigPath = Join-Path $configDir 'cloud-agents.local.json'
$envFile = Join-Path $repoRoot '.env.local'

# 1. Validar existencia de config y .env.local
if (!(Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir | Out-Null }
if (!(Test-Path $envFile)) { New-Item -ItemType File -Path $envFile | Out-Null }

# 2. Validar cloud-agents.local.json
if (Test-Path $localConfigPath) {
    $json = Get-Content $localConfigPath -Raw | ConvertFrom-Json
} else {
    $json = @{ providers = @{} }
}

# 3. No sobrescribir proveedor existente
if ($json.providers.$ProviderName) {
    Write-Host "[INFO] El proveedor '$ProviderName' ya existe en cloud-agents.local.json. No se modifica." -ForegroundColor Yellow
} else {
    $json.providers.$ProviderName = @{ enabled = $true; endpoint = $Endpoint; api_key_env = $ApiKeyEnv }
    $json | ConvertTo-Json -Depth 10 | Set-Content $localConfigPath -Encoding UTF8
    Write-Host "[OK] Proveedor '$ProviderName' agregado a cloud-agents.local.json" -ForegroundColor Green
}

# 4. Agregar API key a .env.local si no existe
$envLines = Get-Content $envFile
$envEntry = "$ApiKeyEnv=$ApiKey"
if ($envLines -notcontains $envEntry) {
    Add-Content $envFile $envEntry
    Write-Host "[OK] API key agregada a .env.local" -ForegroundColor Green
} else {
    Write-Host "[INFO] API key ya estaba presente en .env.local" -ForegroundColor Yellow
}

# 5. Validar conexin
Write-Host "[INFO] Probando conexin..." -ForegroundColor Cyan
$test = & "$repoRoot\scripts\utilities\invoke-cloud-agent.ps1" -Provider $ProviderName -TestConnection
Write-Host $test

Write-Host "[FINALIZADO] Configuracin automatizada completa. Si ves errores arriba, revisa el endpoint y la API key." -ForegroundColor Cyan


