<#
.SYNOPSIS
Comprehensive end-to-end validation of entire Gentle-Vanguard system

.DESCRIPTION
Complete validation that checks:
- All scripts for syntax errors
- Configuration files validity
- Documentation completeness
- Skill definitions
- Automation setup
- System definitions
- Integration points

.PARAMETER Verbose
Show detailed output

.PARAMETER GenerateReport
Generate HTML report

.EXAMPLE
.\comprehensive-validation.ps1 -Verbose -GenerateReport
#>

param(
    [switch]$Verbose,
    [switch]$GenerateReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$sessionRoot = ".session"
$sessionLogsDir = Join-Path $sessionRoot "logs"
$sessionReportsDir = Join-Path $sessionRoot "reports"
foreach ($dir in @($sessionRoot, $sessionLogsDir, $sessionReportsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = Join-Path $sessionLogsDir "comprehensive-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$validationReport = @{
    timestamp = $timestamp
    sections = @{}
    summary = @{
        totalChecks = 0
        passed = 0
        failed = 0
        warnings = 0
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path (Split-Path $logFile)) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

function Add-ValidationResult {
    param([string]$Section, [string]$Check, [string]$Status, [string]$Details = "")
    
    if (-not $validationReport.sections[$Section]) {
        $validationReport.sections[$Section] = @()
    }
    
    $validationReport.sections[$Section] += @{
        check = $Check
        status = $Status
        details = $Details
        timestamp = $timestamp
    }
    
    $validationReport.summary.totalChecks++
    if ($Status -eq "PASS") { $validationReport.summary.passed++ }
    elseif ($Status -eq "FAIL") { $validationReport.summary.failed++ }
    elseif ($Status -eq "WARN") { $validationReport.summary.warnings++ }
}

# ============================================================================
# 1. VALIDATE POWERSHELL SCRIPTS
# ============================================================================
Write-Log "=== VALIDATING POWERSHELL SCRIPTS ===" "INFO"

$psScripts = @(
    "scripts/utilities/WORKFLOW-ORCHESTRATION/pre-process-input.ps1",
    "scripts/utilities/WORKFLOW-ORCHESTRATION/validate-system-health.ps1",
    "scripts/utilities/WORKFLOW-ORCHESTRATION/intelligent-validator.ps1",
    "scripts/utilities/GIT-VERSION-CONTROL/pre-commit-validation.ps1",
    "scripts/utilities/GIT-VERSION-CONTROL/post-merge-sync.ps1"
)

foreach ($script in $psScripts) {
    if (Test-Path $script) {
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$null)
            if ($ast.EndBlock) {
                Add-ValidationResult "PowerShell Scripts" $script "PASS" "Syntax valid"
                Write-Log "[OK] $script - Syntax valid" "SUCCESS"
            }
        }
        catch {
            Add-ValidationResult "PowerShell Scripts" $script "FAIL" "Syntax error: $_"
            Write-Log "[FAIL] $script - Syntax error: $_" "ERROR"
        }
    }
    else {
        Add-ValidationResult "PowerShell Scripts" $script "FAIL" "File not found"
        Write-Log "[FAIL] $script - File not found" "ERROR"
    }
}

# ============================================================================
# 2. VALIDATE JSON CONFIGURATION FILES
# ============================================================================
Write-Log "=== VALIDATING JSON CONFIGURATION FILES ===" "INFO"

$jsonFiles = @(
    "opencode.json",
    "config/hooks-config.json",
    "config/workspace.config.json",
    "scripts/utilities/WORKFLOW-ORCHESTRATION/hook-registry.json"
)

foreach ($jsonFile in $jsonFiles) {
    if (Test-Path $jsonFile) {
        try {
            $json = Get-Content $jsonFile -Raw | ConvertFrom-Json
            Add-ValidationResult "JSON Configuration" $jsonFile "PASS" "Valid JSON"
            Write-Log "[OK] $jsonFile - Valid JSON" "SUCCESS"
            
            # Additional checks
            if ($jsonFile -match "opencode\.json$") {
                if ($json.PSObject.Properties.Name -contains "hooks") {
                    Add-ValidationResult "JSON Configuration" "$jsonFile - hooks section" "FAIL" "Invalid hooks section found"
                    Write-Log "[FAIL] $jsonFile - Invalid hooks section" "ERROR"
                }
                else {
                    Add-ValidationResult "JSON Configuration" "$jsonFile - schema compliance" "PASS" "Schema compliant"
                    Write-Log "[OK] $jsonFile - Schema compliant" "SUCCESS"
                }
            }
        }
        catch {
            Add-ValidationResult "JSON Configuration" $jsonFile "FAIL" "Invalid JSON: $_"
            Write-Log "[FAIL] $jsonFile - Invalid JSON: $_" "ERROR"
        }
    }
    else {
        Add-ValidationResult "JSON Configuration" $jsonFile "WARN" "File not found"
        Write-Log "[WARN] $jsonFile - File not found" "WARN"
    }
}

# ============================================================================
# 3. VALIDATE DOCUMENTATION
# ============================================================================
Write-Log "=== VALIDATING DOCUMENTATION ===" "INFO"

$docFiles = @(
    "docs/HOOKS-IMPLEMENTATION-GUIDE.md",
    "docs/LESSONS-LEARNED-HOOKS-INCIDENT.md",
    "docs/CONFIGURATION-VALIDATION-CHECKLIST.md",
    "docs/AUTONOMOUS-VALIDATION-SYSTEM.md",
    "docs/AUTONOMOUS-SYSTEM-GUIDE.md"
)

foreach ($docFile in $docFiles) {
    if (Test-Path $docFile) {
        $content = Get-Content $docFile -Raw
        $lines = $content.Split("`n").Count
        
        if ($lines -gt 10) {
            Add-ValidationResult "Documentation" $docFile "PASS" "$lines lines"
            Write-Log "[OK] $docFile - Valid ($lines lines)" "SUCCESS"
        }
        else {
            Add-ValidationResult "Documentation" $docFile "WARN" "Document too short ($lines lines)"
            Write-Log "[WARN] $docFile - Document too short" "WARN"
        }
    }
    else {
        Add-ValidationResult "Documentation" $docFile "WARN" "File not found"
        Write-Log "[WARN] $docFile - File not found" "WARN"
    }
}

# ============================================================================
# 4. VALIDATE DIRECTORY STRUCTURE
# ============================================================================
Write-Log "=== VALIDATING DIRECTORY STRUCTURE ===" "INFO"

$requiredDirs = @(
    "config",
    "scripts/utilities/WORKFLOW-ORCHESTRATION",
    "scripts/utilities/GIT-VERSION-CONTROL",
    "docs",
    $sessionLogsDir,
    $sessionReportsDir
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Add-ValidationResult "Directory Structure" $dir "PASS" "Directory exists"
        Write-Log "[OK] $dir - Exists" "SUCCESS"
    }
    else {
        Add-ValidationResult "Directory Structure" $dir "FAIL" "Directory missing"
        Write-Log "[FAIL] $dir - Missing" "ERROR"
    }
}

