<#
.SYNOPSIS
    Pre-process user input — keyword-based routing to skill + agent
.DESCRIPTION
    Canonical implementation. Routes user input to appropriate skill and agent
    based on keyword matching from auto-delegation.json.
    Called by: WORKFLOW-ORCHESTRATION/pre-process-input.ps1 (shim)
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

$inputLower = $UserInput.ToLower()

# Phase 1: Debug/diagnostic output
Write-Output "[pre-process-input] Processing: $UserInput"

# Phase 2: Keyword routing rules (ordered by priority)
# Each rule: { keywords[], skill, agentCode, planMode }
$rules = @(
    # PR / branch-pr
    @{ Keywords = @('abrir un pr', 'abrir un pull request', 'crear pr', 'open a pr', 'create pr', 'necesito abrir un pr'); Skill = 'branch-pr'; AgentCode = 'QA'; PlanMode = $false },

    # Session workflow
    @{ Keywords = @('iniciar sessao', 'iniciar sessão', 'iniciar sesion', 'iniciar sesión', 'start session'); Skill = 'session-workflow-skill'; AgentCode = 'SESSION'; PlanMode = $false },

    # OPS / docker-devops
    @{ Keywords = @('deploy', 'kubernetes', 'docker', 'helm', 'terraform', 'ci/cd'); Skill = 'docker-devops-skill'; AgentCode = 'OPS'; PlanMode = $false },

    # Reporting / dashboard
    @{ Keywords = @('dashboard', 'reporte', 'metrics', 'metricas', 'report', 'resumen ejecutivo'); Skill = 'reporting-skill'; AgentCode = 'DOC'; PlanMode = $false },

    # Bug fix (no PlanMode)
    @{ Keywords = @('fix bug', 'bug fix', 'error 401', 'bug'); Skill = 'sdd-lifecycle'; AgentCode = 'DEV'; PlanMode = $false },

    # New project/component (BA/PlanMode)
    @{ Keywords = @('nuevo proyecto', 'novo projeto', 'criar projeto', 'create project', 'new project', 'crear proyecto', 'empezar proyecto', 'iniciar proyecto', 'bootstrap project', 'scaffold project'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },

    @{ Keywords = @('crear componente', 'new component', 'nuevo componente', 'novo componente', 'criar componente', 'create component'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },

    @{ Keywords = @('nueva funcionalidad', 'nuevo modulo', 'nuevo módulo', 'new feature', 'new module', 'nueva feature', 'nova feature', 'novo recurso'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },

    @{ Keywords = @('feature request', 'add feature', 'add module', 'add component'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },

    # Implement / develop (PlanMode)
    @{ Keywords = @('implementar', 'desarrollar', 'construir', 'implement ', 'develop '); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },

    # Portuguese new project
    @{ Keywords = @('quero criar um novo projeto', 'criar um novo projeto', 'quero criar'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true }
)

$matched = $false
$matchedSkill = $null
$matchedAgent = $null
$matchedPlanMode = $false
$bestScore = 0

foreach ($rule in $rules) {
    foreach ($kw in $rule.Keywords) {
        if ($inputLower -match [regex]::Escape($kw.ToLower())) {
            $score = $kw.Length
            if ($score -gt $bestScore) {
                $bestScore = $score
                $matched = $true
                $matchedSkill = $rule.Skill
                $matchedAgent = $rule.AgentCode
                $matchedPlanMode = $rule.PlanMode
            }
        }
    }
}

# Fallback: ambiguity → BA PlanMode
if (-not $matched) {
    $matchedSkill = 'sdd-lifecycle'
    $matchedAgent = 'BA'
    $matchedPlanMode = $true
}

$summary = @{
    HasMatch = $matched
    Skill = $matchedSkill
    AgentCode = $matchedAgent
    PlanMode = $matchedPlanMode
    Confidence = $bestScore
    Input = $UserInput
}

Write-Output $summary
exit 0
