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
2. **MANDATORY Pre-Processing** - BEFORE ANY user input response:
   - Execute: `powershell -File tools/pre-process-input.ps1 -UserInput "USER_INPUT" -WorkspaceRoot "."`
   - If TRIGGER_MATCH_FOUND  Load skill using `skill` tool BEFORE any other action
   - If NO_TRIGGER_MATCH  Continue with normal behavior
   - This applies to ALL tools: opencode, cline, cursor, windsurf, continue.dev, claude, copilot
3. **Session Startup** - On "iniciar sesion" or session start:
   - Load `session-workflow-skill` automatically
   - Execute `tools/session-autostart.cmd` (Windows) or `bash ./tools/session-autostart.sh` (Linux/macOS)
   - This ensures notifications, optimizations, validations run automatically
4. **Auto-Detect** - Detect stack, project type, and gaps automatically
5. **Load Skills** - Load relevant skills based on context
6. **Git Flow** - Follow branch strategy
7. **Audit on Push** - Generate audit document before push
8. **Code Review on PR** - Full review with 7 dimensions
9. **Spec Validation** - Validate completion before PR
10. **End Properly** - Save to memory, commit, summarize
11. **Session Brief First** - Every substantial session starts with a session brief and task brief when scope is non-trivial
12. **Question Before Adoption** - Challenge proposals that add complexity, lock-in, or weak validation
13. **Evidence Before Content** - Add durable docs/learning only after explicit validation and decision rationale
14. **Goal Alignment Always** - Keep every change aligned to stated objective, constraints, and acceptance criteria

## COMMUNICATION MODE HOMOLOGATION

Use this policy to keep response verbosity deterministic and token-efficient.

1. Global default response mode is `executive`.
2. Local workspace can override mode through `config/orchestrator.json` using `communication_response_mode`.
3. Current local baseline is `simple`.
4. `simple` mode contract:
- success: `OK: closed` (or minimal verifiable result),
- failure: `ERROR: <brief cause> | ACTION: <minimum step>`.
5. Escalate to `standard`/`deep` only for medium/high risk or explicit developer request.

Validation and visibility:

1. `scripts/utilities/orchestrator-status.ps1` must report `communication_response_mode`.
2. `scripts/diagnostics/system-diagnostics.sh` should show orchestrator active state plus response mode.

Reference: `docs/guides/DEVELOPER-COMMUNICATION-POLICY.md`

## SDD ENFORCEMENT POLICY

Current policy baseline:

1. SDD is active and handled by the orchestrator as part of normal workflow.
2. New feature work should be spec-first (`docs/specs/*`) before implementation.
3. Spec validation is required before PR merge when feature behavior changes.

Recommended policy (normalized):

1. Treat SDD as mandatory for all net-new features and behavior changes.
2. Allow hotfix/incident exception only with a mini-spec written before merge.
3. Require evidence in PR:
- spec file path,
- acceptance criteria status,
- validation evidence (tests/checks),
- final spec status (`validated` or `done`).

Role split:

1. Orchestrator: source of truth for process and enforcement decisions.

Reference: `docs/reference/SDD-GOVERNANCE-POLICY.md`

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
4. SHOULD use available native skills; if unavailable, continue with warnings plus remediation commands.
5. MUST run focused validation before push and include evidence in docs.
6. MUST load script-governance skill for any script move, command-path update, hook change, or script documentation change.

## SKILL DISTRIBUTION MODEL (ON-DEMAND)

1. Foundation is the source of truth for skills.
2. Skills are maintained natively in `skills/<skill-name>/SKILL.md` and should not rely on external `references/` dependencies for core operation.
3. Publication flow:
- update skills in Foundation,
- commit and publish Foundation,
- consumers update by running `wf.ps1 foundation-sync apply`.
4. Activation model is on-demand:
- the orchestrator loads only the skills required by current task context,
- avoid loading full catalog by default.
5. Any new skill added to Foundation must be reflected in:
- `skills/SKILL_INDEX.md`,
- orchestrator stack/use-case mapping,
- consumer sync manifest when that consumer depends on shared skill updates.

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

## 7-DIMENSION CODE REVIEW PROTOCOL

Every substantial code review MUST cover all 7 dimensions. The orchestrator is responsible for ensuring complete coverage.

### The 7 Dimensions

