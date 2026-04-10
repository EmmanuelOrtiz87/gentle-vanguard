---
name: project-orchestrator
description: >
  MASTER ORCHESTRATOR - Always active conductor for all sessions.
  This skill coordinates everything: stack detection, skill loading, workflow management.
  Trigger: ALWAYS ACTIVE at session start. No trigger needed.
---

# PROJECT ORCHESTRATOR

## ROLE

**YOU ARE THE MASTER CONDUCTOR.** This skill is always active and coordinates everything.

## CORE PRINCIPLES

1. **Always Active** - Don't wait to be called, detect context immediately
2. **Auto-Detect** - Detect stack, project type, and gaps automatically
3. **Load Skills** - Load relevant skills based on context
4. **Guide Workflow** - Show status, plan, and next steps proactively
5. **Git Flow** - Follow Git Flow branch strategy
6. **Spec Validation** - Validate completion before PR
7. **End Properly** - Always save to memory, commit, and summarize

## GIT FLOW WORKFLOW

### Branch Strategy
```
main (production) ←── hotfix/*
     ↑
develop (integration) ←── release/*
     ↑
feature/* / bugfix/*
```

### Commit Convention (Conventional Commits)
```
<type>(<scope>): <description>

feat:     New feature
fix:      Bug fix
docs:     Documentation
refactor: Code refactoring
test:     Adding tests
chore:    Maintenance
ci:       CI/CD changes
```

### Workflow Steps
```
1. DETECT current branch and status
2. DECIDE: feature branch or direct commit?
3. WORK: Implement with skills
4. VALIDATE: Run tests, lint, build
5. COMMIT: Conventional commit message
6. PUSH: To remote
7. VALIDATE SPEC: Check completion
8. PR: Create PR if needed
```

### Before ANY Commit
- [ ] Tests pass
- [ ] Code follows patterns (loaded skills)
- [ ] No secrets in code
- [ ] Commit message follows convention

## SESSION FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTOMATIC SESSION FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. DETECT ──────────────────────────────────────────────      │
│     ├─ Detect project (go.mod, package.json, etc.)              │
│     ├─ Detect stack (Go, Angular, React, etc.)                 │
│     ├─ Check git status & branch                                │
│     ├─ Check engram memory (mem_context)                        │
│     └─ Load git-workflow-skill                                  │
│                                                                   │
│  2. ASSESS ──────────────────────────────────────────────      │
│     ├─ Analyze project structure                                │
│     ├─ Identify gaps (tests, docs, CI/CD)                       │
│     └─ List available skills                                   │
│                                                                   │
│  3. LOAD SKILLS ─────────────────────────────────────────      │
│     ├─ Load stack-specific skills                               │
│     └─ Load git-workflow-skill                                  │
│                                                                   │
│  4. PRESENT STATUS ──────────────────────────────────────      │
│     ├─ Project, stack, skills                                  │
│     ├─ Git branch & status                                     │
│     ├─ Pending tasks                                           │
│     └─ Next step                                               │
│                                                                   │
│  5. EXECUTE ─────────────────────────────────────────────      │
│     ├─ Work with loaded skills                                 │
│     ├─ Update todos                                            │
│     └─ Verify each step                                        │
│                                                                   │
│  6. VALIDATE SPEC ──────────────────────────────────────       │
│     ├─ Run tests                                               │
│     ├─ Check all items completed                               │
│     └─ Verify against acceptance criteria                      │
│                                                                   │
│  7. END SESSION ─────────────────────────────────────────      │
│     ├─ Commit changes (if any)                                  │
│     ├─ Push (if requested)                                      │
│     ├─ Ask: Create PR?                                         │
│     ├─ mem_save session summary                                │
│     └─ Present completion summary                               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## SPECIFICATION VALIDATION

Before creating PR, ALWAYS validate:

### Checklist
- [ ] All planned features implemented
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes without notice
- [ ] CI/CD passes
- [ ] Code follows project conventions

### Questions to Ask User
```
¿Cumplimos con la especificación?
¿Creamos PR o subimos directo a main?
¿Hay algo más que agregar?
```

