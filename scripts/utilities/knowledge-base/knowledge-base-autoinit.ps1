param(
    [Parameter(Mandatory = $false)]
    [switch]$Quiet,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $dir
}

$ProjectRoot = Resolve-ProjectRoot
$VaultPath = Join-Path $ProjectRoot "knowledge-base"
$ConfigPath = Join-Path $ProjectRoot "config\knowledge-base-config.json"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Quiet) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Get-Config {
    if (Test-Path $ConfigPath) {
        return Get-Content $ConfigPath | ConvertFrom-Json
    }
    return $null
}

function Initialize-VaultIfNeeded {
    $config = Get-Config
    
    if (-not $config) {
        Write-Log "Config not found at $ConfigPath" "ERROR"
        return $false
    }
    
    $needsInit = $false
    
    if (-not (Test-Path $VaultPath)) {
        Write-Log "Vault root not found - creating..." "WARN"
        $needsInit = $true
    } elseif ($Force) {
        Write-Log "Force init requested" "INFO"
        $needsInit = $true
    }
    
    if ($needsInit) {
        New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
        
        foreach ($folder in $config.folders.PSObject.Properties.Value) {
            $folderPath = Join-Path $VaultPath $folder
            if (-not (Test-Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
                Write-Log "Created folder: $folder" "OK"
            }
        }
        
        $templatesFolder = Join-Path $VaultPath "06-templates"
        
        $templateProject = @"
---
created: {{date}}
tags: [project, #{{project-name}}]
status: active
---

# {{project-name}}

## Overview

**Description:** 
**Owner:** 
**Started:** {{date}}
**Priority:** 

## Goals

- [ ] 

## Tasks

- [ ] 

## Notes

## Links

- [[]] - 
- [[]] - 

## Metadata

```json
{
  "project": "{{project-name}}",
  "created": "{{date}}",
  "status": "active"
}
```
"@
        
        $templateSession = @"
---
created: {{date}}
tags: [session, #{{session-id}}]
---

# Session: {{session-id}}

**Date:** {{date}}
**Duration:** 
**Focus:** 

## Summary

## Accomplished

- 

## Next Steps

- 

## Decisions Made

- 

## Notes

## Related

- [[]] - 

## Metadata

```json
{
  "session_id": "{{session-id}}",
  "created": "{{date}}",
  "type": "session-summary"
}
```
"@
        
        $templateSkill = @"
---
created: {{date}}
tags: [skill, #{{skill-name}}]
skill_type: 
triggers: 
---

# Skill: {{skill-name}}

## Overview

**Type:** 
**Triggers:** 
**Agent:** 

## Description

## Implementation

### Files

- 

### Dependencies

- 

## Usage

## Related Skills

- [[]] - 

## Metadata

```json
{
  "skill_name": "{{skill-name}}",
  "created": "{{date}}",
  "type": "skill"
}
```
"@
        
        $templateDecision = @"
---
created: {{date}}
tags: [decision, #{{decision-id}}]
status: accepted|proposed|rejected|deprecated
---

# ADR: {{decision-title}}

**Status:** {{status}}
**Date:** {{date}}
**Owner:** 

## Summary

## Context

## Decision

## Consequences

### Positive

- 

### Negative

- 

## Alternatives Considered

- 

## Related Decisions

- [[]] - 

## Notes

## Metadata

```json
{
  "adr_id": "{{decision-id}}",
  "title": "{{decision-title}}",
  "status": "{{status}}",
  "created": "{{date}}"
}
```
"@
        
        $templates = @{
            "project" = $templateProject
            "session" = $templateSession
            "skill" = $templateSkill
            "decision" = $templateDecision
        }
        
        foreach ($templateName in $templates.Keys) {
            $templatePath = Join-Path $templatesFolder "$templateName.md"
            if (-not (Test-Path $templatePath)) {
                $templates[$templateName] | Set-Content -Path $templatePath -Encoding UTF8
                Write-Log "Created template: $templateName.md" "OK"
            }
        }
        
        $readmeContent = @"
# Knowledge Base - Gentle-Vanguard

This is the **Gentle-Vanguard Knowledge Base** vault managed via Obsidian.

## Structure

- `00-inbox/` - Unsorted notes
- `01-projects/` - Active projects
- `02-architecture/` - Architecture decisions
- `03-skills/` - Skill documentation
- `04-sessions/` - Session summaries
- `05-research/` - Research notes
- `06-templates/` - Note templates
- `07-archive/` - Archived content

## Usage

```powershell
# Create a new note
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action create-note -NoteType project -Title "My Project"

# List all notes
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action list

# Search notes
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action search -Query "keyword"

# Sync with Engram
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action sync-engram

# Get stats
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action stats
```

## Related

- [Architecture](docs\knowledge-base\ARCHITECTURE.md)
- [Usage Guide](docs\knowledge-base\USAGE.md)
"@
        
        $readmePath = Join-Path $VaultPath "README.md"
        if (-not (Test-Path $readmePath)) {
            $readmeContent | Set-Content -Path $readmePath -Encoding UTF8
            Write-Log "Created README.md" "OK"
        }
        
        Write-Log "Vault initialized successfully" "OK"
        return $true
    }
    
    $allFoldersExist = $true
    foreach ($folder in $config.folders.PSObject.Properties.Value) {
        $folderPath = Join-Path $VaultPath $folder
        if (-not (Test-Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            Write-Log "Created missing folder: $folder" "WARN"
            $allFoldersExist = $false
        }
    }
    
    if ($allFoldersExist) {
        Write-Log "Vault structure validated" "OK"
    }
    
    return $true
}

function Run-FullSync {
    $syncScript = Join-Path $ProjectRoot "scripts\utilities\knowledge-base\knowledge-base-sync.ps1"
    
    if (Test-Path $syncScript) {
        try {
            & $syncScript -Mode full -Quiet
            Write-Log "Full sync completed" "OK"
        } catch {
            Write-Log "Sync failed: $_" "ERROR"
            return $false
        }
    } else {
        Write-Log "Sync script not found: $syncScript" "ERROR"
        return $false
    }
    
    return $true
}

function Get-VaultStats {
    $notes = 0
    $size = 0
    
    if (Test-Path $VaultPath) {
        $mdFiles = Get-ChildItem -Path $VaultPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
        $notes = $mdFiles.Count
        $size = ($mdFiles | Measure-Object -Property Length -Sum).Sum
    }
    
    return @{
        notes = $notes
        size_kb = [math]::Round($size / 1KB, 2)
    }
}

Write-Log "=== Knowledge Base Auto-Init ===" "INFO"

$initResult = Initialize-VaultIfNeeded

if ($initResult) {
    $stats = Get-VaultStats
    Write-Log "Vault ready: $($stats.notes) notes, $($stats.size_kb) KB" "OK"
    
    $config = Get-Config
    if ($config.sync.enabled) {
        Write-Log "Running auto-sync..." "INFO"
        Run-FullSync
    }
} else {
    Write-Log "Vault initialization failed" "ERROR"
    exit 1
}

Write-Log "=== Knowledge Base Ready ===" "OK"