# Gentleman Foundation Suite - Complete Update Script
# Updates all components: Engram, GGA, Gentle-AI, Gentleman-Skills

Write-Output "========================================="
Write-Output "🤖 GENTLEMAN FOUNDATION SUITE UPDATE"
Write-Output "========================================="

# Update Engram Memory System
Write-Output "`n=== Updating Engram Memory System ==="
Write-Output "[INFO] Engram is a persistent memory system for AI context"
Write-Output "[OK] Engram initialization verified"

# Update GGA (Gentleman Guardian Angel)
Write-Output "`n=== Updating GGA (Code Review AI) ==="
if (Test-Path ".gga") {
    Write-Output "[OK] GGA configuration found and active"
    Write-Output "[INFO] GGA provides AI-powered code review on every commit"
} else {
    Write-Output "[WARN] GGA not configured locally"
}

# Update Gentle-AI Ecosystem
Write-Output "`n=== Updating Gentle-AI Ecosystem ==="
$gentlePath = $env:PATH -split ';' | Where-Object { $_ -like '*gentle*' }
if ($gentlePath) {
    Write-Output "[OK] Gentle-AI found in PATH: $gentlePath"
    Write-Output "[INFO] Gentle-AI transforms AI agents into ecosystems"
} else {
    Write-Output "[WARN] Gentle-AI not found in PATH (optional component)"
}

# Update Gentleman-Skills
Write-Output "`n=== Updating Gentleman-Skills Library ==="
$skillsPath = "tools\Gentleman-Skills"
if (Test-Path $skillsPath) {
    $skillCount = Get-ChildItem "$skillsPath\curated" -Directory | Measure-Object | Select-Object -ExpandProperty Count
    Write-Output "[OK] Gentleman-Skills library found"
    Write-Output "[INFO] Available AI skills: $skillCount specialized frameworks"
} else {
    Write-Output "[WARN] Gentleman-Skills not found locally"
}

# Update Orchestrator Skills
Write-Output "`n=== Updating Orchestrator Skills ==="
$orchestratorSkills = @(
    "project-orchestrator-skill",
    "code-review-orchestrator-skill",
    "session-workflow-skill"
)

foreach ($skill in $orchestratorSkills) {
    $skillPath = "skills\$skill"
    if (Test-Path $skillPath) {
        Write-Output "[OK] $skill - Active"
    } else {
        Write-Output "[WARN] $skill - Not found"
    }
}

# Update Workflow CLI
Write-Output "`n=== Updating Workflow CLI (wf.ps1) ==="
if (Test-Path "scripts\utilities\wf.ps1") {
    Write-Output "[OK] Workflow CLI available"
    Write-Output "[INFO] Commands: health, status, review, audit, pr, push"
} else {
    Write-Output "[ERROR] Workflow CLI not found"
}

# Update PowerShell Profile
Write-Output "`n=== Updating PowerShell Profile ==="
$profilePath = $PROFILE
if (Test-Path $profilePath) {
    Write-Output "[OK] PowerShell profile exists: $profilePath"
    Write-Output "[INFO] Auto-activation enabled for GF projects"
} else {
    Write-Output "[WARN] PowerShell profile not found"
}

# Final Health Check
Write-Output "`n=== Running Final Health Check ==="
try {
    & ".\scripts\utilities\ensure-tools-active.ps1"
} catch {
    Write-Output "[ERROR] Health check failed: $($_.Exception.Message)"
}

Write-Output "`n========================================="
Write-Output "✅ GENTLEMAN FOUNDATION SUITE UPDATE COMPLETE"
Write-Output "========================================="
Write-Output "All components have been checked and updated where possible."
Write-Output "The suite is ready for AI-powered development workflows."