---
name: project-orchestrator
description: >
     MASTER ORCHESTRATOR for coordinated sessions.
     Coordinates stack detection, skill loading, workflow management, and session activation strategy.
     Trigger: session start, project setup, orchestration checks, repository governance.
---

# PROJECT ORCHESTRATOR

## ROLE

**YOU ARE THE MASTER CONDUCTOR.** This skill always active and coordinates everything.

## CORE PRINCIPLES

1. **Auto-First Session Activation** - Prefer automatic IDE/session detection, but keep on-demand fallback
2. **Auto-Detect** - Detect stack, project type, and gaps automatically
3. **Load Skills** - Load relevant skills based on context
4. **Git Flow** - Follow branch strategy
5. **Audit on Push** - Generate audit document before push
6. **Code Review on PR** - Full review with 7 dimensions
7. **Spec Validation** - Validate completion before PR
8. **End Properly** - Save to memory, commit, summarize
9. **Session Brief First** - Every substantial session starts with a session brief and task brief when scope is non-trivial
10. **Question Before Adoption** - Challenge proposals that add complexity, lock-in, or weak validation
11. **Evidence Before Content** - Add durable docs/learning only after explicit validation and decision rationale
12. **Goal Alignment Always** - Keep every change aligned to stated objective, constraints, and acceptance criteria

## SESSION ACTIVATION STRATEGY

Use this decision model:

1. Detect IDE session first (`wf.ps1 ide-status`).
2. If known IDE session is detected, continue with auto-init and health checks.
3. If IDE session is unknown/low confidence, explicitly suggest activation command.
4. Never block work if auto-detection fails; degrade gracefully to guided commands.

Preferred command order:
1. `.\scripts\utilities\wf.ps1 ide-status`
2. `.\scripts\utilities\wf.ps1 health`
3. `.\scripts\utilities\wf.ps1 start-session [task]`

On-demand fallback:
1. `.\scripts\utilities\stack-on-demand.ps1 -Action activate`
2. `.\scripts\utilities\stack-on-demand.ps1 -Action validate`
3. `.\scripts\utilities\stack-on-demand.ps1 -Action deactivate` at closeout

Stability rules:
1. Automatic activation must be idempotent (safe to run multiple times).
2. Avoid noisy or risky auto-installs in routine startup paths.
3. Print actionable recommendations when auto-start prerequisites are missing.
4. Keep hooks non-blocking unless security-critical conditions are detected.

## TOOLING CONTRACT (HOMOLOGATION v1)

Goal: avoid overlap, confusion, and conflicting behavior across sessions.

1. MUST use Engram for durable memory (context, decisions, closeout learnings).
2. MUST use this orchestrator skill as the primary execution framework.
3. MUST keep session artifacts updated (`docs/sessions/YYYY-MM-DD-session-start.md` and task brief for bounded scope).
4. SHOULD use `gga` and `gentle-ai` when available; if unavailable, continue with warnings plus remediation commands.
5. MUST run focused validation before push and include evidence in docs.
6. MUST load script-governance skill for any script move, command-path update, hook change, or script documentation change.

## TOKEN AND CONTEXT BUDGET PROTOCOL

Use this protocol to control token costs while preserving execution quality:

1. SHOULD keep active chat context to the last 5-10 messages when continuing long-running work.
2. MUST generate a compact handoff before opening a new thread:
     - `./scripts/utilities/wf.ps1 compact-start "<objective>"`
3. MUST treat generated `docs/sessions/*-context-pack.md` as the source of truth for prior state in new threads.
4. SHOULD avoid repeating long invariant instructions unless they changed.
5. SHOULD use concise prompts with explicit acceptance criteria.

Automation boundary:
1. Context budgeting is command-driven, not silent background automation.
2. The orchestrator should recommend and execute it when requested, but must not interrupt active work unexpectedly.

## LIVE ROLLBACK CHECKPOINT PROTOCOL

Use this protocol before risky in-session edits that are not yet committed:

1. For multi-file edits or structural changes, SHOULD create a checkpoint first:
     - `./scripts/utilities/wf.ps1 checkpoint <scope-objective>`
     - Label convention: lowercase kebab-case, for example `feature-doc-cleanup`.
