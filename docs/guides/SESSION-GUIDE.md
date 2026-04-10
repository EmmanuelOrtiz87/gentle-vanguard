# Session Guide

How AI sessions work with this project.

## How It Works

The **project-orchestrator** is ALWAYS ACTIVE. No need to trigger it.

```
┌─────────────────────────────────────────────────────────────┐
│  PROJECT ORCHESTRATOR (Always Running)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  At session start, it automatically:                        │
│                                                              │
│  1. DETECTS project and stack                              │
│  2. CHECKS git status                                     │
│  3. LOADS relevant skills                                 │
│  4. SHOWS status and suggests next step                   │
│                                                              │
│  You don't need to say anything special.                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## User Commands

These trigger specific actions:

| Command | What Happens |
|---------|--------------|
| *(nothing)* | Orchestrator auto-detects and shows status |
| `Continuar` | Resume previous work, show next step |
| `Estado` | Show current project status and todos |
| `Guardar` | mem_save summary, commit, push |

## Session Flow

```
1. You start talking
      │
      ▼
2. Orchestrator auto-detects:
      │ - Project name
      │ - Stack (Go, Angular, etc.)
      │ - Git status
      │ - Recent memory (mem_context)
      │
      ▼
3. Orchestrator loads relevant skills:
      │ - golang-api-skill (if Go detected)
      │ - angular-spa-skill (if Angular detected)
      │ - etc.
      │
      ▼
4. Orchestrator shows:
      │ - Project detected
      │ - Skills loaded
      │ - Suggested next step
      │
      ▼
5. We work together
      │
      ▼
6. Say "Guardar" when done
      │ - mem_save summary
      │ - Commit
      │ - Push
```

## Skills Auto-Loaded

Based on detected stack:

| Stack | Skills Loaded |
|-------|---------------|
| Go | golang-api-skill, testing-skill |
| Angular | angular-spa-skill, tailwind-4-skill |
| React | react-19-skill, tailwind-4-skill, zustand-5-skill |
| Django | django-drf-skill |
| Documentation | documentation-governance-skill |
| Testing | testing-strategy-skill |
| CI/CD | docker-devops-skill |

## Memory

Engram is used automatically:

| Command | When |
|---------|-------|
| `mem_context` | Session start (automatic) |
| `mem_save` | When you say "Guardar" |

## Example Session

```
YOU: (start talking about the project)

ORCHESTRATOR: 
## Session Started

**Project Detected:** bitbucket-dashboard
**Stack:** Go + Angular
**Skills Loaded:** golang-api-skill, angular-spa-skill

**Status:**
- ✅ CI/CD configured
- ⏳ Frontend migration in progress
- 📋 Need to add tests

**Next Step:** Continue Angular component migration

---

YOU: Let's add the user profile component

ORCHESTRATOR: (uses angular-spa-skill)
...

YOU: Guardar

ORCHESTRATOR:
## Session Summary
[Summary created]
[Changes committed]
[Push completed]
```

## Tips

- Just start talking - orchestrator detects automatically
- Say "Estado" to see current status
- Say "Continuar" to resume previous work
- Say "Guardar" when finished

## See Also

- [skills/SKILL_INDEX.md](../skills/SKILL_INDEX.md) - All skills
- [docs/getting-started/DEVELOPER-SETUP.md](../getting-started/DEVELOPER-SETUP.md) - Setup
