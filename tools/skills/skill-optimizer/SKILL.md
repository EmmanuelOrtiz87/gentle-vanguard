---
name: skill-optimizer
description: >
  Technical skill analyzer and optimizer - reviews, improves, and maintains all skills
  in the workspace. Only accessible to workspace owner. Provides auto-maintenance,
  quality assurance, and escalation workflow for developer requests.
owner_only: true
triggers:
  - "optimizar skills"
  - "improve skills"
  - "skill audit"
  - "analizar skills"
  - "escalar skill"
  - "skill improvement request"
  - "optimize orchestrator"
---

# SKILL OPTIMIZER SKILL

## Purpose

Owner-only skill for:
1. **Analyze** all skills for quality, consistency, and completeness
2. **Improve** existing skills with best practices
3. **Optimize** orchestrator and auto-delegation
4. **Escalate** developer requests for skill changes
5. **Auto-maintain** workspace skill ecosystem

## Owner-Only Enforcement

```
ACCESS CONTROL:
├─ This skill is RESTRICTED to workspace owner only
├─ Cannot be triggered by standard developers
├─ All optimization actions require owner authentication
└─ Developer requests must be ESCALATED to owner

RESTRICTED CAPABILITIES:
├─ Modify skill definitions
├─ Update orchestrator logic
├─ Change auto-delegation rules
├─ Create new skills
├─ Delete or deprecate skills
└─ Access workspace configuration
```

## Analysis Engine

### 1. Skill Quality Scanner

```powershell
function Test-SkillQuality {
    param([string]$SkillPath)
    
    $checks = @{
        HasDescription = $false
        HasTriggers = $false
        HasExamples = $false
        HasReferences = $false
        ConsistentNaming = $false
        CompleteMetadata = $false
    }
    
    # Scan skill file
    $content = Get-Content $SkillPath -Raw
    
    if ($content -match 'description:') { $checks.HasDescription = $true }
    if ($content -match 'triggers:') { $checks.HasTriggers = $true }
    if ($content -match '## (Example|Usage)') { $checks.HasExamples = $true }
    if ($content -match '## References') { $checks.HasReferences = $true }
    if ($content -match '^# \w+') { $checks.ConsistentNaming = $true }
    if ($content -match 'name:|version:|status:') { $checks.CompleteMetadata = $true }
    
    $score = ($checks.Values | Where-Object { $_ -eq $true }).Count / $checks.Count * 100
    
    return @{
        Skill = Split-Path $SkillPath -Leaf
        Score = [math]::Round($score, 1)
        Checks = $checks
        Issues = $checks.Keys | Where-Object { $checks[$_] -eq $false }
    }
}
```

### 2. Consistency Validator

```
CONSISTENCY RULES:
├─ All skills must have: name, description, triggers
├─ Naming convention: kebab-case (skill-name)
├─ Must reference other related skills
├─ Must follow markdown structure
├─ Cannot conflict with existing skills
└─ Owner-only skills must have: owner_only: true
```

### 3. Dependency Mapper

```powershell
function Get-SkillDependencies {
    param([string]$SkillPath)
    
    $content = Get-Content $SkillPath -Raw
    
    # Find skill references
    $references = [regex]::Matches($content, '\[.*?\]\(.*?SKILL\.md\)')
    
    $deps = @()
    foreach ($ref in $references) {
        $deps += $ref.Value
    }
    
    return @{
        Skill = Split-Path $SkillPath -Leaf
        Dependencies = $deps
        Orphaned = $deps | Where-Object { $_ -notmatch 'skills/' }
    }
}
```

## Optimization Actions

### 1. Auto-Improve Existing Skills

```
IMPROVEMENT CHECKLIST:
├─ Add missing triggers based on content
├─ Add examples if missing
├─ Add references to related skills
├─ Normalize metadata format
├─ Fix broken links
├─ Update version numbers
└─ Add status flags
```

### 2. Orchestrator Optimization

```powershell
function Optimize-Orchestrator {
    <#
    .SYNOPSIS
    Analyzes and improves the auto-delegation router and orchestrator
    #>
    
    # Analyze keyword coverage
    # Identify missing domains
    # Suggest new skill integrations
    # Optimize routing logic
    
    return @{
        Status = "Analysis Complete"
        Recommendations = @(
            "Add missing technical skill keywords",
            "Update confidence thresholds",
            "Add new skill mappings"
        )
    }
}
```

### 3. Skill Registry Maintenance

```
REGISTRY TASKS:
├─ Scan all skills in tools/skills/
├─ Scan all skills in skills/
├─ Detect duplicates
├─ Identify orphaned skills
├─ Generate skill-registry.md
└─ Validate cross-references
```

