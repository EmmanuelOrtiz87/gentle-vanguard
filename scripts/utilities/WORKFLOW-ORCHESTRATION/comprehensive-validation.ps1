<#
.SYNOPSIS
Comprehensive end-to-end validation of entire Foundation system (updated 2026-05-02)

.DESCRIPTION
Complete validation that checks:
- All scripts for syntax errors
- Configuration files validity (actual files)
- Documentation completeness (actual docs)
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

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = ".session/logs/comprehensive-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
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
# 1. VALIDATE POWERSHELL SCRIPTS (actual scripts)
# ============================================================================
Write-Log "=== VALIDATING POWERSHELL SCRIPTS ===" "INFO"

$psScripts = @(
    "tools/cache-cleanup-manager.ps1",
    "tools/cleanup-project.ps1",
    "tools/clear-context.ps1",
    "tools/enforce-response-mode.ps1",
    "tools/handoff-compress.ps1",
    "tools/initialize-distributed-tracing.ps1",
    "tools/initialize-orchestrator.ps1",
    "tools/master-connector.ps1",
    "tools/message-tracker.ps1",
    "tools/notify-user.ps1",
    "tools/optimize-engram-usage.ps1",
    "tools/post-task-cleanup.ps1",
    "tools/pre-close-validator.ps1",
    "tools/pre-compact-hook.ps1",
    "tools/pre-process-input.ps1",
    "tools/session-idle-monitor.ps1",
    "tools/session-manager.ps1",
    "tools/session-notification.ps1",
    "tools/session-quick-restart.ps1",
    "tools/telemetry-dashboard.ps1",
    "tools/token-guard.ps1",
    "tools/token-monitor.ps1",
    "tools/token-telemetry.ps1",
    "tools/trigger-detector.ps1"
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
        Add-ValidationResult "PowerShell Scripts" $script "WARN" "File not found (optional)"
        Write-Log "[WARN] $script - File not found" "WARN"
    }
}

# ============================================================================
# 2. VALIDATE JSON CONFIGURATION FILES (actual files)
# ============================================================================
Write-Log "=== VALIDATING JSON CONFIGURATION FILES ===" "INFO"

$jsonFiles = @(
    "config/hooks-config.json",
    "config/workspace.config.json",
    "tools/session-autostart.config.json",
    "tools/context-efficiency-config.json",
    "tools/token-guard-config.json"
)

