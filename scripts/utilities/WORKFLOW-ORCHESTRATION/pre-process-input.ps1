<#
.SYNOPSIS
Pre-processing hook for Foundation workflow - validates input and loads skills

.DESCRIPTION
This hook runs BEFORE any AI response to:
- Validate user input format and content
- Detect skill triggers in the input
- Load appropriate skills based on triggers
- Prepare context for the AI agent

.PARAMETER UserInput
The raw user input to process

.PARAMETER WorkspaceRoot
Root directory of the workspace

.PARAMETER SkillRegistry
Path to the skill registry configuration

.EXAMPLE
.\pre-process-input.ps1 -UserInput "implement login feature" -WorkspaceRoot "." -SkillRegistry "config/skill-registry.json"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$UserInput,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkspaceRoot = ".",
    
    [Parameter(Mandatory = $false)]
    [string]$SkillRegistry = "config/skill-registry.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = ".session/logs/pre-process-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path (Split-Path $logFile)) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

Write-Log "Starting pre-process hook for input: $($UserInput.Substring(0, [Math]::Min(50, $UserInput.Length)))..."

try {
    # Validate input
    if ([string]::IsNullOrWhiteSpace($UserInput)) {
        Write-Log "Empty input detected" "WARN"
        Write-Output "NO_TRIGGER_MATCH"
        exit 0
    }

    # Load skill registry if it exists
    $skillTriggers = @{}
    if (Test-Path $SkillRegistry) {
        try {
            $registry = Get-Content $SkillRegistry -Raw | ConvertFrom-Json
            if ($registry.skills) {
                foreach ($skill in $registry.skills) {
                    if ($skill.triggers) {
                        foreach ($trigger in $skill.triggers) {
                            $skillTriggers[$trigger] = $skill.name
                        }
                    }
                }
            }
            Write-Log "Loaded $($skillTriggers.Count) skill triggers from registry"
        }
        catch {
            Write-Log "Error loading skill registry: $_" "WARN"
        }
    }

    # Check for skill triggers
    $matchedSkill = $null
    foreach ($trigger in $skillTriggers.Keys) {
        if ($UserInput -match $trigger) {
            $matchedSkill = $skillTriggers[$trigger]
            Write-Log "Matched skill trigger: $trigger -> $matchedSkill"
            break
        }
    }

    # Output result
    if ($matchedSkill) {
        Write-Log "Skill loaded: $matchedSkill" "SUCCESS"
        Write-Output "TRIGGER_MATCH_FOUND"
        Write-Output "SKILL_LOADED:$matchedSkill"
    }
    else {
        Write-Log "No skill trigger matched"
        Write-Output "NO_TRIGGER_MATCH"
    }

    exit 0
}
catch {
    Write-Log "Error in pre-process hook: $_" "ERROR"
    Write-Output "NO_TRIGGER_MATCH"
    exit 0
}