## Developer Escalation Workflow

### Request Flow

```
DEVELOPER REQUEST:
    │
    ▼
┌─────────────────┐
│ Request received│
│ (via doc-strat) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Log to queue    │
│ .workspace/     │
│  escalation/    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Notify owner    │
│ (internal)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Owner reviews   │
│ & decides       │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
 ▼ ▼         ▼
APPROVE  REJECT  DEFER
 │         │       │
 ▼         ▼       ▼
IMPLEMENT  NOTIFY  SCHEDULE
```

### Escalation Handler

```powershell
function New-SkillEscalation {
    param(
        [string]$DeveloperName,
        [string]$RequestType,  # new-skill, improve-skill, modify-orchestrator
        [string]$Description,
        [string]$Justification,
        [string]$Priority = "normal"  # low, normal, high, critical
    )
    
    $escalation = @{
        Id = (Get-Date).ToString("yyyyMMdd-HHmmss")
        Developer = $DeveloperName
        Type = $RequestType
        Description = $Description
        Justification = $Justification
        Priority = $Priority
        Status = "pending"
        CreatedAt = Get-Date -Format "o"
    }
    
    $queuePath = ".workspace/escalations/pending"
    if (-not (Test-Path $queuePath)) {
        New-Item -ItemType Directory -Path $queuePath -Force
    }
    
    $escalation | ConvertTo-Json -Depth 10 | 
        Set-Content "$queuePath/$($escalation.Id).json"
    
    return @{
        Status = "Escalated"
        Id = $escalation.Id
        Message = "Request queued for owner review"
    }
}
```

### Owner Response Handler

```powershell
function Set-EscalationResponse {
    param(
        [string]$EscalationId,
        [string]$Decision,  # approve, reject, defer
        [string]$Notes,
        [string]$ImplementationPlan
    )
    
    $escalationPath = ".workspace/escalations/pending/$EscalationId.json"
    
    if (-not (Test-Path $escalationPath)) {
        return @{ Status = "Error"; Message = "Escalation not found" }
    }
    
    $escalation = Get-Content $escalationPath | ConvertFrom-Json
    $escalation.Status = $Decision
    $escalation.OwnerNotes = $Notes
    $escalation.ImplementationPlan = $ImplementationPlan
    $escalation.ResolvedAt = Get-Date -Format "o"
    
    # Move to appropriate folder
    $targetFolder = ".workspace/escalations/$Decision"
    if (-not (Test-Path $targetFolder)) {
        New-Item -ItemType Directory -Path $targetFolder -Force
    }
    
    $escalation | ConvertTo-Json -Depth 10 | 
        Set-Content "$targetFolder/$EscalationId.json"
    
    # Remove from pending
    Remove-Item $escalationPath
    
    return @{
        Status = "Resolved"
        Decision = $Decision
        Message = "Developer notified"
    }
}
```

## Auto-Maintenance

### Scheduled Tasks

```
MAINTENANCE TASKS (Owner-triggered):
├─ Weekly: Skill quality scan
├─ Weekly: Dependency validation
├─ Monthly: Orchestrator optimization
├─ Monthly: Registry update
├─ On-demand: Developer request processing
└─ On-demand: Emergency skill disable
```

### Quality Metrics

```powershell
function Get-SkillHealthMetrics {
    $skillsPath = @("tools/skills", "skills")
    
    $metrics = @{
        TotalSkills = 0
        AverageQualityScore = 0
        IssuesFound = @()
        OrphanedSkills = @()
        OutdatedSkills = @()
        RecentlyUpdated = @()
    }
    
    foreach ($path in $skillsPath) {
        $skillFiles = Get-ChildItem -Path $path -Filter "SKILL.md" -Recurse
        $metrics.TotalSkills += $skillFiles.Count
        
        foreach ($file in $skillFiles) {
            $quality = Test-SkillQuality -SkillPath $file.FullName
            $metrics.IssuesFound += $quality.Issues
        }
    }
    
    $metrics.AverageQualityScore = ($metrics.IssuesFound.Count / $metrics.TotalSkills) * 100
    
    return $metrics
}
```

## Usage

### Owner Commands

```powershell
# Analyze all skills
.\scripts\utilities\wf.ps1 skill-optimizer analyze

# Optimize orchestrator
.\scripts\utilities\wf.ps1 skill-optimizer optimize-orchestrator

# Auto-improve skills
.\scripts\utilities\wf.ps1 skill-optimizer improve

# Check escalations
.\scripts\utilities\wf.ps1 skill-optimizer escalations list

# Process developer request
.\scripts\utilities\wf.ps1 skill-optimizer escalations process --id <id> --approve --notes "Approved"

# Generate health report
.\scripts\utilities\wf.ps1 skill-optimizer health
```

