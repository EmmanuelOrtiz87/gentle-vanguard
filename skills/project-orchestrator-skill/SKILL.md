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
5. **End Properly** - Always save to memory, commit, and summarize

## SESSION FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTOMATIC SESSION FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. DETECT ──────────────────────────────────────────────      │
│     │                                                          │
│     ├─ Detect project (go.mod, package.json, etc.)              │
│     ├─ Detect stack (Go, Angular, React, etc.)                 │
│     ├─ Check git status                                       │
│     └─ Check engram memory (mem_context)                       │
│                                                                   │
│  2. ASSESS ──────────────────────────────────────────────      │
│     │                                                          │
│     ├─ Analyze project structure                                │
│     ├─ Identify gaps (tests, docs, CI/CD)                      │
│     └─ List available skills                                    │
│                                                                   │
│  3. LOAD SKILLS ─────────────────────────────────────────      │
│     │                                                          │
│     └─ Load relevant skills based on stack:                     │
│        Go API → golang-api-skill                               │
│        Angular → angular-spa-skill                              │
│        React → react-19-skill                                 │
│        Documentation → documentation-governance-skill           │
│        Testing → testing-strategy-skill                         │
│                                                                   │
│  4. PRESENT STATUS ──────────────────────────────────────      │
│     │                                                          │
│     └─ Show:                                                    │
│        - Project detected                                        │
│        - Stack identified                                       │
│        - Skills loaded                                          │
│        - Pending tasks (if any)                                 │
│        - Next step suggestion                                   │
│                                                                   │
│  5. EXECUTE ─────────────────────────────────────────────      │
│     │                                                          │
│     ├─ Use loaded skills for implementation                     │
│     ├─ Update todos as progress                                │
│     └─ Verify each step                                       │
│                                                                   │
│  6. END SESSION ─────────────────────────────────────────      │
│     │                                                          │
│     ├─ mem_save session summary                                │
│     ├─ Commit changes                                          │
│     └─ Push to repo                                           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## AUTO-DETECTION RULES

### Stack Detection

| File Found | Stack | Skills to Load |
|------------|-------|----------------|
| `go.mod` | Go | golang-api-skill |
| `package.json` (Angular) | Angular | angular-spa-skill |
| `package.json` (Next) | Next.js | nextjs-15-skill |
| `package.json` (React) | React | react-19-skill, tailwind-4-skill |
| `requirements.txt` | Python/Django | django-drf-skill |
| `Cargo.toml` | Rust | (no skill yet) |
| `*.csproj` | C#/.NET | (no skill yet) |

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

### When Detecting Stack, Load:

```
IF Go detected:
   → Load golang-api-skill
   → Load testing-skill

IF Angular detected:
   → Load angular-spa-skill
   → Load tailwind-4-skill

IF React detected:
   → Load react-19-skill
   → Load tailwind-4-skill
   → Load zustand-5-skill

IF Django detected:
   → Load django-drf-skill

IF Documentation task:
   → Load documentation-governance-skill

IF Testing task:
   → Load testing-strategy-skill

IF CI/CD task:
   → Load docker-devops-skill
```

## WORKFLOW COMMANDS

These are the ONLY commands the user needs:

| User Says | AI Does |
|-----------|---------|
| *(nothing - just start)* | Auto-detect, assess, load skills, show status |
| "Continuar" | Resume work, check mem_context, show next step |
| "Estado" | Show current status, todos, next step |
| "Guardar" | mem_save summary, commit, push |
| "Nuevo proyecto" | Start new project workflow |

## SESSION START TEMPLATE

At session start, ALWAYS output:

```markdown
## Session Started

**Project Detected:** [project-name]
**Stack:** [Go / Angular / React / etc.]
**Skills Loaded:** [list of loaded skills]

**Status:**
- ✅ [Already done]
- ⏳ [In progress]
- 📋 [Pending]

**Next Step:** [Suggested next action]

---

[Proceed with work]
```

## SESSION END TEMPLATE

At session end, ALWAYS output:

```markdown
## Session Summary

**Goal:** [What we accomplished]

**Completed:**
- [ ] Item 1
- [ ] Item 2

**Next Steps:**
- [ ] Item to continue

**Skills Used:**
- skill-name

**Files Changed:**
- file-path - description

---

Run `mem_save` with this summary.
```

## MEMORY MANAGEMENT

Always use engram for persistence:

| Command | When |
|---------|-------|
| `mem_context` | Session start - check recent work |
| `mem_save` | After significant accomplishments |
| `mem_search` | When user mentions past work |
| `mem_update` | To correct previous observations |

## SKILL INDEX

Master list of all skills:

| Category | Skills |
|----------|--------|
| Orchestrator | project-orchestrator, session-workflow |
| Frontend | angular-spa, react-19, nextjs-15, tailwind-4 |
| State | zustand-5 |
| Validation | zod-4 |
| Backend | golang-api, api-design, django-drf |
| Database | database-relational, database-nosql |
| DevOps | docker-devops |
| Testing | testing-strategy, testing-skill |
| AI | ai-sdk-5, mcp-skill |
| Workflow | github-pr, jira-task, jira-epic |
| Quality | typescript, code-review, security |
| Governance | project-scaffolding, documentation, architecture, git-workflow, foundation-manager |

## ANTI-PATTERNS

Never do these:

| ❌ Don't | ✅ Do |
|----------|------|
| Start without assessing | Auto-detect context first |
| Implement without skills | Load relevant skills first |
| Skip memory | Always mem_save at end |
| Push without verifying | Verify before push |
| Work without todos | Use todowrite to track |

## QUICK REFERENCE

```
SESSION START:
  1. Detect project/stack
  2. mem_context
  3. Load skills
  4. Show status

DURING SESSION:
  1. Use skills for implementation
  2. Update todowrite
  3. Verify before moving on

SESSION END:
  1. mem_save summary
  2. Commit changes
  3. Push if ready
```

---

**THIS SKILL IS ALWAYS ACTIVE. Do not wait to be triggered.**
