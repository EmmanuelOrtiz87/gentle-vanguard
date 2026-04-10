---
name: session-workflow
description: >
  Session workflow orchestrator: guides complete session from start to finish.
  Trigger: "new session", "start work", "session workflow", "end session", "workflow".
---

# Session Workflow Skill

## Purpose

Ensure complete, documented sessions with proper use of skills, tools, and memory.

## Session Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION WORKFLOW                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. START ────► 2. ASSESS ────► 3. PLAN                       │
│       │               │               │                          │
│       ▼               ▼               ▼                          │
│  - Check context   - Detect stack   - Create todos            │
│  - Load memory     - Identify gaps   - Load skills              │
│  - Open engram     - Check skills   - Prioritize               │
│                                                                 │
│  4. EXECUTE ───► 5. VERIFY ────► 6. DOCUMENT                  │
│       │               │               │                          │
│       ▼               ▼               ▼                          │
│  - Use skills     - Run tests      - Save memory                │
│  - Implement       - Validate       - Commit changes            │
│  - Check progress  - Fix issues     - Push repo                 │
│                                                                 │
│  7. END ────────────────────────────────────────────            │
│       │                                                      │
│       ▼                                                      │
│  - mem_save summary                                         │
│  - Session review                                            │
│  - Next steps clear                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Step 1: START

At session start, ALWAYS:

```markdown
1. Check engram context
   - Call: mem_context or mem_search

2. Load relevant skills
   - project-orchestrator-skill (always)
   - domain-specific skills based on work

3. Create/update todo list
   - Use todowrite tool
```

## Step 2: ASSESS

Assess the work:

```markdown
## Assessment Checklist

- [ ] What project are we working on?
- [ ] What stack/technology?
- [ ] What's the goal?
- [ ] What's already done?
- [ ] What skills are needed?
```

## Step 3: PLAN

Plan before execution:

```markdown
## Plan

### Tasks (priority order)
1. [HIGH] Task 1
2. [MED] Task 2
3. [LOW] Task 3

### Required Skills
- skill1
- skill2

### Risks
- Risk 1
- Risk 2
```

## Step 4: EXECUTE

Execute with skills:

| Task Type | Skills to Load |
|-----------|---------------|
| New project | project-scaffolding, relevant-tech-skill |
| Go API | golang-api-skill |
| Angular | angular-spa-skill |
| React | react-19-skill, tailwind-4-skill |
| Documentation | documentation-governance |
| Testing | testing-strategy-skill |
| CI/CD | docker-devops-skill |
| Code review | code-review-orchestrator-skill |

## Step 5: VERIFY

Before finishing:

```markdown
## Verification Checklist

- [ ] Tests pass?
- [ ] Linting/formatting OK?
- [ ] Documentation updated?
- [ ] Changes committed?
- [ ] Repos pushed?
```

## Step 6: DOCUMENT

Document everything:

### Session Summary

```markdown
## Session Summary

### Goal
[What we were working on]

### Instructions
[User preferences or constraints]

### Discoveries
- [Technical findings]

### Accomplished
- [Completed items]

### Next Steps
- [Remaining work]

### Relevant Files
- path/to/file - [what changed]
```

## Step 7: END

End session properly:

```markdown
1. Call mem_save with summary
2. Verify todos completed
3. Clear next steps for user
```

## Memory Commands (Engram)

| Command | When to Use |
|---------|-------------|
| `mem_save` | After completing significant work |
| `mem_context` | At session start |
| `mem_search` | When recalling past work |
| `mem_get_observation` | To get full details |
| `mem_update` | To correct previous observations |

## Quick Reference

```markdown
Session Start:
  1. mem_context
  2. todowrite (create plan)
  3. Load needed skills

During Session:
  - Use skills for implementation
  - todowrite (update progress)

Session End:
  1. Review todos
  2. mem_save (session summary)
  3. Push changes
```

## Anti-Patterns to Avoid

| ❌ Don't | ✅ Do |
|----------|------|
| Start without assessing | Check context first |
| Skip skills | Load relevant skills |
| No plan | Create todo list |
| Skip verification | Always verify |
| Forget to save | Always mem_save |
| Push without review | Review before push |

---

**This skill ensures consistent, complete sessions.**
