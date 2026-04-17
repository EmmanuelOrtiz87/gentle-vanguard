# setup-wizard.ps1
# Unified dependency checker and installer for Workspace Foundation.
# Usage: .\setup-wizard.ps1

param([switch]$Force)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }

function Test-Tool {
    param([string]$Name, [string]$InstallCmd)
    
    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        Write-Ok "$Name is installed."
        return $true
    }
    
    Write-Warn "$Name is missing."
    if ($Force) {
        Write-Host "Installing $Name..." -ForegroundColor Gray
        Invoke-Expression $InstallCmd
        return $?
    }
    
    $choice = Read-Host "Install $Name now? (y/n)"
    if ($choice -match '^(y|yes|si|s)$') {
        Write-Host "Installing $Name..." -ForegroundColor Gray
        Invoke-Expression $InstallCmd
        return $?
    }
    
    return $false
}

Write-Step "Workspace Foundation Setup Wizard"

# 1. Git
Test-Tool -Name "git" -InstallCmd "winget install --id Git.Git -e --source winget"

# 2. Go (Required for Engram/GGA)
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Warn "Go is missing (required for Engram)."
    $choice = Read-Host "Install Go now? (y/n)"
    if ($choice -match '^(y|yes|si|s)$') {
        winget install --id GoLang.Go -e --source winget
    }
}

# 3. Engram
& "$scriptDir\install-engram.ps1" -Force:$Force

Write-Step "Setup Complete!"
Write-Host "Run '.\wf.ps1 health' to verify your environment." -ForegroundColor Cyan
