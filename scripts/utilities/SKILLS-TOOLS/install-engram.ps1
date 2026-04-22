param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

function Write-Step { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Try-GetEngramCommand {
    param()

    if ($env:ENGRAM_CMD) {
        return $env:ENGRAM_CMD
    }

    $engram = Get-Command engram -ErrorAction SilentlyContinue
    if ($engram) { return $engram.Source }

    if ($env:GOBIN) {
        $path = Join-Path $env:GOBIN 'engram.exe'
        if (Test-Path $path) { return $path }
        $path = Join-Path $env:GOBIN 'engram'
        if (Test-Path $path) { return $path }
    }

    if ($env:GOPATH) {
        $path = Join-Path $env:GOPATH 'bin\engram.exe'
        if (Test-Path $path) { return $path }
        $path = Join-Path $env:GOPATH 'bin\engram'
        if (Test-Path $path) { return $path }
    }

    if ($env:USERPROFILE) {
        $path = Join-Path $env:USERPROFILE 'go\bin\engram.exe'
        if (Test-Path $path) { return $path }
        $path = Join-Path $env:USERPROFILE 'go\bin\engram'
        if (Test-Path $path) { return $path }
    }

    if ($env:HOME) {
        $path = Join-Path $env:HOME 'go/bin/engram'
        if (Test-Path $path) { return $path }
    }

    return $null
}

function Install-Engram {
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Error "Go CLI not found. Install Go first: https://go.dev/"
        exit 1
    }

    Write-Step "Installing Engram CLI via Go..."
    try {
        & go install github.com/Gentleman-Programming/engram/cmd/engram@latest
    } catch {
        Write-Error "Engram installation failed: $($_.Exception.Message)"
        exit 1
    }

    $installed = Try-GetEngramCommand
    if ($installed) {
        Write-Success "Engram installed at: $installed"
        return $installed
    }

    Write-Warning "Engram installed but not found in PATH."
    $goBin = if ($env:GOBIN) { $env:GOBIN } elseif ($env:GOPATH) { Join-Path $env:GOPATH 'bin' } elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'go\bin' } else { $null }
    if ($goBin) {
        Write-Host "Check this path: $goBin" -ForegroundColor Yellow
    }
    Write-Host "Add the Go bin directory to your PATH, or set ENGRAM_CMD to the full path to the engram executable." -ForegroundColor Yellow
    exit 1
}

$existing = Try-GetEngramCommand
if ($existing -and -not $Force) {
    Write-Success "Engram already available: $existing"
    exit 0
}

Write-Warning "Engram CLI is required for persistent memory but was not found."
$choice = Read-Host "Do you want to install Engram now? (y/n)"
if ($choice -match '^(y|yes|si|s)$') {
    Install-Engram
} else {
    Write-Warning "Skipping Engram installation. Some features will be limited."
}
