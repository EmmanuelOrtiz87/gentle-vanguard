# writing-plans-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Writing Plans

## Overview

Write comprehensive implementation plans assuming zero codebase context and questionable taste.
Document everything: files to touch, code, tests, how to test. Bite-sized tasks. DRY. YAGNI. TDD.
Frequent commits.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per
subsystem. Each plan must produce working, testable software independently.

## File Structure

See [references/file-structure.md](references/file-structure.md).

## Plan Document Header

Every plan MUST start with this header:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** [One sentence describing what this builds]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

See [references/task-structure.md](references/task-structure.md) for the full template.

Key rule — **each step is one action (2–5 minutes):**

"Write the failing test" → "Run it to verify it fails" → "Implement minimal code" →
"Run tests to verify" → "Commit"

## No Placeholders

Every step must contain actual content. These are **plan failures**:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — tasks may be read out of order)
- Steps describing what without showing how
- References to types not defined in any task

Full list: [references/no-placeholders.md](references/no-placeholders.md)

## Remember

- Exact file paths always
- Complete code in every step
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

See [references/self-review.md](references/self-review.md).

## Execution Handoff

After saving, offer Subagent-Driven (recommended) or Inline Execution.
See [references/execution-handoff.md](references/execution-handoff.md).
