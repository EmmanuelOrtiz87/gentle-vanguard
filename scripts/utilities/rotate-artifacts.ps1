# rotate-artifacts.ps1
# Rotates generated artifacts (audits, reviews, sessions) keeping only the most recent
# Usage: .\rotate-artifacts.ps1 [-MaxFiles <n>] [-Categories <array>]

param(
    [int]$MaxFiles = 7,
    [string[]]$Categories = @("audits", "sessions", "reviews", "metrics", "reports")
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }
$docsDir = Join-Path $repoRoot 'docs'

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " ARTIFACT ROTATION" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Max files per category: $MaxFiles" -ForegroundColor Gray
Write-Host ""

$totalDeleted = 0
$totalKept = 0

foreach ($category in $Categories) {
    $categoryPath = Join-Path $docsDir $category

    if (-not (Test-Path $categoryPath)) {
        Write-Host "[SKIP] $category/ - not found" -ForegroundColor Gray
        continue
    }

    $files = Get-ChildItem -Path $categoryPath -Filter "*.md" -File -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending

    $count = $files.Count

    if ($count -eq 0) {
        Write-Host "[OK] $category/ - empty" -ForegroundColor Green
        continue
    }

    Write-Host "[$($category.ToUpper())] Found: $count files (max: $MaxFiles)" -ForegroundColor Cyan

    if ($count -le $MaxFiles) {
        Write-Host "  Keeping all $count files" -ForegroundColor Green
        $totalKept += $count
        continue
    }

    $toDelete = $files | Select-Object -Skip $MaxFiles
    $kept = $files | Select-Object -First $MaxFiles

    Write-Host "  Keeping $($kept.Count) files:" -ForegroundColor Green
    foreach ($f in $kept) {
        Write-Host "    - $($f.Name)" -ForegroundColor Gray
    }

    Write-Host "  Deleting $($toDelete.Count) files:" -ForegroundColor Yellow
    foreach ($f in $toDelete) {
        Write-Host "    - $($f.Name)" -ForegroundColor DarkYellow
        Remove-Item $f.FullName -Force
        $totalDeleted++
    }
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " ROTATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Files kept: $totalKept" -ForegroundColor Green
Write-Host " Files deleted: $totalDeleted" -ForegroundColor Yellow
Write-Host ""

if ($totalDeleted -gt 0) {
    Write-Host "[INFO] Run 'git status' to see changes" -ForegroundColor Cyan
}
