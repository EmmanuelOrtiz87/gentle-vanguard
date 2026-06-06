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

function Get-ChangedPaths {
    $lines = git status --porcelain 2>$null
    if (-not $lines) {
        return @()
    }

    return @(
        $lines |
            Where-Object { $_.Length -ge 4 } |
            ForEach-Object { $_.Substring(3).Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Get-CommunicationRecommendation {
    param([string[]]$ChangedPaths)

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) { $branch = 'unknown' }

    $risk = 'medium'
    if ($branch -match '^(hotfix|release)/') {
        $risk = 'high'
    }

    $preset = 'bugfix'
    $reason = 'default fallback for implementation work'

    if ($ChangedPaths -and @($ChangedPaths | Where-Object { $_ -like 'docs/*' }).Count -eq $ChangedPaths.Count) {
        $preset = 'docs'
        $reason = 'changed files are documentation-focused'
    }
    elseif ($ChangedPaths -and @($ChangedPaths | Where-Object { $_ -match 'audit|review|governance' }).Count -gt 0) {
        $preset = 'audit-review'
        $reason = 'audit/review/governance files detected'
    }
    elseif ($ChangedPaths -and @($ChangedPaths | Where-Object { $_ -match 'refactor|cleanup|homologat' }).Count -gt 0) {
        $preset = 'refactor'
        $reason = 'refactor/cleanup indicators detected'
    }

    return [pscustomobject]@{
        preset = $preset
        risk = $risk
        branch = $branch
        reason = $reason
    }
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
    Write-Host "Run project setup or create a new project from the Gentle-Vanguard template to activate it." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $ConfigFile)) {
    Write-Host "Orchestrator configuration file is missing: $ConfigFile" -ForegroundColor Yellow
}

$OrchestratorPath = $null
$skillCandidates = @(
    Join-Path $ProjectRoot '.skills\project-orchestrator-skill',
    Join-Path $ProjectRoot '.gentle-vanguard\\skills\project-orchestrator-skill',
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
    Write-Host "Check '.skills/' or '.gentle-vanguard/skills/' and validate the project setup." -ForegroundColor Yellow
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
Write-Action "Validate the project and orchestrator configuration with the Gentle-Vanguard tools."
Write-Action "Inspect docs/project-context.md and ARCHITECTURE.md to confirm scope and architecture."
Write-Action "Run the next-steps command from the orchestrator to keep the cycle moving."
Write-Action "Use project-orchestrator for analysis, design, architecture and testing guidance."
Write-Action "Check the new project for required skills and ensure the AI workflow is ready."

$changedPaths = Get-ChangedPaths
$communication = Get-CommunicationRecommendation -ChangedPaths $changedPaths

Write-Step "Communication Mode Recommendation"
Write-Info "Branch: $($communication.branch)"
Write-Info "Recommended preset: $($communication.preset)"
Write-Info "Recommended risk: $($communication.risk)"
Write-Info "Reason: $($communication.reason)"
Write-Action ("Apply preset: .\scripts\utilities\gv.ps1 response-mode preset:{0}" -f $communication.preset)
Write-Action ("Inspect recommendation: .\scripts\utilities\gv.ps1 response-mode recommend:{0}:{1}" -f $communication.preset, $communication.risk)

if ($Detailed) {
    Write-Step "Detailed Guidance"
    Write-Action "Use testing-strategy and testing-skill to create or improve test coverage."
    Write-Action "Use architecture-governance for architecture decisions and documentation."
    Write-Action "Use security-expert and code-review-orchestrator for quality and vulnerability analysis."
    Write-Action "Use ai-sdk-5 and mcp-skill for AI-assisted modeling and session memory." 
}

Write-Step "Orchestrator Ready"
Write-Host "The Project Orchestrator is active and ready to guide the development lifecycle." -ForegroundColor Green
Write-Host "Run this script again with -Detailed for extra guidance." -ForegroundColor Green

