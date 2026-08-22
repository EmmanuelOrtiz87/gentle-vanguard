---
name: planning-and-task-breakdown
description:
  Plan before you write. Break work into small, ordered tasks from specs or vague requirements.
  Decompose into implementable units with acceptance criteria, after a structured pre-write planning
  phase (scope, approach, risk, breakdown) with decision gates before implementation.
triggers:
  - plan
  - breakdown
  - tasks
  - decompose
  - planning
  - task breakdown
  - plan before write
  - pre-write planning
  - scope definition
  - approach analysis
  - risk assessment
  - decision gate
---

# Planning and Task Breakdown

## Overview

Plan before you write. Decompose work into small, verifiable tasks with explicit acceptance
criteria. Every task should be small enough to implement, test, and verify in a single focused
session. The pre-write planning phase runs **before any code is written**, and decision gates block
implementation until the plan is approved.

## When to Use

- You have a spec and need to break it into implementable units
- A task feels too large or vague to start
- Work needs to be parallelized across multiple agents or sessions
- You need to communicate scope to a human
- The implementation order isn't obvious

**When NOT to use:** Single-file changes with obvious scope, or when the spec already contains
well-defined tasks.

## Plan Before Write

Pre-write planning turns a vague request into an approved, buildable plan before a single line of
code changes. This is the "superpowers" discipline: **plans come first, code second**. Use the
templates in `references/pre-write-planning.md` and the CLI in `src/planning/planning-templates.ts`.

### Step 1: Scope Definition

Answer three questions and write them down:

- **Problem** — What problem does this solve? What is the user-visible outcome?
- **In scope vs out of scope** — What is explicitly included? What is explicitly excluded?
- **Constraints** — What are the hard constraints (tech stack, time, budget, compatibility)?

### Step 2: Approach Analysis

- List 2-3 possible approaches (not just one — force a real choice)
- Evaluate tradeoffs: complexity, maintainability, performance
- Document rationale for the chosen approach; note why the others lost

### Step 3: Risk Assessment

- **What could go wrong?** List the top failure modes with impact and likelihood
- **Dependencies and blockers** — external systems, other tasks, missing knowledge
- **Rollback strategy** — how do we undo this if it fails?

### Step 4: Task Breakdown

Feed the plan into the existing task breakdown process below (Task Sizing, vertical slicing). Every
subtask gets acceptance criteria, dependencies, and an estimate.

### Decision Gates

Do **not** start implementation until every gate passes. Reject or re-plan at the first failed gate.

| Gate            | Check                                                                          |
| --------------- | ------------------------------------------------------------------------------ |
| **G1 Scope**    | Problem, in/out-of-scope, and constraints are written down and unambiguous     |
| **G2 Approach** | At least 2 approaches considered; chosen approach has documented rationale     |
| **G3 Risk**     | Top risks identified with mitigations; rollback strategy defined               |
| **G4 Tasks**    | Every task has acceptance criteria and verification steps; dependencies mapped |
| **G5 Approval** | Plan is approved by a human or the requesting agent before implementation      |

### Plan Storage

Plans are stored in `.session/sdd-pipeline/plans/` and linked to tasks in the todo list:

```bash
npx tsx src/planning/planning-templates.ts --plan --type feature --name user-auth --title "User Authentication"
npx tsx src/planning/planning-templates.ts --list
npx tsx src/planning/planning-templates.ts --show user-auth
```

## Planning Process

### Step 5: Enter Plan Mode

Read the spec and codebase in read-only mode. Identify patterns, map dependencies, note risks. **Do
NOT write code.** Output saved to `tasks/plan.md` and `tasks/todo.md`.

### Step 6: Dependency Graph

Map what depends on what. See `references/dependency-graph.md` for an example. Implementation order
follows the dependency graph bottom-up: build foundations first.

### Step 7: Vertical Slicing

Build one complete feature path at a time (schema + API + UI together), not all DB then all API then
all UI. Each vertical slice delivers working, testable functionality.

### Step 8: Write Tasks

Each task needs a title, description, acceptance criteria, verification steps, dependencies, files
touched, and estimated scope. See `references/task-template.md` for the full structure.

### Step 9: Order and Checkpoint

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

- **Plan document:** `tasks/plan.md` — full implementation plan including architecture decisions and
  a task checklist. See `references/plan-template.md`.

## Red Flags

- Starting implementation without a written task list
- Tasks without acceptance criteria
- No verification steps in the plan
- All tasks are XL-sized
- No checkpoints between tasks
- Dependency order isn't considered

## Pre-Implementation Checklist

- [ ] **G1:** Scope (problem, in/out, constraints) is written down
- [ ] **G2:** Approach chosen with documented rationale
- [ ] **G3:** Risks assessed with rollback strategy
- [ ] **G4:** Every task has acceptance criteria
- [ ] **G4:** Every task has a verification step
- [ ] **G4:** Task dependencies are ordered correctly
- [ ] **G4:** No task touches more than ~5 files
- [ ] **G4:** Checkpoints exist between major phases
- [ ] **G5:** The human has reviewed and approved the plan

## See Also

- `references/pre-write-planning.md` — Feature, refactoring, and bug-fix planning templates
- `references/task-template.md` — Task and checkpoint structure
- `references/plan-template.md` — Full plan document template
- `references/parallelization.md` — Parallelizing across agents
- `references/common-rationalizations.md` — Planning myths debunked
- `references/dependency-graph.md` — Example dependency graph
- `src/planning/planning-templates.ts` — CLI to scaffold, store, and link plans
