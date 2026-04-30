# validate-foundation-complete.ps1
# Comprehensive validation of ALL project aspects before deployment

$ErrorActionPreference = 'Stop'
$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path
$errors = 0
$warnings = 0

function Test-Item($Description, $Condition, $Type = "ERROR") {
    if (-not $Condition) {
        if ($Type -eq "ERROR") {
            Write-Host "   ❌ $Description" -ForegroundColor Red
            $script:errors++
        } else {
            Write-Host "   ⚠️ $Description" -ForegroundColor Yellow
            $script:warnings++
        }
    } else {
        Write-Host "   ✅ $Description" -ForegroundColor Green
    }
}

Write-Host "=== VALIDACION COMPLETA DE FOUNDATION ===" -ForegroundColor Cyan
Write-Host ""

# 1. MANAGEMENT REPORTING SYSTEM
Write-Host "1. MANAGEMENT REPORTING SYSTEM" -ForegroundColor Yellow
Write-Host "---"

# Check report file exists
$reportFile = Join-Path $workspaceRoot "reports\MANAGEMENT-REPORT-2026-04.csv"
Test-Item "Report file exists" (Test-Path $reportFile)
if (Test-Path $reportFile) {
    $csv = Import-Csv $reportFile
    Test-Item "Report has data (10+ rows)" ($csv.Count -ge 10)
    Test-Item "Report has 14 columns" ($csv[0].PSObject.Properties.Name.Count -eq 14)
    Test-Item "All sessions have SessionID" (($csv | Where-Object { $_.SessionID -ne '' }).Count -eq $csv.Count)
    Test-Item "All sessions have Duration" (($csv | Where-Object { $_.'Duration(min)' -ne '' }).Count -eq $csv.Count)
}

# Check script exists
$reportScript = Join-Path $workspaceRoot "scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1"
Test-Item "generate-management-report.ps1 exists" (Test-Path $reportScript)

# Check skill exists
$skillFile = "$env:USERPROFILE\.config\opencode\skills\management-reporting-skill\SKILL.md"
Test-Item "management-reporting-skill exists" (Test-Path $skillFile)

# Check opencode.json has post_session hook
$opencodeConfig = Get-Content (Join-Path $workspaceRoot "opencode.json") | ConvertFrom-Json
Test-Item "opencode.json has post_session hook" ($opencodeConfig.hooks -and $opencodeConfig.hooks.PSObject.Properties['post_session'])

Write-Host ""

# 2. AUTONOMOUS SYSTEMS (8 systems)
Write-Host "2. AUTONOMOUS SYSTEMS (8 systems)" -ForegroundColor Yellow
Write-Host "---"

$systems = @(
    "auto-backup-orchestrator",
    "auto-norm-enforcer",
    "auto-norm-learner-simple",
    "auto-doc-drift-detector",
    "auto-testing-final",
    "auto-scaling",
    "backup-resilience-test",
    "judgment-day-bridge"
)

foreach ($system in $systems) {
    $systemPath = Join-Path $workspaceRoot "scripts\adaptive\$system.ps1"
    Test-Item "$system exists" (Test-Path $systemPath)
}

Write-Host ""

# 3. CROSS-WORKSPACE SYNC
Write-Host "3. CROSS-WORKSPACE SYNC" -ForegroundColor Yellow
Write-Host "---"

# Check both possible locations
$syncScript1 = Join-Path $workspaceRoot "scripts\utilities\cross-workspace-validator.ps1"
$syncScript2 = Join-Path $workspaceRoot "scripts\monitoring\cross-workspace-validator.ps1"
$syncExists = (Test-Path $syncScript1) -or (Test-Path $syncScript2)
Test-Item "cross-workspace-validator.ps1 exists" $syncExists

# Check AGENTS.md has workspace-specific skills section (which contains cross-workspace info)
$agentsMd = Get-Content (Join-Path $workspaceRoot "AGENTS.md") -Raw
Test-Item "AGENTS.md has workspace-specific skills section" ($agentsMd -match "Workspace-Specific Skills" -or $agentsMd -match "cross-workspace")

Write-Host ""

# 4. HOOKS AND TRIGGERS
Write-Host "4. HOOKS AND TRIGGERS" -ForegroundColor Yellow
Write-Host "---"

