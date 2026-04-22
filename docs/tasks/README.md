# Task Briefs

This directory contains task briefs that provide context, scope, and acceptance criteria for development work.

## Purpose

Task briefs serve as lightweight documentation for development tasks, capturing essential information that helps maintain focus and alignment during implementation.

## Directory Structure

```
tasks/
├── [task-name].md             # Individual task briefs
└── TASK-BRIEF-TEMPLATE.md     # Template for new task briefs
```

## Task Brief Components

Each task brief should include:

1. **Goal** - Clear problem statement and desired outcome
2. **Scope** - What's in scope and out of scope
3. **Key Files** - Primary files to work with
4. **Acceptance Criteria** - Conditions for completion
5. **Risks** - Known technical or workflow risks
6. **Status** - Current state and next steps
7. **Future Release Backlog** - Items deferred to future releases

## When to Create a Task Brief

- For any significant work that spans multiple sessions
- When tackling complex problems requiring detailed planning
- For tasks that others might need to understand or take over
- As part of the session workflow (`wf.ps1 start-session [task-name]`)

## Creating New Task Briefs

Use the template [TASK-BRIEF-TEMPLATE.md](../supplementary/TASK-BRIEF.template.md) as a starting point for new task briefs.

You can also generate a task brief using the workflow CLI:
```powershell
.\scripts\utilities\wf.ps1 task-brief <task-name>
```

## Current Task Briefs

### Active Development
- [foundation-session-hardening.md](foundation-session-hardening.md) - Task brief for governance improvements
- [chat-baseline-architecture-validation.md](chat-baseline-architecture-validation.md) - Chat architecture validation task

### Templates
- [TASK-BRIEF-TEMPLATE.md](../supplementary/TASK-BRIEF.template.md) - Template for new task briefs

## Related Documentation

- [Session Guide](../guides/SESSION-GUIDE.md)
- [Development Workflow](../guides/DEVELOPMENT-WORKFLOW.md)
- [Specification Driven Development](../sdd/README.md)