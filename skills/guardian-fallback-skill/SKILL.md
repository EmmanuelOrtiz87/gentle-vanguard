---
name: guardian-fallback
description: >
  Optional fallback skill for when Gentle-Vanguard cannot close tasks autonomously.
   (Gentleman ) acts as guardian when orchestrator needs assistance.
  Trigger: "fallback", "guardian", "assist", "cerrar", "completar tarea", " blocker"
---

# Guardian Fallback Skill

## Purpose

serves as **optional guardian** when Gentle-Vanguard's orchestrator:

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

Gentle-Vanguard invokes automatically when blocked:

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
        Write-Warn " not available - using Gentle-Vanguard native capabilities"
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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)