# pre-process-input.ps1
# MANDATORY pre-processing hook - runs BEFORE any AI response

param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$SkillsPath = "skills",
    [string]$WorkspaceRoot = "."
)

$triggerMap = @{}
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir
$skillsFullPath = Join-Path $workspaceRoot $SkillsPath

# Source 1: SKILL.md files
$skillFiles = Get-ChildItem -Path $skillsFullPath -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $skillFiles) {
    $content = Get-Content $file.FullName -Raw
    $skillName = $file.Directory.Name
    
    # Extract frontmatter (between --- markers)
    $startMarker = $content.IndexOf("---")
    if ($startMarker -ge 0) {
        $secondMarker = $content.IndexOf("---", $startMarker + 3)
        if ($secondMarker -ge 0) {
            $frontMatter = $content.Substring($startMarker + 3, $secondMarker - $startMarker - 3)
            
            # Find trigger line (allowing leading whitespace)
            $lines = $frontMatter -split "`n"
            foreach ($line in $lines) {
                if ($line -match '\s*[Tt]rigger:\s*"([^"]+)"') {
                    $triggerText = $matches[1]
                    $triggers = $triggerText -split ',' | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_.Length -gt 0 }
                    
                    foreach ($trigger in $triggers) {
                        if ($trigger -and -not $triggerMap.ContainsKey($trigger)) {
                            $triggerMap[$trigger] = $skillName
                        }
                    }
                }
            }
        }
    }
}

# Source 2: auto-delegation.json (keyword mappings)
$autoDelegationConfig = Join-Path $workspaceRoot "config/auto-delegation.json"
if (Test-Path $autoDelegationConfig) {
    $config = Get-Content $autoDelegationConfig -Raw | ConvertFrom-Json
    if ($config.keywordMappings) {
        # Map keywords to their corresponding skills
        $skillMapping = @{
            "GOV" = "judgment-day"
            "SAD" = "sdd-design"
            "DEV" = "sdd-apply"
            "QA" = "sdd-verify"
            "OPS" = "docker-devops-skill"
            "DOC" = "documentation-governance"
            "SCRIPT-GOV" = "script-governance-skill"
            "REPORT" = "reporting-skill"
        }
        
        foreach ($agent in $config.keywordMappings.PSObject.Properties.Name) {
            $keywords = $config.keywordMappings.$agent
            $skillName = $skillMapping[$agent]
            if (-not $skillName) { $skillName = $agent.ToLower() }
            
            foreach ($keyword in $keywords) {
                if ($keyword -and -not $triggerMap.ContainsKey($keyword)) {
                    $triggerMap[$keyword] = $skillName
                }
            }
        }
    }
}

# Check user input against triggers
$inputLower = $UserInput.ToLower()
$matchingSkill = $null
$matchingTrigger = $null

$sortedTriggers = $triggerMap.Keys | Sort-Object Length -Descending

foreach ($trigger in $sortedTriggers) {
    if ($inputLower.Contains($trigger.ToLower())) {
        $matchingSkill = $triggerMap[$trigger]
        $matchingTrigger = $trigger
        break
    }
}

if ($matchingSkill) {
    Write-Output "TRIGGER_MATCH_FOUND"
    Write-Output "SKILL: $matchingSkill"
    Write-Output "TRIGGER_MATCHED: $matchingTrigger"
    Write-Output "ACTION: Load skill '$matchingSkill' using skill tool"
} else {
    Write-Output "NO_TRIGGER_MATCH"
    Write-Output "ACTION: Continue with normal behavior"
}

return @{
    HasMatch = ($matchingSkill -ne $null)
    Skill = $matchingSkill
    Trigger = $matchingTrigger
}
