#!/usr/bin/env pwsh
#
# Cleanup Script - Remove Obsolete Design Apps
# 
# Este script elimina las apps obsoletas de diseño:
# - apps/gv-design-studio (reemplazado por Design Hub)
# - apps/gv-design-system-catalog (reemplazado por Design Hub)
#
# ANTES DE EJECUTAR:
# 1. Asegurar que Design Hub funciona correctamente
# 2. Backup si es necesario
# 3. Verificar que no hay referencias cruzadas
#

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🧹 Gentle-Vanguard Design Apps Cleanup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$obsoleteApps = @(
    "apps/gv-design-studio",
    "apps/gv-design-system-catalog"
)

$appsFound = @()
$appsNotFound = @()

# Verificar qué apps existen
Write-Host "📁 Scanning for obsolete apps..." -ForegroundColor Yellow
foreach ($app in $obsoleteApps) {
    $appPath = Join-Path (Get-Location) $app
    if (Test-Path $appPath) {
        $appsFound += $app
        Write-Host "  ⚠️ Found: $app" -ForegroundColor Red
    } else {
        $appsNotFound += $app
        Write-Host "  ✓ Already removed: $app" -ForegroundColor Green
    }
}

Write-Host ""

if ($appsFound.Count -eq 0) {
    Write-Host "✅ All obsolete apps already removed!" -ForegroundColor Green
    exit 0
}

Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "  Apps to remove: $($appsFound.Count)"
Write-Host "  Apps not found: $($appsNotFound.Count)"
Write-Host ""

# Mostrar lo que se va a eliminar
Write-Host "🗂️ Apps that will be removed:" -ForegroundColor Yellow
foreach ($app in $appsFound) {
    $appPath = Join-Path (Get-Location) $app
    $itemCount = (Get-ChildItem -Path $appPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $size = (Get-ChildItem -Path $appPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)
    Write-Host "  - $app ($itemCount files, ${sizeMB} MB)" -ForegroundColor Red
}

Write-Host ""

# Dry run mode
if ($DryRun) {
    Write-Host "🎭 DRY RUN - No files will be deleted" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to actually delete" -ForegroundColor Yellow
    exit 0
}

# Confirmación
if (-not $Force) {
    Write-Host "⚠️ WARNING: This action cannot be undone!" -ForegroundColor Red -BackgroundColor Black
    $confirm = Read-Host "Are you sure you want to delete these apps? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "🚫 Operation cancelled by user" -ForegroundColor Yellow
        exit 1
    }
}

# Eliminar apps
Write-Host ""
Write-Host "🗑️ Removing obsolete apps..." -ForegroundColor Yellow

foreach ($app in $appsFound) {
    $appPath = Join-Path (Get-Location) $app
    try {
        Remove-Item -Path $appPath -Recurse -Force
        Write-Host "  ✅ Removed: $app" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Failed to remove $app`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Cleanup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify Design Hub works: cd apps/design-hub && npm run status"
Write-Host "  2. Start Design Hub if needed: cd apps/design-hub && npm run start"
Write-Host "  3. Access: http://127.0.0.1:8095"
Write-Host ""
Write-Host "🎨 Design Hub is now the unified design tool!" -ForegroundColor Cyan
