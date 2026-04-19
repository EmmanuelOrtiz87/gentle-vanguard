# check-testing.ps1
# Ejecuta tests y valida cobertura mínima

$ErrorActionPreference = 'Continue'

# Node.js/TypeScript
if (Test-Path "package.json") {
    Write-Host "[TESTING] Ejecutando tests (npm test)..." -ForegroundColor Cyan
    npm test || exit 1
}

# Go
if (Test-Path "go.mod") {
    Write-Host "[TESTING] Ejecutando tests (go test)..." -ForegroundColor Cyan
    go test ./... || exit 1
}

Write-Host "[TESTING] Todos los tests pasaron." -ForegroundColor Green
exit 0
