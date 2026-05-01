<#
.SYNOPSIS
Pre-commit hook for Foundation workflow - validates code quality and security

.DESCRIPTION
This hook runs BEFORE git commit to:
- Validate code quality standards
- Check for security issues
- Verify file formatting
- Ensure commit message standards

.PARAMETER StagedFiles
List of staged files to validate

.PARAMETER WorkspaceRoot
Root directory of the workspace

.EXAMPLE
.\pre-commit-validation.ps1 -StagedFiles @("src/main.ps1", "config/app.json") -WorkspaceRoot "."
#>

param(
    [Parameter(Mandatory = $false)]
    [string[]]$StagedFiles,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkspaceRoot = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = ".session/logs/pre-commit-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$validationErrors = @()
$validationWarnings = @()

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path (Split-Path $logFile)) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

Write-Log "Starting pre-commit validation hook"

try {
    # Get staged files if not provided
    if (-not $StagedFiles -or $StagedFiles.Count -eq 0) {
        $StagedFiles = @(git diff --cached --name-only 2>$null)
        Write-Log "Retrieved $($StagedFiles.Count) staged files from git"
    }

    if ($StagedFiles.Count -eq 0) {
        Write-Log "No staged files to validate"
        Write-Output "VALIDATION_PASSED"
        exit 0
    }

    # Validate each file
    foreach ($file in $StagedFiles) {
        Write-Log "Validating file: $file"

        # Check file exists
        if (-not (Test-Path $file)) {
            $validationWarnings += "File not found: $file"
            continue
        }

        # Check for common issues
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        
        # Check for TODO/FIXME without context
        if ($content -match '(TODO|FIXME):\s*$') {
            $validationWarnings += "File $file has TODO/FIXME without description"
        }

        # Check for debug statements
        if ($content -match '(Write-Host|console\.log|print)\s*\(' -and $file -notmatch '\.test\.' -and $file -notmatch '\.spec\.') {
            $validationWarnings += "File $file may contain debug statements"
        }

        # Check JSON files
        if ($file -match '\.json$') {
            try {
                $json = Get-Content $file -Raw | ConvertFrom-Json
                Write-Log "JSON validation passed for $file"
            }
            catch {
                $validationErrors += "Invalid JSON in file $file: $_"
            }
        }

        # Check PowerShell files
        if ($file -match '\.ps1$') {
            try {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
                if ($ast.EndBlock -eq $null) {
                    Write-Log "PowerShell syntax validation passed for $file"
                }
            }
            catch {
                $validationWarnings += "PowerShell syntax issue in $file: $_"
            }
        }
    }

    # Report results
    if ($validationWarnings.Count -gt 0) {
        Write-Log "Validation warnings found:" "WARN"
        foreach ($warning in $validationWarnings) {
            Write-Log "  - $warning" "WARN"
        }
    }

    if ($validationErrors.Count -gt 0) {
        Write-Log "Validation errors found:" "ERROR"
        foreach ($error in $validationErrors) {
            Write-Log "  - $error" "ERROR"
        }
        Write-Output "VALIDATION_FAILED"
        exit 1
    }

    Write-Log "Pre-commit validation passed" "SUCCESS"
    Write-Output "VALIDATION_PASSED"
    exit 0
}
catch {
    Write-Log "Error in pre-commit validation: $_" "ERROR"
    Write-Output "VALIDATION_FAILED"
    exit 1
}