foreach ($jsonFile in $jsonFiles) {
    if (Test-Path $jsonFile) {
        try {
            $json = Get-Content $jsonFile -Raw | ConvertFrom-Json
            Add-ValidationResult "JSON Configuration" $jsonFile "PASS" "Valid JSON"
            Write-Log "[OK] $jsonFile - Valid JSON" "SUCCESS"
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
# 3. VALIDATE DOCUMENTATION (actual docs)
# ============================================================================
Write-Log "=== VALIDATING DOCUMENTATION ===" "INFO"

$docFiles = @(
    "README.md",
    "AGENTS.md",
    "CLAUDE.md",
    "docs/README.md",
    "docs/architecture/README.md",
    "docs/guides/README.md",
    "docs/reference/NORMATIVAS-ORQUESTADOR.md",
    "docs/reference/OPERATING-DECISIONS-2026-04-15.md"
)

foreach ($docFile in $docFiles) {
    if (Test-Path $docFile) {
        $content = Get-Content $docFile -Raw
        $lines = $content.Split("`n").Count
        
        # Check for Spanish accents (governance rule)
        $hasAccents = $content -match "ación|ón|ín|é|á|í|ó|ú"
        
        if ($lines -gt 10) {
            $status = if ($hasAccents) { "PASS" } else { "WARN" }
            $details = if ($hasAccents) { "$lines lines, accents OK" } else { "$lines lines, missing accents" }
            Add-ValidationResult "Documentation" $docFile $status $details
            Write-Log "[$($status)] $docFile - $details" $(if ($status -eq "PASS") { "SUCCESS" } else { "WARN" })
        }
        else {
            Add-ValidationResult "Documentation" $docFile "WARN" "Document too short ($lines lines)"
            Write-Log "[WARN] $docFile - Document too short" "WARN"
        }
    }
    else {
        Add-ValidationResult "Documentation" $docFile "FAIL" "File not found"
        Write-Log "[FAIL] $docFile - File not found" "ERROR"
    }
}

# ============================================================================
# 4. VALIDATE DIRECTORY STRUCTURE (actual structure)
# ============================================================================
Write-Log "=== VALIDATING DIRECTORY STRUCTURE ===" "INFO"

$requiredDirs = @(
    "config",
    "docs",
    "docs/architecture",
    "docs/guides",
    "docs/reference",
    "scripts",
    "scripts/utilities",
    "skills",
    "tools",
    ".session/logs",
    ".session/reports"
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
    if (Test-Path "config/hooks-config.json") {
        $hooksConfig = Get-Content "config/hooks-config.json" -Raw | ConvertFrom-Json
        
        if ($hooksConfig.hooks) {
            Add-ValidationResult "Hooks Configuration" "hooks-config.json" "PASS" "Hooks section exists"
            Write-Log "[OK] hooks-config.json - Hooks section exists" "SUCCESS"
        }
        else {
            Add-ValidationResult "Hooks Configuration" "hooks-config.json" "WARN" "No hooks defined"
            Write-Log "[WARN] hooks-config.json - No hooks defined" "WARN"
        }
    }
    else {
        Add-ValidationResult "Hooks Configuration" "hooks-config.json" "WARN" "File not found"
        Write-Log "[WARN] Hooks configuration error: File not found" "WARN"
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
        Add-ValidationResult "Automation Setup" $file "WARN" "File not found (may be archived)"
        Write-Log "[WARN] $file - File not found" "WARN"
    }
}

# ============================================================================
# 7. VALIDATE SYSTEM DEFINITIONS
# ============================================================================
Write-Log "=== VALIDATING SYSTEM DEFINITIONS ===" "INFO"

try {
    if (Test-Path "opencode.json") {
        $opencode = Get-Content "opencode.json" -Raw | ConvertFrom-Json
        
        if ($opencode.provider) {
            Add-ValidationResult "System Definitions" "opencode.json - provider" "PASS" "Provider configured"
            Write-Log "[OK] opencode.json - Provider configured" "SUCCESS"
        }
        
        if ($opencode.agent) {
            Add-ValidationResult "System Definitions" "opencode.json - agent" "PASS" "Agent configured"
            Write-Log "[OK] opencode.json - Agent configured" "SUCCESS"
        }
    }
    else {
        Add-ValidationResult "System Definitions" "opencode.json" "WARN" "File not found"
        Write-Log "[WARN] opencode.json - File not found" "WARN"
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
# 9. VALIDATE .gitignore
# ============================================================================
Write-Log "=== VALIDATING .gitignore ===" "INFO"

if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore" -Raw
    
    $requiredIgnores = @("node_modules", ".telemetry/", ".engram-data/")
    $missingIgnores = @()
    
    foreach ($ignore in $requiredIgnores) {
        if ($gitignore -notmatch [regex]::Escape($ignore)) {
            $missingIgnores += $ignore
        }
    }
    
    if ($missingIgnores.Count -eq 0) {
        Add-ValidationResult ".gitignore" ".gitignore" "PASS" "Required ignores present"
        Write-Log "[OK] .gitignore - Required ignores present" "SUCCESS"
    }
    else {
        Add-ValidationResult ".gitignore" ".gitignore" "WARN" "Missing: $($missingIgnores -join ', ')"
        Write-Log "[WARN] .gitignore - Missing some ignores" "WARN"
    }
}
else {
    Add-ValidationResult ".gitignore" ".gitignore" "FAIL" "File not found"
    Write-Log "[FAIL] .gitignore - File not found" "ERROR"
}

# ============================================================================
# GENERATE SUMMARY REPORT
# ============================================================================
Write-Log "=== GENERATING SUMMARY REPORT ===" "INFO"

$reportPath = ".session/reports/comprehensive-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
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
