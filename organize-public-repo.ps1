# organize-public-repo.ps1
# Organiza el repositorio público removiendo contenido privado

$ErrorActionPreference = 'Stop'

Write-Output "[PUBLIC-REPO] Iniciando organización del repositorio público"

# Contenido a MANTENER (público)
$publicContent = @(
    'README-PUBLIC.md',
    'LICENSE',
    'CONTRIBUTING.md',
    'CODE_OF_CONDUCT.md',
    'docs/',
    'demos/',
    '.github/workflows/',
    'skills/'
)

# Contenido a ELIMINAR (privado)
$privateContent = @(
    'tests/',
    'scripts/',
    'config/',
    '.env*',
    '*.key',
    '*.pem',
    'session/',
    'logs/',
    '.runtime/',
    '.audit/',
    '.local/',
    '.antigravity/',
    '.atl/',
    '.cline/',
    '.codex/',
    '.continue/',
    '.cursor/',
    '.engram-data/',
    '.event-bus/',
    'tmp-session-debug/',
    'templates/',
    'tools/',
    'projects/',
    'openspec/',
    'rules/',
    '.workspace/'
)

Write-Output "[PUBLIC-REPO] Eliminando contenido privado..."
foreach ($item in $privateContent) {
    if (Test-Path $item) {
        Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "  ✓ Eliminado: $item"
    }
}

Write-Output "[PUBLIC-REPO] Limpiando archivos de configuración privada..."
$filesToRemove = @(
    'CLAUDE.md',
    'CLINE-CONTEXT-AUDIT.md',
    'CLINE-OPTIMIZATION-GUIDE.md',
    'CHANGELOG.md',
    '.clinerules',
    '.clinerules.optimized',
    '.cursorrules',
    '.clineignore',
    '.codeiumignore',
    '.editorconfig',
    '.eslintrc.json',
    '.gitleaks.toml',
    '.lefthook.yml',
    '.markdownlint.json',
    '.npmrc',
    '.prettierignore',
    '.prettierrc',
    '.secretlintignore',
    '.secretlintrc.json',
    '.trivyignore',
    'tsconfig.json',
    '.gitattributes'
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
        Write-Output "  ✓ Eliminado: $file"
    }
}

Write-Output "[PUBLIC-REPO] Limpieza completada"
Write-Output "[PUBLIC-REPO] Contenido público restante:"
Get-ChildItem -Force | Where-Object { $_.Name -notmatch '^\.' } | ForEach-Object { Write-Output "  - $($_.Name)" }

Write-Output "[PUBLIC-REPO] Organización completada"