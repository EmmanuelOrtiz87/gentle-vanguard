<#
.SYNOPSIS
Intelligent validation engine with auto-correction capabilities

.DESCRIPTION
Advanced validator that:
- Detects configuration errors
- Applies known solutions automatically
- Learns from new errors
- Maintains knowledge base
- Provides detailed reporting

.PARAMETER FilePath
Path to file to validate

.PARAMETER AutoCorrect
Enable automatic correction

.PARAMETER Verbose
Show detailed output

.EXAMPLE
.\intelligent-validator.ps1 -FilePath "config/opencode.json" -AutoCorrect
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    
    [switch]$AutoCorrect,
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = ".session/logs/intelligent-validator-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$knowledgeBase = ".session/knowledge-base.json"
$validationResult = @{
    file = $FilePath
    timestamp = $timestamp
    errors = @()
    warnings = @()
    corrections = @()
    status = "UNKNOWN"
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path (Split-Path $logFile)) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

function Load-KnowledgeBase {
    if (Test-Path $knowledgeBase) {
        try {
            return Get-Content $knowledgeBase -Raw | ConvertFrom-Json
        }
        catch {
            Write-Log "Error loading knowledge base: $_" "WARN"
            return @{ patterns = @(); solutions = @() }
        }
    }
    return @{ patterns = @(); solutions = @() }
}

function Save-KnowledgeBase {
    param($KB)
    if (-not (Test-Path (Split-Path $knowledgeBase))) {
        New-Item -ItemType Directory -Path (Split-Path $knowledgeBase) -Force | Out-Null
    }
    $KB | ConvertTo-Json -Depth 10 | Set-Content -Path $knowledgeBase
    Write-Log "Knowledge base updated" "INFO"
}

function Detect-ConfigError {
    param([string]$FilePath)
    
    $errors = @()
    
    try {
        $content = Get-Content $FilePath -Raw
        $json = $content | ConvertFrom-Json
        
        # Check for known error patterns
        if ($FilePath -match "opencode\.json$") {
            if ($json.PSObject.Properties.Name -contains "hooks") {
                $errors += @{
                    type = "ConfigInvalidError"
                    message = "Invalid 'hooks' section in opencode.json"
                    severity = "CRITICAL"
                    pattern = "hooks_in_opencode"
                }
            }
        }
        
        # Check for schema violations
        if ($FilePath -match "hooks-config\.json$") {
            if (-not $json.hooks) {
                $errors += @{
                    type = "SchemaError"
                    message = "Missing required 'hooks' section"
                    severity = "CRITICAL"
                    pattern = "missing_hooks_section"
                }
            }
        }
    }
    catch {
        $errors += @{
            type = "SyntaxError"
            message = "Invalid JSON: $_"
            severity = "CRITICAL"
            pattern = "invalid_json"
        }
    }
    
    return $errors
}

function Apply-AutoCorrection {
    param($Error, [string]$FilePath)
    
    $correction = @{
        error = $Error.pattern
        applied = $false
        details = ""
    }
    
    try {
        if ($Error.pattern -eq "hooks_in_opencode") {
            Write-Log "Applying auto-correction for hooks in opencode.json" "INFO"
            
            $content = Get-Content $FilePath -Raw
            $json = $content | ConvertFrom-Json
            
            # Extract hooks configuration
            $hooksConfig = $json.hooks
            
            # Remove hooks from opencode.json
            $json.PSObject.Properties.Remove("hooks")
            
            # Save corrected opencode.json
            $json | ConvertTo-Json | Set-Content -Path $FilePath
            
            # Create/update hooks-config.json
            $hooksFile = "workspace-foundation/config/hooks-config.json"
            if (Test-Path $hooksFile) {
                $existing = Get-Content $hooksFile -Raw | ConvertFrom-Json
                $existing.hooks = $hooksConfig
                $existing | ConvertTo-Json | Set-Content -Path $hooksFile
            }
            
            $correction.applied = $true
            $correction.details = "Moved hooks configuration to hooks-config.json"
            Write-Log "Auto-correction applied successfully" "SUCCESS"
        }
    }
    catch {
        $correction.details = "Error during correction: $_"
        Write-Log "Auto-correction failed: $_" "ERROR"
    }
    
    return $correction
}

# Main validation logic
Write-Log "Starting intelligent validation for: $FilePath" "INFO"

if (-not (Test-Path $FilePath)) {
    $validationResult.status = "FILE_NOT_FOUND"
    $validationResult.errors += "File not found: $FilePath"
    Write-Log "File not found: $FilePath" "ERROR"
}
else {
    # Load knowledge base
    $kb = Load-KnowledgeBase
    
    # Detect errors
    $errors = Detect-ConfigError -FilePath $FilePath
    
    if ($errors.Count -eq 0) {
        $validationResult.status = "VALID"
        Write-Log "File is valid" "SUCCESS"
    }
    else {
        $validationResult.errors = $errors
        
        if ($AutoCorrect) {
            Write-Log "Attempting auto-correction..." "INFO"
            
            foreach ($error in $errors) {
                $correction = Apply-AutoCorrection -Error $error -FilePath $FilePath
                $validationResult.corrections += $correction
                
                # Update knowledge base
                if ($correction.applied) {
                    $kb.solutions += @{
                        pattern = $error.pattern
                        solution = $correction.details
                        timestamp = $timestamp
                        confidence = 100
                    }
                }
            }
            
            # Re-validate after correction
            $revalidation = Detect-ConfigError -FilePath $FilePath
            if ($revalidation.Count -eq 0) {
                $validationResult.status = "CORRECTED"
                Write-Log "File corrected and validated" "SUCCESS"
            }
            else {
                $validationResult.status = "CORRECTION_FAILED"
                $validationResult.errors = $revalidation
                Write-Log "Correction failed, errors remain" "ERROR"
            }
        }
        else {
            $validationResult.status = "INVALID"
            Write-Log "File has errors (auto-correct disabled)" "ERROR"
        }
    }
    
    # Save updated knowledge base
    Save-KnowledgeBase -KB $kb
}

# Generate report
$reportPath = ".session/reports/validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
if (-not (Test-Path (Split-Path $reportPath))) {
    New-Item -ItemType Directory -Path (Split-Path $reportPath) -Force | Out-Null
}
$validationResult | ConvertTo-Json | Set-Content -Path $reportPath

Write-Log "Validation report saved to: $reportPath" "INFO"

# Output result
$validationResult | ConvertTo-Json

# Exit with appropriate code
if ($validationResult.status -eq "VALID" -or $validationResult.status -eq "CORRECTED") {
    exit 0
}
else {
    exit 1
}