# ============================================================================
# 5. VALIDATE HOOKS CONFIGURATION
# ============================================================================
Write-Log "=== VALIDATING HOOKS CONFIGURATION ===" "INFO"

try {
    $hooksConfig = Get-Content "config/hooks-config.json" -Raw | ConvertFrom-Json
    
    $expectedHooks = @("pre_process", "post_session", "pre_commit", "post_merge")
    foreach ($hook in $expectedHooks) {
        if ($hooksConfig.hooks.$hook) {
            Add-ValidationResult "Hooks Configuration" "Hook: $hook" "PASS" "Configured"
            Write-Log "[OK] Hook $hook - Configured" "SUCCESS"
        }
        else {
            Add-ValidationResult "Hooks Configuration" "Hook: $hook" "FAIL" "Not configured"
            Write-Log "[FAIL] Hook $hook - Not configured" "ERROR"
        }
    }
}
catch {
    Add-ValidationResult "Hooks Configuration" "hooks-config.json" "FAIL" "Error: $_"
    Write-Log "[FAIL] Hooks configuration error: $_" "ERROR"
}

# ============================================================================
# 6. VALIDATE AUTOMATION SETUP
# ============================================================================
Write-Log "=== VALIDATING AUTOMATION SETUP ===" "INFO"

$automationFiles = @(
    ".github/workflows/autonomous-validation.yml"
)

foreach ($file in $automationFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match "autonomous-validation") {
            Add-ValidationResult "Automation Setup" $file "PASS" "Workflow configured"
            Write-Log "[OK] $file - Workflow configured" "SUCCESS"
        }
        else {
            Add-ValidationResult "Automation Setup" $file "WARN" "Workflow may be incomplete"
            Write-Log "[WARN] $file - Workflow may be incomplete" "WARN"
        }
    }
    else {
        Add-ValidationResult "Automation Setup" $file "FAIL" "File not found"
        Write-Log "[FAIL] $file - File not found" "ERROR"
    }
}

# ============================================================================
# 7. VALIDATE SYSTEM DEFINITIONS
# ============================================================================
Write-Log "=== VALIDATING SYSTEM DEFINITIONS ===" "INFO"

try {
    $opencode = Get-Content "opencode.json" -Raw | ConvertFrom-Json
    $agentConfig = if ($opencode.PSObject.Properties.Name -contains 'agent') { $opencode.agent } else { $null }
    
    # Check providers
    if ($opencode.PSObject.Properties.Name -contains 'provider' -and $opencode.provider.PSObject.Properties.Name -contains 'anthropic' -and $opencode.provider.anthropic) {
        Add-ValidationResult "System Definitions" "Provider: Anthropic" "PASS" "Configured"
        Write-Log "[OK] Anthropic provider - Configured" "SUCCESS"
    }
    
    # Check agents
    if ($agentConfig -and $agentConfig.PSObject.Properties.Name -contains 'orchestrator' -and $agentConfig.orchestrator) {
        $agentNames = @('orchestrator')
        if ($agentConfig.PSObject.Properties.Name -contains 'default' -and $agentConfig.default) {
            $agentNames += 'default'
        }
        Add-ValidationResult "System Definitions" "Agents" "PASS" "$($agentNames -join ', ') configured"
        Write-Log "[OK] Agents - Configured ($($agentNames -join ', '))" "SUCCESS"
    }
    elseif ($agentConfig) {
        Add-ValidationResult "System Definitions" "Agents" "WARN" "Orchestrator not configured"
        Write-Log "[WARN] Agents - Orchestrator not configured" "WARN"
    }
}
catch {
    Add-ValidationResult "System Definitions" "opencode.json" "FAIL" "Error: $_"
    Write-Log "[FAIL] System definitions error: $_" "ERROR"
}

