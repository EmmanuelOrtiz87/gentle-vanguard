# subagent-driven-dev-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.

**Why subagents:** Delegate tasks to specialized agents with isolated context. Construct exactly what they need — they should never inherit your session's context or history. This preserves your context for coordination.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration.

**Continuous execution:** Do not pause to check in between tasks. Only stop for: BLOCKED status you cannot resolve, ambiguity preventing progress, or all tasks complete.

## When to Use

Use when you have an implementation plan with mostly independent tasks and you stay in the same session. For tightly coupled tasks, execute manually. For parallel sessions, use the executing-plans skill.

## The Process

1. **Read plan** — extract all tasks with full text and context, create TodoWrite
2. **Per task, dispatch implementer** (via implementer-prompt.md) — provide task text + context. Answer questions and re-dispatch if needed
3. **Implementer implements** — writes code, tests, commits, self-reviews, reports status
4. **Dispatch spec reviewer** (via spec-reviewer-prompt.md) — confirms code matches spec. If issues: implementer fixes, re-review
5. **Dispatch code quality reviewer** (via code-quality-reviewer-prompt.md) — if issues: implementer fixes, re-review
6. **Mark task complete** — proceed to next task
7. **After all tasks** — dispatch final code reviewer for entire implementation, then finishing-a-development-branch

## Model Selection

Use the least powerful model that can handle each role.

- **Mechanical** (1-2 files, complete spec) → fast/cheap model
- **Integration** (multi-file, coordination) → standard model
- **Architecture/design/review** → most capable model

## Handling Implementer Status

- **DONE** — proceed to spec compliance review
- **DONE_WITH_CONCERNS** — read concerns; address correctness/scope issues before review, or note observations and proceed
- **NEEDS_CONTEXT** — provide missing context and re-dispatch
- **BLOCKED** — context problem? re-dispatch; need more reasoning? upgrade model; task too large? split; plan wrong? escalate to human

## Red Flags

- Never start implementation on main/master without consent
- Never skip spec compliance or code quality review
- Never dispatch multiple implementers in parallel
- Never skip review loops (reviewer found issues = fix + re-review)
- Never accept "close enough" on spec compliance
- Never start code quality review before spec compliance is ✅
- Never move to next task while either review has open issues
- Answer subagent questions before letting them proceed
- Never ignore subagent escalations

## Prompt Templates

- `references/implementer-prompt.md`
- `references/spec-reviewer-prompt.md`
- `references/code-quality-reviewer-prompt.md`

## Integration

Requires: git-worktrees, writing-plans, requesting-code-review, finishing-a-development-branch.
Subagents should use test-driven-development.

## See Also

- `references/example-workflow.md` — full worked example
- `references/advantages.md` — detailed advantages breakdown
