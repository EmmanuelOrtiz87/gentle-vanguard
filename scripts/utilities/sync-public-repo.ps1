# sync-public-repo.ps1
# Sincroniza solo contenido público hacia gentle-vanguard-public
# Excluye: tests internos, scripts privados, configuraciones sensibles

param(
    [string]$SourceBranch = "main",
    [string]$TargetBranch = "main",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Output "[SYNC-PUBLIC] Iniciando sincronización de repositorio público"

# Contenido que DEBE estar en público
$publicContent = @(
    'README-PUBLIC.md',
    'LICENSE',
    'CONTRIBUTING.md',
    'docs/',
    'scripts/gentle-vanguard/bootstrap.ps1',
    'config/workspace.example.json',
    'config/orchestrator.json.example',
    'skills/*/SKILL.md',
    'demos/',
    '.github/workflows/'
)

# Contenido que NO debe estar en público
$privateContent = @(
    'tests/unit/',
    'tests/integration/',
    'tests/security/',
    'scripts/utilities/',
    'scripts/security/',
    '.env*',
    '*.key',
    '*.pem',
    'session/',
    'logs/',
    '.runtime/'
)

Write-Output "[SYNC-PUBLIC] Contenido público a incluir:"
foreach ($item in $publicContent) {
    Write-Output "  ✓ $item"
}

Write-Output "[SYNC-PUBLIC] Contenido privado a excluir:"
foreach ($item in $privateContent) {
    Write-Output "  ✗ $item"
}

Write-Output "[SYNC-PUBLIC] Verificando rama 'public-distribution'..."

# Crear rama si no existe
$branchExists = git rev-parse --verify public-distribution 2>$null
if (-not $branchExists) {
    Write-Output "[SYNC-PUBLIC] Creando rama 'public-distribution'..."
    git checkout -b public-distribution $SourceBranch
} else {
    git checkout public-distribution
    git reset --hard origin/$SourceBranch
}

Write-Output "[SYNC-PUBLIC] Rama 'public-distribution' lista"

if (-not $DryRun) {
    Write-Output "[SYNC-PUBLIC] Sincronizando con 'public' remote..."
    git push public public-distribution:$TargetBranch --force
    Write-Output "[SYNC-PUBLIC] ✓ Sincronización completada"
} else {
    Write-Output "[SYNC-PUBLIC] [DRY-RUN] No se realizaron cambios"
}

Write-Output "[SYNC-PUBLIC] Sincronización finalizada"
exit 0