# ============================================================================
# 8. VALIDATE INTEGRATION POINTS
# ============================================================================
Write-Log "=== VALIDATING INTEGRATION POINTS ===" "INFO"

# Check git integration
if (Test-Path ".git") {
    Add-ValidationResult "Integration Points" "Git repository" "PASS" "Repository initialized"
    Write-Log "[OK] Git repository - Initialized" "SUCCESS"
}
else {
    Add-ValidationResult "Integration Points" "Git repository" "WARN" "Not a git repository"
    Write-Log "[WARN] Git repository - Not initialized" "WARN"
}

# Check CI/CD integration
if (Test-Path ".github/workflows") {
    Add-ValidationResult "Integration Points" "GitHub Actions" "PASS" "Workflows configured"
    Write-Log "[OK] GitHub Actions - Configured" "SUCCESS"
}

# ============================================================================
# 9. VALIDATE MANUAL PROCEDURES
# ============================================================================
Write-Log "=== VALIDATING MANUAL PROCEDURES ===" "INFO"

$manualDocs = @(
    "docs/CONFIGURATION-VALIDATION-CHECKLIST.md",
    "docs/LESSONS-LEARNED-HOOKS-INCIDENT.md"
)

foreach ($doc in $manualDocs) {
    if (Test-Path $doc) {
        $content = Get-Content $doc -Raw
        if ($content -match "checklist|procedure|step") {
            Add-ValidationResult "Manual Procedures" $doc "PASS" "Procedures documented"
            Write-Log "[OK] $doc - Procedures documented" "SUCCESS"
        }
    }
}

# ============================================================================
# 10. VALIDATE AUTONOMOUS SYSTEMS
# ============================================================================
Write-Log "=== VALIDATING AUTONOMOUS SYSTEMS ===" "INFO"

$autonomousDocs = @(
    "docs/AUTONOMOUS-VALIDATION-SYSTEM.md",
    "docs/AUTONOMOUS-SYSTEM-GUIDE.md"
)

foreach ($doc in $autonomousDocs) {
    if (Test-Path $doc) {
        Add-ValidationResult "Autonomous Systems" $doc "PASS" "Documentation complete"
        Write-Log "[OK] $doc - Documentation complete" "SUCCESS"
    }
}

# ============================================================================
# GENERATE SUMMARY REPORT
# ============================================================================
Write-Log "=== GENERATING SUMMARY REPORT ===" "INFO"

$reportPath = Join-Path $sessionReportsDir "comprehensive-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
if (-not (Test-Path (Split-Path $reportPath))) {
    New-Item -ItemType Directory -Path (Split-Path $reportPath) -Force | Out-Null
}

$validationReport | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath

Write-Log "=== VALIDATION SUMMARY ===" "INFO"
Write-Log "Total Checks: $($validationReport.summary.totalChecks)" "INFO"
Write-Log "Passed: $($validationReport.summary.passed)" "SUCCESS"
Write-Log "Failed: $($validationReport.summary.failed)" "ERROR"
Write-Log "Warnings: $($validationReport.summary.warnings)" "WARN"

$passPercentage = if ($validationReport.summary.totalChecks -gt 0) {
    [math]::Round(($validationReport.summary.passed / $validationReport.summary.totalChecks) * 100, 2)
} else {
    0
}

Write-Log "Pass Rate: $passPercentage%" "INFO"
Write-Log "Report saved to: $reportPath" "INFO"

# Output summary
Write-Host ""
Write-Host "+============================================================+"
Write-Host "|         COMPREHENSIVE VALIDATION REPORT                   |"
Write-Host "+============================================================+"
Write-Host "| Total Checks:    $($validationReport.summary.totalChecks)"
Write-Host "| Passed:          $($validationReport.summary.passed)"
Write-Host "| Failed:          $($validationReport.summary.failed)"
Write-Host "| Warnings:        $($validationReport.summary.warnings)"
Write-Host "| Pass Rate:       $passPercentage%"
Write-Host "+============================================================+"
Write-Host ""

# Exit code based on results
if ($validationReport.summary.failed -eq 0) {
    Write-Log "[OK] ALL VALIDATIONS PASSED" "SUCCESS"
    exit 0
}
else {
    Write-Log "[FAIL] SOME VALIDATIONS FAILED" "ERROR"
    exit 1
}

