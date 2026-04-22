param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('discover', 'map', 'agents', 'validate', 'sync')]
    [string]$Action = 'discover',
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = '',
    
    [switch]$Force,
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$skillsPath = Join-Path $repoRoot 'skills'
$configPath = Join-Path $repoRoot 'config'

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

function Write-WarningLine {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[WARN] $Message" -ForegroundColor Yellow
    }
}

function Get-SkillMetadata {
    param([string]$SkillPath)
    
    $skillMd = Join-Path $SkillPath 'SKILL.md'
    if (-not (Test-Path $skillMd)) {
        return $null
    }
    
    $content = Get-Content -Path $skillMd -Raw -Encoding UTF8
    
    if ($content -match '(?m)^name:\s*(.+)$') { 
        $name = $matches[1].Trim() 
    } else { 
        $name = Split-Path $SkillPath -Leaf 
    }
    
    if ($content -match '(?s)description:\s*>(.+?)---') { 
        $description = $matches[1].Trim() -replace '\s+', ' ' 
    } elseif ($content -match '(?m)^description:\s*(.+)$') {
        $description = $matches[1].Trim()
    } else { 
        $description = $null 
    }
    
    if ($content -match '(?m)^Trigger:\s*(.+)$') { 
        $trigger = $matches[1].Trim() 
    } else { 
        $trigger = $null 
    }
    
    $hasAssets = Test-Path (Join-Path $SkillPath 'assets')
    $hasReferences = Test-Path (Join-Path $SkillPath 'references')
    
    $skillFiles = @()
    Get-ChildItem -Path $SkillPath -File -Recurse | ForEach-Object { 
        $skillFiles += $_.Name 
    }
    
    return @{
        name = $name
        path = $SkillPath
        description = $description
        trigger = $trigger
        has_assets = $hasAssets
        has_references = $hasReferences
        files = $skillFiles
    }
}

function Discover-AllSkills {
    $skills = @()
    
    if (-not (Test-Path $skillsPath)) {
        Write-WarningLine "Skills directory not found: $skillsPath"
        return $skills
    }
    
    $skillDirs = Get-ChildItem -Path $skillsPath -Directory | Where-Object { $_.Name -notmatch '^\.' }
    
    foreach ($dir in $skillDirs) {
        $metadata = Get-SkillMetadata -SkillPath $dir.FullName
        if ($metadata) {
            $skills += $metadata
        }
    }
    
    return $skills
}

function Get-AutoSkillMapping {
    param([array]$Skills)
    
    $AGENT_CATEGORIES = @{
        'BA'  = @('bdd', 'requirement', 'acceptance', 'scenario', 'gherkin', 'user story')
        'SAD' = @('architecture', 'api-design', 'database', 'relational', 'nosql', 'sdd', 'system design')
        'DEV' = @('angular', 'react', 'nextjs', 'frontend', 'backend', 'typescript', 'golang', 'django', 'component', 'implement')
        'QA'  = @('test', 'testing', 'playwright', 'pytest', 'e2e', 'unit test', 'validation', 'quality')
        'OPS' = @('docker', 'kubernetes', 'k8s', 'terraform', 'devops', 'deploy', 'ci-cd', 'infrastructure', 'helm')
        'GOV' = @('security', 'governance', 'observability', 'monitoring', 'audit', 'incident', 'compliance', 'review')
        'DOC' = @('documentation', 'readme', 'guide', 'runbook', 'spec', 'markdown', 'document')
    }
    
    $mapping = @{}
    
    foreach ($agent in $AGENT_CATEGORIES.Keys) {
        $mapping[$agent] = @{
            skills = @()
            keywords = $AGENT_CATEGORIES[$agent]
        }
    }
    
    foreach ($skill in $Skills) {
        $skillName = $skill.name
        $skillDesc = ($skill.description + ' ' + ($skill.trigger -join ' ')).ToLower()
        
        foreach ($agent in $AGENT_CATEGORIES.Keys) {
            $keywords = $AGENT_CATEGORIES[$agent]
            foreach ($keyword in $keywords) {
                if ($skillDesc -match $keyword -or $skillName -match $keyword) {
                    $mapping[$agent].skills += $skillName
                    break
                }
            }
        }
    }
    
    return $mapping
}

function Invoke-SkillsDiscover {
    $skills = Discover-AllSkills
    
    if ($AsJson) {
        $result = @{
            timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
            total_skills = $skills.Count
            skills = $skills
        }
        $result | ConvertTo-Json -Depth 4
        return
    }
    
    Write-Host "`n=== SKILLS AUTO-DISCOVERY ===" -ForegroundColor Cyan
    Write-Host "Found $($skills.Count) skills in $skillsPath" -ForegroundColor White
    Write-Host ""
    
    $withAssets = ($skills | Where-Object { $_.has_assets }).Count
    $withRefs = ($skills | Where-Object { $_.has_references }).Count
    
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  Total skills: $($skills.Count)"
    Write-Host "  With assets: $withAssets"
    Write-Host "  With references: $withRefs"
    Write-Host ""
    
    foreach ($skill in $skills | Sort-Object { $_.name }) {
        $status = if ($skill.trigger) { '[*]' } else { '[-]' }
        Write-Host "$status $($skill.name)" -ForegroundColor Green
        if ($skill.description) {
            $descLen = [Math]::Min(60, $skill.description.Length)
            Write-Host "       $($skill.description.Substring(0, $descLen))..." -ForegroundColor Gray
        }
    }
}