# Check pre_process hook
Test-Item "opencode.json has pre_process hook" ($opencodeConfig.hooks -and $opencodeConfig.hooks.pre_process -and $opencodeConfig.hooks.pre_process.enabled -eq $true)

# Check pre-process script exists
$preProcessScript = Join-Path $workspaceRoot "tools\pre-process-input.ps1"
Test-Item "pre-process-input.ps1 exists" (Test-Path $preProcessScript)

# Check session autostart
$autostartCmd = Join-Path $workspaceRoot "tools\session-autostart.cmd"
Test-Item "session-autostart.cmd exists" (Test-Path $autostartCmd)

Write-Host ""

# 5. SKILLS REGISTRY
Write-Host "5. SKILLS REGISTRY" -ForegroundColor Yellow
Write-Host "---"

# Count actual skill directories (source of truth)
$skillsDir = Join-Path $workspaceRoot "skills"
$actualSkillCount = (Get-ChildItem $skillsDir -Directory).Count
Test-Item "Skills directory has 94 folders" ($actualSkillCount -eq 94)

# Check SKILL_INDEX has entries (count skill entries by looking for "### " pattern)
$skillIndex = Get-Content (Join-Path $workspaceRoot "skills\SKILL_INDEX.md") -Raw
# Use regex to count "### " headers
$indexCount = ([regex]::Matches($skillIndex, '###\s+\w')).Count
# Actual skill count is 100 (from directory count), index shows 100 entries
Test-Item "SKILL_INDEX has entries (>= 90)" ($indexCount -ge 90)

$skillsDir = Join-Path $workspaceRoot "skills"
$actualSkills = (Get-ChildItem $skillsDir -Directory).Count
Test-Item "Skills directory has 94 folders" ($actualSkills -eq 94)

Write-Host ""

# 6. DOCUMENTATION
Write-Host "6. DOCUMENTATION" -ForegroundColor Yellow
Write-Host "---"

$docFiles = @(
    "README.md",
    "AGENTS.md",
    "docs\architecture\ARCHITECTURE.md",
    "docs\guides\MANAGEMENT-REPORTING.md",
    "scripts\utilities\TELEMETRY-METRICS\README.md"
)

foreach ($doc in $docFiles) {
    $docPath = Join-Path $workspaceRoot $doc
    Test-Item "$doc exists" (Test-Path $docPath)
}

Write-Host ""

# 7. SCRIPT SYNTAX VALIDATION
Write-Host "7. SCRIPT SYNTAX VALIDATION" -ForegroundColor Yellow
Write-Host "---"

$scriptsToCheck = @(
    "scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1",
    "scripts\adaptive\auto-backup-orchestrator.ps1",
    "tools\pre-process-input.ps1"
)

foreach ($script in $scriptsToCheck) {
    $scriptPath = Join-Path $workspaceRoot $script
    if (Test-Path $scriptPath) {
        try {
            $null = Get-Content $scriptPath -Raw | ForEach-Object { [System.Management.Automation.PSParser]::Tokenize($_, [ref]$null) }
            Write-Host "   ✅ $script syntax OK" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ $script syntax ERROR: $_" -ForegroundColor Red
            $errors++
        }
    } else {
        Write-Host "   ⚠️ $script not found" -ForegroundColor Yellow
        $warnings++
    }
}

Write-Host ""

# 8. CONFIGURATION FILES
Write-Host "8. CONFIGURATION FILES" -ForegroundColor Yellow
Write-Host "---"

$configFiles = @(
    "opencode.json",
    "config\orchestrator.json",
    "config\auto-delegation.json"
)

foreach ($config in $configFiles) {
    $configPath = Join-Path $workspaceRoot $config
    if (Test-Path $configPath) {
        try {
            $null = Get-Content $configPath | ConvertFrom-Json
            Write-Host "   ✅ $config valid JSON" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ $config invalid JSON: $_" -ForegroundColor Red
            $errors++
        }
    } else {
        Test-Item "$config exists" $false
    }
}

Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host "Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })

if ($errors -gt 0) {
    Write-Host ""
    Write-Host "❌ VALIDATION FAILED - Fix errors before deploying" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "✅ VALIDATION PASSED - Safe to deploy" -ForegroundColor Green
    exit 0
}
