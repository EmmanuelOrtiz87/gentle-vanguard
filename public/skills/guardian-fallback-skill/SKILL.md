---
name: guardian-fallback
description: >
  Optional fallback skill for when Foundation cannot close tasks autonomously.
   (Gentleman ) acts as guardian when orchestrator needs assistance.
  Trigger: "fallback", "guardian", "assist", "cerrar", "completar tarea", " blocker"
---

# Guardian Fallback Skill

## Purpose

serves as **optional guardian** when Foundation's orchestrator:

- Cannot determine next step
- Is blocked by unknown error
- Needs second opinion on complex decisión
- Requires code review to close PR

## Architecture

```
ORCHESTRATOR (Primary)

     Can proceed?  Execute normally

     Blocked?  Try self-healing

     Still blocked?   FALLBACK (optional)

             Code review
             decisión assist
             Task completion
             Commit hygiene
```

## Trigger Conditions

Use fallback when:

| Condition                     | Action                  |
| ----------------------------- | ----------------------- |
| Unknown error blocks progress | ` run` for diagnosis    |
| PR needs final review         | ` run --pr-mode`        |
| Complex decisión needed       | reasoning assist        |
| Blocked on coding standards   | review                  |
| Commit message validation     | ` install --commit-msg` |

## Invocation

### Automatic (Recommended)

Foundation invokes automatically when blocked:

```powershell
# Automatic detection and fallback
if (-not $canProceed) {
    Write-Host "[FALLBACK] Invoking  guardian..."
     run --ci
}
```

### Manual

```powershell
# Manual invocation
 run                    # Review staged files
 run --pr-mode        # Full PR review
 run --ci             # CI mode (last commit)
```

## Availability Check

```powershell
function Test-Available {
    $ = Get-Command  -ErrorAction SilentlyContinue
    return ($null -ne $)
}

function Invoke-Fallback {
    if (-not (Test-Available)) {
        Write-Warn " not available - using Foundation native capabilities"
        return $false
    }

    # Invoke  for assistance
     run
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
        #  fallback (optional)
        if (Test-Available) {
            Write-Host "[ORCHESTRATOR]  guardian invoked..."
            Invoke-Fallback
        } else {
            Write-Warn "Blocked and  unavailable - manual intervention required"
        }
    }
}
```

### In Session Close

```powershell
# Before session end
if (-not (Test-AllTasksComplete)) {
    if (Test-Available) {
         run --ci  # Final review before close
    }
}
```

## Configuration

reads from `.` config or environment:

```bash
# . (project level)
PROVIDER="opencode"
FILE_PATTERNS="*.ps1,*.ts,*.js"
STRICT_MODE="true"
```

## Dependencies

| Tool                    | Required | Purpose                     |
| ----------------------- | -------- | --------------------------- |
| Foundation Orchestrator | **YES**  | Primary execution           |
| invoke-ai-review.ps1    | **YES**  | Native review (replacement) |
| ()                      | **NO**   | Optional fallback guardian  |

## Coexistence

Foundation operates **fully** without :

- Native AI review via `invoke-ai-review.ps1`
- Pre-commit hooks via Foundation hooks
- Code review via `code-review-orchestrator-skill`

is **enhancement**, not **requirement**.

## Error Handling

```

              FALLBACK decisión TREE


  Orchestrator blocked?


  Self-healing possible?


    YES       NO

  Apply       available?
  healing

            YES   NO

        Invoke   Flag for
             manual
            intervention

  Report result


```

## Commands Reference

```powershell
#  commands (when available)
 run              # Review staged files
 run --ci        # CI mode
 run --pr-mode   # PR review
 config          # Show config
 cache status    # Cache info

# Foundation native (always available)
invoke-ai-review.ps1 run
foundation review --scope quick
foundation review --scope full
```

## Skill Priority

| Priority | Skill                    | Availability    |
| -------- | ------------------------ | --------------- |
| 1        | project-orchestrator     | Always          |
| 2        | invoke-ai-review         | Always (native) |
| 3        | code-review-orchestrator | Always          |
| **4**    | **guardian-fallback ()** | **Optional**    |

---

**Note:** is a convenience, not a requirement. Foundation works fully without it.
