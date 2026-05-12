# skills-auto-discovery.ps1
# Auto-discover skills in skills/ directory and update auto-delegation.json
# FF-008: Skills Auto-Discovery implementation

param(
    [string]$SkillsPath = "skills",
    [string]$OutputConfig = "config/auto-delegation.json",
    [switch]$Update,
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
if ($env:FOUNDATION_BASE_DIR) {
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
$skillsFullPath = Join-Path $repoRoot $SkillsPath
$configFullPath = Join-Path $repoRoot $OutputConfig

function Write-InfoLine {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[INFO] $Message" -ForegroundColor Gray
    }
}

function Write-SuccessLine {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[OK] $Message" -ForegroundColor Green
    }
}

function Write-WarnLine {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Get-SkillMetadata {
    param([string]$SkillPath)
    
    $skillMdPath = Join-Path $skillPath 'SKILL.md'
    if (-not (Test-Path $skillMdPath)) {
        return $null
    }
    
    $content = Get-Content $skillMdPath -Raw -Encoding UTF8
    $skillName = Split-Path $skillPath -Leaf
    
    $metadata = @{
        name = $skillName
        path = $skillPath
        triggers = @()
        agent_mapping = $null
        description = ""
        available = $true
    }
    
    # Extract triggers from SKILL.md
    if ($content -match '(?i)trigger[s]?[:\s]+([^\n]+)') {
        $triggerText = $matches[1].Trim()
        $metadata.triggers = $triggerText -split ',' | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ }
    }
    
    # Extract description
    if ($content -match '(?s)^#\s*(.+?)\n(.*?)(?=\n#|\z)') {
        $metadata.description = $matches[2].Trim() -replace '\n', ' ' | ForEach-Object { $_.Substring(0, [Math]::Min(100, $_.Length)) }
    }
    
    return $metadata
}