| # | Dimension | Icon | Agent | Skills | Auto? |
|---|----------|------|-------|--------|-------|
| 1 | **Security** | [S] | AGENT-GOV | security-skill, security-expert-skill | Yes |
| 2 | **Quality** | [Q] | AGENT-DEV | typescript-skill, code-review-orchestrator | Yes |
| 3 | **Architecture** | [A] | AGENT-SAD | architecture-governance, api-design-skill | No |
| 4 | **Testing** | [T] | AGENT-QA | testing-skill, playwright-skill, pytest-skill | No |
| 5 | **Documentation** | [D] | AGENT-DOC | documentation-governance, README checks | No |
| 6 | **API Design** | [API] | AGENT-SAD | api-design-skill, golang-api-skill | No |
| 7 | **Git Workflow** | [G] | AGENT-GOV | git-workflow-skill, github-pr-skill | No |

### Agent-to-Dimension Mapping

```
ORCHESTRATOR
    
     AGENT-BA      BDD Scenarios, Requirements
    
     AGENT-SAD     [A] Architecture + [API] API Design
                        architecture-governance
                        api-design-skill
                        database-relational-skill
                        database-nosql-skill
    
     AGENT-DEV     [Q] Quality + Code Implementation
                        typescript-skill
                        code-review-orchestrator-skill
                        technical-debt-skill
                        security-skill (basic)
    
     AGENT-QA      [T] Testing + Validation
                        testing-strategy-skill
                        testing-skill
                        playwright-skill
                        pytest-skill
                        judgment-day (dual-review)
    
     AGENT-OPS     Infrastructure, CI/CD
                        docker-devops-skill
                        kubernetes-deployment
                        terraform-infrastructure
    
     AGENT-GOV     [S] Security + [G] Git Workflow
                        security-expert-skill
                        git-workflow-skill
                        observability-skill
                        incident-response-plan
    
     AGENT-DOC     [D] Documentation
                         documentation-governance
                         readme-standards
                         docs-structure
```

### Review Scope Commands

```powershell
wf review                # Full 7-dimension review
wf review --scope quick  # Security + Quality only (~30s)
wf review --scope full   # All 7 dimensions
wf review --scope security   # Dimension 1 only
wf review --scope quality   # Dimension 2 only
wf review --scope testing   # Dimension 4 only
```

### Mandatory Coverage Rules

1. **PRE-COMMIT**: Run `wf review --scope quick` (Security + Quality)
2. **PRE-MERGE**: Run `wf review --scope full` (all 7 dimensions)
3. **JUDGMENT DAY**: Invoke for adversarial dual-review before major releases

### Severity Matrix

| Level | Icon | Action | Exit Code |
|-------|------|--------|-----------|
| CRITICAL | [!C] | BLOCK commit | 1 |
| HIGH | [!H] | WARN + require review | 0 |
| MEDIUM | [!M] | INFO + log | 0 |
| LOW | [!L] | SUGGESTION | 0 |

See: `skills/code-review-orchestrator-skill/SKILL.md` for full implementation.

## GUARDIAN FALLBACK PROTOCOL

GGA (Gentleman Guardian Angel) serves as **optional fallback** when Foundation cannot proceed autonomously.

### Architecture

```
ORCHESTRATOR (Primary - Always Active)
    
     Can proceed?  Execute normally
    
     Blocked/Unknown?  Try self-healing
    
     Still blocked?  GGA FALLBACK (Optional Guardian)
            
             Code review assistance
             Decision support
             Task completion assist
             Commit hygiene
```

### Fallback Trigger Conditions

| Condition | Action |
|-----------|--------|
| Unknown error blocks progress | Invoke GGA for diagnosis |
| Complex decision needed | GGA reasoning assist |
| PR needs final review | `gga run --pr-mode` |
| Code review assistance | `invoke-ai-review.ps1` (native) OR `gga run` (fallback) |
| Commit validation | GGA commit-msg hook |

### Implementation

```powershell
# Check GGA availability
function Test-GgaAvailable {
    $gga = Get-Command gga -ErrorAction SilentlyContinue
    return ($null -ne $gga)
}

# Fallback decision tree
if (-not $canProceed) {
    # Step 1: Self-healing attempt
    $healed = Invoke-SelfHealing -Context $context
    
    if (-not $healed) {
        # Step 2: GGA fallback (optional)
        if (Test-GgaAvailable) {
            Write-Host "[ORCHESTRATOR] Invoking GGA guardian..."
            gga run --ci
        } else {
            # Step 3: Manual intervention flag
            Write-Warn "Blocked: GGA unavailable - manual intervention required"
            Flag-ForManualReview -Context $context
        }
    }
}
```

### Dependency Model

| Component | Required | Status |
|-----------|----------|--------|
| project-orchestrator | **YES** | Always active |
| invoke-ai-review.ps1 | **YES** | Native replacement |
| code-review-orchestrator | **YES** | 7-dimension review |
| **GGA (gga)** | **NO** | **Optional guardian** |

### Skill Loading Order

```
1. project-orchestrator         ALWAYS (master conductor)
2. session-workflow             On session start/end
3. context-engineering          On context operations
4. code-review-orchestrator     On review requests
5. guardian-fallback (GGA)      ONLY when blocked (optional)
```