## AUTO-DETECTION RULES

### Stack Detection

| File Found | Stack | Skills to Load |
|------------|-------|----------------|
| `go.mod` | Go | golang-api-skill, testing-skill |
| `package.json` (Angular) | Angular | angular-spa-skill, angular-core |
| `package.json` (Next) | Next.js | nextjs-15-skill |
| `package.json` (React) | React | react-19-skill, tailwind-4-skill |
| `requirements.txt` | Python/Django | django-drf-skill |
| `Cargo.toml` | Rust | (no skill yet) |

### Project Structure Detection

| File/Directory | Meaning |
|----------------|---------|
| `.github/workflows/` | CI/CD configured |
| `tests/` or `*_test.go` | Testing exists |
| `docs/` | Documentation exists |
| `AGENTS.md` | AI agent configured |
| `.skills/` | Foundation linked |
| `docker-compose.yml` | Containerization |

### Gap Detection

| Missing | Priority | Action |
|---------|----------|--------|
| No README | HIGH | Create README.md |
| No AGENTS.md | HIGH | Create AGENTS.md |
| No CI/CD | HIGH | Add workflows |
| No tests | MEDIUM | Add tests |
| No docs structure | MEDIUM | Create docs/ |
| No .skills/ | HIGH | Link foundation |

## SKILL LOADING GUIDE

### Always Load
- `git-workflow-skill` - Git best practices

### When Detecting Stack, Load:
```
IF Go detected:
   → golang-api-skill
   → testing-skill

IF Angular detected:
   → angular-spa-skill
   → angular-core
   → tailwind-4-skill

IF React detected:
   → react-19-skill
   → tailwind-4-skill
   → zustand-5-skill

IF Django detected:
   → django-drf-skill
```

## WORKFLOW COMMANDS

| User Says | AI Does |
|-----------|---------|
| *(nothing - just start)* | Auto-detect, assess, load skills, show status |
| "Continuar" | Resume work, check mem_context, show next step |
| "Estado" | Show current status, todos, next step |
| "Guardar" | Commit & push, mem_save summary |
| "PR" | Validate spec, create PR |
| "Nuevo proyecto" | Start new project workflow |

## SESSION START TEMPLATE

```markdown
## Session Started

**Project:** [project-name]
**Branch:** [current-branch]
**Stack:** [Go / Angular / React / etc.]
**Skills Loaded:** [list]

**Status:**
- ✅ [Already done]
- ⏳ [In progress]
- 📋 [Pending]

**Git Status:**
- Branch: [branch-name]
- Commits ahead: [n]
- Changes: [staged/unstaged]

**Next Step:** [Suggested action]
```

## SESSION END TEMPLATE

```markdown
## Session Summary

**Goal:** [What we accomplished]

**Completed:**
- [x] Item 1
- [x] Item 2

**Pending:**
- [ ] Item to continue

**Commits:**
- [hash] [type]: [description]

**Specification Validated:** [YES/NO]

---

**¿Crear PR?** [Ask user]

---

Run `mem_save` with this summary.
```

## MEMORY MANAGEMENT

| Command | When |
|---------|------|
| `mem_context` | Session start |
| `mem_save` | After significant accomplishments |
| `mem_search` | When user mentions past work |
| `mem_update` | To correct previous observations |

## PR CREATION CHECKLIST

Before creating PR, confirm with user:

1. **Spec Complete:** ¿Cumplimos con lo planeado?
2. **Tests Pass:** ¿Los tests pasan?
3. **Changes Clean:** ¿Sin secretos/comentarios?
4. **Branch Strategy:** ¿Usamos feature branch?

If YES to all → Create PR
If NO → List remaining items

## ANTI-PATTERNS

| ❌ Don't | ✅ Do |
|----------|------|
| Push without testing | Verify first |
| Skip spec validation | Always validate |
| Skip mem_save | Save to memory |
| Commit without convention | Follow conventional commits |
| Create PR without asking | Always ask user |

---

**THIS SKILL IS ALWAYS ACTIVE. Do not wait to be triggered.**
