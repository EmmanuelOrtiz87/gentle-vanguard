# Pre-commit Privacy Hook
# Bloquea commits que contengan data sensible

#Requires -Version 5.1

param(
    [Parameter(ValueFromPipeline)]
    [string[]]$FilePaths,
    
    [switch]$Staged,
    
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'

# =============================================================================
# PATRONES CRITICOS (Bloqueo inmediato)
# =============================================================================

$CRITICAL_PATTERNS = @(
    @{ Name = 'AWS Key'; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = 'GitHub Token'; Pattern = 'ghp_[A-Za-z0-9]{36}' },
    @{ Name = 'Stripe Key'; Pattern = 'sk_live_[0-9a-zA-Z]{24,}' },
    @{ Name = 'Private Key'; Pattern = '-----' + 'BEGIN (RSA|EC|DSA|PRIVATE) KEY-----' },
    @{ Name = 'AWS Secret'; Pattern = 'aws_secret' + '_access_key' },
    @{ Name = 'SendGrid Key'; Pattern = 'SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}' }
)

# =============================================================================
# EXCLUSIONS — files that DEFINE security patterns; exempt from self-scan
# =============================================================================

$EXCLUDED_PATHS = @(
    'config/security-privacy.json',
    'config/security-policy.json',
    'hooks/pre-commit-privacy.ps1',
    'hooks/pre-commit.ps1',
    'scripts/hooks/check-security.ps1',
    'docs/reference/ARCHITECTURE.md',
    'scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1',
    'skills/docker-devops-skill/SKILL.md',
    'skills/security-expert-skill/references/security-patterns.md'
)

# =============================================================================
# PATRONES DE MACHINE ID (Warn)
# =============================================================================

$MACHINE_PATTERNS = @(
    @{ Name = 'ComputerName'; Pattern = '\$env:COMPUTERNAME' },
    @{ Name = 'UserProfile Path'; Pattern = 'C:\\Users\\[^\\]+' },
    @{ Name = 'Unix Home'; Pattern = '/home/[^/]+' },
    @{ Name = 'Machine Ref'; Pattern = '[System\.Environment\]::MachineName' }
)

# =============================================================================
# PATRONES DE USER ID (Warn)
# =============================================================================

$USER_PATTERNS = @(
    @{ Name = 'Username Env'; Pattern = '\$env:USERNAME' },
    @{ Name = 'UserName Ref'; Pattern = '[System\.Environment\]::UserName' }
)

# =============================================================================
# SCAN FUNCTION
# =============================================================================

function Invoke-PrivacyScan {
    param([string[]]$Files, [switch]$Verbose)
    
    $violations = @{
        Critical = @()
        MachineId = @()
        UserId = @()
    }
    
    foreach ($file in $Files) {
        if (-not (Test-Path $file)) { continue }
        if ((Get-Item $file).PSIsContainer) { continue }
        
        # Skip policy/config files that define detection patterns
        $normalizedFile = $file -replace '\\', '/'
        $isExcluded = $EXCLUDED_PATHS | Where-Object { $normalizedFile -like "*$_*" }
        if ($isExcluded) { continue }
        
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { continue }
        
        # Scan critical patterns
        foreach ($p in $CRITICAL_PATTERNS) {
            if ($content -match $p.Pattern) {
                $violations.Critical += @{
                    File = $file
                    Pattern = $p.Name
                    Line = (Find-LineNumber $content $p.Pattern)
                }
            }
        }
        
        # Scan machine patterns
        foreach ($p in $MACHINE_PATTERNS) {
            if ($content -match $p.Pattern) {
                $violations.MachineId += @{
                    File = $file
                    Pattern = $p.Name
                }
            }
        }
        
        # Scan user patterns
        foreach ($p in $USER_PATTERNS) {
            if ($content -match $p.Pattern) {
                $violations.UserId += @{
                    File = $file
                    Pattern = $p.Name
                }
            }
        }
    }
    
    return $violations
}

function Find-LineNumber {
    param([string]$Content, [string]$Pattern)
    $lines = $Content -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $Pattern) {
            return $i + 1
        }
    }
    return '?'
}

# =============================================================================
# MAIN
# =============================================================================

Write-Host "=== PRE-COMMIT PRIVACY SCAN ===" -ForegroundColor Cyan

# Get files to scan
if ($Staged) {
    $files = git diff --cached --name-only --diff-filter=ACM
}
else {
    $files = $FilePaths
}

if ($files.Count -eq 0) {
    Write-Host "No files to scan" -ForegroundColor Gray
    exit 0
}

Write-Host "Scanning $($files.Count) files..." -ForegroundColor Yellow

$violations = Invoke-PrivacyScan -Files $files -Verbose:$Verbose

# =============================================================================
# CRITICAL: BLOCK COMMIT
# =============================================================================

if ($violations.Critical.Count -gt 0) {
    Write-Host "`n=== CRITICAL VIOLATIONS - COMMIT BLOCKED ===" -ForegroundColor Red
    
    foreach ($v in $violations.Critical) {
        Write-Host "  FILE: $($v.File)" -ForegroundColor Red
        Write-Host "  PATTERN: $($v.Pattern) at line $($v.Line)" -ForegroundColor Red
        Write-Host ""
    }
    
    Write-Host "These patterns indicate hardcoded credentials or secrets." -ForegroundColor Red
    Write-Host "Move secrets to environment variables or .env files." -ForegroundColor Red
    Write-Host "Use: .gitignore to exclude .env from commits." -ForegroundColor Gray
    
    exit 1
}

# =============================================================================
# MACHINE/USER ID: WARN
# =============================================================================

$warnings = $violations.MachineId.Count + $violations.UserId.Count

if ($warnings -gt 0) {
    Write-Host "`n=== PRIVACY WARNINGS ===" -ForegroundColor Yellow
    
    foreach ($v in $violations.MachineId) {
        Write-Host "  [MACHINE] $($v.File): $($v.Pattern)" -ForegroundColor Yellow
    }
    
    foreach ($v in $violations.UserId) {
        Write-Host "  [USER] $($v.File): $($v.Pattern)" -ForegroundColor Yellow
    }
    
    Write-Host "`nRecommendation: Use generic placeholders instead of machine-specific values." -ForegroundColor Cyan
}

# =============================================================================
# SUCCESS
# =============================================================================

Write-Host "`n[OK] Privacy scan passed" -ForegroundColor Green
exit 0
