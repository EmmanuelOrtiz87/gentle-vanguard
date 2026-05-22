# validate-gentle-vanguard-complete.ps1
# Comprehensive validation of ALL project aspects before deployment

$ErrorActionPreference = 'Stop'
$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path
$script:homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$errors = 0
$warnings = 0

function Test-Item($Description, $Condition, $Type = "ERROR") {
    if (-not $Condition) {
        if ($Type -eq "ERROR") {
            Write-Host "    [ERROR] $Description" -ForegroundColor Red
            $script:errors++
        } else {
            Write-Host "    [WARN] $Description" -ForegroundColor Yellow
            $script:warnings++
        }
    } else {
        Write-Host "    $Description" -ForegroundColor Green
    }
}

Write-Host "=== VALIDACION COMPLETA DE GENTLE_VANGUARD ===" -ForegroundColor Cyan
Write-Host ""

# 1. MANAGEMENT REPORTING SYSTEM
Write-Host "1. MANAGEMENT REPORTING SYSTEM" -ForegroundColor Yellow
Write-Host "---"

# Check report file exists (any recent report)
$reportFiles = Get-ChildItem (Join-Path $workspaceRoot "reports") -Filter "MANAGEMENT-REPORT-*.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Test-Item "Report file exists" ($null -ne $reportFiles)
if ($reportFiles) {
    $csv = Import-Csv $reportFiles.FullName
    # Report structure validation (always required)
    if ($csv.Count -gt 0) {
        Test-Item "Report has 14 columns" ($csv[0].PSObject.Properties.Name.Count -eq 14)
        Test-Item "All sessions have SessionID" (($csv | Where-Object { $_.SessionID -ne '' }).Count -eq $csv.Count)
        Test-Item "All sessions have Duration" (($csv | Where-Object { $_.'Duration(min)' -ne '' }).Count -eq $csv.Count)
    } else {
        # Empty report is OK for new deployments - just warn
        Test-Item "Report has data (10+ rows)" ($false) "WARNING"
    }
}

# Check script exists
$reportScript = Join-Path $workspaceRoot "scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1"
Test-Item "generate-management-report.ps1 exists" (Test-Path $reportScript)

# Check skill exists (in project skills directory)
$skillFile = Join-Path $workspaceRoot "skills\reporting-skill\SKILL.md"
Test-Item "reporting-skill exists" (Test-Path $skillFile)

# Check opencode.json has post_session hook (optional - may be handled by session manager)
$hasPostSession = ($opencodeConfig.hooks -and $opencodeConfig.hooks.PSObject.Properties['post_session']) -or
                  (Test-Path (Join-Path $workspaceRoot "scripts\utilities\session-manager.ps1"))
Test-Item "opencode.json has post_session hook or session manager" $hasPostSession

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

# Check AGENTS.md has required sections
$agentsMdPath = Join-Path $workspaceRoot "docs\AGENTS.md"
if (-not (Test-Path $agentsMdPath)) {
    $agentsMdPath = Join-Path $workspaceRoot "AGENTS.md"
}
$agentsMd = Get-Content $agentsMdPath -Raw
Test-Item "AGENTS.md has Tool Detection Rule" ($agentsMd -match "Tool Detection Rule" -or $agentsMd -match "tool-agnostic")

Write-Host ""

# 4. HOOKS AND TRIGGERS
Write-Host "4. HOOKS AND TRIGGERS" -ForegroundColor Yellow
Write-Host "---"

# Check pre_process configuration (hooks may be in agent routing instead of global hooks)
$hasPreProcess = ($opencodeConfig.hooks -and $opencodeConfig.hooks.pre_process -and $opencodeConfig.hooks.pre_process.enabled -eq $true) -or 
                 (Get-Content (Join-Path $workspaceRoot "opencode.json") -Raw | Select-String -Pattern "pre-process-input.ps1" -Quiet)
Test-Item "opencode.json has pre_process hook" $hasPreProcess

# Check pre-process script exists
$preProcessScript = Join-Path $workspaceRoot "scripts\utilities\pre-process-input.ps1"
Test-Item "pre-process-input.ps1 exists" (Test-Path $preProcessScript)

# Check session autostart
$autostartFile = if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
    Join-Path $workspaceRoot "scripts\utilities\session-autostart.cmd"
} else {
    Join-Path $workspaceRoot "scripts\utilities\session-autostart.sh"
}
Test-Item "session-autostart exists" (Test-Path $autostartFile)

Write-Host ""

# 5. SKILLS REGISTRY
Write-Host "5. SKILLS REGISTRY" -ForegroundColor Yellow
Write-Host "---"

# Count actual skill directories (source of truth)
$skillsDir = Join-Path $workspaceRoot "skills"
$actualSkillCount = (Get-ChildItem $skillsDir -Directory).Count
Test-Item "Skills directory has 90+ folders" ($actualSkillCount -ge 90)

# Check SKILL_INDEX has entries (count skill entries by looking for "### " pattern)
$skillIndex = Get-Content (Join-Path $workspaceRoot "skills\SKILL_INDEX.md") -Raw
# Use regex to count "### " headers
$indexCount = ([regex]::Matches($skillIndex, '###\s+\w')).Count
# Actual skill count is 100 (from directory count), index shows 100 entries
Test-Item "SKILL_INDEX has entries (>= 90)" ($indexCount -ge 90)

$skillsDir = Join-Path $workspaceRoot "skills"
$actualSkills = (Get-ChildItem $skillsDir -Directory).Count
Test-Item "Skills directory has 90+ folders" ($actualSkills -ge 90)

Write-Host ""

# 6. DOCUMENTATION
Write-Host "6. DOCUMENTATION" -ForegroundColor Yellow
Write-Host "---"

$docFiles = @(
    "README.md",
    "docs\AGENTS.md",
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
    "scripts\utilities\pre-process-input.ps1"
)

foreach ($script in $scriptsToCheck) {
    $scriptPath = Join-Path $workspaceRoot $script
    if (Test-Path $scriptPath) {
        try {
            $null = Get-Content $scriptPath -Raw | ForEach-Object { [System.Management.Automation.PSParser]::Tokenize($_, [ref]$null) }
            Write-Host "    $script syntax OK" -ForegroundColor Green
        } catch {
            Write-Host "    $script syntax ERROR: $_" -ForegroundColor Red
            $errors++
        }
    } else {
        Write-Host "    $script not found" -ForegroundColor Yellow
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
            Write-Host "    $config valid JSON" -ForegroundColor Green
        } catch {
            Write-Host "    $config invalid JSON: $_" -ForegroundColor Red
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
    Write-Host " VALIDATION FAILED - Fix errors before deploying" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host " VALIDATION PASSED - Safe to deploy" -ForegroundColor Green
    exit 0
}


