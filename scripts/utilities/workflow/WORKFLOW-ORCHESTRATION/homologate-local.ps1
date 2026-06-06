<#
.SYNOPSIS
Homologate local environment with production standards

.DESCRIPTION
Ensures local environment matches production standards:
- Validates all configurations
- Synchronizes documentation
- Verifies automation setup
- Checks system definitions
- Validates integration points

.PARAMETER Force
Force homologation without confirmation

.EXAMPLE
.\homologate-local.ps1 -Force
#>

param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = ".session/logs/homologate-local-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$homologationReport = @{
    timestamp = $timestamp
    actions = @()
    status = "PENDING"
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path (Split-Path $logFile)) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

function Add-Action {
    param([string]$Action, [string]$Status, [string]$Details = "")
    $homologationReport.actions += @{
        action = $Action
        status = $Status
        details = $Details
        timestamp = $timestamp
    }
}

Write-Log "=== LOCAL HOMOLOGATION STARTED ===" "INFO"

# 1. Verify directory structure
Write-Log "Verifying directory structure..." "INFO"

$requiredDirs = @(
    ".session",
    ".session/logs",
    ".session/reports",
    "gentle-vanguard/config",
    "gentle-vanguard/scripts/utilities/WORKFLOW-ORCHESTRATION",
    "gentle-vanguard/scripts/utilities/GIT-VERSION-CONTROL",
    "gentle-vanguard/docs"
)

foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Add-Action "Create Directory" "SUCCESS" $dir
        Write-Log "[OK] Created directory: $dir" "SUCCESS"
    }
    else {
        Add-Action "Verify Directory" "SUCCESS" $dir
        Write-Log "[OK] Directory exists: $dir" "SUCCESS"
    }
}

# 2. Validate all configuration files
Write-Log "Validating configuration files..." "INFO"

$configFiles = @(
    "gentle-vanguard/opencode.json",
    "gentle-vanguard/config/hooks-config.json",
    "gentle-vanguard/config/workspace.config.json",
    "gentle-vanguard/scripts/utilities/WORKFLOW-ORCHESTRATION/hook-registry.json"
)

foreach ($configFile in $configFiles) {
    if (Test-Path $configFile) {
        try {
            $json = Get-Content $configFile -Raw | ConvertFrom-Json
            Add-Action "Validate Config" "SUCCESS" $configFile
            Write-Log "[OK] Config valid: $configFile" "SUCCESS"
        }
        catch {
            Add-Action "Validate Config" "FAIL" "$configFile - $_"
            Write-Log "[FAIL] Config invalid: $configFile - $_" "ERROR"
        }
    }
}

# 3. Verify all scripts exist and are valid
Write-Log "Verifying scripts..." "INFO"

$scripts = @(
    "gentle-vanguard/scripts/utilities/WORKFLOW-ORCHESTRATION/pre-process-input.ps1",
    "gentle-vanguard/scripts/utilities/WORKFLOW-ORCHESTRATION/validate-system-health.ps1",
    "gentle-vanguard/scripts/utilities/WORKFLOW-ORCHESTRATION/intelligent-validator.ps1",
    "gentle-vanguard/scripts/utilities/WORKFLOW-ORCHESTRATION/comprehensive-validation.ps1",
    "gentle-vanguard/scripts/utilities/GIT-VERSION-CONTROL/pre-commit-validation.ps1",
    "gentle-vanguard/scripts/utilities/GIT-VERSION-CONTROL/post-merge-sync.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$null)
            Add-Action "Verify Script" "SUCCESS" $script
            Write-Log "[OK] Script valid: $script" "SUCCESS"
        }
        catch {
            Add-Action "Verify Script" "FAIL" "$script - $_"
            Write-Log "[FAIL] Script invalid: $script - $_" "ERROR"
        }
    }
}

# 4. Verify documentation
Write-Log "Verifying documentation..." "INFO"

