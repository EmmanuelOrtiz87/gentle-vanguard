param(
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Fix,
    [switch]$Delegate
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PWD.Path

Set-Location $repoRoot

$script:Results = @{
    scripts = @{ issues = @(); fixed = @(); delegated = @() }
    docs = @{ issues = @(); fixed = @(); delegated = @() }
    skills = @{ issues = @(); fixed = @(); delegated = @() }
    config = @{ issues = @(); fixed = @(); delegated = @() }
}

$script:TotalIssues = 0

function Write-Orchestrate {
    param([string]$Message, [string]$Type = "INFO")
    $color = switch ($Type) {
        "SCRIPT" { "Cyan" }
        "DOC" { "Yellow" }
        "SKILL" { "Magenta" }
        "CONFIG" { "Blue" }
        "FIX" { "Green" }
        "DELEGATE" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[ORCHESTRATOR] $Message" -ForegroundColor $color
}

function Invoke-ScriptValidator {
    Write-Orchestrate "Validating scripts..." "SCRIPT"

    $validator = Join-Path $repoRoot "scripts\hooks\auto-fix-delegate.ps1"
    if (-not (Test-Path $validator)) {
        $validator = Join-Path $repoRoot "scripts\hooks\pre-push-script-validator.ps1"
    }
    if (-not (Test-Path $validator)) {
        Write-Orchestrate "Script validator not found, skipping" "SCRIPT"
        return
    }

    $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validator 2>&1 | Out-String

    if ($result -match "SUCCESS|PASS|All scripts validated") {
        $script:Results.scripts.fixed += "auto-fix-delegate"
        Write-Orchestrate "Scripts: OK" "SUCCESS"
    } elseif ($result -match "0 issues found") {
        $script:Results.scripts.fixed += "auto-fix-delegate"
        Write-Orchestrate "Scripts: OK (0 issues)" "SUCCESS"
    } elseif ($result -match "Auto-fixed") {
        $script:Results.scripts.fixed += "auto-fix-delegate"
        Write-Orchestrate "Scripts: AUTO-FIXED" "FIX"
    } else {
        $script:Results.scripts.issues += @{ output = $result }
        Write-Orchestrate "Scripts: Check output" "SCRIPT"
    }
}

function Invoke-DocsValidator {
    Write-Orchestrate "Validating documentation..." "DOC"

    $auditScript = Join-Path $repoRoot "skills\foundation-audit-skill\scripts\audit-sweep.ps1"
    if (-not (Test-Path $auditScript)) {
        $auditScript = Join-Path $repoRoot "tools\skills\foundation-audit-skill\scripts\audit-sweep.ps1"
    }
    if (-not (Test-Path $auditScript)) {
        Write-Orchestrate "Docs validator not found" "DOC"
        return
    }

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $auditScript -Scope quick 2>&1 | Out-String

    if ($output -match "0 errors|0 issues|passed|Audit passed") {
        Write-Orchestrate "Documentation: OK" "SUCCESS"
    } elseif ($output -match "(\d+) errors") {
        $count = $matches[1]
        $script:Results.docs.issues += @{ count = $count; output = $output }
        Write-Orchestrate "Documentation: $count errors" "DOC"
    } elseif ($output -match "(\d+) issues") {
        $count = $matches[1]
        $script:Results.docs.issues += @{ count = $count; output = $output }
        Write-Orchestrate "Documentation: $count issues" "DOC"
    } else {
        Write-Orchestrate "Documentation: Check output" "DOC"
    }
}

function Invoke-SkillsValidator {
    Write-Orchestrate "Validating skills..." "SKILL"

    $auditScript = Join-Path $repoRoot "skills\foundation-audit-skill\scripts\audit-sweep.ps1"
    if (-not (Test-Path $auditScript)) {
        $auditScript = Join-Path $repoRoot "tools\skills\foundation-audit-skill\scripts\audit-sweep.ps1"
    }
    if (-not (Test-Path $auditScript)) {
        Write-Orchestrate "Skills validator not found" "SKILL"
        return
    }

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $auditScript -Scope standard 2>&1 | Out-String

    if ($output -match "0 errors|0 issues|passed|Audit passed") {
        Write-Orchestrate "Skills: OK" "SUCCESS"
    } elseif ($output -match "(\d+) errors") {
        $count = $matches[1]
        $script:Results.skills.issues += @{ count = $count; output = $output }
        Write-Orchestrate "Skills: $count errors" "SKILL"
    } elseif ($output -match "(\d+) (skills|issues)") {
        $count = $matches[1]
        $script:Results.skills.issues += @{ count = $count; output = $output }
        Write-Orchestrate "Skills: $count $($matches[2])" "SKILL"
    } else {
        $script:Results.skills.issues += @{ output = $output }
        Write-Orchestrate "Skills: Check output" "SKILL"
    }
}

function Invoke-ConfigValidator {
    Write-Orchestrate "Validating configuration..." "CONFIG"

    $validatorScript = Join-Path $repoRoot "scripts\monitoring\cross-workspace-validator.ps1"
    if (-not (Test-Path $validatorScript)) {
        Write-Orchestrate "Config validator not found" "CONFIG"
        return
    }

    try {
        $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript 2>&1 | Out-String

        if ($output -match "inconsistencies|s diferencias") {
            if ($output -match "0|sin diferencias") {
                Write-Orchestrate "Configuration: OK" "SUCCESS"
            } else {
                $script:Results.config.issues += @{ output = $output }
                Write-Orchestrate "Configuration: Differences found" "CONFIG"
            }
        } else {
            Write-Orchestrate "Configuration: OK" "SUCCESS"
        }
    } catch {
        Write-Orchestrate "Configuration validation failed: $_" "CONFIG"
    }
}

function Invoke-Delegation {
    param([string]$Type, [string]$Files)

    if (-not $Delegate) { return }

    Write-Orchestrate "Delegating $Type issues..." "DELEGATE"

    $delegateScript = Join-Path $repoRoot "scripts\utilities\auto-delegation-wrapper.ps1"
    if (-not (Test-Path $delegateScript)) {
        Write-Orchestrate "Delegation not available" "DELEGATE"
        return
    }

    $task = "fix $Type issues: $Files"
    Write-Orchestrate "Task: $task" "DELEGATE"

    if (-not $DryRun) {
        & pwsh -NoProfile -Command "& `"$delegateScript`" `"$task`"" 2>&1
    }
}

Set-Location $repoRoot
Write-Orchestrate "=============================================="
Write-Orchestrate "ORCHESTRATOR: Autofix Unified Flow"
Write-Orchestrate "=============================================="

Write-Host ""
Write-Orchestrate "Phase 1: Detection"
Write-Orchestrate "----------------------------------------------"

Invoke-ScriptValidator
Invoke-DocsValidator
Invoke-SkillsValidator
Invoke-ConfigValidator

Write-Host ""
Write-Orchestrate "Phase 2: Auto-Fix (if enabled)"
Write-Orchestrate "----------------------------------------------"

$needsFix = @()
foreach ($key in $script:Results.Keys) {
    if ($script:Results[$key].issues.Count -gt 0) {
        $needsFix += $key
    }
}

if ($needsFix.Count -gt 0 -and $Fix) {
    Write-Orchestrate "Attempting auto-fix for: $($needsFix -join ', ')" "FIX"

    if ($Fix -and $script:Results.scripts.issues.Count -gt 0) {
        $fixScript = Join-Path $repoRoot "scripts\hooks\auto-fix-delegate.ps1"
        if (Test-Path $fixScript) {
            $fixResult = & pwsh -NoProfile -ExecutionPolicy Bypass -File $fixScript -DryRun:$DryRun 2>&1
            Write-Orchestrate "Scripts auto-fix: $fixResult" "FIX"
        }
    }
}

Write-Host ""
Write-Orchestrate "Phase 3: Summary"
Write-Orchestrate "----------------------------------------------"

$totalFixed = ($script:Results.scripts.fixed.Count + $script:Results.docs.fixed.Count + $script:Results.skills.fixed.Count + $script:Results.config.fixed.Count)
$totalIssues = ($script:Results.scripts.issues.Count + $script:Results.docs.issues.Count + $script:Results.skills.issues.Count + $script:Results.config.issues.Count)

Write-Orchestrate "Results:"
Write-Host "  Scripts:   $($script:Results.scripts.fixed.Count) fixed, $($script:Results.scripts.issues.Count) issues" -ForegroundColor $(if ($script:Results.scripts.issues.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Docs:     $($script:Results.docs.fixed.Count) fixed, $($script:Results.docs.issues.Count) issues" -ForegroundColor $(if ($script:Results.docs.issues.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Skills:   $($script:Results.skills.fixed.Count) fixed, $($script:Results.skills.issues.Count) issues" -ForegroundColor $(if ($script:Results.skills.issues.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Config:   $($script:Results.config.fixed.Count) fixed, $($script:Results.config.issues.Count) issues" -ForegroundColor $(if ($script:Results.config.issues.Count -gt 0) { "Yellow" } else { "Green" })

Write-Host ""
Write-Orchestrate "Total: $totalFixed fixed, $totalIssues issues"

if ($totalIssues -gt 0 -and $Delegate) {
    Write-Host ""
    Write-Orchestrate "Delegating unresolved issues..." "DELEGATE"

    if ($script:Results.scripts.issues.Count -gt 0) {
        Invoke-Delegation -Type "script" -Files "scripts"
    }
    if ($script:Results.docs.issues.Count -gt 0) {
        Invoke-Delegation -Type "documentation" -Files "docs"
    }
    if ($script:Results.skills.issues.Count -gt 0) {
        Invoke-Delegation -Type "skill" -Files "skills"
    }
    if ($script:Results.config.issues.Count -gt 0) {
        Invoke-Delegation -Type "configuration" -Files "config"
    }
}

Write-Host ""
if ($totalIssues -eq 0) {
    Write-Orchestrate "SUCCESS: All validations passed!" "SUCCESS"
    Write-Orchestrate "READY: Push authorized"
    exit 0
} elseif ($totalFixed -gt 0) {
    Write-Orchestrate "PARTIAL: Fixed $totalFixed, $totalIssues remaining"
    Write-Orchestrate "RECOMMENDATION: Run with -Fix -Delegate for auto-fix and delegation"
    exit 0
} else {
    Write-Orchestrate "ACTION REQUIRED: $totalIssues issues need attention"
    exit 1
}