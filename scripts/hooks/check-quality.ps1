# check-quality.ps1
# Ejecuta linters y formatters

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M,[string]$C='White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C } else { Write-Host $M -ForegroundColor $C } }

# Node.js/TypeScript
if (Test-Path "package.json") {
    _Wh "[QUALITY] Ejecutando ESLint..." Cyan
    npx eslint .  -or  exit 1
    _Wh "[QUALITY] Ejecutando Prettier..." Cyan
    npx prettier --check .  -or  exit 1
}

# Go
if (Test-Path "go.mod") {
    _Wh "[QUALITY] Ejecutando golint..." Cyan
    golint ./...  -or  exit 1
    _Wh "[QUALITY] Ejecutando gofmt..." Cyan
    gofmt -l . | ForEach-Object { if ($_) { _Wh "[QUALITY] gofmt error: $_" Red; exit 1 } }
}

_Wh "[QUALITY] Chequeos de calidad completados." Green
exit 0