function Get-AgentFromSkillName {
    param([string]$SkillName)
    
    $skillToAgent = @{
        'sdd-lifecycle' = 'BA'
        'bdd-scenarios-skill' = 'BA'
        'documentation-governance' = 'DOC'
        'code-review-orchestrator-skill' = 'QA'
        'testing-skill' = 'QA'
        'testing-strategy-skill' = 'QA'
        'playwright-skill' = 'QA'
        'pytest-skill' = 'QA'
        'go-testing' = 'QA'
        'docker-devops-skill' = 'OPS'
        'git-workflow-skill' = 'DEV'
        'architecture-governance' = 'SAD'
        'api-design-skill' = 'SAD'
        'database-relational-skill' = 'SAD'
        'database-nosql-skill' = 'SAD'
        'typescript-skill' = 'DEV'
        'golang-api-skill' = 'DEV'
        'angular-spa-skill' = 'DEV'
        'react-19-skill' = 'DEV'
        'nextjs-15-skill' = 'DEV'
        'tailwind-4-skill' = 'DEV'
        'zustand-5-skill' = 'DEV'
        'zod-4-skill' = 'DEV'
        'security-skill' = 'GOV'
        'judgment-day' = 'GOV'
        'project-orchestrator-skill' = 'GOV'
        'reporting-skill' = 'DOC'
        'script-governance-skill' = 'DEV'
        'release-management-skill' = 'OPS'
        'gitflow-orchestrator-skill' = 'GOV'
        'branch-pr' = 'QA'
        'karpathy-guidelines' = 'DEV'
        'auto-delegation-router' = 'GOV'
        'github-pr-skill' = 'QA'
        'mcp-skill' = 'GOV'
        'django-drf-skill' = 'DEV'
        'pretool-format-hook-skill' = 'DEV'
        '_semantic-skill-matcher' = 'GOV'
        'ai-sdk-5-skill' = 'DEV'
        'firecrawl-web-skill' = 'DEV'
        'distributed-tracing-skill' = 'GOV'
        'cloud-agent-connector-skill' = 'GOV'
        'context-engineering-skill' = 'GOV'
        'session-workflow-skill' = 'GOV'
        'shellcheck-standards-skill' = 'DEV'
        'script-runtime-engineering-skill' = 'DEV'
        'skill-creator-skill' = 'GOV'
        'skill-factory-skill' = 'GOV'
        'skill-registry' = 'GOV'
        'project-scaffolding-skill' = 'DEV'
        'gitflow-skill' = 'DEV'
        'commit-hygiene-skill' = 'DEV'
        'issue-creation' = 'QA'
        'chained-pr' = 'QA'
        'config-risk-analyzer' = 'GOV'
        'foundation-audit-skill' = 'GOV'
        'foundation-manager-skill' = 'GOV'
        'sync-automation' = 'GOV'
        'cross-workspace-sync' = 'GOV'
        'monitoring-aggregator' = 'GOV'
        'parallel-execution-limits' = 'GOV'
        'guardian-fallback-skill' = 'GOV'
        'technical-debt-skill' = 'QA'
        'testing-coverage-skill' = 'QA'
        'testing-evidence-qa' = 'QA'
        'security-pentester' = 'QA'
        'security-expert-skill' = 'GOV'
        'incident-response-skill' = 'GOV'
        'incident-response-plan' = 'GOV'
        'observability-skill' = 'GOV'
        'workflow-orchestrator' = 'GOV'
        'adaptive-orchestrator' = 'GOV'
        'adaptive-mode-orchestrator' = 'GOV'
        'backend-engineer' = 'DEV'
        'frontend-engineer' = 'DEV'
        'android-architecture-skill' = 'SAD'
        'android-kotlin-skill' = 'DEV'
        'android-kotlin-coroutines-skill' = 'DEV'
        'android-jetpack-compose-skill' = 'DEV'
        'ios-swiftui-patterns-skill' = 'DEV'
        'flutter-skill' = 'DEV'
        'react-native-skill' = 'DEV'
        'ui-mobile-skill' = 'DEV'
        'mobile-developer' = 'DEV'
        'mobile-app-debugging' = 'QA'
        'ios-swift-development' = 'DEV'
        'flutter-development' = 'DEV'
        'design-md' = 'SAD'
        'design-ui-designer' = 'SAD'
        'design-ux-researcher' = 'SAD'
        'brand-guide-skill' = 'DOC'
        'visual-content-skill' = 'DOC'
        'content-output-skill' = 'DOC'
        'content-strategist' = 'DOC'
        'marketing-content-writer' = 'DOC'
        'marketing-growth-hacker' = 'DOC'
        'seo-specialist' = 'DOC'
        'seo-audit-skill' = 'DOC'
        'terraform-infrastructure' = 'OPS'
        'kubernetes-deployment' = 'OPS'
        'devops-sre' = 'OPS'
        'web-artifacts-builder-skill' = 'DEV'
        'web-performance-optimization' = 'DEV'
        'game-designer' = 'SAD'
        'product-manager' = 'BA'
        'project-manager' = 'BA'
        'data-analyst' = 'SAD'
        'data-scientist' = 'SAD'
        'business-telemetry-skill' = 'GOV'
        'hr-talent-acquisition' = 'BA'
        'customer-success-manager' = 'BA'
        'customer-support-lead' = 'BA'
        'sales-account-executive' = 'BA'
        'sales-outbound-strategist' = 'BA'
        'operations-manager' = 'OPS'
        'finance-financial-analyst' = 'SAD'
        'legal-compliance-officer' = 'GOV'
        'backlog-management-skill' = 'BA'
        'multi-agent-registry' = 'GOV'
    }
    
    if ($skillToAgent.ContainsKey($SkillName)) {
        return $skillToAgent[$SkillName]
    }
    
    # Fallback: try to infer from skill name
    if ($SkillName -match 'orchestrator|governance|judgment|workflow|monitoring|observability|incident|security|compliance') { return 'GOV' }
    if ($SkillName -match 'test|playwright|pytest|quality|pentest|evidence|coverage|chained-pr|branch-pr|github-pr') { return 'QA' }
    if ($SkillName -match 'devops|docker|kubernetes|release|deploy|terraform|sre|operations') { return 'OPS' }
    if ($SkillName -match 'doc|readme|markdown|report|content|brand|seo|marketing|cognitive') { return 'DOC' }
    if ($SkillName -match 'arch|api|database|design|data-analyst|data-scientist|finance|game-designer') { return 'SAD' }
    if ($SkillName -match 'angular|react|next|vue|svelte|frontend|backend|ui|mobile|flutter|ios|android|kotlin|swift|typescript|golang|zod|zustand|tailwind|web-artifacts|web-performance|karpathy|script-runtime|git-workflow|gitflow|commit-hygiene|project-scaffolding|firecrawl|ai-sdk') { return 'DEV' }
    if ($SkillName -match 'bdd|scenario|requirement|sdd|product|project|backlog|hr|customer|sales|talent') { return 'BA' }
    
    return $null
}

