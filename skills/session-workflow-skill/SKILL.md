---
name: session-workflow
description: >
  Session workflow executor: handles the mechanics of session management.
  Coordinate with project-orchestrator for context detection.
  Trigger: "iniciar sesion", "guardar sesion", "continuar", "estado".
---

# SESSION WORKFLOW

## Purpose

Execute the mechanical aspects of session management while coordinating with the orchestrator.

## Role Division

```
┌─────────────────────────────────────────────────────────────────┐
│              COORDINATION                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  PROJECT ORCHESTRATOR (Always Active)                            │
│  └── Context detection, skill loading, guidance                   │
│                                                                   │
│  SESSION WORKFLOW (On Request)                                   │
│  └── Memory management, todos, session mechanics                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Commands

### "Iniciar sesion" / "Start session"

```markdown
1. mem_context              # Check engram memory
2. todowrite                # Create/update session plan
3. Show:                   # Present to user
   - Project detected
   - Skills to load
   - Suggested plan
```

### "Continuar" / "Continue"

```markdown
1. mem_context             # Get recent context
2. Check current todos     # Where were we?
3. Show next step
4. Resume work
```

### "Estado" / "Status"

```markdown
1. Show current project
2. Show active todos
3. Show pending work
4. Suggest next step
```

### "Guardar sesion" / "Save session"

```markdown
1. Review todos completed
2. Create session summary
3. mem_save summary
4. Commit if changes exist
5. Push if ready
```

## Todo Management

Use todowrite at session start:

```markdown
todowrite([...todos])
```

Use todowrite during session to update:

```markdown
todowrite([...updated todos])
```

## Session Summary Format

```markdown
## Session Summary - [DATE]

### Goal
[What we worked on]

### Accomplished
- [Completed item 1]
- [Completed item 2]

### Discoveries
- [Technical finding 1]

### Next Steps
- [Remaining work 1]
- [Remaining work 2]

### Skills Used
- skill-name-1
- skill-name-2

### Relevant Files
- path/to/file - description
```

## Memory Commands

| Command | Purpose |
|---------|---------|
| `mem_context` | Get recent session context |
| `mem_save` | Save current session |
| `mem_search` | Find past work |
| `mem_update` | Correct previous |

## Workflow Checklist

- [ ] Session start: todowrite created
- [ ] Skills loaded per orchestrator
- [ ] Work executed with skills
- [ ] Verification done
- [ ] Session end: mem_save executed
- [ ] Changes committed
- [ ] Repo pushed if ready

---

**Coordinate with project-orchestrator for all technical guidance.**
