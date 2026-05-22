# sync-skills.ps1
# Sync skills to global gentle-vanguard installation
# Creates symlinks for easy updates

param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Copy,
    [switch]$Symlink,
    [string]$Source = "",
    [string]$Target = ""
)

$ErrorActionPreference = 'Stop'

$scriptDir = if ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Get-Location
}

if (-not $Source) {
    $possibleSources = @(
        (Join-Path (Split-Path -Parent $scriptDir) 'skills'),
        (Join-Path $scriptDir '..\skills'),
        ".\gentle-vanguard\\skills"
    )
    
    foreach ($loc in $possibleSources) {
        if (Test-Path $loc) {
            $Source = $loc
            break
        }
    }
}

$script:homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }

if (-not $Target) {
    $possibleTargets = @(
        (Join-Path $script:homePath ".gentleman\skills"),
        (Join-Path $script:homePath ".claude\skills"),
        (Join-Path $scriptDir "..\skills")
    )
    
    foreach ($loc in $possibleTargets) {
        if (Test-Path (Split-Path -Parent $loc)) {
            $Target = $loc
            break
        }
    }
}

if (-not $Source) {
    Write-Host "Source skills directory not found." -ForegroundColor Red
    exit 1
}

if (-not $Target) {
    Write-Host "Target directory path invalid." -ForegroundColor Red
    exit 1
}

$UseSymlink = -not $Copy
if (-not $Symlink -and -not $Copy) {
    $UseSymlink = $true
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Skipped {
    param([string]$Message)
    Write-Host "[SKIP] $Message" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Skill Synchronization" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Source: $Source"
Write-Host "Target: $Target"
Write-Host "Mode:   $(if ($UseSymlink) { 'Symlinks' } else { 'Copy' })"
Write-Host ""

if (-not (Test-Path $Source)) {
    Write-Host "Source not found: $Source" -ForegroundColor Red
    exit 1
}

$targetParent = Split-Path -Parent $Target
if (-not (Test-Path $targetParent)) {
    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
}

if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}

Write-Step "Scanning Source Skills"
$sourceSkills = Get-ChildItem -Path $Source -Directory | Where-Object { 
    Test-Path (Join-Path $_.FullName 'SKILL.md') 
}

Write-Host "Found $($sourceSkills.Count) skills"
Write-Host ""

$syncCount = 0
$skipCount = 0
$failCount = 0

Write-Step "Syncing Skills"

foreach ($skill in $sourceSkills) {
    $destPath = Join-Path $Target $skill.Name
    
    if ((Test-Path $destPath) -and -not $Force) {
        Write-Skipped "$($skill.Name) (exists)"
        $skipCount++
        continue
    }
    
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would sync: $($skill.Name)" -ForegroundColor Cyan
        continue
    }
    
    if (Test-Path $destPath) {
        if ((Get-Item $destPath).LinkType -eq "SymbolicLink") {
            Remove-Item $destPath -Force
        } else {
            Remove-Item -Recurse -Force $destPath
        }
    }
    
    if ($UseSymlink) {
        try {
            New-Item -ItemType SymbolicLink -Path $destPath -Target $skill.FullName -Force | Out-Null
            Write-Success "[SYMLINK] $($skill.Name)"
            $syncCount++
        } catch {
            Write-Host "[COPY] Symlink failed, copying: $($skill.Name)" -ForegroundColor Yellow
            Copy-Item -Path $skill.FullName -Destination $destPath -Recurse -Force
            $syncCount++
        }
    } else {
        Copy-Item -Path $skill.FullName -Destination $destPath -Recurse -Force
        Write-Success "[COPY] $($skill.Name)"
        $syncCount++
    }
}

Write-Step "Updating SKILL_INDEX.md"
$sourceIndex = Join-Path $Source 'SKILL_INDEX.md'
$targetIndex = Join-Path $Target 'SKILL_INDEX.md'

if (Test-Path $sourceIndex) {
    if ($UseSymlink) {
        try {
            if (Test-Path $targetIndex) { Remove-Item $targetIndex -Force }
            New-Item -ItemType SymbolicLink -Path $targetIndex -Target $sourceIndex -Force | Out-Null
            Write-Success "SKILL_INDEX.md symlinked"
        } catch {
            Copy-Item -Path $sourceIndex -Destination $Target -Force
            Write-Success "SKILL_INDEX.md copied"
        }
    } else {
        Copy-Item -Path $sourceIndex -Destination $Target -Force
        Write-Success "SKILL_INDEX.md copied"
    }
}

Write-Step "Summary"
Write-Host ""
Write-Host "  Synced:   $syncCount" -ForegroundColor Green
Write-Host "  Skipped:  $skipCount" -ForegroundColor Yellow
Write-Host "  Failed:   $failCount" -ForegroundColor Red
Write-Host "  Total:    $($sourceSkills.Count)"
Write-Host ""

if (-not $DryRun) {
    Write-Host "Skills synchronized successfully!" -ForegroundColor Green
    Write-Host "Run 'gv validate' to verify installation."
}

exit $(if ($failCount -gt 0) { 1 } else { 0 })


