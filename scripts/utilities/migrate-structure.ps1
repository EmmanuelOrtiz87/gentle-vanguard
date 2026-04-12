<#
.SYNOPSIS
    Preflight report and guided migration of loose scripts to canonical subdirectories.

.DESCRIPTION
    Reads config/structure-policy.json for allowed directories.
    Scans scripts/ root for files that should be in a canonical subdirectory.
    Presents an impact report and requires user confirmation (or -Force) before moving.
    Generates rollback commands after each move.

.PARAMETER DryRun
    Only print the preflight report. No files are moved.

.PARAMETER Force
    Skip confirmation prompt. Execute moves immediately.

.EXAMPLE
    .\scripts\utilities\migrate-structure.ps1 -DryRun
    .\scripts\utilities\migrate-structure.ps1
    .\scripts\utilities\migrate-structure.ps1 -Force
#>
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

function Write-Step  { param([string]$M) Write-Host "`n=== $M ===" -ForegroundColor Cyan }
function Write-Ok    { param([string]$M) Write-Host "[OK]   $M"   -ForegroundColor Green }
function Write-Warn  { param([string]$M) Write-Host "[WARN] $M"   -ForegroundColor Yellow }
function Write-Info  { param([string]$M) Write-Host "       $M"   -ForegroundColor White }
function Write-Fatal { param([string]$M) Write-Host "[FAIL] $M"   -ForegroundColor Red }

# -----------------------------------------------------------------------
# Load policy
# -----------------------------------------------------------------------
$policyFile = Join-Path $repoRoot 'config/structure-policy.json'
if (-not (Test-Path $policyFile)) {
    Write-Fatal "config/structure-policy.json not found. Cannot determine canonical directories."
    exit 1
}
$policy = Get-Content $policyFile -Raw | ConvertFrom-Json
$allowedRootFiles    = $policy.allowedRootFiles    ?? @('README.md')
$allowedScriptDirs   = $policy.allowedScriptDirs   ?? @()
$policyMode          = $policy.structureMode       ?? 'adopt-existing'

Write-Step "Structure Migration Preflight"
Write-Info "Policy mode   : $policyMode"
Write-Info "Allowed dirs  : $($allowedScriptDirs -join ', ')"

# -----------------------------------------------------------------------
# Scan scripts/ root for loose files
# -----------------------------------------------------------------------
$scriptsRoot = Join-Path $repoRoot 'scripts'
$looseFiles  = Get-ChildItem -Path $scriptsRoot -File -ErrorAction SilentlyContinue |
    Where-Object { $allowedRootFiles -notcontains $_.Name }

if ($looseFiles.Count -eq 0) {
    Write-Ok "No loose files found at scripts/ root. Nothing to migrate."
    exit 0
}

# -----------------------------------------------------------------------
# Heuristic: decide canonical destination for each loose file
# -----------------------------------------------------------------------
function Resolve-CanonicalDir {
    param([string]$FileName)
    $n = $FileName.ToLower()
    if ($n -match 'validate|diagnos|audit|check|lint|test')  { return 'scripts/diagnostics' }
    if ($n -match 'install|setup|init|bootstrap|project')    { return 'scripts/project' }
    if ($n -match 'update|sync|refresh|upgrade')              { return 'scripts/validation' }
    if ($n -match 'hook|post-|pre-')                          { return 'scripts/git-hooks' }
    if ($n -match 'foundation|scaffold')                      { return 'scripts/foundation' }
    return 'scripts/utilities'
}

Write-Step "Preflight Report — Files to Migrate"
$plan = @()
foreach ($file in $looseFiles) {
    $relSrc  = $file.FullName.Replace("$($repoRoot.Path)\", '').Replace('\', '/')
    $destDir = Resolve-CanonicalDir -FileName $file.Name
    $relDst  = "$destDir/$($file.Name)"
    $plan   += [PSCustomObject]@{ File = $file; RelSrc = $relSrc; RelDst = $relDst; DestDir = $destDir }

    Write-Info "  $relSrc"
    Write-Info "  -> $relDst"
    Write-Info ""
}

Write-Warn "RISK: Any hardcoded references to old paths in scripts, docs, or CI must be updated manually after migration."
Write-Warn "      Review internal references before proceeding."

if ($DryRun) {
    Write-Step "Dry-run complete. No files moved."
    Write-Info "Re-run without -DryRun to apply, or with -Force to skip confirmation."
    exit 0
}

# -----------------------------------------------------------------------
# Confirm
# -----------------------------------------------------------------------
if (-not $Force) {
    Write-Host ""
    Write-Host "Proceed with migration? [y/N] " -ForegroundColor Yellow -NoNewline
    $answer = Read-Host
    if ($answer -notmatch '^[Yy]$') {
        Write-Warn "Migration cancelled by user."
        exit 0
    }
}

# -----------------------------------------------------------------------
# Execute migration with rollback tracking
# -----------------------------------------------------------------------
Write-Step "Executing migration"
$rollback = @()

foreach ($item in $plan) {
    $destDirFull = Join-Path $repoRoot $item.DestDir
    if (-not (Test-Path $destDirFull)) {
        New-Item -ItemType Directory -Path $destDirFull -Force | Out-Null
    }

    # Use git mv to preserve history
    $gitResult = git -C $repoRoot mv $item.RelSrc $item.RelDst 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fatal "git mv failed for $($item.RelSrc): $gitResult"
        Write-Warn  "Partial migration completed. Run rollback commands below to revert."
        break
    }

    Write-Ok "$($item.RelSrc) -> $($item.RelDst)"
    $rollback += "git -C . mv `"$($item.RelDst)`" `"$($item.RelSrc)`""
}

# -----------------------------------------------------------------------
# Rollback reference
# -----------------------------------------------------------------------
Write-Step "Rollback Commands (run in repo root to revert all moves)"
Write-Host ""
foreach ($cmd in $rollback) {
    Write-Host "  $cmd" -ForegroundColor DarkYellow
}
Write-Host ""
Write-Warn "Remember: update all internal path references after migration."
Write-Ok   "Migration complete. Run governance validator to confirm: .\scripts\diagnostics\validate-script-governance.ps1"
exit 0
