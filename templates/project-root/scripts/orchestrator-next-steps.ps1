param(
    [switch]$Detailed
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
if (-not (Test-Path (Join-Path $ProjectRoot 'README.md'))) {
    $ProjectRoot = Resolve-Path (Join-Path $ProjectRoot '..')
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor White
}

function Write-Action {
    param([string]$Message)
    Write-Host "  - $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Resolve-SkillPath {
    param([string]$Candidate)
    if (Test-Path $Candidate) { return (Resolve-Path $Candidate).Path }
    return $null
}

$ActivationFile = Join-Path $ProjectRoot '.orchestrator-active'
$ConfigFile = Join-Path $ProjectRoot 'config\orchestrator.json'

Write-Step "Project Orchestrator - Next Steps"

if (-not (Test-Path $ActivationFile)) {
    Write-Host "The orchestrator does not appear to be active in this project." -ForegroundColor Red
    Write-Host "Run project setup or create a new project from the Foundation template to activate it." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $ConfigFile)) {
    Write-Host "Orchestrator configuration file is missing: $ConfigFile" -ForegroundColor Yellow
}

$OrchestratorPath = $null
$skillCandidates = @(
    Join-Path $ProjectRoot '.skills\project-orchestrator-skill',
    Join-Path $ProjectRoot '.workspace-foundation\skills\project-orchestrator-skill',
    Join-Path $ProjectRoot 'skills\project-orchestrator-skill'
)

foreach ($candidate in $skillCandidates) {
    if (Test-Path $candidate) {
        $OrchestratorPath = Resolve-SkillPath $candidate
        break
    }
}

if (-not $OrchestratorPath -and (Test-Path $ConfigFile)) {
    try {
        $configData = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($configData.skill_path) {
            $candidate = Join-Path $ProjectRoot $configData.skill_path
            if (Test-Path $candidate) {
                $OrchestratorPath = Resolve-SkillPath $candidate
            }
        }
    } catch {
        Write-Host "Unable to parse orchestrator configuration." -ForegroundColor Yellow
    }
}

Write-Step "Activation Status"
if ($OrchestratorPath) {
    Write-Success "Orchestrator skill found: $OrchestratorPath"
} else {
    Write-Host "Orchestrator skill not found in expected locations." -ForegroundColor Yellow
    Write-Host "Check '.skills/' or '.workspace-foundation/skills/' and validate the project setup." -ForegroundColor Yellow
}

if (Test-Path $ActivationFile) {
    $activationData = Get-Content $ActivationFile | ConvertFrom-Json
    Write-Info "Activated: $($activationData.activated)"
    Write-Info "Skill: $($activationData.skill)"
    Write-Info "Project: $($activationData.project)"
}

if (Test-Path $ConfigFile) {
    try {
        $configData = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        Write-Info "Workflow mode: $($configData.workflow_mode)"
        Write-Info "Auto detect: $($configData.auto_detect)"
        Write-Info "Memory integration: $($configData.memory_integration)"
        Write-Info "Quality gates: $($configData.quality_gates)"
    } catch {
        Write-Host "Unable to read orchestrator configuration details." -ForegroundColor Yellow
    }
}

Write-Step "Recommended Next Activities"
Write-Action "Validate the project and orchestrator configuration with the Foundation tools."
Write-Action "Inspect docs/project-context.md and ARCHITECTURE.md to confirm scope and architecture."
Write-Action "Use the orchestrator to guide analysis, design, architecture, and testing." 
Write-Action "Ensure the AI workflow is ready and the required skills are available." 

if ($Detailed) {
    Write-Step "Detailed Guidance"
    Write-Action "Apply testing-strategy and testing-skill to improve test coverage." 
    Write-Action "Use architecture-governance for architecture decisions and documentation." 
    Write-Action "Use security-expert and code-review-orchestrator for quality and vulnerability analysis." 
    Write-Action "Use ai-sdk-5 and mcp-skill for AI-assisted modeling and session memory." 
}

Write-Step "Orchestrator Ready"
Write-Host "The Project Orchestrator is active and ready to guide the development lifecycle." -ForegroundColor Green
Write-Host "Run this script again with -Detailed for extra guidance." -ForegroundColor Green
