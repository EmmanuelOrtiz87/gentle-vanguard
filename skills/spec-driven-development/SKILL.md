---
name: spec-driven-development
aliases: ["spec-driven-development"]
description:
  Create specs before coding. Use when starting new projects or when requirements are unclear or
  ambiguous.
  
triggers:
  - spec
  - specification
  - requirements
  - sdd
  - spec-driven
  - spec first
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.093Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\spec-driven-development\SKILL.md
  version: "1.0.0"
---

# Spec-Driven Development

## Overview

Write a structured specification before writing any code. The spec is the shared source of truth
between you and the human engineer — it defines what we're building, why, and how we'll know it's
done. Code without a spec is guessing.

## When to Use

- Starting a new project or feature
- Requirements are ambiguous or incomplete
- The change touches multiple files or modules
- You're about to make an architectural decision
- The task would take more than 30 minutes to implement

**When NOT to use:** Single-line fixes, typo corrections, or changes where requirements are
unambiguous and self-contained.

## The Gated Workflow

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```

### Phase 1: Specify

Start with a high-level vision. Ask clarifying questions until requirements are concrete. Surface
assumptions immediately — list what you're assuming before writing spec content.

Cover six core areas: **Objective**, **Commands**, **Project Structure**, **Code Style**, **Testing
Strategy**, **Boundaries** (Always / Ask First / Never).

See `references/spec-template.md` for the spec template and success criteria reframing.

### Phase 2: Plan

With the validated spec, generate a technical implementation plan identifying major components,
dependencies, implementation order, and risks.

> Follow `planning-and-task-breakdown` for dependency-graph and vertical-slicing mechanics. Save the
> plan to `tasks/plan.md` and task list to `tasks/todo.md`.

### Phase 3: Tasks

Break the plan into discrete tasks — each completable in one session with explicit acceptance
criteria and a verification step.

> Follow `planning-and-task-breakdown` for task-sizing and dependency-ordering.

### Phase 4: Implement

Execute tasks one at a time following `incremental-implementation` and `test-driven-development`.
Use `context-engineering` to load the right spec sections at each step.

## Keeping the Spec Alive

The spec is a living document — update it when decisions or scope change, commit it alongside code,
and reference it in PRs.

## Verification

Before proceeding to implementation, confirm:

- [ ] The spec covers all six core areas
- [ ] The human has reviewed and approved the spec
- [ ] Success criteria are specific and testable
- [ ] Boundaries (Always/Ask First/Never) are defined
- [ ] The spec is saved to a file in the repository

## Examples

Concrete usage drawn from this skill's own documentation:

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```
