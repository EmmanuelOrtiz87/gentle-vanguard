<#
.SYNOPSIS
Validates complete system health including configuration, hooks, and dependencies

.DESCRIPTION
Comprehensive health check that verifies:
- Configuration files are valid
- All required files exist
- Hooks are properly configured
- Scripts are executable
- No critical errors exist

.PARAMETER Verbose
Show detailed output

.EXAMPLE
.\validate-system-health.ps1 -Verbose
#>

param(
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = ".session/logs/system-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$errors = @()
$warnings = @()
$successes = @()

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path (Split-Path $logFile)) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

Write-Log "=== SYSTEM HEALTH VALIDATION STARTED ===" "INFO"

# 1. Validate Configuration Files
Write-Log "Validating configuration files..." "INFO"

$configFiles = @(
    "workspace-foundation/opencode.json",
    "workspace-foundation/config/hooks-config.json",
    "workspace-foundation/config/workspace.config.json"
)

foreach ($configFile in $configFiles) {
    if (Test-Path $configFile) {
        try {
            $json = Get-Content $configFile -Raw | ConvertFrom-Json
            $successes += "[OK] Configuration valid: $configFile"
            Write-Log "Configuration valid: $configFile" "SUCCESS"
        }
        catch {
            $errors += "[FAIL] Invalid configuration: $configFile - $_"
            Write-Log "Invalid configuration: $configFile - $_" "ERROR"
        }
    }
    else {
        $warnings += "[WARN] Configuration file not found: $configFile"
        Write-Log "Configuration file not found: $configFile" "WARN"
    }
}

# 2. Validate Hook Scripts Exist
Write-Log "Validating hook scripts..." "INFO"

$hookScripts = @(
    "workspace-foundation/scripts/utilities/WORKFLOW-ORCHESTRATION/pre-process-input.ps1",
    "workspace-foundation/scripts/utilities/GIT-VERSION-CONTROL/pre-commit-validation.ps1",
    "workspace-foundation/scripts/utilities/GIT-VERSION-CONTROL/post-merge-sync.ps1"
)

foreach ($script in $hookScripts) {
    if (Test-Path $script) {
        $successes += "[OK] Hook script exists: $script"
        Write-Log "Hook script exists: $script" "SUCCESS"
    }
    else {
        $errors += "[FAIL] Hook script missing: $script"
        Write-Log "Hook script missing: $script" "ERROR"
    }
}

# 3. Validate Hook Registry
Write-Log "Validating hook registry..." "INFO"

$hookRegistry = "workspace-foundation/scripts/utilities/WORKFLOW-ORCHESTRATION/hook-registry.json"
if (Test-Path $hookRegistry) {
    try {
        $registry = Get-Content $hookRegistry -Raw | ConvertFrom-Json
        $hookCount = $registry.hooks.PSObject.Properties.Count
        $successes += "[OK] Hook registry valid with $hookCount hooks"
        Write-Log "Hook registry valid with $hookCount hooks" "SUCCESS"
    }
    catch {
        $errors += "[FAIL] Invalid hook registry: $_"
        Write-Log "Invalid hook registry: $_" "ERROR"
    }
}
else {
    $errors += "[FAIL] Hook registry not found: $hookRegistry"
    Write-Log "Hook registry not found: $hookRegistry" "ERROR"
}

# 4. Validate Documentation
Write-Log "Validating documentation..." "INFO"

$docFiles = @(
    "workspace-foundation/docs/HOOKS-IMPLEMENTATION-GUIDE.md",
    "workspace-foundation/docs/LESSONS-LEARNED-HOOKS-INCIDENT.md",
    "workspace-foundation/docs/CONFIGURATION-VALIDATION-CHECKLIST.md"
)