### Key Principle

> **Foundation operates fully without GGA.** GGA is enhancement, not requirement.

See: `skills/guardian-fallback-skill/SKILL.md` for full protocol.

## FAILURE POLICY

1. Blocking failures: syntax errors, broken validation, missing required governance files.
2. Advisory failures: missing optional tools unless strict mode is enabled.
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

## DEFERRED-WORK REGISTRY PROTOCOL

Use this protocol whenever the user decides to postpone optimization, enhancement, or refactor work.

1. Register deferred work in `docs/reference/FUTURE-FEATURES-BACKLOG.md`.
2. Keep one row per unique deferred scope (no duplicates).
3. Include date, value, status, and trigger-to-revisit.

Confirmation is mandatory before registration if:

1. The deferred request is ambiguous.
2. The deferred request appears redundant with existing backlog items.

If ambiguity/redundancy exists, ask a short confirmation question and only then write/update the backlog.

Default behavior:

1. If clear and non-redundant: append backlog item automatically.
2. If clear and already tracked: update existing row instead of creating new one.

Reference: `docs/reference/FUTURE-FEATURES-BACKLOG.md`

## GLOBAL VS REPOSITORY BOUNDARY PROTOCOL

Use this protocol to keep workspace-global decisions and repository decisions separated without losing traceability.

1. Global-level artifacts (workspace root docs/process notes) are coordination artifacts and must not be auto-published into repository history.
2. Repository-level artifacts are implementation/governance artifacts and follow normal PR workflow in their own repository.

Replication checks are mandatory:

1. If a global artifact changes, ask the user whether any repository must receive a mirrored implementation change.
2. If a repository artifact changes, ask the user whether global workspace guidance must be updated to keep cross-repo consistency.

Decision outcomes:

1. Global only: keep change at workspace scope and do not replicate to repos.
2. Repo only: keep change in repository and do not modify workspace-global docs.
3. Both: apply in both places with explicit cross-reference.

If unclear or seemingly redundant, request user confirmation before writing either side.

Workspace reference: `c:/Workspace_local/docs/reference/WORKSPACE-FUTURE-FEATURES-BACKLOG.md`

## LEARNING QUALITY BAR

Only persist learning as durable guidance when all are true:

1. The change was executed or tested against a real repo slice.
2. Validation evidence exists (command/test/check result).
3. A reusable pattern or decision rationale was identified.
4. Limits/trade-offs are recorded (when not to use the pattern).

If evidence is weak, store as `hypothesis` in session notes, not as durable rule.

## REASONING CACHE PROTOCOL

Use Engram memory as a reasoning cache to avoid redundant analysis and preserve cross-session continuity.

### At Task Start (automatic)

1. Extract 2-4 keywords from the user's request (topic, feature name, file, technology).
2. Call `mem_search` with those keywords scoped to the current project.
3. If results are found:
   - Call `mem_get_observation` for the top match to load full context.
   - Use prior decisions, patterns, and gotchas as starting constraints.
   - State briefly what prior context was loaded so the user has visibility.
4. If no results are found:
   - Proceed normally; do not delay work waiting for context.
5. Also call `mem_context` if the task references recent session work (last 1-2 sessions).

### At Task End (automatic)

1. Identify key decisions, non-obvious learnings, and reusable patterns from the completed work.
2. Call `mem_save` for each distinct item using structured format:
   - **title**: verb + subject, searchable (e.g. "Chose retry strategy for HTTP client").
   - **type**: `decision` | `discovery` | `pattern` | `bugfix` | `architecture`.
   - **topic_key**: use `mem_suggest_topic_key` for evolving topics to enable upsert.
   - **content**: `What / Why / Where / Learned` structure.
3. Skip saving if the task was trivial (single-line fix, no decision made, no new pattern).
4. Do not duplicate observations already stored under the same `topic_key`.

### Guardrails

1. Search adds at most one tool round-trip; never block user-facing work for memory lookup.
2. Saving happens after the user confirms task completion, not mid-flight.
3. Respect the Learning Quality Bar: only persist validated, evidence-backed learnings.

## GIT FLOW WORKFLOW