function Invoke-SkillsMap {
    $skills = Discover-AllSkills
    $mapping = Get-AutoSkillMapping -Skills $skills
    
    if ($AsJson) {
        $result = @{
            timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
            auto_generated = $true
            mapping = $mapping
            total_skills_mapped = ($mapping.Values | ForEach-Object { $_.skills.Count } | Measure-Object -Sum).Sum
        }
        $result | ConvertTo-Json -Depth 4
        return
    }
    
    Write-Host "`n=== AUTO SKILL MAPPING ===" -ForegroundColor Cyan
    Write-Host "Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    $totalMapped = 0
    foreach ($agent in ($mapping.Keys | Sort-Object)) {
        $agentSkills = $mapping[$agent].skills
        $totalMapped += $agentSkills.Count
        
        Write-Host "[$agent] Mapped skills ($($agentSkills.Count)):" -ForegroundColor Yellow
        foreach ($skillName in $agentSkills) {
            Write-Host "  - $skillName" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    Write-Host "Total mapped: $totalMapped / $($skills.Count)" -ForegroundColor White
    
    $unmapped = $skills | Where-Object { 
        $skillName = $_.name
        -not ($mapping.Values | Where-Object { $_.skills -contains $skillName })
    }
    
    if ($unmapped.Count -gt 0) {
        Write-WarningLine "Unmapped skills ($($unmapped.Count)):"
        foreach ($skill in $unmapped) {
            Write-Host "  - $($skill.name)" -ForegroundColor DarkGray
        }
    }
}

function Invoke-AgentsView {
    $skills = Discover-AllSkills
    $mapping = Get-AutoSkillMapping -Skills $skills
    
    Write-Host "`n=== AGENT SKILL ASSIGNMENTS ===" -ForegroundColor Cyan
    Write-Host ""
    
    $AGENT_ROLES = @{
        'BA'  = 'Business Analyst'
        'SAD' = 'Solution Architect'
        'DEV' = 'Developer'
        'QA'  = 'Quality Assurance'
        'OPS' = 'DevOps'
        'GOV' = 'Governance'
        'DOC' = 'Documentation'
    }
    
    foreach ($agent in ($mapping.Keys | Sort-Object)) {
        $agentSkills = $mapping[$agent].skills
        
        Write-Host "AGENT-$agent | $($AGENT_ROLES[$agent])" -ForegroundColor Yellow
        Write-Host "  Skills: $($agentSkills.Count)" -ForegroundColor White
        
        if ($agentSkills.Count -gt 0) {
            Write-Host "  $($agentSkills -join ', ')" -ForegroundColor Green
        } else {
            Write-Host "  (no skills mapped)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}

function Invoke-SkillsValidate {
    $skills = Discover-AllSkills
    
    Write-Host "`n=== SKILLS VALIDATION ===" -ForegroundColor Cyan
    Write-Host ""
    
    $issues = @()
    
    foreach ($skill in $skills) {
        if (-not $skill.name) {
            $issues += @{
                type = 'missing-name'
                path = $skill.path
                severity = 'error'
            }
        }
        
        if (-not $skill.description) {
            $issues += @{
                type = 'missing-description'
                path = $skill.name
                severity = 'warning'
            }
        }
        
        if (-not $skill.trigger) {
            $issues += @{
                type = 'missing-trigger'
                path = $skill.name
                severity = 'warning'
            }
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-SuccessLine "All $($skills.Count) skills passed validation"
    } else {
        $errors = @($issues | Where-Object { $_.severity -eq 'error' }).Count
        $warnings = @($issues | Where-Object { $_.severity -eq 'warning' }).Count
        
        Write-WarningLine "Validation found issues:"
        Write-Host "  Errors: $errors" -ForegroundColor Red
        Write-Host "  Warnings: $warnings" -ForegroundColor Yellow
        
        foreach ($issue in $issues) {
            $color = if ($issue.severity -eq 'error') { 'Red' } else { 'Yellow' }
            Write-Host "  [$($issue.severity.ToUpper())] $($issue.type): $($issue.path)" -ForegroundColor $color
        }
    }
}

switch ($Action) {
    'discover' { Invoke-SkillsDiscover }
    'map' { Invoke-SkillsMap }
    'agents' { Invoke-AgentsView }
    'validate' { Invoke-SkillsValidate }
    'sync' { 
        Invoke-SkillsMap
        Write-Host ""
        Write-InfoLine "Use 'wf skills sync' to update agent-router.ps1 with auto-detected mapping"
    }
}
