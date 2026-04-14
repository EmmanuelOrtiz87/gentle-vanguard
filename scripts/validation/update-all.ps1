# update-all.ps1
# Update Gentleman Foundation and all related tools

param(
    [switch]$All,
    [switch]$Foundation,
    [switch]$Skills,
    [switch]$Tools,
    [switch]$DryRun,
    [switch]$Force,
    [string]$Source = ""
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSScriptRoot }

$GFRoot = Join-Path $env:USERPROFILE ".gentleman"

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

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Invoke-LocalPowerShellScript {
    param(
        [string]$ScriptPath,
        [string[]]$ScriptArgs = @()
    )

    & $ScriptPath @ScriptArgs
}

function Update-Skills {
    Write-Step "Updating Skills"
    
    $skillsSource = if ($Source) { 
        $src = Join-Path $Source "skills"
        if (Test-Path $src) { $src } else { $null }
    } else {
        $src = Join-Path (Split-Path -Parent $scriptDir) "skills"
        if (Test-Path $src) { $src } else { $null }
    }
    
    if (-not $skillsSource) {
        Write-Err "Skills source not found"
        return $false
    }
    
    $syncScript = Join-Path $scriptDir "sync-skills.ps1"
    if (Test-Path $syncScript) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would sync skills from: $skillsSource" -ForegroundColor Cyan
        } else {
            & $syncScript -Force
        }
        Write-Success "Skills updated"
        return $true
    } else {
        Write-Err "Sync script not found"
        return $false
    }
}

function Update-Foundation {
    Write-Step "Updating Foundation"
    
    if (-not $Source) {
        $possibleSources = @(
            (Split-Path -Parent $scriptDir),
            "C:\Workspace_local\workspace-foundation",
            "C:\Workspace_local\gentleman-foundation"
        )
        
        foreach ($src in $possibleSources) {
            if (Test-Path $src) {
                $Source = $src
                break
            }
        }
    }
    
    if (-not $Source -or -not (Test-Path $Source)) {
        Write-Err "Foundation source not found. Specify with -Source parameter."
        return $false
    }
    
    Push-Location $Source
    try {
        Write-Host "Fetching latest from remote..." -ForegroundColor Gray
        git fetch origin 2>$null
        
        $local = git rev-parse HEAD
        $remote = git rev-parse "origin/$(git rev-parse --abbrev-ref HEAD)"
        
        if ($local -eq $remote) {
            Write-Skipped "Foundation already up to date"
            return $true
        }
        
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would update foundation" -ForegroundColor Cyan
            return $true
        }
        
        Write-Host "Pulling latest changes..." -ForegroundColor Gray
        git pull origin (git rev-parse --abbrev-ref HEAD)
        
        $versionFile = Join-Path $GFRoot "foundation.version"
        if (Test-Path $versionFile) {
            $vf = Get-Content $versionFile | ConvertFrom-Json
            $vf.version = "updated-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            $vf | ConvertTo-Json | Set-Content -Path $versionFile
        }
        
        Write-Success "Foundation updated to latest"
        return $true
    } catch {
        Write-Err "Failed to update: $($_.Exception.Message)"
        return $false
    } finally {
        Pop-Location
    }
}

function Install-Tool {
    param([string]$Name, [string]$InstallCommand, [string]$VerifyCommand)
    
    Write-Host "Installing $Name..." -ForegroundColor Gray
    
    try {
        Invoke-Expression $InstallCommand 2>$null | Out-Null
        $installed = Get-Command $VerifyCommand -ErrorAction SilentlyContinue
        if ($installed) {
            Write-Success "$Name installed"
            return $true
        } else {
            Write-Err "$Name installation failed"
            return $false
        }
    } catch {
        Write-Err "$Name install error: $($_.Exception.Message)"
        return $false
    }
}

function Update-Tools {
    Write-Step "Updating Tools"
    # Delegate to the canonical tool updater which installs gga, engram, and gentle-ai.
    $toolsScript = Join-Path $scriptDir "..\utilities\update-tools.ps1"
    if (-not (Test-Path $toolsScript)) {
        Write-Err "update-tools.ps1 not found at: $toolsScript"
        return $false
    }
    if ($DryRun -and $Force) {
        & $toolsScript -DryRun -Force
    } elseif ($DryRun) {
        & $toolsScript -DryRun
    } elseif ($Force) {
        & $toolsScript -Force
    } else {
        & $toolsScript
    }
    return $?
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Gentleman Foundation - Update All" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if (-not $All -and -not $Foundation -and -not $Skills -and -not $Tools) {
    $All = $true
}

$success = $true

if ($All -or $Foundation) {
    $result = Update-Foundation
    if (-not $result) { $success = $false }
}

if ($All -or $Skills) {
    $result = Update-Skills
    if (-not $result) { $success = $false }
}

if ($All -or $Tools) {
    $result = Update-Tools
    if (-not $result) { $success = $false }
}

Write-Step "Update Complete"
Write-Host ""

if ($success) {
    Write-Success "All updates completed successfully!"
    Write-Host ""
    Write-Host "Restart terminal or run 'gf validate' to verify." -ForegroundColor Gray
} else {
    Write-Err "Some updates failed. Check logs above."
}

exit $(if ($success) { 0 } else { 1 })