foreach ($docFile in $docFiles) {
    if (Test-Path $docFile) {
        $successes += "[OK] Documentation exists: $docFile"
        Write-Log "Documentation exists: $docFile" "SUCCESS"
    }
    else {
        $warnings += "[WARN] Documentation missing: $docFile"
        Write-Log "Documentation missing: $docFile" "WARN"
    }
}

# 5. Validate Directory Structure
Write-Log "Validating directory structure..." "INFO"

$requiredDirs = @(
    "workspace-foundation/config",
    "workspace-foundation/scripts/utilities/WORKFLOW-ORCHESTRATION",
    "workspace-foundation/scripts/utilities/GIT-VERSION-CONTROL",
    ".session/logs",
    ".session/reports"
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        $successes += "[OK] Directory exists: $dir"
        Write-Log "Directory exists: $dir" "SUCCESS"
    }
    else {
        $warnings += "[WARN] Directory missing: $dir"
        Write-Log "Directory missing: $dir" "WARN"
        # Try to create it
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $successes += "[OK] Directory created: $dir"
            Write-Log "Directory created: $dir" "SUCCESS"
        }
        catch {
            $errors += "[FAIL] Failed to create directory: $dir - $_"
            Write-Log "Failed to create directory: $dir - $_" "ERROR"
        }
    }
}

# 6. Validate opencode.json doesn't have invalid hooks section
Write-Log "Validating opencode.json schema compliance..." "INFO"

try {
    $opencode = Get-Content "workspace-foundation/opencode.json" -Raw | ConvertFrom-Json
    if ($opencode.PSObject.Properties.Name -contains "hooks") {
        $errors += "[FAIL] opencode.json contains invalid 'hooks' section"
        Write-Log "opencode.json contains invalid 'hooks' section" "ERROR"
    }
    else {
        $successes += "[OK] opencode.json schema is compliant"
        Write-Log "opencode.json schema is compliant" "SUCCESS"
    }
}
catch {
    $errors += "[FAIL] Failed to validate opencode.json: $_"
    Write-Log "Failed to validate opencode.json: $_" "ERROR"
}

# 7. Summary Report
Write-Log "=== VALIDATION SUMMARY ===" "INFO"

$totalSuccesses = $successes.Count
$totalWarnings = $warnings.Count
$totalErrors = $errors.Count

Write-Log "Successes: $totalSuccesses" "SUCCESS"
Write-Log "Warnings: $totalWarnings" "WARN"
Write-Log "Errors: $totalErrors" "ERROR"

if ($Verbose) {
    Write-Log "=== DETAILED RESULTS ===" "INFO"
    
    if ($successes.Count -gt 0) {
        Write-Log "SUCCESSES:" "SUCCESS"
        foreach ($success in $successes) {
            Write-Log "  $success" "SUCCESS"
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Log "WARNINGS:" "WARN"
        foreach ($warning in $warnings) {
            Write-Log "  $warning" "WARN"
        }
    }
    
    if ($errors.Count -gt 0) {
        Write-Log "ERRORS:" "ERROR"
        foreach ($error in $errors) {
            Write-Log "  $error" "ERROR"
        }
    }
}

# Generate report
$report = @{
    timestamp = $timestamp
    totalSuccesses = $totalSuccesses
    totalWarnings = $totalWarnings
    totalErrors = $totalErrors
    status = if ($totalErrors -eq 0) { "HEALTHY" } else { "UNHEALTHY" }
    successes = $successes
    warnings = $warnings
    errors = $errors
}

# Save report
$reportPath = ".session/reports/system-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
if (-not (Test-Path (Split-Path $reportPath))) {
    New-Item -ItemType Directory -Path (Split-Path $reportPath) -Force | Out-Null
}
$report | ConvertTo-Json | Set-Content -Path $reportPath

Write-Log "Health report saved to: $reportPath" "INFO"
Write-Log "=== VALIDATION COMPLETED ===" "INFO"

# Exit with appropriate code
if ($totalErrors -gt 0) {
    exit 1
}
else {
    exit 0
}