# create-skill.ps1
# Creates a new skill with standardized structure and validates naming conventions.
# Usage: .\create-skill.ps1 -Name "my-new-skill" -Description "Does something cool"

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Triggers = @(),
    
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$skillsDir = Join-Path $repoRoot 'skills'

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Err  { param([string]$m) Write-Host "[ERROR] $m" -ForegroundColor Red }

function Test-SkillExists {
    param([string]$SkillName)
    $skillPath = Join-Path $skillsDir $SkillName
    return Test-Path $skillPath
}

function New-SkillStructure {
    param([string]$SkillName, [string]$Desc, [string[]]$TriggerList)
    
    $skillPath = Join-Path $skillsDir $SkillName
    if (Test-Path $skillPath) {
        if (-not $Force) {
            Write-Err "Skill '$SkillName' already exists. Use -Force to overwrite."
            exit 1
        }
        Write-Step "Overwriting existing skill: $SkillName"
    } else {
        New-Item -ItemType Directory -Path $skillPath -Force | Out-Null
    }
    
    $triggerString = if ($TriggerList.Count -gt 0) { 
        $TriggerList | ForEach-Object { ""# create-skill.ps1
# Creates a new skill with standardized structure and validates naming conventions.
# Usage: .\create-skill.ps1 -Name "my-new-skill" -Description "Does something cool"

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Triggers = @(),
    
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$skillsDir = Join-Path $repoRoot 'skills'

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Err  { param([string]$m) Write-Host "[ERROR] $m" -ForegroundColor Red }

function Test-SkillExists {
    param([string]$SkillName)
    $skillPath = Join-Path $skillsDir $SkillName
    return Test-Path $skillPath
}

function New-SkillStructure {
    param([string]$SkillName, [string]$Desc, [string[]]$TriggerList)
    
    $skillPath = Join-Path $skillsDir $SkillName
    if (Test-Path $skillPath) {
        if (-not $Force) {
            Write-Err "Skill '$SkillName' already exists. Use -Force to overwrite."
            exit 1
        }
        Write-Step "Overwriting existing skill: $SkillName"
    } else {
        New-Item -ItemType Directory -Path $skillPath -Force | Out-Null
    }
    
    $triggerString = if ($TriggerList.Count -gt 0) { 
        $TriggerList | ForEach-Object { ""$_"" } | Join-String -Separator ', '
    } else { 
        ""$SkillName"" 
    }
    
    $template = @"
---
name: $SkillName
description: >
  $Desc.
  Trigger: $triggerString
---

## When to Use
[Describe when this skill should be activated]

## Core Rules
1. [Rule 1]
2. [Rule 2]

## Workflow
1. [Step 1]
2. [Step 2]

## Output Expectations
[What the user should see]
"@
    
    $template | Out-File -FilePath (Join-Path $skillPath 'SKILL.md') -Encoding UTF8BOM
    Write-Ok "Created SKILL.md at $skillPath"
}

Write-Step "Creating Skill: $Name"

if (Test-SkillExists -SkillName $Name) {
    Write-Step "Skill already exists"
    if (-not $Force) {
        Write-Err "Use -Force to overwrite."
        exit 1
    }
}

New-SkillStructure -SkillName $Name -Desc $Description -TriggerList $Triggers

Write-Ok "Skill '$Name' created successfully."
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit $(Join-Path $skillsDir $Name 'SKILL.md') to add details." -ForegroundColor Gray
Write-Host "2. Run '.\scripts\utilities\sync-agent-instructions.ps1' to update registries." -ForegroundColor Gray
" } | Join-String -Separator ', '
    } else { 
        ""$SkillName"" 
    }
    
    $template = @"
---
name: $SkillName
description: >
  $Desc.
  Trigger: $triggerString
---

## When to Use
[Describe when this skill should be activated]

## Core Rules
1. [Rule 1]
2. [Rule 2]

## Workflow
1. [Step 1]
2. [Step 2]

## Output Expectations
[What the user should see]
"@
    
    $template | Out-File -FilePath (Join-Path $skillPath 'SKILL.md') -Encoding UTF8BOM
    Write-Ok "Created SKILL.md at $skillPath"
}

Write-Step "Creating Skill: $Name"

if (Test-SkillExists -SkillName $Name) {
    Write-Step "Skill already exists"
    if (-not $Force) {
        Write-Err "Use -Force to overwrite."
        exit 1
    }
}

New-SkillStructure -SkillName $Name -Desc $Description -TriggerList $Triggers

Write-Ok "Skill '$Name' created successfully."
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit $(Join-Path $skillsDir $Name 'SKILL.md') to add details." -ForegroundColor Gray
Write-Host "2. Run '.\scripts\utilities\sync-agent-instructions.ps1' to update registries." -ForegroundColor Gray
