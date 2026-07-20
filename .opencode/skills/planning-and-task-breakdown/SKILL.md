---
name: planning-and-task-breakdown
description: Breaks work into small, ordered tasks from specs or vague requirements.
---

# Planning and Task Breakdown

## Overview

Decompose work into small, verifiable tasks with explicit acceptance criteria. Every task should be
small enough to implement, test, and verify in a single focused session.

## When to Use

- You have a spec and need to break it into implementable units
- A task feels too large or vague to start
- Work needs to be parallelized across multiple agents or sessions
- You need to communicate scope to a human
- The implementation order isn't obvious

**When NOT to use:** Single-file changes with obvious scope, or when the spec already contains
well-defined tasks.

## Planning Process

### Step 1: Enter Plan Mode

Read the spec and codebase in read-only mode. Identify patterns, map dependencies, note risks.
**Do NOT write code.** Output saved to `tasks/plan.md` and `tasks/todo.md`.

### Step 2: Dependency Graph

Map what depends on what. See `references/dependency-graph.md` for an example. Implementation order
follows the dependency graph bottom-up: build foundations first.

### Step 3: Vertical Slicing

Build one complete feature path at a time (schema + API + UI together), not all DB then all API
then all UI. Each vertical slice delivers working, testable functionality.

### Step 4: Write Tasks

Each task needs a title, description, acceptance criteria, verification steps, dependencies,
files touched, and estimated scope. See `references/task-template.md` for the full structure.

### Step 5: Order and Checkpoint

Arrange tasks so dependencies are satisfied first, each task leaves the system working, and
checkpoints occur after every 2-3 tasks. Put high-risk tasks early (fail fast). See
`references/checkpoint-template.md`.

## Task Sizing

| Size   | Files | Scope                                 | Example                              |
| ------ | ----- | ------------------------------------- | ------------------------------------ |
| **XS** | 1     | Single function or config change      | Add a validation rule                |
| **S**  | 1-2   | One component or endpoint             | Add a new API endpoint               |
| **M**  | 3-5   | One feature slice                     | User registration flow               |
| **L**  | 5-8   | Multi-component feature               | Search with filtering and pagination |
| **XL** | 8+    | **Too large — break it down further** | —                                    |

An agent performs best on S and M tasks. Break L/XL tasks into smaller units.

**When to break a task down further:**
- It takes more than one focused session (~2+ hours)
- Acceptance criteria can't fit in 3 or fewer bullet points
- It touches two or more independent subsystems
- The task title contains "and"

## Output Files

- **Plan document:** `tasks/plan.md` — full implementation plan including architecture decisions
  and a task checklist. See `references/plan-template.md`.

## Red Flags

- Starting implementation without a written task list
- Tasks without acceptance criteria
- No verification steps in the plan
- All tasks are XL-sized
- No checkpoints between tasks
- Dependency order isn't considered

## Pre-Implementation Checklist

- [ ] Every task has acceptance criteria
- [ ] Every task has a verification step
- [ ] Task dependencies are ordered correctly
- [ ] No task touches more than ~5 files
- [ ] Checkpoints exist between major phases
- [ ] The human has reviewed and approved the plan

## See Also

- `references/task-template.md` — Task and checkpoint structure
- `references/plan-template.md` — Full plan document template
- `references/parallelization.md` — Parallelizing across agents
- `references/common-rationalizations.md` — Planning myths debunked
- `references/dependency-graph.md` — Example dependency graph
