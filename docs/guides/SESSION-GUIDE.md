# Session Guide

How to work with this project using AI agents.

## Starting a Session

### Step 1: Say "Iniciar sesion" or "Start session"

This triggers the **session-workflow-skill** which will:

1. Check engram memory (`mem_context`)
2. Create session plan (`todowrite`)
3. Load required skills
4. Set up the workflow

### Step 2: Automatic Actions

When you say "Iniciar sesion", the AI will:

```
1. mem_context           # Check memory for past work
2. todowrite             # Create session plan
3. Load skills:          # Based on project type
   - project-orchestrator-skill
   - session-workflow-skill
   - domain-specific skills
4. Present plan          # Ask for confirmation
```

## Session Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. START                                                 │
│     "Iniciar sesion"                                       │
│          │                                                │
│          ▼                                                │
│  2. ASSESS ────► Check context, load memory               │
│          │                                                │
│          ▼                                                │
│  3. PLAN ─────► Create todos, load skills                │
│          │                                                │
│          ▼                                                │
│  4. EXECUTE ───► Implement with skills                     │
│          │                                                │
│          ▼                                                │
│  5. VERIFY ────► Run tests, validate                     │
│          │                                                │
│          ▼                                                │
│  6. DOCUMENT ──► Save memory, commit                      │
│          │                                                │
│          ▼                                                │
│  7. END ────────► "Guardar sesion" or "End session"    │
└─────────────────────────────────────────────────────────────┘
```

## Commands Reference

| Command | Action |
|---------|--------|
| `Iniciar sesion` | Start session workflow |
| `Continuar` | Resume previous work |
| `Guardar sesion` | End session, save to engram |
| `Nuevo proyecto` | Start new project workflow |

## Required Skills

Always loaded at session start:

| Skill | Purpose |
|-------|---------|
| `project-orchestrator-skill` | Project assessment and guidance |
| `session-workflow-skill` | Session management |

Domain skills loaded based on project:

| Project Type | Skills to Load |
|--------------|---------------|
| Go API | `golang-api-skill` |
| Angular | `angular-spa-skill` |
| React | `react-19-skill`, `tailwind-4-skill` |
| Fullstack | `golang-api-skill`, `angular-spa-skill` |

## Memory Commands

Engram is used for persistent memory:

| Command | When |
|---------|-------|
| `mem_context` | Session start - check recent work |
| `mem_search` | Recall specific topics |
| `mem_save` | After completing significant work |
| `mem_update` | Correct previous observations |

## Ending a Session

### Say "Guardar sesion" or "End session"

The AI will:

```
1. Review todos completed
2. Create session summary
3. mem_save summary
4. Commit changes
5. Push to repo (if ready)
```

### Session Summary Format

```markdown
## Session Summary

### Goal
[What we were working on]

### Accomplished
- [Completed item 1]
- [Completed item 2]

### Next Steps
- [Remaining work]

### Discoveries
- [Technical findings, if any]

### Relevant Files
- path/to/file - [what it does]
```

## Tips

### Do
- Say "Iniciar sesion" at the beginning of each session
- Say "Guardar sesion" at the end
- Use skills for implementation
- Update todos as work progresses

### Don't
- Start implementing without assessing first
- Skip saving memory
- Push without verifying

## See Also

- [skills/SKILL_INDEX.md](skills/SKILL_INDEX.md) - All available skills
- [docs/getting-started/DEVELOPER-SETUP.md](docs/getting-started/DEVELOPER-SETUP.md) - Setup guide
- [docs/reference/ARCHITECTURE.md](docs/reference/ARCHITECTURE.md) - Architecture