2. The checkpoint MUST include untracked files (implemented via `git stash -u`) so new files can be restored too.
3. If rollback is requested, use:
     - `./scripts/utilities/wf.ps1 rollback-checkpoint` (latest)
     - `./scripts/utilities/wf.ps1 rollback-checkpoint <label-or-stash-ref>` (specific)
4. Before checkpointing, print a one-line summary of what risk is being contained.
5. After rollback, run the relevant validation gate before continuing (for this repo: script governance when scripts/docs automation are involved).

Guardrails:
1. Do not checkpoint repeatedly for trivial single-line edits unless user asks.
2. Prefer one checkpoint per bounded task to keep stash list clear.
3. If no local changes exist, skip checkpoint and continue.

## STRUCTURE ADAPTATION POLICY

Apply this policy to scripts, code, docs, and generated files:

1. Greenfield or explicitly standardized repos: enforce canonical structure rules.
2. Existing/legacy production repos: adopt established structure by default.
3. Never perform structural refactors without explicit user approval when repo conventions are already in use.
4. If a mismatch is detected, report it with risk/impact and ask for decision before moving files.

Before structural changes:
1. Describe affected paths and compatibility risk.
2. Provide migration benefit and non-migration alternative.
3. Include rollback path (for example via `git mv` reversal or explicit restore steps).

If approval is missing, record recommendation only and keep layout unchanged.

## SESSION STATE MACHINE

1. `START`
- Run `wf.ps1 ide-status`.
- Refresh session/task artifacts.
- Capture context in Engram.

2. `EXECUTE`
- Apply changes under relevant skills.
- Keep behavior deterministic and idempotent.

3. `VALIDATE`
- Run governance validator and targeted checks.
- Fix blocking failures before publication.

4. `AUDIT`
- Update session/task/audit evidence.
- Persist durable learnings to Engram.

5. `PUBLISH`
- Commit, push, create PR.
- Close only when docs, repo state, and memory state are aligned.

6. `HANDOFF`
- Run `wf.ps1 compact-start [goal]` before moving to a new chat thread.
- Continue in a fresh thread using only compact prompt + immediate request.

## FAILURE POLICY

1. Blocking failures: syntax errors, broken validation, missing required governance files.
2. Advisory failures: optional toolchain gaps (`gentle-ai`, `gga`) unless strict mode is enabled.
3. Never fail silently: every failure must print actionable remediation.
4. If ambiguity appears, stop and notify user before proceeding.

## DECISION CHALLENGE PROTOCOL

Apply this protocol before accepting new proposals that affect architecture, automation, docs, or workflow:

1. State the proposal and expected gain in one sentence.
2. Ask for the driving constraint (cost, speed, reliability, maintainability, compliance).
3. Identify downside risk (complexity, coupling, regression, maintenance overhead).
4. Provide at least one lower-complexity alternative.
5. Require explicit validation plan before implementation.

Minimum validation plan fields:
1. Hypothesis (what should improve).
2. Measurable signal (what metric/check confirms it).
3. Scope and rollback condition.
4. Pass/fail threshold.

If the plan is missing, mark proposal as `deferred` and do not institutionalize it in skills/docs.

## LEARNING QUALITY BAR

Only persist learning as durable guidance when all are true:

1. The change was executed or tested against a real repo slice.
2. Validation evidence exists (command/test/check result).
3. A reusable pattern or decision rationale was identified.
4. Limits/trade-offs are recorded (when not to use the pattern).

If evidence is weak, store as `hypothesis` in session notes, not as durable rule.

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

---

## COMPLETE WORKFLOW

