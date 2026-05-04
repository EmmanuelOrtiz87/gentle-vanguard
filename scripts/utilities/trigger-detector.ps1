# trigger-detector.ps1
# Automatic skill trigger detection from user input
# This script extracts triggers from all SKILL.md files and matches against user input

param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    
    [string]$SkillsPath = "skills",
    
    [switch]$Verbose
)

# Load all skill triggers from SKILL.md files
function Get-SkillTriggers {
    param([string]$SkillsPath)
    
    $triggers = @()
    $skillFiles = Get-ChildItem -Path $SkillsPath -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $skillFiles) {
        $content = Get-Content $file.FullName -Raw
        $skillName = $file.Directory.Name
        
        # Extract trigger from frontmatter or content
        if ($content -match '(?s)Trigger:\s*"([^"]+)"') {
            $triggerText = $matches[1]
        } elseif ($content -match '(?s)Trigger:\s*([^\n]+)') {
            $triggerText = $matches[1]
        } else {
            continue
        }
        
        # Parse trigger phrases (comma-separated, quoted, or pipe-separated)
        $triggerList = @()
        if ($triggerText -match '"[^"]*"') {
            $triggerList = [regex]::Matches($triggerText, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value.Trim() }
        } elseif ($triggerText -match '\|') {
            $triggerList = $triggerText -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        } else {
            $triggerList = $triggerText -split ',' | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_ }
        }
        
        foreach ($trigger in $triggerList) {
            if ($trigger) {
                $triggers += [PSCustomObject]@{
                    Skill = $skillName
                    Trigger = $trigger
                    File = $file.FullName
                }
            }
        }
    }
    
    return $triggers
}

# Match user input against triggers
function Find-MatchingSkills {
    param(
        [string]$UserInput,
        [array]$Triggers
    )
    
    $inputLower = $UserInput.ToLower()
    $matches = @()
    
    foreach ($trigger in $Triggers) {
        $triggerPattern = $trigger.Trigger.ToLower()
        
        # Check if trigger is in user input
        if ($inputLower -match [regex]::Escape($triggerPattern)) {
            $matches += $trigger
        }
    }
    
    return $matches
}

# Main execution
$allTriggers = Get-SkillTriggers -SkillsPath $SkillsPath
$matchingSkills = Find-MatchingSkills -UserInput $UserInput -Triggers $allTriggers

if ($Verbose) {
    Write-Host "Total triggers loaded: $($allTriggers.Count)" -ForegroundColor Gray
    Write-Host "User input: $UserInput" -ForegroundColor Cyan
    Write-Host "Matching skills: $($matchingSkills.Count)" -ForegroundColor Green
}

if ($matchingSkills.Count -gt 0) {
    Write-Output "MATCHES_FOUND"
    foreach ($match in $matchingSkills) {
        Write-Output "SKILL: $($match.Skill)"
        Write-Output "TRIGGER: $($match.Trigger)"
        Write-Output "FILE: $($match.File)"
        Write-Output "---"
    }
} else {
    Write-Output "NO_MATCHES"
}

return $matchingSkills
