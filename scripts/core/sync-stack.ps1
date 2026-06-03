# sync-stack.ps1
# Synchronize Gentle-Vanguard stack with latest remote release or local updates
# Useful for updating installed Gentle-Vanguard without re-running the installer

param(
    [ValidateSet('remote', 'local', 'check')]
    [string]$Source = 'check',
    [switch]$DryRun,
    [switch]$Force,
    [string]$RemoteUrl = 'https://github.com/EmmanuelOrtiz87/gentle-vanguard',
    [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($PSScriptRoot) { (Resolve-Path (Join-Path $scriptDir '..\...')).Path } else { Get-Location }
$script:homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }

function Write-Step { param([string]$msg) Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-OK { param([string]$msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err { param([string]$msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Detect Gentle-Vanguard installation location
$gentle-vanguardInstall = $null
$possibleLocations = @(
    "C:\Program Files\Gentle-Vanguard",
    "C:\Program Files (x86)\Gentle-Vanguard",
    "$script:homePath\.gentleman",
    "$env:LOCALAPPDATA\Gentle-Vanguard"
)

foreach ($loc in $possibleLocations) {
    if (Test-Path (Join-Path $loc "Gentle-Vanguard-Launcher.exe")) {
        $gentle-vanguardInstall = $loc
        break
    }
}

function Get-LocalVersion {
    $versionFile = Join-Path $repoRoot 'VERSION'
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    return 'unknown'
}

function Get-InstalledVersion {
    if (-not $gentle-vanguardInstall) { return 'not-installed' }
    
    $manifestFile = Join-Path $gentle-vanguardInstall 'integrity-manifest.json'
    if (Test-Path $manifestFile) {
        $manifest = Get-Content $manifestFile -Raw | ConvertFrom-Json
        return $manifest.version -or 'unknown'
    }
    return 'unknown'
}

function Check-Status {
    Write-Step "Gentle-Vanguard Stack Status"
    
    $localVer = Get-LocalVersion
    $installedVer = Get-InstalledVersion
    
    Write-Host "Local Repo Version:       $localVer"
    Write-Host "Installed Version:        $installedVer"
    Write-Host "Gentle-Vanguard Install Path:  $(if ($gentle-vanguardInstall) { $gentle-vanguardInstall } else { 'NOT FOUND' })"
    
    if ($installedVer -eq 'not-installed') {
        Write-Warn "Gentle-Vanguard not detected in standard locations"
        Write-Host "`nTo install Gentle-Vanguard, run:" -ForegroundColor Cyan
        Write-Host "  .\dist\Gentle-Vanguard-Setup.exe" -ForegroundColor Yellow
        return $false
    }
    
    if ($localVer -eq $installedVer) {
        Write-OK "Versions match - stack is up to date"
        return $true
    } else {
        Write-Warn "Version mismatch - update available!"
        Write-Host "  Local:     $localVer" -ForegroundColor Yellow
        Write-Host "  Installed: $installedVer" -ForegroundColor Yellow
        Write-Host "`nTo update, run:" -ForegroundColor Cyan
        Write-Host "  sync-stack.ps1 -Source local -Force" -ForegroundColor Yellow
        return $false
    }
}

function Sync-LocalUpdate {
    if (-not $gentle-vanguardInstall) {
        Write-Err "Gentle-Vanguard not installed. Run Gentle-Vanguard-Setup.exe first."
        return $false
    }
    
    Write-Step "Syncing from local repository"
    
    $protectedSrc = Join-Path $repoRoot 'build\protected'
    $publicSrc = Join-Path $repoRoot 'build\public'
    $protectedDst = Join-Path $gentle-vanguardInstall 'protected'
    $publicDst = Join-Path $gentle-vanguardInstall 'public'
    
    if (-not (Test-Path $protectedSrc)) {
        Write-Err "Protected scripts not found. Run 'build\protect-gentle-vanguard.ps1' first."
        return $false
    }
    
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would sync:" -ForegroundColor Yellow
        Write-Host "  protected/ from $protectedSrc"
        Write-Host "  public/ from $publicSrc"
        return $true
    }
    
    try {
        # Backup existing installation
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupDir = Join-Path $gentle-vanguardInstall "backup-$timestamp"
        Write-Host "Creating backup at: $backupDir" -ForegroundColor Gray
        
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item "$protectedDst\*" "$backupDir\protected" -Recurse -ErrorAction SilentlyContinue
        Copy-Item "$publicDst\*" "$backupDir\public" -Recurse -ErrorAction SilentlyContinue
        
        # Sync new files
        Write-Host "Syncing protected scripts..." -ForegroundColor Gray
        Remove-Item $protectedDst -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item $protectedSrc -Destination $protectedDst -Recurse -Force
        Write-OK "Protected scripts updated"
        
        if (Test-Path $publicSrc) {
            Write-Host "Syncing public skills..." -ForegroundColor Gray
            Remove-Item $publicDst -Recurse -Force -ErrorAction SilentlyContinue
            Copy-Item $publicSrc -Destination $publicDst -Recurse -Force
            Write-OK "Public skills updated"
        }
        
        # Copy integrity manifest if exists
        $manifestSrc = Join-Path $repoRoot 'build\integrity-manifest.json'
        if (Test-Path $manifestSrc) {
            Copy-Item $manifestSrc -Destination (Join-Path $gentle-vanguardInstall 'integrity-manifest.json') -Force
            Write-OK "Integrity manifest updated"
        }
        
        Write-Host ""
        Write-Host "Sync complete! Backup saved to: $backupDir" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Restart your terminal or run: refreshenv"
        Write-Host "  2. Verify with: gv validate"
        Write-Host "  3. If issues occur, restore backup from: $backupDir"
        
        return $true
    } catch {
        Write-Err "Sync failed: $($_.Exception.Message)"
        Write-Warn "Your previous installation is intact in backup-$timestamp"
        return $false
    }
}

function Sync-RemoteUpdate {
    Write-Warn "Remote sync not yet implemented"
    Write-Host "To use latest remote version:" -ForegroundColor Cyan
    Write-Host "  1. Download Gentle-Vanguard-Setup.exe from: $RemoteUrl/releases"
    Write-Host "  2. Run the installer (will upgrade or reinstall)"
    Write-Host "  3. Or manually update from repo and run: sync-stack.ps1 -Source local"
    return $false
}

# Main execution
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Gentle-Vanguard Stack Synchronization" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$result = switch ($Source) {
    'check' { Check-Status }
    'local' { 
        if ($Force) { 
            Sync-LocalUpdate 
        } else { 
            Check-Status
            Write-Host ""
            Write-Host "To sync local updates, run:" -ForegroundColor Cyan
            Write-Host "  sync-stack.ps1 -Source local -Force" -ForegroundColor Yellow
            $false
        }
    }
    'remote' { Sync-RemoteUpdate }
}

Write-Host ""
exit $(if ($result) { 0 } else { 1 })