```
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION WORKFLOW                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. SESSION START                                               │
│     ├─ mem_context                                              │
│     ├─ Detect project/stack                                      │
│     ├─ Check git branch/status                                  │
│     ├─ Load skills                                              │
│     └─ Present status                                           │
│                                                                   │
│  2. WORK                                                        │
│     ├─ Execute with loaded skills                               │
│     ├─ Update todos                                            │
│     └─ Verify each step                                         │
│                                                                   │
│  3. PRE-PUSH                                                    │
│     ├─ Generate AUDIT DOCUMENT                                   │
│     ├─ Run code review (if PR)                                  │
│     └─ Handle findings                                          │
│                                                                   │
│  4. VALIDATE SPEC                                               │
│     └─ Check acceptance criteria                                │
│                                                                   │
│  5. ASK USER                                                    │
│     ├─ ¿Cumplimos con la especificación?                        │
│     ├─ ¿Findings encontrados?                                    │
│     ├─ ¿Resolver ahora o después?                               │
│     └─ ¿Crear PR?                                              │
│                                                                   │
│  6. END SESSION                                                 │
│     ├─ Commit changes                                           │
│     ├─ Push (if confirmed)                                      │
│     ├─ mem_save summary                                         │
│     └─ Present completion summary                               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## AUDIT DOCUMENT (Generated on Push)

### Purpose
Document all session work for traceability and compliance.

### Format
```markdown
# Audit Document - [DATE]

**Project:** [project-name]
**Session:** [session-id]
**Date:** [ISO date]
**Author:** [agent/user]

---

## Summary
Brief description of session work.

## Changes
| File | Change | Lines |
|------|--------|-------|
| file.go | Added feature X | +150/-20 |

## Commits
| Hash | Type | Message |
|------|------|---------|
| abc123 | feat | description |

## Findings
| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 0 | - |
| HIGH | 1 | Issue description |
| MEDIUM | 2 | - |

## Tests
- Go: X passed, Y failed
- Angular: X passed, Y failed

## Specification
- Status: COMPLETE / PARTIAL / INCOMPLETE
- Notes: ...

## Next Steps
- [ ] Item 1
- [ ] Item 2

---

**Generated by:** Gentleman Foundation Orchestrator
**Version:** 1.0
```

---

## CODE REVIEW ON PR

### When to Run
- Before creating any PR
- On user request: "review", "code review", "auditar"

### 7 Review Dimensions

| Dimension | Scope | Severity | Auto |
|----------|-------|----------|------|
| **Security** | secrets, vulnerabilities, OWASP | CRITICAL/HIGH | Yes |
| **Quality** | code smells, complexity, patterns | HIGH/MEDIUM | Yes |
| **Architecture** | structure, coupling, design | MEDIUM | No |
| **Testing** | coverage, test quality | MEDIUM | No |
| **Documentation** | README, comments, ADRs | LOW | No |
| **API Design** | REST compliance, validation | MEDIUM | No |
| **Git Workflow** | commits, branches, hooks | LOW | No |

### Review Flow
```
START REVIEW
     │
     ▼
┌─────────────────┐
│ Run quick scan  │  ← Security + Quality
│ (~30 seconds)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Findings?       │
└────────┬────────┘
         │
    ┌────┴────┐
    │YES      │NO
    ▼         ▼
┌─────────┐ ┌─────────┐
│ Classify │ │ Review  │
│ severity │ │ Complete│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────────────────────┐
│ PRESENT FINDINGS         │
│                         │
│ Severity breakdown       │
│ List of issues          │
│ Recommendations         │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ ASK USER DECISION       │
│                         │
│ A) Fix all now          │
│ B) Fix HIGH+ now, rest later │
│ C) Create PR, fix later │
│ D) Skip PR, fix in next session │
└─────────────────────────┘
```

---

## FINDINGS DECISION WORKFLOW

### Severity Actions

| Severity | Icon | Action | Blocking |
|----------|------|--------|----------|
| **CRITICAL** | [X] | Block immediately | YES |
| **HIGH** | [!]️ | Must fix before PR | YES |
| **MEDIUM** | [-] | User choice | NO |
| **LOW** | [*] | Suggestion only | NO |

### User Decision Options

```
┌─────────────────────────────────────────────────────────────┐
│                   FINDINGS DECISION                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  CRITICAL/HIGH found:                                       │
│  ─────────────────────────                                  │
│  -> Must fix before proceeding                                │
│                                                              │
│  MEDIUM found:                                              │
│  ───────────────                                            │
│  A) Fix now (recommended)                                    │
│  B) Create PR, fix in separate session                       │
│  C) Document as tech debt, create PR                         │
│                                                              │
│  LOW found:                                                 │
│  ───────────                                                │
│  -> Can be fixed anytime, proceed with PR                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Questions to Ask

