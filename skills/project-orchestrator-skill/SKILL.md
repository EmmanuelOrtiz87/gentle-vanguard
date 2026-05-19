---
name: project-orchestrator
description:
  'Trigger: session start, project setup, orchestration, repository governance, iniciar sesion.
  Master orchestrator for coordinated sessions: stack detection, skill loading, workflow management,
  and session activation.'
---

## Activation Contract

ALWAYS ACTIVE. Loads on every session for coordination, stack detection, skill loading, and workflow
governance. Do not wait to be triggered.

## Hard Rules

- MUST execute pre-process-input.ps1 BEFORE every user response
- MUST load triggered skill before any other action
- MUST use Engram for durable memory (not session-only state)
- MUST run `gv.ps1 ide-status` -> `gv.ps1 health` -> `gv.ps1 start-session` on session start
- MUST validate spec before PR merge
- MUST generate audit document before push
- MUST NOT modify repository structure without explicit user approval
- MUST stop and notify on ambiguity before proceeding

## Communication Mode

Default: executive. Override via config/orchestrator.json.

- simple: "OK: <result>" / "ERROR: <cause> | ACTION: <step>"
- Escalate to standard/deep only for medium/high risk or explicit request.

## Decision Gates

| Gate             | Condition             | Action                                         |
| ---------------- | --------------------- | ---------------------------------------------- |
| Pre-processing   | Trigger match?        | Load skill immediately                         |
| Pre-processing   | No match?             | Continue normal behavior                       |
| Session state    | START                 | Detect IDE, refresh artifacts, capture context |
| Session state    | EXECUTE               | Apply changes under loaded skills              |
| Session state    | VALIDATE              | Run governance and targeted checks             |
| Session state    | AUDIT                 | Persist durable learnings to Engram            |
| Session state    | PUBLISH               | Commit, push, create PR                        |
| Session state    | HANDOFF               | Compact-start before new thread                |
| Structure change | Existing conventions? | Adopt as-is, do not refactor                   |
| Structure change | Greenfield repo?      | Enforce canonical rules                        |

## Execution Steps

1. Pre-process user input via pre-process-input.ps1
2. Detect stack from project files (go.mod, package.json, etc.)
3. Load skills matching detected stack
4. Execute work using session state machine (START -> EXECUTE -> VALIDATE -> AUDIT -> PUBLISH ->
   HANDOFF)
5. Validate acceptance criteria before PR
6. Generate audit document before push
7. Save durable learnings to Engram
8. Close with session summary

## Output Contract

Return session status: project, branch, stack, loaded skills, next step. For substantive changes:
audit document + session summary persisted to Engram.

## References

- `references/auto-detection.md` — Stack detection rules and skill mapping
- `references/session-state-machine.md` — Full session workflow and activation strategy
- `references/protocols.md` — All protocols (rollback, token budget, guardian, SDD, etc.)
- `references/templates.md` — Session start/end and audit templates
- `references/agent-mapping.md` — Agent-to-dimension mapping
- `references/code-review.md` — 7-dimension review protocol and findings workflow
