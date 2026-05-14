## SDD Enforcement Policy

Current baseline:

1. SDD is active and handled by the orchestrator as part of normal workflow
2. New feature work should be spec-first (`docs/sdd/*`) before implementation
3. Spec validation is required before PR merge when feature behavior changes

Recommended policy:

1. Treat SDD as mandatory for all net-new features and behavior changes
2. Allow hotfix/incident exception only with a mini-spec written before merge
3. Require evidence in PR: spec file path, acceptance criteria status, validation evidence, final
   spec status

Role split: Orchestrator is source of truth for process and enforcement decisions.

Reference: `docs/reference/SDG-GOVERNANCE-POLICY.md`

## Tooling Contract

1. MUST use Engram for durable memory (context, decisions, closeout learnings)
2. MUST use this orchestrator skill as the primary execution framework
3. MUST keep session artifacts updated (`docs/sessions/YYYY-MM-DD-session-start.md` and task brief)
4. SHOULD use available native skills; if unavailable, continue with warnings plus remediation
   commands
5. MUST run focused validation before push and include evidence in docs
6. MUST load script-governance skill for any script move, command-path update, hook change, or
   script documentation change

## Skill Distribution Model

1. Foundation is the source of truth for skills
2. Skills maintained natively in `skills/<skill-name>/SKILL.md`
3. Publication: update in Foundation, commit/publish, consumers run `wf.ps1 foundation-sync apply`
4. Activation: on-demand — orchestrator loads only skills needed by current task
5. New skills must be reflected in: `skills/SKILL_INDEX.md`, orchestrator stack mapping, consumer
   sync manifest

## Token and Context Budget Protocol

1. SHOULD keep active chat context to last 5-10 messages for long-running work
2. MUST generate compact handoff before opening new thread: `wf.ps1 compact-start "<objective>"`
3. MUST treat generated `docs/sessions/*-context-pack.md` as source of truth in new threads
4. SHOULD avoid repeating long invariant instructions unless changed
5. SHOULD use concise prompts with explicit acceptance criteria

Automation: context budgeting is command-driven, not silent background automation.

## Live Rollback Checkpoint Protocol

For risky in-session edits not yet committed:

1. Create checkpoint: `wf.ps1 checkpoint <scope-objective>` (label: lowercase kebab-case)
2. Checkpoint MUST include untracked files (`git stash -u`)
3. Rollback: `wf.ps1 rollback-checkpoint` (latest) or with label/stash-ref
4. Print one-line risk summary before checkpointing
5. After rollback, run relevant validation gate

Guardrails: no checkpoint for trivial single-line edits; one checkpoint per bounded task.

## Guardian Fallback Protocol

serves as optional fallback when Foundation cannot proceed autonomously.

Architecture: ORCHESTRATOR (primary) → self-healing → (optional) → manual intervention

| Condition         | Action               |
| ----------------- | -------------------- |
| Unknown error     | Invoke for diagnosis |
| Complex decision  | reasoning assist     |
| PR needs review   | ` run --pr-mode`     |
| Commit validation | commit-msg hook      |

Dependency: is enhancement, not requirement. Foundation operates fully without it.

## Decision Challenge Protocol

Before accepting proposals affecting architecture, automation, docs, or workflow:

1. State proposal and expected gain in one sentence
2. Ask for driving constraint (cost, speed, reliability, maintainability, compliance)
3. Identify downside risk (complexity, coupling, regression, maintenance)
4. Provide at least one lower-complexity alternative
5. Require explicit validation plan before implementation

Validation plan: hypothesis, measurable signal, scope/rollback condition, pass/fail threshold. If
plan is missing: mark as deferred, do not institutionalize.

## Deferred-Work Registry Protocol

1. Register deferred work in `docs/reference/FUTURE-FEATURES-BACKLOG.md`
2. One row per unique deferred scope (no duplicates)
3. Include date, value, status, and trigger-to-revisit
4. Require confirmation if ambiguous or redundant with existing items

## Global vs Repository Boundary Protocol

1. Global-level artifacts (workspace root) are coordination artifacts — not auto-published to repos
2. Repository-level artifacts follow normal PR workflow in their own repo
3. Cross-boundary changes: ask user before replicating

## Learning Quality Bar

Only persist learning as durable guidance when ALL are true:

1. Change was executed/tested against real repo slice
2. Validation evidence exists (command/test/check result)
3. Reusable pattern or decision rationale identified
4. Limits/trade-offs recorded (when NOT to use)

If evidence weak: store as hypothesis in session notes, not as durable rule.

## Reasoning Cache Protocol

At task start:

1. Extract 2-4 keywords from user request
2. Call `mem_search` scoped to current project
3. Load top match via `mem_get_observation` for full context
4. Call `mem_context` if task references recent session work
5. If no results: proceed normally

At task end:

1. Call `mem_save` for distinct items in structured format
2. Skip if task was trivial
3. Do not duplicate existing observations

Guardrails: search adds at most one round-trip; saving after user confirms completion.

## Structure Adaptation Policy

- Greenfield repos: enforce canonical structure rules
- Existing repos: adopt established structure
- Never perform structural refactors without explicit approval
- Before changes: describe affected paths, compatibility risk, migration benefit, rollback path
- If no approval: record recommendation only, keep layout unchanged

## Failure Policy

1. Blocking: syntax errors, broken validation, missing required governance files
2. Advisory: missing optional tools (unless strict mode)
3. Never fail silently: every failure must print actionable remediation
4. If ambiguity: stop and notify user before proceeding

## Anti-Patterns

| Don't                  | Do                 |
| ---------------------- | ------------------ |
| Push without audit     | Generate audit doc |
| PR without review      | Run code review    |
| Skip critical issues   | Block and fix      |
| Skip mem_save          | Always save        |
| Skip user confirmation | Ask for decision   |

## Workflow Commands

| User Says                                       | AI Does                          |
| ----------------------------------------------- | -------------------------------- |
| (start)                                         | Auto-detect, assess, load skills |
| "Continuar"                                     | Resume, show next step           |
| "Estado"                                        | Show status, todos               |
| "Guardar"                                       | Commit and push, audit doc       |
| "Review" / "Auditar"                            | Run code review                  |
| "PR"                                            | Validate, code review, decision  |
| "Push"                                          | Generate audit, commit, push     |
| "Judgment Day" / "Juicio Final" / "Dual Review" | Run adversarial review           |