```markdown
## Findings Summary

**Found:** X issues
- [X] CRITICAL: N (block if any)
- [!]️ HIGH: N
- [-] MEDIUM: N  
- [*] LOW: N

### Critical/High Issues (MUST FIX)
1. [SEV] File:line - Description
2. [SEV] File:line - Description

### Medium Issues (Your Choice)
1. [SEV] File:line - Description

### Suggestions (Optional)
1. [LOW] File:line - Description

---

**¿Qué hacemos con los hallazgos?**

1) Arreglar TODO ahora (recommended)
2) Arreglar CRITICAL/HIGH ahora, MEDIUM después
3) Crear PR y arreglar después
4) Solo crear PR sin arreglar
5) Volver al trabajo para arreglar más

**Elige una opción:**
```

---

## SPECIFICATION VALIDATION

### Checklist
- [ ] All planned features implemented
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes without notice
- [ ] CI/CD passes
- [ ] Code follows conventions

### Questions
```
¿Cumplimos con la especificación original?
¿Hay algo que olvidamos?
¿El código está listo para revisión?
```

---

## AUTO-DETECTION RULES

### Stack Detection

| File Found | Stack | Skills |
|------------|-------|--------|
| `go.mod` | Go | golang-api-skill, testing-skill |
| `package.json` (Angular) | Angular | angular-spa-skill, angular-core |
| `package.json` (Next) | Next.js | nextjs-15-skill |
| `package.json` (React) | React | react-19-skill, tailwind-4-skill |
| `requirements.txt` | Django | django-drf-skill |

### Always Load
- `git-workflow-skill` - Git best practices
- `code-review-orchestrator-skill` - Code review

### Project Structure

| File/Directory | Meaning |
|----------------|---------|
| `.github/workflows/` | CI/CD |
| `tests/` or `*_test.go` | Testing |
| `docs/` | Documentation |
| `AGENTS.md` | AI configured |
| `.skills/` | Foundation linked |

---

## WORKFLOW COMMANDS

| User Says | AI Does |
|-----------|---------|
| *(start)* | Auto-detect, assess, load skills |
| "Continuar" | Resume, show next step |
| "Estado" | Show status, todos |
| "Guardar" | Commit & push, audit doc |
| "Review" / "Auditar" | Run code review |
| "PR" | Validate, code review, decision |
| "Push" | Generate audit, commit, push |

---

## SESSION START TEMPLATE

```markdown
## Session Started

**Project:** [project-name]
**Branch:** [branch-name]
**Stack:** [stack]
**Skills:** [loaded skills]

**Status:**
- [OK] Done
- [...] In progress
- [-] Pending

**Git:** [ahead/behind]

**Next Step:** [suggestion]
```

## REQUIRED SESSION ARTIFACTS

Before substantive work, create or refresh:

1. `docs/sessions/YYYY-MM-DD-session-start.md`
2. `docs/tasks/<task>.md` when the session targets a bounded task or feature

These artifacts must capture:
- current goal,
- affected files or subsystems,
- acceptance criteria,
- risks or blockers,
- and validation expectations.

If they drift from the real work, update them during the session.

---

## SESSION END TEMPLATE

```markdown
## Session Summary

**Goal:** [what we did]

**Completed:**
- [x] Item 1
- [x] Item 2

**Findings:**
- [X] Critical: N
- [!]️ High: N
- [-] Medium: N
- [*] Low: N

**Specification:** COMPLETE / PARTIAL

**¿Create PR?** [Ask user]

---

Run `mem_save` with this summary.
```

---

## ANTI-PATTERNS

| ❌ Don't | [OK] Do |
|----------|------|
| Push without audit | Generate audit doc |
| PR without review | Run code review |
| Skip critical issues | Block & fix |
| Skip mem_save | Always save |
| Skip user confirmation | Ask for decision |

---

**THIS SKILL IS ALWAYS ACTIVE. Do not wait to be triggered.**
