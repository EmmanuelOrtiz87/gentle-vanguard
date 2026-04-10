#!/usr/bin/env pwsh
# pre-commit.ps1
# Pre-commit hook for Gentleman Foundation projects
# Place this in .githooks/ or configure git to use it

param(
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

$GitRoot = git rev-parse --show-toplevel 2>$null
if (-not $GitRoot) {
    Write-Host "[SKIP] Not in a git repository." -ForegroundColor Yellow
    exit 0
}

$GFRoot = $env:GENTLEMAN_ROOT
if (-not $GFRoot) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSScriptRoot }
    
    $candidate = Split-Path -Parent $scriptDir
    while ($candidate) {
        if (Test-Path (Join-Path $candidate ".gentleman")) {
            $GFRoot = $candidate
            break
        }
        if (Test-Path (Join-Path $candidate "SKILL.md")) {
            $GFRoot = Split-Path -Parent $candidate
            break
        }
        $parent = Split-Path -Parent $candidate
        if (-not $parent -or $parent -eq $candidate) { break }
        $candidate = $parent
    }
}

if (-not $GFRoot) {
    $GFRoot = Join-Path $env:USERPROFILE ".gentleman"
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Gentleman Foundation - Pre-commit" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure tools are active before proceeding
Write-Host "Ensuring development tools are active..." -ForegroundColor Yellow
$healthScript = Join-Path $PSScriptRoot "..\scripts\utilities\ensure-tools-active.ps1"
if (Test-Path $healthScript) {
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $healthScript -Quiet
        Write-Host "[OK] Tools activation check completed." -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Tools activation check failed, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARN] Health check script not found, skipping tools activation." -ForegroundColor Yellow
}
Write-Host ""

$StagedFiles = git diff --cached --name-only --diff-filter=ACM 2>$null
if (-not $StagedFiles) {
    Write-Host "[OK] No files staged for commit." -ForegroundColor Green
    exit 0
}

Write-Host "Scanning staged files..." -ForegroundColor Gray
Write-Host ""

$SecretFound = $false
$CriticalPatterns = @(
    @{ Name = "AWS Access Key"; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = "GitHub Token"; Pattern = 'ghp_[A-Za-z0-9]{36}' },
    @{ Name = "Private Key"; Pattern = '-----BEGIN.*PRIVATE KEY-----' },
    @{ Name = "Generic API Key"; Pattern = '(?i)(api[_-]?key|apikey)["\s]*[=:]["\s]*["''][A-Za-z0-9]{20,}["'']' },
    @{ Name = "Database URL"; Pattern = '(?i)(mysql|postgres|mongodb)://[^:]+:[^@]+@' },
    @{ Name = "Stripe Key"; Pattern = 'sk_live_[0-9a-zA-Z]{24,}' },
    @{ Name = "JWT Token"; Pattern = 'eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+' }
)

foreach ($file in $StagedFiles.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    
    $content = git show ":0:$file" 2>$null
    if (-not $content) { continue }
    
    foreach ($pattern in $CriticalPatterns) {
        if ($content -match $pattern.Pattern) {
            Write-Host "[CRITICAL] $($pattern.Name) detected in: $file" -ForegroundColor Red
            $SecretFound = $true
        }
    }
}

if ($SecretFound) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host " COMMIT BLOCKED - Secrets detected!" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "[OK] Pre-commit checks passed!" -ForegroundColor Green
Write-Host ""

exit 0
