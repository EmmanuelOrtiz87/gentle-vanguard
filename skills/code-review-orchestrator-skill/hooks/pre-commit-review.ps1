#!/usr/bin/env pwsh
# pre-commit-review.ps1
# Unified pre-commit hook for Code Review Orchestrator
# Fast scan optimized for pre-commit performance

param(
    [string]$Path = ".",
    [switch]$Fast,
    [switch]$BlockOnCritical
)

$ErrorActionPreference = 'Continue'

$HookStart = Get-Date
$GitRoot = git rev-parse --show-toplevel 2>$null
if (-not $GitRoot) {
    Write-Host "[SKIP] Not in a git repository." -ForegroundColor Yellow
    exit 0
}

$SkillDir = Split-Path $PSScriptRoot -Parent
$ReviewScript = Join-Path $SkillDir "code-review.ps1"

if (-not (Test-Path $ReviewScript)) {
    Write-Host "[SKIP] Code Review Orchestrator not found." -ForegroundColor Yellow
    exit 0
}

$StagedFiles = git diff --cached --name-only --diff-filter=ACM 2>$null
if (-not $StagedFiles) {
    Write-Host "[OK] No files staged for commit." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Code Review - Pre-commit Scan" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$IsWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)

$HookMarker = if ($IsWindows) { ".hooks\pre-commit.marker" } else { ".hooks/pre-commit.marker" }
$markerPath = Join-Path $GitRoot $HookMarker

$IsReentrant = Test-Path $markerPath
if ($IsReentrant) {
    Write-Host "[SKIP] Reentrant hook detected. Skipping nested execution." -ForegroundColor Yellow
    exit 0
}

try {
    New-Item -ItemType File -Path $markerPath -Force | Out-Null

    Write-Host "Scanning staged files for issues..." -ForegroundColor Gray
    Write-Host ""

    $CriticalPatterns = @(
        @{ Name = "AWS Access Key"; Pattern = "AKIA[0-9A-Z]{16}"; Severity = "CRITICAL" },
        @{ Name = "GitHub Token"; Pattern = "ghp_[A-Za-z0-9]{36}"; Severity = "CRITICAL" },
        @{ Name = "Private Key"; Pattern = "-----BEGIN.*PRIVATE KEY-----"; Severity = "CRITICAL" },
        @{ Name = "Stripe Key"; Pattern = "sk_live_[0-9a-zA-Z]{24,}"; Severity = "CRITICAL" },
        @{ Name = "SendGrid Key"; Pattern = "SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}"; Severity = "CRITICAL" },
        @{ Name = "Generic API Key"; Pattern = "(?i)(api[_-]?key|apikey)[\"'\s]*[=:][\"'\s]*[A-Za-z0-9]{20,}"; Severity = "HIGH" },
        @{ Name = "Database URL"; Pattern = "(?i)(mysql|postgres|mongodb)://[^:\s]+:[^@\s]+@"; Severity = "HIGH" }
    )

    $CriticalFound = $false
    $HighFound = $false

    foreach ($file in $StagedFiles.Split("`n")) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        
        $content = git show ":0:$file" 2>$null
        if (-not $content) { continue }
        
        foreach ($pattern in $CriticalPatterns) {
            if ($content -match $pattern.Pattern) {
                $color = if ($pattern.Severity -eq "CRITICAL") { "Red" } else { "Magenta" }
                Write-Host "  [$($pattern.Severity)] $file - $($pattern.Name)" -ForegroundColor $color
                
                if ($pattern.Severity -eq "CRITICAL") { $CriticalFound = $true }
                if ($pattern.Severity -eq "HIGH") { $HighFound = $true }
            }
        }
    }

    Write-Host ""

    if ($CriticalFound) {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host " BLOCKED - Critical issues detected!" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Critical secrets detected in staged files." -ForegroundColor White
        Write-Host "Remove or secure credentials before committing." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Run 'gv review security' for details." -ForegroundColor Gray
        Write-Host ""
        
        Remove-Item $markerPath -Force -ErrorAction SilentlyContinue
        exit 1
    }

    if ($Fast) {
        Write-Host "[OK] Fast scan passed (no critical issues)" -ForegroundColor Green
        
        Remove-Item $markerPath -Force -ErrorAction SilentlyContinue
        exit 0
    }

    Write-Host "Running full orchestrator scan..." -ForegroundColor Gray
    Write-Host ""

    $scanParams = @{
        Scope = 'quick'
        Path = $GitRoot
        Verbose = $false
    }

    & $ReviewScript @scanParams 2>&1 | Out-Null

    $exitCode = $LASTEXITCODE

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Scan completed in $([math]::Round(((Get-Date) - $HookStart).TotalSeconds))s" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Remove-Item $markerPath -Force -ErrorAction SilentlyContinue

    if ($exitCode -eq 1) {
        Write-Host "Run 'gv review' for detailed report." -ForegroundColor Yellow
    }

    exit $exitCode

} catch {
    Write-Host "[WARN] Pre-commit scan encountered an error: $_" -ForegroundColor Yellow
    Remove-Item $markerPath -Force -ErrorAction SilentlyContinue
    exit 0
}

