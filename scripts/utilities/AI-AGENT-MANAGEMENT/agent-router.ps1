param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC', 'MKT', 'SALES', 'FINANCE', 'HR', 'LEGAL', 'BUS-TELE', 'SESSION', 'PREMORTEM', 'status', 'list')]
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
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$skillsPath = Join-Path $repoRoot 'skills'
$userSkillsPath = 'C:\Users\emman\.claude\skills'
$modelRouterPath = Join-Path $repoRoot 'config\model-router.json'
$autoDelegationPath = Join-Path $repoRoot 'config\auto-delegation.json'

function Get-AgentModelConfig {
    param([string]$AgentName)
    $info = @{ model = $null; temperature = $null; provider = $null; subagent = $null; fallback = $null; rationale = $null; source = 'none' }
    if (Test-Path $modelRouterPath) {
        try {
            $mr = Get-Content $modelRouterPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($mr.enabled -and $mr.agentBindings.$AgentName) {
                $b = $mr.agentBindings.$AgentName
                $info.model = if ($b.model) { $b.model } else { $mr.defaults.model }
                $info.temperature = if ($b.temperature -ne $null) { [double]$b.temperature } else { [double]$mr.defaults.temperature }
                $info.provider = if ($b.provider) { $b.provider } else { $mr.defaults.provider }
                $info.subagent = $b.subagent
                $info.rationale = $b.rationale
                $info.fallback = if ($mr.fallback) { $mr.fallback.model } else { $null }
                $info.source = 'model-router'
            } elseif ($mr.fallback) {
                # Agent not in bindings — use defaults + fallback
                $info.model = $mr.defaults.model
                $info.temperature = [double]$mr.defaults.temperature
                $info.provider = $mr.defaults.provider
                $info.fallback = $mr.fallback.model
                $info.source = 'defaults'
            }
        } catch {}
    }
    if ($info.source -eq 'none' -and (Test-Path $autoDelegationPath)) {
        try {
            $ad = Get-Content $autoDelegationPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $profile = $ad.agentProfiles.$AgentName
            if ($profile -and $profile.temperature -ne $null) {
                $info.temperature = [double]$profile.temperature
                $info.source = 'auto-delegation'
            }
        } catch {}
    }
    return $info
}

