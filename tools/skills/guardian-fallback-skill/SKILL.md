---
name: guardian-fallback
description: >
  Optional fallback skill for when Foundation cannot close tasks autonomously.
  GGA (Gentleman Guardian Angel) acts as guardian when orchestrator needs assistance.
  Trigger: "fallback", "guardian", "assist", "cerrar", "completar tarea", " blocker"
---

# Guardian Fallback Skill

## Purpose
GGA serves as **optional guardian** when Foundation's orchestrator:
- Cannot determine next step
- Is blocked by unknown error
- Needs second opinion on complex decision
- Requires code review to close PR

## Architecture

```
ORCHESTRATOR (Primary)
    │
    ├── Can proceed? → Execute normally
    │
    ├── Blocked? → Try self-healing
    │
    └── Still blocked? → GGA FALLBACK (optional)
            │
            ├── Code review
            ├── Decision assist
            ├── Task completion
            └── Commit hygiene
```

## Trigger Conditions

Use GGA fallback when:

| Condition | Action |
|-----------|--------|
| Unknown error blocks progress | `gga run` for diagnosis |
| PR needs final review | `gga run --pr-mode` |
| Complex decision needed | GGA reasoning assist |
| Blocked on coding standards | GGA review |
| Commit message validation | `gga install --commit-msg` |

## Invocation

### Automatic (Recommended)
Foundation invokes GGA automatically when blocked:

```powershell
# Automatic detection and fallback
if (-not $canProceed) {
    Write-Host "[FALLBACK] Invoking GGA guardian..."
    gga run --ci
}
```

### Manual
```powershell
# Manual invocation
gga run                    # Review staged files
gga run --pr-mode        # Full PR review
gga run --ci             # CI mode (last commit)
```

## Availability Check

```powershell
function Test-GgaAvailable {
    $gga = Get-Command gga -ErrorAction SilentlyContinue
    return ($null -ne $gga)
}

function Invoke-GgaFallback {
    if (-not (Test-GgaAvailable)) {
        Write-Warn "GGA not available - using Foundation native capabilities"
        return $false
    }
    
    # Invoke GGA for assistance
    gga run
    return ($LASTEXITCODE -eq 0)
}
```

## Integration Points

### In Orchestrator
```powershell
# Before escalation
$canProceed = Test-CanProceed -Context $context

if (-not $canProceed) {
    # Try self-healing
    $healed = Invoke-SelfHealing -Context $context
    
    if (-not $healed) {
        # GGA fallback (optional)
        if (Test-GgaAvailable) {
            Write-Host "[ORCHESTRATOR] GGA guardian invoked..."
            Invoke-GgaFallback
        } else {
            Write-Warn "Blocked and GGA unavailable - manual intervention required"
        }
    }
}
```

### In Session Close
```powershell
# Before session end
if (-not (Test-AllTasksComplete)) {
    if (Test-GgaAvailable) {
        gga run --ci  # Final review before close
    }
}
```

## Configuration

GGA reads from `.gga` config or environment:

```bash
# .gga (project level)
PROVIDER="opencode"
FILE_PATTERNS="*.ps1,*.ts,*.js"
STRICT_MODE="true"
```

## Dependencies

| Tool | Required | Purpose |
|------|----------|---------|
| Foundation Orchestrator | **YES** | Primary execution |
| invoke-ai-review.ps1 | **YES** | Native review (replacement) |
| GGA (gga) | **NO** | Optional fallback guardian |

## Coexistence

Foundation operates **fully** without GGA:
- Native AI review via `invoke-ai-review.ps1`
- Pre-commit hooks via Foundation hooks
- Code review via `code-review-orchestrator-skill`

GGA is **enhancement**, not **requirement**.

## Error Handling

```
┌─────────────────────────────────────────────┐
│              FALLBACK DECISION TREE            │
├─────────────────────────────────────────────┤
│                                              │
│  Orchestrator blocked?                       │
│         │                                   │
│         ▼                                   │
│  Self-healing possible?                      │
│         │                                   │
│    ┌────┴────┐                            │
│    │YES       │NO                          │
│    ▼          ▼                             │
│  Apply      GGA available?                  │
│  healing        │                           │
│    │        ┌──┴──┐                        │
│    │        │YES   │NO                      │
│    │        ▼       ▼                       │
│    │    Invoke   Flag for                    │
│    │    GGA     manual                      │
│    │        intervention                     │
│    ▼                                           │
│  Report result                                │
│                                              │
└─────────────────────────────────────────────┘
```

## Commands Reference

```powershell
# GGA commands (when available)
gga run              # Review staged files
gga run --ci        # CI mode
gga run --pr-mode   # PR review
gga config          # Show config
gga cache status    # Cache info

# Foundation native (always available)
invoke-ai-review.ps1 run
wf review --scope quick
wf review --scope full
```

## Skill Priority

| Priority | Skill | Availability |
|----------|-------|--------------|
| 1 | project-orchestrator | Always |
| 2 | invoke-ai-review | Always (native) |
| 3 | code-review-orchestrator | Always |
| **4** | **guardian-fallback (GGA)** | **Optional** |

---
**Note:** GGA is a convenience, not a requirement. Foundation works fully without it.
