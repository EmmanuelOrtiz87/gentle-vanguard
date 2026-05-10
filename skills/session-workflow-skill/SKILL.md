---
name: session-workflow
description: >
  Trigger: "iniciar sesion", "guardar sesion", "continuar", "estado", "pr", "push", "review", "auditar". Session
  workflow executor handling session management mechanics. Coordinates with project-orchestrator for
  technical guidance.
---

# Session Workflow

## Activation Contract

Load when user triggers session commands: "iniciar sesion" / "start session", "continuar" /
"continue", "estado" / "status", "push" / "guardar", "review" / "auditar", or "PR" / "create PR".
Coordinates with project-orchestrator for technical decisions.

## Hard Rules

- MUST generate AUDIT DOCUMENT before any push
- MUST run code review before PR creation
- MUST create todowrite at session start
- MUST save session summary via mem_save after significant work
- MUST coordinate with project-orchestrator for technical guidance

## Decision Gates

| Command  | Trigger Words                     | Action                                                     |
| -------- | --------------------------------- | ---------------------------------------------------------- |
| Start    | "iniciar sesion", "start session" | Autostart, mem_context, git status, todowrite              |
| Continue | "continuar", "continue"           | mem_context, git status, show next step, resume            |
| Status   | "estado", "status"                | Show project, git branch/status, todos, suggest next       |
| Push     | "push", "guardar"                 | Review todos, generate audit doc, commit, push, mem_save   |
| Review   | "review", "auditar"               | Quick scan (Security + Quality), classify, present, decide |
| PR       | "pr"                              | Validate spec, run review, handle findings, create PR      |

## Execution Steps

1. **Start session**: `scripts/utilities/session-autostart.cmd` → `mem_context` → `git status` →
   `todowrite` → present status
2. **Continue session**: `mem_context` → `git status` → show next step → resume work
3. **Show status**: Show project info → git branch/status → todos → suggest next step
4. **Push / Guardar**: Review todos completed → generate audit doc → git status/diff → commit → push
   → mem_save summary
5. **Review / Auditar**: Run code review (7 dimensions) → classify findings by severity → present
   summary → ask decision options → execute choice
6. **Create PR**: Validate spec → run code review → handle findings → ask: met spec? → ask: create
   PR? → branch → commit → push → create PR with template

## Output Contract

- **Push**: Audit document + session summary + git commit/push + mem_save
- **Review**: Findings summary with severity classification (CRITICAL/HIGH/MEDIUM/LOW)
- **PR**: GitHub PR created with template
- **Session start**: todowrite + status presentation
- **Session summary**: Structured mem_save with goal, accomplishments, findings, next steps

## References

- Templates (audit doc, code review, session summary, todo): `references/templates.md`
- Scripts: `scripts/utilities/session-autostart.cmd`
- Coordination: `../project-orchestrator-skill/SKILL.md`