function Write-AgentLine {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

$AGENT_SKILLS = @{
    'BA'  = @('bdd-scenarios-skill', 'documentation-governance')
    'SAD' = @('architecture-governance', 'api-design-skill', 'database-relational-skill', 'database-nosql-skill', 'typescript-skill', 'golang-api-skill', 'sdd-lifecycle')
    'DEV' = @('angular-spa-skill', 'react-19-skill', 'nextjs-15-skill', 'tailwind-4-skill', 'zustand-5-skill', 'zod-4-skill', 'security-skill', 'technical-debt-skill', 'typescript-skill', 'work-unit-commits')
    'QA'  = @('testing-strategy-skill', 'testing-skill', 'playwright-skill', 'pytest-skill')
    'OPS' = @('docker-devops-skill', 'kubernetes-deployment', 'terraform-infrastructure', 'git-workflow-skill', 'release-management-skill')
    'GOV' = @('observability-skill', 'incident-response-plan', 'security-skill', 'code-review-orchestrator-skill', 'comment-writer')
    'DOC' = @('documentation-governance', 'sdd-lifecycle', 'bdd-scenarios-skill', 'github-pr-skill')
    'MKT' = @('marketing-content-writer', 'marketing-growth-hacker', 'seo-audit-skill')
    'SALES' = @('sales-account-executive', 'sales-outbound-strategist')
    'FINANCE' = @('finance-financial-analyst')
    'HR' = @('hr-talent-acquisition')
    'LEGAL' = @('legal-compliance-officer')
    'BUS-TELE' = @('business-telemetry-skill')
    'SESSION' = @('session-workflow-skill', 'project-orchestrator-skill')
    'PREMORTEM' = @('premortem-skill')
}

$AGENT_DESCRIPTIONS = @{
    'BA'  = 'Business Analyst - Requirements, BDD, Acceptance Criteria'
    'SAD' = 'Solution Architect - Architecture, SDD, Technical Decisions'
    'DEV' = 'Developer - Implementation, Features, Refactoring'
    'QA'  = 'Quality Assurance - Testing, Validation, Test Automation'
    'OPS' = 'DevOps - Deployment, CI/CD, Infrastructure'
    'GOV' = 'Governance - Compliance, Observability, Security Audits'
    'DOC' = 'Documentation - BDD/SDD Specs, Guides, README'
    'MKT' = 'Marketing - Content Writing, Growth Hacking, SEO'
    'SALES' = 'Sales - Enterprise Sales, Outbound, Pipeline'
    'FINANCE' = 'Finance - Financial Analysis, Budgeting, Forecasting'
    'HR' = 'HR - Talent Acquisition, Recruiting'
    'LEGAL' = 'Legal - Compliance, Regulatory, Privacy'
    'BUS-TELE' = 'Business Telemetry - Metrics, Reporting, Analytics'
    'SESSION' = 'Session Manager - Session lifecycle, state tracking, git verification'
    'PREMORTEM' = 'Premortem Analyst - Risk analysis, failure scenarios, adversarial review'
}

$AGENT_DELIVERABLES = @{
    'BA'  = @('bdd-scenarios', 'acceptance-criteria', 'user-stories', 'requirements-traceability')
    'SAD' = @('sdd-documents', 'architecture-decisions', 'api-contracts', 'database-designs')
    'DEV' = @('source-code', 'refactoring', 'technical-debt-records', 'security-hardening')
    'QA'  = @('test-files', 'e2e-scenarios', 'coverage-reports', 'validation-evidence')
    'OPS' = @('docker-configs', 'k8s-manifests', 'cicd-pipelines', 'deployment-runbooks')
    'GOV' = @('audit-reports', 'compliance-docs', 'incident-runbooks', 'monitoring-dashboards')
    'DOC' = @('readme-files', 'api-docs', 'runbooks', 'bdd-sdd-specs')
    'MKT' = @('blog-posts', 'landing-pages', 'email-campaigns', 'growth-experiments', 'seo-audits')
    'SALES' = @('account-plans', 'deal-proposals', 'pipeline-reports', 'outreach-sequences')
    'FINANCE' = @('financial-models', 'variance-reports', 'budget-analysis', 'roi-calculations')
    'HR' = @('job-descriptions', 'interview-rubrics', 'offer-letters', 'onboarding-plans')
    'LEGAL' = @('privacy-policies', 'compliance-checklists', 'dpias', 'audit-evidence')
    'BUS-TELE' = @('telemetry-reports', 'efficiency-scores', 'management-summaries')
    'SESSION' = @('session-audit', 'state-report', 'git-status', 'continuity-context')
    'PREMORTEM' = @('premortem-report', 'risk-register', 'blind-spot-analysis', 'failure-scenarios')
}

function Get-AgentSkills {
    param([string]$AgentName)
    
    $skills = $AGENT_SKILLS[$AgentName]
    $skillFiles = @()
    
    foreach ($skill in $skills) {
        $skillDir = Join-Path $skillsPath $skill
        $skillMd = Join-Path $skillDir 'SKILL.md'
        $userSkillDir = Join-Path $userSkillsPath $skill
        $userSkillMd = Join-Path $userSkillDir 'SKILL.md'
        if ((Test-Path $skillMd) -or (Test-Path $userSkillMd)) {
            $skillFiles += @{
                name = $skill
                path = if (Test-Path $skillMd) { $skillMd } else { $userSkillMd }
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

function Get-SkillSummary {
    param([hashtable]$SkillEntry, [int]$MaxLines = 40)
    # Read first MaxLines of SKILL.md to extract key rules/patterns without loading full file
    if (-not $SkillEntry.available) { return '' }
    try {
        $lines = Get-Content -Path $SkillEntry.path -TotalCount $MaxLines -Encoding UTF8 -ErrorAction Stop
        return ($lines -join "`n").Trim()
    } catch { return '' }
}

function Build-ExecutionContext {
    param(
        [string]$AgentName,
        [string]$Role,
        [string]$TaskText,
        [string]$ActionType,
        [array]$AvailableSkills,
        [array]$Deliverables
    )

    $skillSections = foreach ($skill in $AvailableSkills) {
        $summary = Get-SkillSummary -SkillEntry $skill -MaxLines 30
        if ($summary) {
            "### SKILL: $($skill.name)`n$summary"
        }
    }

    $deliverableList = ($Deliverables | ForEach-Object { "- $_" }) -join "`n"

    $prompt = @"
## AGENT: $AgentName — $Role
## ACTION: $ActionType
## TASK: $TaskText

### Expected deliverables
$deliverableList

### Loaded skill guidance
$($skillSections -join "`n`n")

### Execution instructions
1. Apply skill patterns above to complete the task.
2. Produce only the deliverables listed. Do not add unrequested work.
3. Follow security and code-quality standards from the loaded skills.
4. On completion set completion_signal.finished = true and list files_touched.
"@

    return @{
        prompt          = $prompt.Trim()
        skills_included = @($AvailableSkills | ForEach-Object { $_.name })
        char_count      = $prompt.Length
        token_estimate  = [math]::Ceiling($prompt.Length / 4)
    }
}

function Get-AgentResult {
    param(
        [string]$AgentName,
        [string]$TaskText,
        [string]$ActionType
    )
    
    $skills = Get-AgentSkills -AgentName $AgentName
    $availableSkills = $skills | Where-Object { $_.available }
    $missingSkills = $skills | Where-Object { -not $_.available }
    $deliverables = $AGENT_DELIVERABLES[$AgentName]
    
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'

    # Build real execution context from loaded skill files
    $execCtx = $null
    if ($availableSkills.Count -gt 0) {
        $execCtx = Build-ExecutionContext `
            -AgentName $AgentName `
            -Role $AGENT_DESCRIPTIONS[$AgentName] `
            -TaskText $TaskText `
            -ActionType $ActionType `
            -AvailableSkills @($availableSkills) `
            -Deliverables $deliverables
    }

    $modelInfo = Get-AgentModelConfig -AgentName $AgentName
    $baseTokenEstimate = if ($execCtx) { $execCtx.token_estimate + 500 } else { 2000 }

    $result = @{
        agent_id = $AgentName
        agent_name = $AGENT_DESCRIPTIONS[$AgentName]
        status = 'dispatched'
        task = $TaskText
        action = $ActionType
        timestamp = $timestamp
        duration_ms = 0
        model_info = $modelInfo
        skills_loaded = @($availableSkills | ForEach-Object { $_.name })
        skills_missing = @($missingSkills | ForEach-Object { $_.name })
        deliverables_expected = $deliverables
        deliverables = @()
        files_touched = @()
        findings = @()
        validation_result = $null
        next_action = $null
        token_estimate = $null
        execution_context = $execCtx
        completion_signal = @{
            finished = $false
            message = "Agent $AgentName ready. Use execution_context.prompt to delegate to AI backend."
            continuity_instruction = "Maintain current session context, rules, and definitions. Do not deviate from established workflow."
            required_skills_enforced = @($availableSkills | ForEach-Object { $_.name })
        }
        metrics = @{
            tokens_used = 0
            files_touched = 0
            lines_added = 0
            lines_deleted = 0
        }
        issues = @()
        next_steps = @()
        confidence = 0
        summary = ""
        details = ""
    }
    
    if ($result.skills_missing.Count -eq 0) {
        $result.status = 'ready'
        $result.token_estimate = $baseTokenEstimate
        $result.completion_signal.message = "Agent $AgentName ready with full skill coverage. Execution context built — delegate prompt to AI backend."
    } elseif ($result.skills_missing.Count -lt $availableSkills.Count) {
        $result.status = 'partial'
        $result.token_estimate = $baseTokenEstimate
        $result.completion_signal.message = "Agent $AgentName partially ready ($($missingSkills.Count) skills missing). Execution context built from available skills."
    } else {
        $result.status = 'blocked'
        $result.token_estimate = 500
        $result.validation_result = @{
            passed = $false
            reason = 'All required skills missing'
        }
    }
    
    return $result
}

function Invoke-Agent {
    param(
        [string]$AgentName,
        [string]$TaskText,
        [string]$ActionType
    )
    
    $result = Get-AgentResult -AgentName $AgentName -TaskText $TaskText -ActionType $ActionType
    
    if ($AsJson) {
        $result | ConvertTo-Json -Depth 5
        return
    }
    
    Write-AgentLine "`n=== AGENT-$AgentName ===" 'Cyan'
    Write-AgentLine "Role: $($result.role)" 'White'
    Write-AgentLine "Task: $($result.task)" 'Gray'
    Write-AgentLine "Action: $($result.action)" 'Gray'
    Write-AgentLine "Status: $($result.status)" -Color $(if ($result.status -eq 'ready') { 'Green' } elseif ($result.status -eq 'blocked') { 'Red' } else { 'Yellow' })
    Write-AgentLine ""
    
    if ($result.skills_loaded.Count -gt 0) {
        Write-AgentLine "Skills loaded ($($result.skills_loaded.Count)):" 'Green'
        foreach ($skill in $result.skills_loaded) {
            Write-Host "  [OK] $skill" -ForegroundColor Green
        }
    }
    
    if ($result.skills_missing.Count -gt 0) {
        Write-AgentLine "`nSkills missing ($($result.skills_missing.Count)):" 'Yellow'
        foreach ($skill in $result.skills_missing) {
            Write-Host "  [--] $skill" -ForegroundColor Yellow
        }
    }
    
    Write-AgentLine "`nExpected deliverables:" 'Cyan'
    foreach ($deliverable in $result.deliverables_expected) {
        Write-Host "  - $deliverable" -ForegroundColor Gray
    }
    
    if ($result.token_estimate) {
        Write-AgentLine "`nToken estimate: ~$($result.token_estimate) chars" 'DarkGray'
    }
    
    Write-AgentLine "`n--- Ready to execute ---" 'Cyan'
    Write-Host "The orchestrator will now delegate to AGENT-$AgentName for:" -ForegroundColor White
    Write-Host "  $($result.task)" -ForegroundColor Gray
    Write-Host ""
}

function Show-AgentStatus {
    param([string]$AgentName)
    
    $skills = Get-AgentSkills -AgentName $AgentName
    $available = ($skills | Where-Object { $_.available }).Count
    $total = $skills.Count
    $deliverables = $AGENT_DELIVERABLES[$AgentName]
    
    return @{
        agent = $AgentName
        role = $AGENT_DESCRIPTIONS[$AgentName]
        skills_available = $available
        skills_total = $total
        readiness = if ($available -eq $total) { 'READY' } elseif ($available -gt 0) { 'PARTIAL' } else { 'UNAVAILABLE' }
        skills = $skills
        deliverables = $deliverables
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
            Write-Host "       Deliverables: $($result.deliverables -join ', ')" -ForegroundColor DarkGray
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
    Write-Host "Usage: .\wf.ps1 agent <AGENT> [TASK] [-AsJson]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Agents: BA, SAD, DEV, QA, OPS, GOV, DOC, MKT, SALES, FINANCE, HR, LEGAL, BUS-TELE, SESSION, PREMORTEM" -ForegroundColor White
    Write-Host "Actions: run, plan, validate, status" -ForegroundColor White
    Write-Host "Flags: -AsJson for structured output" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\wf.ps1 agent list" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 agent status" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 agent DEV `"implement login`"" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 agent QA `"validate checkout`" -AsJson" -ForegroundColor Gray
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Task)) {
    Write-AgentLine "Task parameter is required when specifying an agent." 'Yellow'
    Write-Host "Use: .\wf.ps1 agent $Agent `"<task description>`"" -ForegroundColor Gray
    exit 1
}

$validAgents = @('BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC', 'MKT', 'SALES', 'FINANCE', 'HR', 'LEGAL', 'BUS-TELE', 'SESSION', 'PREMORTEM')
if ($validAgents -notcontains $Agent) {
    Write-AgentLine "Unknown agent: $Agent" 'Red'
    Write-Host "Valid agents: $($validAgents -join ', ')" -ForegroundColor Gray
    exit 1
}

Invoke-Agent -AgentName $Agent -TaskText $Task -ActionType $Action
