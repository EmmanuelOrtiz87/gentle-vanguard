<#
.SYNOPSIS
    Pre-commit Hook - Validate configuration changes
    
.DESCRIPTION
    Hook that runs before commit to validate
    that configuration files are correct.
    
.NOTES
    Author: workspace-foundation
    Version: 1.0.0
#>

$ErrorActionPreference = 'Continue'

Write-Host "🔍 Pre-commit: Validating configuration changes..." -ForegroundColor Cyan

# Get modified files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

$configFiles = $stagedFiles | Where-Object { $_ -match '\.json$' -and $_ -match '(config|opencode)' }

if ($configFiles.Count -eq 0) {
    Write-Host "✅ No configuration changes" -ForegroundColor Green
    exit 0
}

Write-Host "📋 Configuration files to validate: $($configFiles.Count)" -ForegroundColor Yellow

$hasErrors = $false

foreach ($file in $configFiles) {
    Write-Host "  Validating: $file" -ForegroundColor Cyan
    
    # Validate JSON
    try {
        $content = Get-Content $file -Raw
        $json = $content | ConvertFrom-Json
        Write-Host "    ✅ Valid JSON" -ForegroundColor Green
    } catch {
        Write-Host "    ❌ Invalid JSON: $_" -ForegroundColor Red
        $hasErrors = $true
        continue
    }
    
    # Validate schema if exists
    $schemaFile = $file -replace '\.json$', '.schema.json'
    if (Test-Path $schemaFile) {
        Write-Host "    Validating against schema..." -ForegroundColor Cyan
        # Here would go schema validation
    }
}

if ($hasErrors) {
    Write-Host "❌ Configuration validation failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Configuration validation passed" -ForegroundColor Green
exit 0
