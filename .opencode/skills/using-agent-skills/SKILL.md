---
name: using-agent-skills
description:
  Discover and invoke agent skills. Use when starting a session or when you need to discover which
  skill applies.
triggers:
  - skill
  - discover skill
  - invoke skill
  - which skill
  - find skill
---

# Using Agent Skills

## Overview

Agent Skills is a collection of engineering workflow skills organized by development phase. Each
skill encodes a specific process. This meta-skill helps you discover and apply the right skill.

## Skill Discovery

```
Task arrives
    │
    ├── Don't know what you want yet? ──────→ interview-me
    ├── Have a rough concept, need variants? → idea-refine
    ├── New project/feature/change? ──→ spec-driven-development
    ├── Have a spec, need tasks? ──────→ planning-and-task-breakdown
    ├── Implementing code? ────────────→ incremental-implementation
    │   ├── UI work? ─────────────────→ frontend-ui-engineering
    │   ├── API work? ────────────────→ api-and-interface-design
    │   ├── Need better context? ─────→ context-engineering
    │   ├── Need doc-verified code? ───→ source-driven-development
    │   └── Stakes high / unfamiliar code? ──→ doubt-driven-development
    ├── Writing/running tests? ────────→ test-driven-development
    │   └── Browser-based? ───────────→ browser-testing-with-devtools
    ├── Something broke? ──────────────→ debugging-and-error-recovery
    ├── Reviewing code? ───────────────→ code-review-and-quality
    │   ├── Too complex? ─────────────→ code-simplification
    │   ├── Security concerns? ───────→ security-and-hardening
    │   └── Performance concerns? ────→ performance-optimization
    ├── Committing/branching? ─────────→ git-workflow-and-versioning
    ├── CI/CD pipeline work? ──────────→ ci-cd-and-automation
    ├── Deprecating/migrating? ────────→ deprecation-and-migration
    ├── Writing docs/ADRs? ───────────→ documentation-and-adrs
    ├── Adding logs/metrics/alerts? ───→ observability-and-instrumentation
    └── Deploying/launching? ─────────→ shipping-and-launch
```

## Skill Rules

1. **Check for an applicable skill before starting work.** Skills encode processes that prevent
   common mistakes.

2. **Skills are workflows, not suggestions.** Follow the steps in order. Don't skip verification.

3. **Multiple skills can apply.** A feature might sequence multiple skills end-to-end.

4. **When in doubt, start with a spec.** If the task is non-trivial and there's no spec, begin with
   `spec-driven-development`.

## See Also

- `references/core-behaviors.md` — 6 non-negotiable operating behaviors
- `references/failure-modes.md` — 10 subtle errors to avoid
- `references/lifecycle-sequence.md` — Typical skill sequence for a full feature
- `references/quick-reference.md` — Phase/skill/summary table
