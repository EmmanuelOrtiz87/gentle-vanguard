param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC', 'status', 'list')]
    [string]$Agent,
    
    [Parameter(Mandatory=$false)]
    [string]$Task,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('run', 'plan', 'validate', 'status')]
    [string]$Action = 'run',
    
    [switch]$Quiet,
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$skillsPath = Join-Path $repoRoot 'skills'

function Write-InfoLine {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[INFO] $Message" -ForegroundColor Gray
    }
}

function Write-AgentLine {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

$AGENT_SKILLS = @{
    'BA'  = @('bdd-scenarios-skill', 'documentation-governance')
    'SAD' = @('architecture-governance', 'api-design-skill', 'database-relational-skill', 'database-nosql-skill', 'typescript-skill', 'golang-api-skill', 'sdd-skill')
    'DEV' = @('angular-spa-skill', 'react-19-skill', 'nextjs-15-skill', 'tailwind-4-skill', 'zustand-5-skill', 'zod-4-skill', 'security-skill', 'technical-debt-skill', 'typescript-skill')
    'QA'  = @('testing-strategy-skill', 'testing-skill', 'playwright-skill', 'pytest-skill')
    'OPS' = @('docker-devops-skill', 'kubernetes-deployment', 'terraform-infrastructure', 'git-workflow-skill', 'release-management-skill')
    'GOV' = @('observability-skill', 'incident-response-plan', 'security-skill', 'code-review-orchestrator-skill')
    'DOC' = @('documentation-governance', 'sdd-skill', 'bdd-scenarios-skill', 'github-pr-skill')
}

$AGENT_DESCRIPTIONS = @{
    'BA'  = 'Business Analyst - Requirements, BDD, Acceptance Criteria'
    'SAD' = 'Solution Architect - Architecture, SDD, Technical Decisions'
    'DEV' = 'Developer - Implementation, Features, Refactoring'
    'QA'  = 'Quality Assurance - Testing, Validation, Test Automation'
    'OPS' = 'DevOps - Deployment, CI/CD, Infrastructure'
    'GOV' = 'Governance - Compliance, Observability, Security Audits'
    'DOC' = 'Documentation - BDD/SDD Specs, Guides, README'
}

function Get-AgentSkills {
    param([string]$AgentName)
    
    $skills = $AGENT_SKILLS[$AgentName]
    $skillFiles = @()
    
    foreach ($skill in $skills) {
        $skillDir = Join-Path $skillsPath $skill
        $skillMd = Join-Path $skillDir 'SKILL.md'
        if (Test-Path $skillMd) {
            $skillFiles += @{
                name = $skill
                path = $skillMd
                available = $true
            }
        } else {
            $skillFiles += @{
                name = $skill
                path = $skillMd
                available = $false
            }
        }
    }
    
    return $skillFiles
}

function Invoke-Agent {
    param(
        [string]$AgentName,
        [string]$TaskText,
        [string]$ActionType
    )
    
    Write-AgentLine "`n=== AGENT-$AgentName ===" 'Cyan'
    Write-AgentLine "Role: $($AGENT_DESCRIPTIONS[$AgentName])" 'White'
    Write-AgentLine "Task: $TaskText" 'Gray'
    Write-AgentLine "Action: $ActionType" 'Gray'
    Write-AgentLine ""
    
    $skills = Get-AgentSkills -AgentName $AgentName
    $availableSkills = $skills | Where-Object { $_.available }
    $missingSkills = $skills | Where-Object { -not $_.available }
    
    Write-AgentLine "Skills loaded ($($availableSkills.Count)):" 'Green'
    foreach ($skill in $availableSkills) {
        Write-Host "  [OK] $($skill.name)" -ForegroundColor Green
    }
    
    if ($missingSkills.Count -gt 0) {
        Write-AgentLine "`nSkills missing ($($missingSkills.Count)):" 'Yellow'
        foreach ($skill in $missingSkills) {
            Write-Host "  [--] $($skill.name)" -ForegroundColor Yellow
        }
    }
    
    Write-AgentLine "`n--- Ready to execute ---" 'Cyan'
    Write-Host "The orchestrator will now delegate to AGENT-$AgentName for:" -ForegroundColor White
    Write-Host "  $TaskText" -ForegroundColor Gray
    Write-Host ""
}

function Show-AgentStatus {
    param([string]$AgentName)
    
    $skills = Get-AgentSkills -AgentName $AgentName
    $available = ($skills | Where-Object { $_.available }).Count
    $total = $skills.Count
    
    return @{
        agent = $AgentName
        role = $AGENT_DESCRIPTIONS[$AgentName]
        skills_available = $available
        skills_total = $total
        readiness = if ($available -eq $total) { 'READY' } elseif ($available -gt 0) { 'PARTIAL' } else { 'UNAVAILABLE' }
        skills = $skills
    }
}

function Show-AllAgentsStatus {
    $results = @()
    
    foreach ($agent in $AGENT_SKILLS.Keys) {
        $results += Show-AgentStatus -AgentName $agent
    }
    
    return $results
}

if ($Agent -eq 'status') {
    $results = Show-AllAgentsStatus
    
    if ($AsJson) {
        $results | ConvertTo-Json -Depth 4
    } else {
        Write-Host "`n=== MULTI-AGENT REGISTRY STATUS ===" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($result in $results) {
            $color = switch ($result.readiness) {
                'READY' { 'Green' }
                'PARTIAL' { 'Yellow' }
                'UNAVAILABLE' { 'Red' }
            }
            
            Write-Host "[$($result.readiness)] AGENT-$($result.agent)" -ForegroundColor $color
            Write-Host "       $($result.role)" -ForegroundColor Gray
            Write-Host "       Skills: $($result.skills_available)/$($result.skills_total)" -ForegroundColor White
            Write-Host ""
        }
    }
    exit 0
}

if ($Agent -eq 'list') {
    Write-Host "`n=== AVAILABLE AGENTS ===" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($agent in $AGENT_SKILLS.Keys) {
        Write-Host "AGENT-$agent" -ForegroundColor Green
        Write-Host "  $($AGENT_DESCRIPTIONS[$agent])" -ForegroundColor Gray
        $skills = $AGENT_SKILLS[$agent] -join ", "
        Write-Host "  Skills: $skills" -ForegroundColor DarkGray
        Write-Host ""
    }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Agent)) {
    Write-Host "Usage: .\wf.ps1 agent <AGENT> [TASK] [ACTION]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Agents: BA, SAD, DEV, QA, OPS, GOV, DOC" -ForegroundColor White
    Write-Host "Actions: run, plan, validate, status" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\wf.ps1 agent list" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 agent status" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 agent DEV `"implement login feature`"" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 agent QA `"validate checkout flow`"" -ForegroundColor Gray
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Task)) {
    Write-AgentLine "Task parameter is required when specifying an agent." 'Yellow'
    Write-Host "Use: .\wf.ps1 agent $Agent `"<task description>`"" -ForegroundColor Gray
    exit 1
}

$validAgents = @('BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC')
if ($validAgents -notcontains $Agent) {
    Write-AgentLine "Unknown agent: $Agent" 'Red'
    Write-Host "Valid agents: $($validAgents -join ', ')" -ForegroundColor Gray
    exit 1
}

Invoke-Agent -AgentName $Agent -TaskText $Task -ActionType $Action
