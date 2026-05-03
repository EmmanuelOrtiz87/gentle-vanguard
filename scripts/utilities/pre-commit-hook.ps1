<#
.SYNOPSIS
Pre-commit hook for Foundation workspace

.DESCRIPTION
Validates staged files before commit:
- JSON syntax
- PowerShell syntax
- Markdown documentation standards
- No emojis in scripts
#>

param()

$ErrorActionPreference = "Continue"
$stagedFiles = git diff --cached --name-only

if (-not $stagedFiles) {
    Write-Host "[INFO] No staged files to validate"
    exit 0
}

$allPassed = $true

# Validate JSON files
$jsonFiles = $stagedFiles | Where-Object { $_ -match '\.json$' }
foreach ($file in $jsonFiles) {
    if (Test-Path $file) {
        try {
            Get-Content $file -Raw | ConvertFrom-Json | Out-Null
            Write-Host "[OK] $file - Valid JSON"
        }
        catch {
            Write-Host "[FAIL] $file - Invalid JSON: $_"
            $allPassed = $false
        }
    }
}

# Validate PowerShell scripts
$psFiles = $stagedFiles | Where-Object { $_ -match '\.ps1$' }
foreach ($file in $psFiles) {
    if (Test-Path $file) {
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
            if ($ast.EndBlock) {
                Write-Host "[OK] $file - Syntax valid"
            }
        }
        catch {
            Write-Host "[FAIL] $file - Syntax error: $_"
            $allPassed = $false
        }
    }
}

# Check markdown accents
$mdFiles = $stagedFiles | Where-Object { $_ -match '\.md$' }
foreach ($file in $mdFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match 'ción|ón|ín|é|á|í|ó|ú') {
            Write-Host "[OK] $file - Spanish accents found"
        } else {
            Write-Host "[WARN] $file - No Spanish accents detected"
        }
    }
}

# Check no emojis in scripts
$scriptFiles = $stagedFiles | Where-Object { $_ -match '\.ps1$' }
foreach ($file in $scriptFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match '[^\x00-\x7F]') {
            Write-Host "[FAIL] $file - Emojis found in script (not allowed)"
            $allPassed = $false
        }
    }
}

if (-not $allPassed) {
    Write-Host "[FAIL] Pre-commit validation failed"
    exit 1
}

Write-Host "[OK] All pre-commit validations passed"
exit 0
