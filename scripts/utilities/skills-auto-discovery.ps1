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
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
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
    }
    
    if ($skillToAgent.ContainsKey($SkillName)) {
        return $skillToAgent[$SkillName]
    }
    
    # Fallback: try to infer from skill name
    if ($SkillName -match 'orchestrator|governance|judgment') { return 'GOV' }
    if ($SkillName -match 'test|playwright|pytest|quality') { return 'QA' }
    if ($SkillName -match 'devops|docker|kubernetes|release|deploy') { return 'OPS' }
    if ($SkillName -match 'doc|readme|markdown|report') { return 'DOC' }
    if ($SkillName -match 'arch|api|database|design') { return 'SAD' }
    if ($SkillName -match 'angular|react|next|vue|svelte|frontend|ui') { return 'DEV' }
    if ($SkillName -match 'bdd|scenario|requirement|sdd') { return 'BA' }
    
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
