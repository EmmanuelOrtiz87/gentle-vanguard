---
name: session-workflow
description: >
  Session workflow executor: handles the mechanics of session management.
  Coordinate with project-orchestrator for context detection.
  Trigger: "iniciar sesion", "guardar sesion", "continuar", "estado", "pr", "push", "review", "auditar".
---

# SESSION WORKFLOW

## Purpose

Execute the mechanical aspects of session management while coordinating with the orchestrator.

## Commands

### "Iniciar sesion" / "Start session"

**Note: This skill should be AUTO-LOADED when user says "iniciar sesion" via pre-process-input.ps1**

```markdown
1. tools/session-autostart.cmd  # Ejecutar autostart (notificaciones, optimizacin, validaciones)
2. mem_context                  # Check engram memory
3. git status                   # Current branch
4. todowrite                    # Create session plan
5. Present status
```

### "Continuar" / "Continue"

```markdown
1. mem_context             # Get context
2. git status              # Current branch
3. Show next step
4. Resume work
```

### "Estado" / "Status"

```markdown
1. Show project info
2. Show git branch/status
3. Show todos
4. Suggest next step
```

### "Push" / "Guardar"

```markdown
1. Review todos completed
2. Generate AUDIT DOCUMENT
3. git status / diff
4. Commit if changes
5. Push to remote
6. mem_save summary
```

### "Review" / "Auditar"

```markdown
1. Run code review (7 dimensions)
2. Classify findings by severity
3. Present findings summary
4. Ask: decision options
5. Execute user choice
```

### "PR" / "Create PR"

```markdown
1. Validate specification
2. Run code review
3. Handle findings (if any)
4. Ask: Did we meet the spec?
5. Ask: Create PR?
6. If YES:
   - Create branch (if needed)
   - Commit
   - Push
   - Create PR with template
```

---

## AUDIT DOCUMENT GENERATION

### When
- Before any push
- On user request: "audit", "push", "guardar"

### Format
```markdown
# Audit Document - [DATE]

**Project:** [project-name]
**Session:** [session-id]
**Date:** [ISO date]

## Summary
Brief description of session work.

## Changes
| File | Change | Lines |
|------|--------|-------|
| file.go | Added feature | +150/-20 |

## Commits
| Hash | Type | Message |
|------|------|---------|
| abc123 | feat | description |

## Findings
| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 2 |
| LOW | 3 |

## Tests
- Go: X passed
- Angular: Y passed

## Specification
- Status: COMPLETE
- Notes: ...

## Next Steps
- [ ] Item 1
- [ ] Item 2
```

---

## CODE REVIEW WORKFLOW

### Trigger
- "review", "auditar", "code review"
- Before PR creation

### Process
```
1. Run quick scan (Security + Quality)
2. If findings:
   - Classify by severity
   - Present to user
   - Ask decision
3. If no critical/high:
   - Proceed with PR option
```

### Findings Decision

```markdown
## Findings Summary

**Found:** X issues
- [X] CRITICAL: N (blocks if any)
- [!] HIGH: N
- [-] MEDIUM: N  
- [*] LOW: N

### Options

1) Fix everything now (recommended)
2) Fix CRITICAL/HIGH now, handle the rest later
3) Create the PR, then fix later
4) Only create the PR
5) Go back to implementation

**Choose:**
```

---

## Todo Management

```typescript
todowrite([
  { content: "Task 1", status: "in_progress", priority: "high" },
  { content: "Task 2", status: "pending", priority: "medium" }
])
```

---

## Session Summary Format

```markdown
## Session Summary - [DATE]

### Goal
[What we worked on]

### Accomplished
- [Completed item 1]
- [Completed item 2]

### Findings
- [X] Critical: N
- [!] High: N
- [-] Medium: N
- [*] Low: N

### Git
- Branch: [branch]
- Commits: [list]

### Specification
- Validated: YES/NO
- Notes: ...

### Next Steps
- [ ] Item 1
- [ ] Item 2

### Skills Used
- skill-1
- skill-2

### Relevant Files
- path - description
```

---

## Memory Commands

| Command | When |
|---------|------|
| `mem_context` | Session start |
| `mem_save` | After significant work |
| `mem_search` | User mentions past work |
| `mem_update` | Correct previous |

---

## Workflow Checklist

- [ ] Session start: todowrite created
- [ ] Git branch checked
- [ ] Skills loaded
- [ ] Work executed
- [ ] Tests verified
- [ ] Audit document generated (before push)
- [ ] Code review run (before PR)
- [ ] Findings handled
- [ ] Commit follows convention
- [ ] User asked: Create PR?
- [ ] Pushed if confirmed
- [ ] mem_save executed

---

**Coordinate with project-orchestrator for technical guidance.**
