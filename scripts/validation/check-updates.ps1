# check-updates.ps1
# Check system status - Agnostic detection

param(
    [switch]$All,
    [switch]$Core,
    [switch]$Skills,
    [switch]$Tools,
    [string]$Source = ""
)

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSScriptRoot }

$GFRoot = Join-Path $env:USERPROFILE ".gentleman"
if (-not (Test-Path $GFRoot)) {
    $GFRoot = Split-Path -Parent $scriptDir
}

$versionFile = Join-Path $GFRoot "foundation.version"

function Write-Check {
    param([string]$Name, [string]$Status, [string]$Message = "")
    $color = switch ($Status) {
        "OK" { "Green" }
        "WARN" { "Yellow" }
        "MISSING" { "Red" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$Status] $Name" -ForegroundColor $color
    if ($Message) {
        Write-Host "       $Message" -ForegroundColor Gray
    }
}

function Get-CommandVersion {
    param([string]$Command)
    
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    
    try {
        $output = & $Command --version 2>$null
        if (-not $output) { $output = & $Command version 2>$null }
        if (-not $output) { $output = & $Command -v 2>$null }
        
        if ($output) {
            if ($output -is [array]) { return $output[0].ToString().Trim() }
            return $output.ToString().Trim()
        }
    } catch {
        Write-Verbose "Version check failed for command: $Command"
    }
    
    return "installed"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Gentleman Foundation - System Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $All -and -not $Core -and -not $Skills -and -not $Tools) {
    $All = $true
}

if ($All -or $Core) {
    Write-Host "Core Requirements" -ForegroundColor Yellow
    Write-Host "----------------"
    
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        $version = git --version 2>$null
        Write-Check "git" "OK" $version
    } else {
        Write-Check "git" "MISSING" "Required - install with: winget install Git.Git"
    }
    
    $ps = $PSVersionTable.PSVersion
    Write-Check "PowerShell" "OK" "v$($ps.Major).$($ps.Minor)"
    
    $opencode = Get-Command opencode -ErrorAction SilentlyContinue
    if ($opencode) {
        Write-Check "opencode" "OK" "AI Agent installed"
    } else {
        Write-Check "opencode" "WARN" "Not installed (optional - any AI agent works)"
    }
    
    Write-Host ""
}

if ($All -or $Skills) {
    Write-Host "Foundation Status" -ForegroundColor Yellow
    Write-Host "-----------------"
    
    if (Test-Path $versionFile) {
        $vf = Get-Content $versionFile | ConvertFrom-Json
        Write-Check "Foundation" "OK" "v$($vf.version) (installed: $($vf.installed))"
    } else {
        Write-Check "Foundation" "MISSING" "Run bootstrap-machine.ps1"
    }
    
    $skillsDir = Join-Path $GFRoot "skills"
    if (Test-Path $skillsDir) {
        $count = (Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue).Count
        Write-Check "Skills" "OK" "$count skills installed"
    } else {
        Write-Check "Skills" "MISSING" "Skills directory not found"
    }
    
    $hooks = git config --global core.hooksPath 2>$null
    if ($hooks) {
        Write-Check "Git Hooks" "OK" $hooks
    } else {
        Write-Check "Git Hooks" "WARN" "Not configured"
    }
    
    Write-Host ""
}

if ($All -or $Tools) {
    Write-Host "Optional Tools" -ForegroundColor Yellow
    Write-Host "-------------"
    
    $gga = Get-Command gga -ErrorAction SilentlyContinue
    if ($gga) {
        Write-Check "gga" "OK" "AI-powered code review"
    } else {
        Write-Check "gga" "MISSING" "AI-powered code review"
        Write-Host "       Install: git clone + bash install.sh (see scripts/utilities/update-tools.ps1)" -ForegroundColor Gray
    }
    
    $engram = Get-Command engram -ErrorAction SilentlyContinue
    if ($engram) {
        Write-Check "engram" "OK" "Persistent memory"
    } else {
        Write-Check "engram" "MISSING" "Persistent memory"
        Write-Host "       Install: go install github.com/Gentleman-Programming/engram/cmd/engram@latest" -ForegroundColor Gray
    }
    
    $gentleAi = Get-Command gentle-ai -ErrorAction SilentlyContinue
    if ($gentleAi) {
        Write-Check "gentle-ai" "OK" "Ecosystem configurator"
    } else {
        Write-Check "gentle-ai" "MISSING" "Ecosystem configurator"
        Write-Host "       Install: go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest" -ForegroundColor Gray
    }
    
    $cfgPath   = Join-Path (Split-Path -Parent $scriptDir) 'config\workspace.config.json'
    $toolsRoot = if (Test-Path $cfgPath) {
        $c = Get-Content $cfgPath -Raw | ConvertFrom-Json
        if ($c.toolsRoot) { Join-Path (Split-Path -Parent $scriptDir) $c.toolsRoot } else { Join-Path (Split-Path -Parent $scriptDir) 'tools' }
    } else { Join-Path (Split-Path -Parent $scriptDir) 'tools' }
    $skillsDir = Join-Path $toolsRoot 'Gentleman-Skills'
    if (Test-Path $skillsDir) {
        Write-Check "gentleman-skills" "OK" "AI skills library"
    } else {
        Write-Check "gentleman-skills" "MISSING" "AI skills library"
        Write-Host "       Install: git clone https://github.com/Gentleman-Programming/Gentleman-Skills.git $skillsDir" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Optional: These enhance the foundation but are not required." -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($All -or $Core -or $Skills) {
    Write-Host ""
    Write-Host "To fix missing items:" -ForegroundColor Yellow
    Write-Host "  1. Run .\scripts\foundation\bootstrap-machine.ps1" -ForegroundColor White
    Write-Host "  2. Restart terminal" -ForegroundColor White
    Write-Host "  3. Run gf validate" -ForegroundColor White
}

Write-Host ""
