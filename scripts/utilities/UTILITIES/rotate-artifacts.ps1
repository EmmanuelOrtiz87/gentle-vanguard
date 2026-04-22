# rotate-artifacts.ps1
# Rotates generated artifacts keeping only the most recent in the repo,
# while archiving all older files locally (gitignored).
# Supports per-category retention limits via config file.
# Usage: .\rotate-artifacts.ps1 [-MaxRepoFiles <n>] [-MaxLocalFiles <n>] [-Categories <array>] [-ConfigPath <path>]

param(
    [int]$MaxRepoFiles = -1,
    [int]$MaxLocalFiles = -1,
    [string[]]$Categories = @("audits", "sessions", "code-reviews"),
    [string]$ConfigPath = "",
    [switch]$Force
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }
$docsDir = Join-Path $repoRoot 'docs'
$archiveRoot = Join-Path $docsDir '.local-archive'

# Load configuration from file or use defaults
$defaultRetention = @{
    "audits" = @{ "maxRepo" = 5; "maxLocal" = 30 }
    "sessions" = @{ "maxRepo" = 1; "maxLocal" = 30 }
    "code-reviews" = @{ "maxRepo" = 1; "maxLocal" = 30 }
}

$globalMaxRepo = $MaxRepoFiles
$globalMaxLocal = $MaxLocalFiles

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $repoRoot 'config\artifacts-retention.json'
}

if (Test-Path $ConfigPath) {
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if ($config.PSObject.Properties.Name -contains "defaultMaxRepo") {
            $globalMaxRepo = $config.defaultMaxRepo
        }
        if ($config.PSObject.Properties.Name -contains "defaultMaxLocal") {
            $globalMaxLocal = $config.defaultMaxLocal
        }
        Write-Host "[CONFIG] Loaded retention config from $ConfigPath" -ForegroundColor Cyan
    } catch {
        Write-Host "[WARN] Could not load config file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] No config file found, using defaults (repo: $globalMaxRepo, local: $globalMaxLocal)" -ForegroundColor Gray
}

function Get-CategoryRetention {
    param([string]$Category)
    
    $repoLimit = if ($globalMaxRepo -gt 0) { $globalMaxRepo } else { $defaultRetention[$Category].maxRepo }
    $localLimit = if ($globalMaxLocal -gt 0) { $globalMaxLocal } else { $defaultRetention[$Category].maxLocal }
    
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            if ($config.PSObject.Properties.Name -contains "categories") {
                $catConfig = $config.categories.$Category
                if ($catConfig) {
                    if ($catConfig.PSObject.Properties.Name -contains "maxRepo") {
                        $repoLimit = $catConfig.maxRepo
                    }
                    if ($catConfig.PSObject.Properties.Name -contains "maxLocal") {
                        $localLimit = $catConfig.maxLocal
                    }
                }
            }
        } catch {
            # Ignore config errors, use defaults
        }
    }
    
    return @{ "maxRepo" = $repoLimit; "maxLocal" = $localLimit }
}

function Test-NonArtifactDocChanges {
    param([string]$Root)

    $status = git -C $Root status --short -- docs 2>$null
    if ([string]::IsNullOrWhiteSpace($status)) { return $false }

    $allowed = @(
        'docs/audits/',
        'docs/sessions/',
        'docs/code-reviews/',
        'docs/.local-archive/'
    )

    foreach ($line in ($status -split "`n")) {
        $trim = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trim)) { continue }
        $path = $trim.Substring(3)

        $isAllowed = $false
        foreach ($prefix in $allowed) {
            if ($path.Replace('\\','/').StartsWith($prefix)) { $isAllowed = $true; break }
        }

        if (-not $isAllowed) { return $true }
    }

    return $false
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " ARTIFACT ROTATION" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
if ($globalMaxRepo -gt 0) {
    Write-Host " Default max repo files: $globalMaxRepo (override per-category config)" -ForegroundColor Gray
}
if ($globalMaxLocal -gt 0) {
    Write-Host " Default max local files: $globalMaxLocal (override per-category config)" -ForegroundColor Gray
}
Write-Host ""

if (-not $Force -and (Test-NonArtifactDocChanges -Root $repoRoot)) {
    Write-Host "[WARN] Uncommitted docs changes detected outside artifact folders." -ForegroundColor Yellow
    Write-Host "[WARN] Commit or move those changes before rotating artifacts." -ForegroundColor Yellow
    Write-Host "[INFO] Use -Force to bypass." -ForegroundColor Cyan
    exit 1
}

$totalArchived = 0
$totalDeleted = 0
$totalKept = 0
$totalErrors = 0

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

    $retention = Get-CategoryRetention -Category $category
    $maxRepo = $retention.maxRepo
    $maxLocal = $retention.maxLocal
    
    Write-Host "[$($category.ToUpper())] Found: $count files (max repo: $maxRepo, max local: $maxLocal)" -ForegroundColor Cyan

    if ($count -le $maxRepo) {
        Write-Host "  Keeping all $count files" -ForegroundColor Green
        $totalKept += $count
        continue
    }

    $toArchive = $files | Select-Object -Skip $maxRepo
    $kept = $files | Select-Object -First $maxRepo
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
        try {
            Move-Item -LiteralPath $f.FullName -Destination $destination -Force -ErrorAction Stop
            $totalArchived++
        } catch {
            Write-Host "      [ERROR] Could not archive '$($f.Name)': $($_.Exception.Message)" -ForegroundColor Red
            $totalErrors++
        }
    }

    $archiveFiles = Get-ChildItem -Path $archivePath -Filter "*.md" -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending

    if ($archiveFiles.Count -gt $maxLocal) {
        $archiveDelete = $archiveFiles | Select-Object -Skip $maxLocal
        Write-Host "  Pruning archive: $($archiveDelete.Count) old files" -ForegroundColor Yellow
        foreach ($f in $archiveDelete) {
            try {
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                $totalDeleted++
            } catch {
                Write-Host "      [ERROR] Could not delete archived file '$($f.Name)': $($_.Exception.Message)" -ForegroundColor Red
                $totalErrors++
            }
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
Write-Host " Errors: $totalErrors" -ForegroundColor Red
Write-Host ""

if ($totalDeleted -gt 0) {
    Write-Host "[INFO] Run 'git status' to see changes" -ForegroundColor Cyan
}

if ($totalErrors -gt 0) {
    exit 1
}