### Branch Strategy
```
main (production)  hotfix/*
     
develop (integration)  release/*
     
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

                    SESSION WORKFLOW                                

                                                                   
  1. SESSION START                                               
      mem_context                                              
      Detect project/stack                                      
      Check git branch/status                                  
      Load skills                                              
      Present status                                           
                                                                   
  2. WORK                                                        
      Execute with loaded skills                               
      Update todos                                            
      Verify each step                                         
                                                                   
  3. PRE-PUSH                                                    
      Generate AUDIT DOCUMENT                                   
      Run code review (if PR)                                  
      Handle findings                                          
                                                                   
  4. VALIDATE SPEC                                               
      Check acceptance criteria                                
                                                                   
  5. ASK USER                                                    
      Did we meet the specification?                          
      Were any findings identified?                           
      Fix them now or later?                                  
      Create a PR?                                            
                                                                   
  6. END SESSION                                                 
      Commit changes                                           
      Push (if confirmed)                                      
      mem_save summary                                         
      Present completion summary                               
                                                                   

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
     
     

 Run quick scan     Security + Quality
 (~30 seconds)   

         
         

 Findings?       

         
    
    YES      NO
             
 
 Classify   Review  
 severity   Complete
 
                
                

 PRESENT FINDINGS         
                         
 Severity breakdown       
 List of issues          
 Recommendations         

             
             

 ASK USER DECISION       
                         
 A) Fix all now          
 B) Fix HIGH+ now, rest later 
 C) Create PR, fix later 
 D) Skip PR, fix in next session 

```

---

## FINDINGS DECISION WORKFLOW

### Severity Actions

| Severity | Icon | Action | Blocking |
|----------|------|--------|----------|
| **CRITICAL** | [X] | Block immediately | YES |
| **HIGH** | [!] | Must fix before PR | YES |
| **MEDIUM** | [-] | User choice | NO |
| **LOW** | [*] | Suggestion only | NO |

### User Decision Options

```

                   FINDINGS DECISION                         

                                                              
  CRITICAL/HIGH found:                                       
                                    
  -> Must fix before proceeding                                
                                                              
  MEDIUM found:                                              
                                              
  A) Fix now (recommended)                                    
  B) Create PR, fix in separate session                       
  C) Document as tech debt, create PR                         
                                                              
  LOW found:                                                 
                                                  
  -> Can be fixed anytime, proceed with PR                     
                                                              

```

### Questions to Ask

```markdown
## Findings Summary

**Found:** X issues
- [X] CRITICAL: N (block if any)
- [!] HIGH: N
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

**What should we do with the findings?**

1) Fix everything now (recommended)
2) Fix CRITICAL/HIGH now, MEDIUM later
3) Create the PR and fix them later
4) Only create the PR without fixing them
5) Go back to implementation and fix more

**Choose an option:**
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
Did we meet the original specification?
Did we forget anything?
Is the code ready for review?
```

---

## AUTO-DETECTION RULES

### Stack Detection

| File Found | Stack | Skills |
|------------|-------|--------|
| `go.mod` | Go | golang-api-skill, api-design-skill, testing-skill |
| `package.json` (Angular) | Angular | angular-spa-skill, testing-skill |
| `package.json` (Next) | Next.js | nextjs-15-skill, tailwind-4-skill |
| `package.json` (React) | React | react-19-skill, tailwind-4-skill |
| `pubspec.yaml` | Flutter | flutter-skill, testing-skill |
| `ios/` + `.swift` | iOS | ios-swift-development, ios-swiftui-patterns-skill |
| `android/` + `.kt` | Android | android-kotlin-skill, android-architecture-skill, android-jetpack-compose-skill |
| `requirements.txt` | Django/Python | django-drf-skill, pytest-skill |
| `*.tf` | Terraform | terraform-infrastructure |
| `k8s/*.yaml` or `helm/` | Kubernetes | kubernetes-deployment |

### Always Load
- `git-workflow-skill` - Git best practices
- `code-review-orchestrator-skill` - Code review
- `project-orchestrator-skill` - Task coordination and skill routing

### Project Structure

| File/Directory | Meaning |
|----------------|---------|
| `.github/workflows/` | CI/CD |
| `tests/` or `*_test.go` | Testing |
| `docs/` | Documentation |
| `AGENTS.md` | AI configured |
| `skills/` | Native Foundation skills catalog |

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
| "Judgment Day" / "Juicio Final" / "Revision de a Pares" / "Dual Review" | Run adversarial dual-review protocol |
| "Corre juicio" / "Ejecuta dia del juicio" / "Activa juicio" | Run judgment-day --scope judgment-day |

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
- [!] High: N
- [-] Medium: N
- [*] Low: N

**Specification:** COMPLETE / PARTIAL

**Create PR?** [Ask user]

---

Run `mem_save` with this summary.
```

---

## ANTI-PATTERNS

|  Don't | [OK] Do |
|----------|------|
| Push without audit | Generate audit doc |
| PR without review | Run code review |
| Skip critical issues | Block & fix |
| Skip mem_save | Always save |
| Skip user confirmation | Ask for decision |

---

**THIS SKILL IS ALWAYS ACTIVE. Do not wait to be triggered.**
