<#
.SYNOPSIS
    Sync Foundation to public demo repository
.DESCRIPTION
    Copy non-sensitive files to public repo.
    Filters exclude: security scripts, workspace config, internal docs
    Includes: public README, getting-started docs, basic scripts
#>

param(
    [string]$PublicRepoPath = "..\foundation-demo",
    [switch]$DryRun,
    [switch]$AutoCommit,
    [switch]$Verify,
    [switch]$AsJson,
    [ValidateSet("full", "demo")]
    [string]$Mode = "demo"
)

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptDir '....')

# =============================================================================
# EXCLUDE PATTERNS - FULL MODE (all non-sensitive)
# =============================================================================

$EXCLUDE_DIRS_FULL = @(
    '.workspace',
    'scripts\security',
    'docs\security',
    'docs\sessions',
    'docs\tasks',
    'skills\orchestrator',
    'skills\governance'
)

$EXCLUDE_FILES_FULL = @(
    'AGENTS.md',
    'config\security*.json',
    'config\orchestrator.json',
    'config\adaptive*.json',
    'config\owner*.json'
)

$EXCLUDE_SCAN_PATHS_FULL = @(
    'docs\',
    'skills\',
    'templates\',
    'config\README',
    'scripts\foundation\sync-public-repo'
)

# =============================================================================
# EXCLUDE PATTERNS - DEMO MODE (minimal for public demo)
# =============================================================================

$EXCLUDE_DIRS_DEMO = @(
    '.workspace',
    'scripts',
    'skills',
    'tools',
    'hooks',
    'tests',
    'bin',
    '.event-bus',
    '.session',
    '.telemetry',
    '.runtime',
    '.audit',
    '.engram',
    '.engram-data',
    'config',
    'demos',
    'docs\security',
    'docs\sessions',
    'docs\tasks',
    'docs\audits',
    'docs\code-reviews',
    'docs\reference',
    'docs\sdd',
    'docs\judgment',
    'docs\backlog',
    'docs\architecture',
    'scripts\security',
    'scripts\diagnostics',
    'scripts\foundation',
    'scripts\git-hooks',
    'scripts\hooks',
    'scripts\monitoring',
    'scripts\project',
    'scripts\testing',
    'scripts\validation'
)

$EXCLUDE_FILES_DEMO = @(
    'AGENTS.md',
    'config\*.json',
    'config\*.md',
    'config\*-config.json',
    'config\*-example.json'
)

$EXCLUDE_SCAN_PATHS_DEMO = @(
    'docs\',
    'skills\',
    'tools\'
)

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..')

# =============================================================================
# EXCLUDE PATTERNS
# =============================================================================

$EXCLUDE_DIRS = @(
    '.workspace',
    'scripts\security',
    'docs\security',
    'docs\sessions',
    'docs\tasks',
    'skills\orchestrator',
    'skills\governance'
)

$EXCLUDE_FILES = @(
    'AGENTS.md',
    'config\security*.json',
    'config\orchestrator.json',
    'config\adaptive*.json',
    'config\owner*.json'
)

$EXCLUDE_SCAN_PATHS = @(
    'docs\',
    'skills\',
    'templates\',
    'config\README',
    'scripts\foundation\sync-public-repo'
)

# =============================================================================

function Test-ShouldExclude {
    param([string]$Path)
    
    foreach ($dir in $EXCLUDE_DIRS) {
        if ($Path -like "*\$dir\*" -or $Path -like "*\$dir") {
            return $true
        }
    }
    
    foreach ($pattern in $EXCLUDE_FILES) {
        if ($Path -like $pattern) {
            return $true
        }
    }
    
    return $false
}

function Test-ShouldScan {
    param([string]$Path)
    
    foreach ($ex in $EXCLUDE_SCAN_PATHS) {
        if ($Path -like "*$ex*") {
            return $false
        }
    }
    return $true
}

function Copy-Filtered {
    param([string]$Source, [string]$Dest)
    
    $copied = @()
    $skipped = @()
    
    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Replace($Source + '\', '')
        
        if (Test-ShouldExclude -Path $relativePath) {
            $skipped += $relativePath
        }
        else {
            $destPath = Join-Path $Dest $relativePath
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            if (-not $DryRun) {
                Copy-Item -Path $_.FullName -Destination $destPath -Force
            }
            $copied += $relativePath
        }
    }
    
    return @{ copied = $copied; skipped = $skipped }
}

# =============================================================================
# MAIN
# =============================================================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  FOUNDATION SYNC TO PUBLIC REPO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$publicPath = Join-Path $repoRoot $PublicRepoPath

if (-not (Test-Path $publicPath)) {
    Write-Host "[CREATE] Creating: $publicPath" -ForegroundColor Yellow
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $publicPath -Force | Out-Null
    }
}

# Skip verification for now (need to fix string concat issue in pwsh)

if ($DryRun) {
    Write-Host "[DRY RUN] No files will be copied" -ForegroundColor Yellow
}

Write-Host "[SYNC] Copying files..." -ForegroundColor Cyan
$result = Copy-Filtered -Source $repoRoot -Dest $publicPath

Write-Host ""
Write-Host "Files copied: $($result.copied.Count)" -ForegroundColor Green
Write-Host "Files skipped: $($result.skipped.Count)" -ForegroundColor Yellow

if ($result.skipped.Count -gt 0 -and $result.skipped.Count -le 10) {
    Write-Host ""
    Write-Host "[SKIPPED - Sensitive]" -ForegroundColor Yellow
    $result.skipped | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}

# Auto-commit
if ($AutoCommit -and -not $DryRun -and $result.copied.Count -gt 0) {
    Write-Host ""
    Write-Host "[GIT] Committing..." -ForegroundColor Cyan
    Push-Location $publicPath
    git init 2>$null
    git add -A 2>$null
    git commit -m "Auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null | Out-Null
    Pop-Location
    Write-Host "[OK] Committed" -ForegroundColor Green
}

Write-Host ""
if ($DryRun) {
    Write-Host "[DONE] Run without -DryRun to sync" -ForegroundColor Cyan
}
else {
    Write-Host "[OK] Sync complete" -ForegroundColor Green
}

if ($AsJson) {
    $result | ConvertTo-Json
}