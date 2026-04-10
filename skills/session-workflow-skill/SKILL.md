---
name: session-workflow
description: >
  Session workflow executor: handles the mechanics of session management.
  Coordinate with project-orchestrator for context detection.
  Trigger: "iniciar sesion", "guardar sesion", "continuar", "estado", "pr".
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
2. Check git branch/status
3. todowrite                # Create/update session plan
4. Show:                   # Present to user
   - Project detected
   - Branch & status
   - Skills to load
   - Suggested plan
```

### "Continuar" / "Continue"

```markdown
1. mem_context             # Get recent context
2. Check git status        # Current branch, changes
3. Check current todos     # Where were we?
4. Show next step
5. Resume work
```

### "Estado" / "Status"

```markdown
1. Show current project
2. Show git branch & status
3. Show active todos
4. Show pending work
5. Suggest next step
```

### "Guardar sesion" / "Save session"

```markdown
1. Review todos completed
2. Create session summary
3. Run: git status
4. Validate: tests pass?
5. Commit if changes exist
6. Ask: ¿Push to remote?
7. mem_save summary
```

### "PR" / "Create PR"

```markdown
1. Validate specification
2. Ask: ¿Cumplimos con la especificación?
3. If YES:
   - Create branch (if needed)
   - Commit changes
   - Push
   - Create PR with template
4. If NO:
   - List remaining items
   - Continue work
```

## Git Flow Integration

Before any commit:

1. Check current branch
2. Commit follows convention: `type(scope): description`
3. Tests pass
4. No secrets

Before PR:

1. Validate all checklist items
2. Ask user confirmation
3. Create PR with description template

## Todo Management

Use todowrite at session start:

```markdown
todowrite([
  { content: "Task 1", status: "in_progress", priority: "high" },
  { content: "Task 2", status: "pending", priority: "medium" }
])
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

### Git
- Branch: [branch-name]
- Commits: [list]

### Specification Validated
[YES/NO + notes]

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
- [ ] Git branch checked
- [ ] Skills loaded per orchestrator
- [ ] Work executed with skills
- [ ] Tests verified
- [ ] Commit follows convention
- [ ] Session end: mem_save executed
- [ ] PR validated (if requested)

---

**Coordinate with project-orchestrator for all technical guidance.**
