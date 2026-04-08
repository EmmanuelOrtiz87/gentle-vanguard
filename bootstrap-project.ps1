# bootstrap-project.ps1
# Inicializa el proyecto Bitbucket Dashboard.

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Write-Host "`n>> Sincronizando dependencias del Dashboard..." -ForegroundColor Cyan
Set-Location $projectRoot
& go mod tidy
Write-Host "[OK] Dashboard listo para operar." -ForegroundColor Green