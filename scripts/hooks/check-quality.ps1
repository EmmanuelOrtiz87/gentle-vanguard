# check-quality.ps1
# Ejecuta linters y formatters

$ErrorActionPreference = 'Continue'

# Node.js/TypeScript
if (Test-Path "package.json") {
    Write-Host "[QUALITY] Ejecutando ESLint..." -ForegroundColor Cyan
    npx eslint . || exit 1
    Write-Host "[QUALITY] Ejecutando Prettier..." -ForegroundColor Cyan
    npx prettier --check . || exit 1
}

# Go
if (Test-Path "go.mod") {
    Write-Host "[QUALITY] Ejecutando golint..." -ForegroundColor Cyan
    golint ./... || exit 1
    Write-Host "[QUALITY] Ejecutando gofmt..." -ForegroundColor Cyan
    gofmt -l . | ForEach-Object { if ($_) { Write-Host "[QUALITY] gofmt error: $_" -ForegroundColor Red; exit 1 } }
}

Write-Host "[QUALITY] Chequeos de calidad completados." -ForegroundColor Green
exit 0
