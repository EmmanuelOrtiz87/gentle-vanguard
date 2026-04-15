# rotate-artifacts.ps1
# Rotates generated artifacts keeping only the most recent in the repo,
# while archiving all older files locally (gitignored).
# Usage: .\rotate-artifacts.ps1 [-MaxRepoFiles <n>] [-MaxLocalFiles <n>] [-Categories <array>]

param(
    [int]$MaxRepoFiles = 1,
    [int]$MaxLocalFiles = 30,
    [string[]]$Categories = @("audits", "sessions", "reviews", "metrics", "reports")
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }
$docsDir = Join-Path $repoRoot 'docs'
$archiveRoot = Join-Path $docsDir '.local-archive'

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " ARTIFACT ROTATION" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Max repo files per category: $MaxRepoFiles" -ForegroundColor Gray
Write-Host " Max local archive files per category: $MaxLocalFiles" -ForegroundColor Gray
Write-Host ""

$totalArchived = 0
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

    Write-Host "[$($category.ToUpper())] Found: $count files (max repo: $MaxRepoFiles)" -ForegroundColor Cyan

    if ($count -le $MaxRepoFiles) {
        Write-Host "  Keeping all $count files" -ForegroundColor Green
        $totalKept += $count
        continue
    }

    $toArchive = $files | Select-Object -Skip $MaxRepoFiles
    $kept = $files | Select-Object -First $MaxRepoFiles
    $archivePath = Join-Path $archiveRoot $category
    if (-not (Test-Path $archivePath)) {
        New-Item -ItemType Directory -Path $archivePath -Force | Out-Null
    }

    Write-Host "  Keeping $($kept.Count) files:" -ForegroundColor Green
    foreach ($f in $kept) {
        Write-Host "    - $($f.Name)" -ForegroundColor Gray
    }

    Write-Host "  Archiving $($toArchive.Count) files:" -ForegroundColor Yellow
    foreach ($f in $toArchive) {
        $destination = Join-Path $archivePath $f.Name
        Write-Host "    - $($f.Name)" -ForegroundColor DarkYellow
        Move-Item $f.FullName $destination -Force
        $totalArchived++
    }

    $archiveFiles = Get-ChildItem -Path $archivePath -Filter "*.md" -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending

    if ($archiveFiles.Count -gt $MaxLocalFiles) {
        $archiveDelete = $archiveFiles | Select-Object -Skip $MaxLocalFiles
        Write-Host "  Pruning archive: $($archiveDelete.Count) old files" -ForegroundColor Yellow
        foreach ($f in $archiveDelete) {
            Remove-Item $f.FullName -Force
            $totalDeleted++
        }
    }
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " ROTATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Files kept: $totalKept" -ForegroundColor Green
Write-Host " Files archived: $totalArchived" -ForegroundColor Cyan
Write-Host " Files deleted: $totalDeleted" -ForegroundColor Yellow
Write-Host ""

if ($totalDeleted -gt 0) {
    Write-Host "[INFO] Run 'git status' to see changes" -ForegroundColor Cyan
}
