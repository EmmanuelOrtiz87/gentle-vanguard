#!/usr/bin/env pwsh
# pre-commit-security.ps1
# Security pre-commit hook (Windows)
# Place this file in .git/hooks/ as pre-commit

param(
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

$GitRoot = git rev-parse --show-toplevel 2>$null
if (-not $GitRoot) {
    Write-Host "[SKIP] Not in a git repository." -ForegroundColor Yellow
    exit 0
}

$SkillDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SkillDir) { $SkillDir = Split-Path -Parent $PSScriptRoot }
while ($SkillDir -and (Split-Path -Parent $SkillDir)) {
    $parent = Split-Path -Parent $SkillDir
    if (Test-Path (Join-Path $parent 'SKILL.md')) {
        $SkillDir = $parent
        break
    }
    $SkillDir = $parent
}
$ScanScript = Join-Path $SkillDir 'security-scan.ps1'
$HookBackup = Join-Path $GitRoot '.git\hooks\pre-commit.backup.ps1'

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Security Expert - Pre-commit Scan" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $ScanScript)) {
    Write-Host "[SKIP] Security skill not found. Run 'gv skills --install' to install." -ForegroundColor Yellow
    exit 0
}

$StagedFiles = git diff --cached --name-only --diff-filter=ACM 2>$null
if (-not $StagedFiles) {
    Write-Host "[OK] No files staged for commit." -ForegroundColor Green
    exit 0
}

Write-Host "Scanning staged files for security issues..." -ForegroundColor Gray
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
    Write-Host "Remove secrets from staged files or use environment variables." -ForegroundColor White
    Write-Host "See: docs/security-best-practices.md" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "Running security scanner..." -ForegroundColor Gray
& $ScanScript -Path $GitRoot -Interactive:$(-not $Force)

$ScanResult = $LASTEXITCODE

if ($ScanResult -eq 1) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host " COMMIT BLOCKED - Security issues found!" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run 'gv security audit' for detailed report." -ForegroundColor White
    Write-Host "Run 'gv security scan --interactive' to review and fix." -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "[OK] Security scan passed!" -ForegroundColor Green
Write-Host ""

exit 0