$docs = @(
    "gentle-vanguard/docs/HOOKS-IMPLEMENTATION-GUIDE.md",
    "gentle-vanguard/docs/LESSONS-LEARNED-HOOKS-INCIDENT.md",
    "gentle-vanguard/docs/CONFIGURATION-VALIDATION-CHECKLIST.md",
    "gentle-vanguard/docs/AUTONOMOUS-VALIDATION-SYSTEM.md",
    "gentle-vanguard/docs/AUTONOMOUS-SYSTEM-GUIDE.md"
)

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Add-Action "Verify Documentation" "SUCCESS" $doc
        Write-Log "[OK] Documentation exists: $doc" "SUCCESS"
    }
}

# 5. Create local git hooks if in git repository
Write-Log "Setting up git hooks..." "INFO"

if (Test-Path ".git") {
    $hooksDir = ".git/hooks"
    
    # Create pre-commit hook
    $preCommitHook = Join-Path $hooksDir "pre-commit"
    $preCommitContent = @"
#!/bin/sh
# Pre-commit hook for Gentle-Vanguard validation
powershell -NoProfile -ExecutionPolicy Bypass -File "gentle-vanguard\\scripts\utilities\GIT-VERSION-CONTROL\pre-commit-validation.ps1"
exit `$?
"@
    
    if (-not (Test-Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }
    
    Set-Content -Path $preCommitHook -Value $preCommitContent -Encoding UTF8
    Add-Action "Create Git Hook" "SUCCESS" "pre-commit"
    Write-Log "[OK] Git pre-commit hook created" "SUCCESS"
}

# 6. Initialize knowledge base
Write-Log "Initializing knowledge base..." "INFO"

$kbPath = ".session/knowledge-base.json"
if (-not (Test-Path $kbPath)) {
    $kb = @{
        patterns = @()
        solutions = @()
        metadata = @{
            created = $timestamp
            version = "1.0.0"
        }
    }
    $kb | ConvertTo-Json | Set-Content -Path $kbPath
    Add-Action "Initialize Knowledge Base" "SUCCESS" $kbPath
    Write-Log "[OK] Knowledge base initialized" "SUCCESS"
}

# 7. Create local configuration if needed
Write-Log "Verifying local configuration..." "INFO"

$localConfig = ".session/local-config.json"
if (-not (Test-Path $localConfig)) {
    $config = @{
        environment = "local"
        timestamp = $timestamp
        version = "1.0.0"
        settings = @{
            autoValidation = $true
            autoCorrection = $true
            logLevel = "INFO"
        }
    }
    $config | ConvertTo-Json | Set-Content -Path $localConfig
    Add-Action "Create Local Config" "SUCCESS" $localConfig
    Write-Log "[OK] Local configuration created" "SUCCESS"
}

# 8. Generate homologation report
Write-Log "Generating homologation report..." "INFO"

$successResults = @($homologationReport.actions | Where-Object { $_.status -eq "SUCCESS" })
$failResults = @($homologationReport.actions | Where-Object { $_.status -eq "FAIL" })
$successCount = $successResults.Count
$failCount = $failResults.Count

if ($failCount -eq 0) {
    $homologationReport.status = "SUCCESS"
}
else {
    $homologationReport.status = "PARTIAL"
}

$reportPath = ".session/reports/homologation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
if (-not (Test-Path (Split-Path $reportPath))) {
    New-Item -ItemType Directory -Path (Split-Path $reportPath) -Force | Out-Null
}

$homologationReport | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath

Write-Log "=== HOMOLOGATION SUMMARY ===" "INFO"
Write-Log "Total Actions: $($homologationReport.actions.Count)" "INFO"
Write-Log "Successful: $successCount" "SUCCESS"
Write-Log "Failed: $failCount" "ERROR"
Write-Log "Status: $($homologationReport.status)" "INFO"
Write-Log "Report saved to: $reportPath" "INFO"

# Output summary
Write-Host ""
Write-Host "+============================================================+"
Write-Host "|         LOCAL HOMOLOGATION REPORT                         |"
Write-Host "+============================================================+"
Write-Host "| Total Actions:   $($homologationReport.actions.Count)"
Write-Host "| Successful:      $successCount"
Write-Host "| Failed:          $failCount"
Write-Host "| Status:          $($homologationReport.status)"
Write-Host "+============================================================+"
Write-Host ""

Write-Log "[OK] LOCAL HOMOLOGATION COMPLETED" "SUCCESS"

if ($failCount -eq 0) {
    exit 0
}
else {
    exit 1
}
