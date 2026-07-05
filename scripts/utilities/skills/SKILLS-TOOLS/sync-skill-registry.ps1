<#
.SYNOPSIS
    Synchronizes skill directories with skill-registry.md
.DESCRIPTION
    Scans skills/ directory and updates .atl/skill-registry.md
    to ensure all skills are properly registered.
.PARAMETER DryRun
    Show changes without applying them
.PARAMETER ValidateOnly
    Only validate, exit with error if out of sync
.EXAMPLE
    .\sync-skill-registry.ps1
    .\sync-skill-registry.ps1 -DryRun
    .\sync-skill-registry.ps1 -ValidateOnly
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Level, [string]$Message)
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Resolve paths
$script:ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$script:SkillsDir = Join-Path $ProjectRoot "skills"
$script:RegistryPath = Join-Path (Join-Path $ProjectRoot ".atl") "skill-registry.md"

Write-Log "INFO" "Skill Registry Sync Tool"
Write-Log "INFO" "Project: $ProjectRoot"

# Ensure .atl directory exists
$atlDir = Join-Path $ProjectRoot ".atl"
if (-not (Test-Path $atlDir)) {
    New-Item -ItemType Directory -Path $atlDir -Force | Out-Null
}

# Scan skill directories
Write-Log "INFO" "Scanning skills directory..."
$discoveredSkills = @()

if (Test-Path $SkillsDir) {
    $skillDirs = Get-ChildItem -Path $SkillsDir -Directory -ErrorAction SilentlyContinue
    
    foreach ($dir in $skillDirs) {
        $skillMdPath = Join-Path $dir.FullName "SKILL.md"
        
        if (Test-Path $skillMdPath) {
            try {
                $content = Get-Content $skillMdPath -Raw -ErrorAction SilentlyContinue
                
                # Parse frontmatter
                $name = $dir.Name
                $agent = "DEV"  # Default agent
                $description = ""
                $triggers = @()
                
                if ($content -match "^---") {
                    $end = $content.IndexOf("---", 3)
                    if ($end -gt 0) {
                        $fm = $content.Substring(3, $end - 3).Trim()
                        
                        $nameMatch = $fm | Select-String -Pattern "^name:\s*(.+)$" -AllMatches
                        if ($nameMatch.Matches.Count -gt 0) {
                            $name = $nameMatch.Matches[0].Groups[1].Value.Trim()
                        }
                        
                        $descMatch = $fm | Select-String -Pattern "^description:\s*(.+)$" -AllMatches
                        if ($descMatch.Matches.Count -gt 0) {
                            $description = $descMatch.Matches[0].Groups[1].Value.Trim()
                        }
                    }
                }
                
                # Extract triggers from content
                $triggerMatches = $content | Select-String -Pattern "trigger[s]?:\s*[`"']([^`"']+)[`"']" -AllMatches
                if ($triggerMatches.Matches.Count -gt 0) {
                    $triggers = $triggerMatches.Matches | ForEach-Object { $_.Groups[1].Value }
                }
                
                $discoveredSkills += [PSCustomObject]@{
                    Name = $name
                    Agent = $agent
                    Description = $description
                    Triggers = $triggers -join ", "
                    Path = $dir.FullName
                    HasSkillMd = $true
                }
            } catch {
                Write-Log "WARN" "Failed to parse $($dir.Name): $_"
            }
        } else {
            $discoveredSkills += [PSCustomObject]@{
                Name = $dir.Name
                Agent = "UNKNOWN"
                Description = ""
                Triggers = ""
                Path = $dir.FullName
                HasSkillMd = $false
            }
        }
    }
}

Write-Log "INFO" "Found $($discoveredSkills.Count) skill directories"

# Parse existing registry
$existingSkills = @{}
if (Test-Path $RegistryPath) {
    $registryContent = Get-Content $RegistryPath -Raw -ErrorAction SilentlyContinue
    
    # Find table section
    $inTable = $false
    $lines = $registryContent -split "`n"
    
    foreach ($line in $lines) {
        if ($line -match "^\|.*Agent.*Skill.*Trigger") {
            $inTable = $true
            continue
        }
        if ($inTable -and $line -match "^\|([^|]+)\|([^|]+)\|([^|]+)") {
            $agent = $Matches[1].Trim()
            $name = $Matches[2].Trim()
            $triggers = $Matches[3].Trim()
            
            if ($name -and $name -ne "Skill") {
                $existingSkills[$name] = @{
                    Agent = $agent
                    Triggers = $triggers
                }
            }
        }
    }
}

Write-Log "INFO" "Found $($existingSkills.Count) skills in registry"

# Compare and identify changes
$missingInRegistry = $discoveredSkills | Where-Object { -not $existingSkills.ContainsKey($_.Name) }
$extraInRegistry = $existingSkills.Keys | Where-Object { 
    $key = $_
    -not ($discoveredSkills | Where-Object { $_.Name -eq $key })
}

Write-Log "INFO" "Missing in registry: $($missingInRegistry.Count)"
Write-Log "INFO" "Extra in registry: $($extraInRegistry.Count)"

if ($ValidateOnly) {
    if ($missingInRegistry.Count -gt 0 -or $extraInRegistry.Count -gt 0) {
        Write-Log "ERROR" "Registry is out of sync!"
        exit 1
    } else {
        Write-Log "SUCCESS" "Registry is in sync"
        exit 0
    }
}

# Generate updated registry
if ($DryRun) {
    Write-Log "INFO" "[DRY-RUN] Would update registry with:"
    foreach ($skill in $missingInRegistry) {
        Write-Host "  + $($skill.Name) ($($skill.Agent))"
    }
    foreach ($name in $extraInRegistry) {
        Write-Host "  - $name"
    }
} else {
    # Build new registry content
    $registryLines = @(
        "# Skill Registry",
        "",
        "| Agent | Skill | Triggers |",
        "|-------|-------|----------|"
    )
    
    foreach ($skill in ($discoveredSkills | Sort-Object Name)) {
        $triggersStr = if ($skill.Triggers) { "`"$($skill.Triggers)`"" } else { "" }
        $registryLines += "| $($skill.Agent) | $($skill.Name) | $triggersStr |"
    }
    
    $registryContent = $registryLines -join "`n"
    $registryContent | Set-Content -Path $RegistryPath -Encoding UTF8
    
    Write-Log "SUCCESS" "Registry updated: $($discoveredSkills.Count) skills"
}

# Summary
Write-Log "INFO" "=== Summary ==="
Write-Log "INFO" "Total skills discovered: $($discoveredSkills.Count)"
Write-Log "INFO" "Skills in registry: $($existingSkills.Count)"
Write-Log "INFO" "Missing: $($missingInRegistry.Count)"
Write-Log "INFO" "Extra: $($extraInRegistry.Count)"
