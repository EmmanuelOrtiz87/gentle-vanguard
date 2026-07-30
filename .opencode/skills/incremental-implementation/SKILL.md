---
name: incremental-implementation
description: Deliver changes incrementally. Break features into small, ordered steps that can be implemented, tested, and verified.
triggers:
  - incremental
  - small steps
  - break down
  - step by step
  - iterative
---

# Incremental Implementation

## Overview

Build in thin vertical slices — implement one piece, test it, verify it, then expand. Each increment leaves the system in a working, testable state.

## When to Use

- Multi-file changes
- New features from a task breakdown
- Refactoring existing code
- More than ~100 lines before testing

When NOT: single-file, single-function changes with minimal scope.

## The Increment Cycle

```
Implement → Test → Verify → Commit → Next slice
```

1. **Implement** the smallest complete piece of functionality
2. **Test** — run the test suite
3. **Verify** — tests pass, build succeeds
4. **Commit** — descriptive message (see `git-workflow-and-versioning`)
5. **Next slice** — carry forward, don't restart

## Core Principles

### Rule 0: Simplicity First
Before writing, ask: "What is the simplest thing that could work?" Three similar lines beat a premature abstraction.

### Rule 0.5: Scope Discipline
Touch only what the task requires. Note improvements — don't fix them.

### Rule 1: One Thing at a Time
Each increment changes one logical thing.

### Rule 2: Keep It Compilable
After each increment, the project must build and tests pass.

### Rule 3: Feature Flags for Incomplete Features
Use flags to merge incomplete work without exposing it to users.

### Rule 4: Safe Defaults
New code defaults to safe, conservative behavior.

### Rule 5: Rollback-Friendly
Each increment should be independently revertable.

## Reference Files

| File | Contents |
|------|----------|
| `references/slicing-strategies.md` | Vertical, contract-first, risk-first slicing with examples |
| `references/implementation-rules.md` | Detailed rules with code examples |
| `references/working-with-agents.md` | Directing agents to implement incrementally |
| `references/increment-checklist.md` | Checklist, red flags, common rationalizations |

## See Also

Per-increment verification is the local check. Before declaring a task done, apply the project-wide Definition of Done. See `references/definition-of-done.md`.