function Get-DiscoveredSkills {
    param([string]$SkillsDir)
    
    if (-not (Test-Path $SkillsDir)) {
        Write-WarnLine "Skills directory not found: $SkillsDir"
        return @()
    }
    
    $skillDirs = Get-ChildItem -Path $SkillsDir -Directory -ErrorAction SilentlyContinue
    $discovered = @()
    
    foreach ($dir in $skillDirs) {
        $metadata = Get-SkillMetadata -SkillPath $dir.FullName
        if ($null -ne $metadata) {
            $agent = Get-AgentFromSkillName -SkillName $metadata.name
            $metadata.agent_mapping = $agent
            $discovered += $metadata
        }
    }
    
    return $discovered
}

function Update-AutoDelegationConfig {
    param(
        [string]$ConfigPath,
        [array]$DiscoveredSkills
    )
    
    if (-not (Test-Path $ConfigPath)) {
        Write-WarnLine "Config not found: $ConfigPath"
        return $false
    }
    
    $config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $updated = $false
    
    # Update agentCodeToSkill mapping
    if (-not $config.agentCodeToSkill) {
        $config | Add-Member -MemberType NoteProperty -Name "agentCodeToSkill" -Value @{} -Force
    }
    
    foreach ($skill in $DiscoveredSkills) {
        if ($skill.agent_mapping -and -not $config.agentCodeToSkill.$($skill.agent_mapping)) {
            $config.agentCodeToSkill.$($skill.agent_mapping) = $skill.name
            $updated = $true
            Write-SuccessLine "Added mapping: $($skill.agent_mapping) -> $($skill.name)"
        }
    }
    
    # Update keywordMappings
    if (-not $config.keywordMappings) {
        $config | Add-Member -MemberType NoteProperty -Name "keywordMappings" -Value @{} -Force
    }
    
    foreach ($skill in $DiscoveredSkills) {
        if ($skill.triggers.Count -gt 0 -and $skill.agent_mapping) {
            foreach ($trigger in $skill.triggers) {
                $found = $false
                foreach ($key in $config.keywordMappings.PSObject.Properties.Name) {
                    if ($config.keywordMappings.$key -contains $trigger) {
                        $found = $true
                        break
                    }
                }
                
                if (-not $found) {
                    if (-not $config.keywordMappings.$($skill.agent_mapping)) {
                        $config.keywordMappings | Add-Member -MemberType NoteProperty -Name $skill.agent_mapping -Value @() -Force
                    }
                    $config.keywordMappings.$($skill.agent_mapping) += $trigger
                    $updated = $true
                    Write-SuccessLine "Added trigger: $trigger -> $($skill.agent_mapping)"
                }
            }
        }
    }
    
    if ($updated) {
        $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
        Write-SuccessLine "Config updated: $ConfigPath"
    } else {
        Write-InfoLine "No updates needed"
    }
    
    return $updated
}

# Main execution
Write-InfoLine "Scanning skills directory: $skillsFullPath"
$discovered = Get-DiscoveredSkills -SkillsDir $skillsFullPath

if ($AsJson) {
    $discovered | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "`n=== SKILLS AUTO-DISCOVERY ===" -ForegroundColor Cyan
Write-Host ""

if ($discovered.Count -eq 0) {
    Write-WarnLine "No skills found in $skillsFullPath"
    exit 0
}

Write-Host "Discovered skills ($($discovered.Count)):" -ForegroundColor Green
foreach ($skill in $discovered) {
    $agent = if ($skill.agent_mapping) { $skill.agent_mapping } else { 'UNASSIGNED' }
    $color = if ($skill.agent_mapping) { 'White' } else { 'Yellow' }
    Write-Host "  [$($agent)] $($skill.name)" -ForegroundColor $color
    
    if ($skill.triggers.Count -gt 0) {
        Write-Host "       Triggers: $($skill.triggers -join ', ')" -ForegroundColor Gray
    }
    if ($skill.description) {
        Write-Host "       Desc: $($skill.description)" -ForegroundColor DarkGray
    }
}

Write-Host ""

if ($Update) {
    Write-InfoLine "Updating config: $configFullPath"
    Update-AutoDelegationConfig -ConfigPath $configFullPath -DiscoveredSkills $discovered
} else {
    Write-InfoLine "Dry run (use -Update to apply changes)"
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
exit 0