### Developer Commands (Limited)

```powershell
# Request new skill
.\scripts\utilities\wf.ps1 skill-optimizer request new-skill --name "new-feature" --justification "..."

# Request improvement
.\scripts\utilities\wf.ps1 skill-optimizer request improve --skill "existing-skill" --description "..."

# Check request status
.\scripts\utilities\wf.ps1 skill-optimizer request status
```

## Access Control Configuration

### User Roles

```json
{
  "roles": {
    "owner": {
      "name": "Workspace Owner",
      "can": [
        "run-skill-optimizer",
        "modify-skills",
        "modify-orchestrator",
        "approve-escalations",
        "access-workspace-config"
      ],
      "cannot": []
    },
    "developer": {
      "name": "Developer",
      "can": [
        "read-skills",
        "use-skills",
        "request-skill-changes",
        "run-documentation-strategist"
      ],
      "cannot": [
        "run-skill-optimizer",
        "modify-skills",
        "modify-orchestrator",
        "access-workspace-config"
      ]
    }
  }
}
```

### Enforcement Points

```
ENFORCEMENT:
├─ auth-session.ps1 validates before any restricted command
├─ API key required OR security questions
├─ Session authenticated for 8 hours after valid auth
├─ Developer attempts are BLOCKED with error message
└─ All modifications require owner authentication
```

## Authentication Flow

### Flow 1: API Key (Preferred)
```powershell
# Authenticate for this session
.\scripts\utilities\auth-session.ps1 -ApiKey "fnd_local_2026_Emmanuel_"

# Now run skill-optimizer commands
.\wf.ps1 skill-optimizer analyze
.\wf.ps1 skill-optimizer improve
```

### Flow 2: Security Questions (Recovery)
```powershell
# If you forgot your API key
.\scripts\utilities\auth-session.ps1 -UseSecurityQuestions

# Answer 3 questions correctly
# If all correct → can use recovered API key for session
```

### Flow 3: Developer Request
```powershell
# Developer wants to modify something
# They CANNOT do it directly
# They must submit an escalation request
.\wf.ps1 skill-optimizer request new-skill --name "xyz" --justification "..."

# This goes to .workspace/escalations/pending/
# Owner reviews and approves/rejects/defers
```

### Error Messages (Block Unauthorized Access)

| Scenario | Message |
|----------|----------|
| No auth attempted | "Esta operación requiere autenticación del owner" |
| Invalid API key | "API key inválida. Usa --security-questions si la olvidaste" |
| Wrong security answers | "Acceso denegado: solo 1/3 respuestas correctas" |
| Developer attempting | "No tienes permisos para realizar esta operación" |

## Commands

### Owner Commands (Require Authentication)
```powershell
# With API key (session persists 8 hours)
.\scripts\utilities\auth-session.ps1 -ApiKey fnd_local_2026_Emmanuel_
.\wf.ps1 skill-optimizer analyze
.\wf.ps1 skill-optimizer improve
.\wf.ps1 skill-optimizer optimize-orchestrator
.\wf.ps1 skill-optimizer escalations list
.\wf.ps1 skill-optimizer health

# With security questions (recovery)
.\scripts\utilities\auth-session.ps1 -UseSecurityQuestions
```

### Developer Commands (Always Blocked)
```powershell
# These will be denied
.\wf.ps1 skill-optimizer analyze  # BLOCKED
.\wf.ps1 skill-optimizer improve  # BLOCKED
.\wf.ps1 orchestrator            # BLOCKED
.\wf.ps1 admin                  # BLOCKED

# Only this is allowed
.\wf.ps1 skill-optimizer request new-skill --name "..." --justification "..."
```

## Integration Points

| Skill | Integration |
|-------|-------------|
| documentation-strategist | Receives escalation for doc requests |
| auto-delegation-router | Routes to skill-optimizer only for owner |
| github-pr | Auto-flags skill changes for owner review |
| foundation-audit-skill | Runs quality checks |

## Quality Gates

Before any skill change is applied:
- [ ] Owner approval obtained
- [ ] No breaking changes to other skills
- [ ] Documentation updated
- [ ] Registry regenerated
- [ ] Tests validated (if applicable)
- [ ] Breaking change flagged in changelog

## References

- Auto-Delegation Router: [skills/auto-delegation-router/SKILL.md](../auto-delegation-router/SKILL.md)
- Documentation Strategist: [tools/skills/documentation-strategist/SKILL.md](../documentation-strategist/SKILL.md)
- Foundation Audit: [tools/skills/foundation-audit-skill/SKILL.md](../foundation-audit-skill/SKILL.md)