---
name: git-workflow-and-versioning
aliases: ["git-workflow-and-versioning"]
description: >
  
triggers:
  - git
  - commit
  - branch
  - version
  - release
  - tag
  - changelog
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T01:46:58.312Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\git-workflow-and-versioning\SKILL.md
  version: "1.0.0"
---

# Git Workflow and Versioning

## Overview

Git is your safety net. Treat commits as save points, branches as sandboxes, history as
documentation. Disciplined version control keeps AI-generated changes manageable and reversible.

## When to Use

Always. Every code change flows through git.

## Core Principles

### Trunk-Based Development

Keep `main` always deployable. Work in short-lived branches (1-3 days) — merge risk accumulates
daily. Prefer feature flags.

→ See [references/branching-strategy.md](references/branching-strategy.md) for full model, naming
conventions, and worktree usage.

### Commit Early, Atomic Commits, Descriptive Messages

- Each increment gets its own commit (save points, not giant dumps).
- One logical thing per commit. Message explains _why_, not _what_.
- Don't mix formatting with feature work.
- Target ~100 lines per commit; split changes over ~1000.

→ See [references/commit-conventions.md](references/commit-conventions.md) for message format,
types, pre-commit hygiene, and generated file handling.

### Semantic Versioning + Changelog

Version `MAJOR.MINOR.PATCH`. Tag the release (`git tag -a v1.4.0`). Changelog grouped by
`Added / Changed / Fixed / Deprecated / Removed / Security`.

→ See [references/release-process.md](references/release-process.md) for semver rules, tagging, and
changelog format.

### The Save Point Pattern

```
Implement slice → Test → Verify → Commit → Next slice
```

Never lose more than one increment. If an agent goes off the rails, `git reset --hard HEAD` goes
back to the last known-good state.

### Change Summaries

After every modification, provide a summary with `CHANGES MADE`, `THINGS I DIDN'T TOUCH`, and
`POTENTIAL CONCERNS`. The "DIDN'T TOUCH" section shows scope discipline.

### Git for Debugging

Use `git bisect`, `git blame`, and `git log --grep` to trace bugs and messages.

→ See [references/operations-and-diagnostics.md](references/operations-and-diagnostics.md) for
debugging commands, save point pattern, change summary template, rationalizations, red flags, and
verification checklists.

## Reference Files

| File                                                                      | Description                                                         |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [branching-strategy.md](references/branching-strategy.md)                 | Branch model, naming, worktrees                                     |
| [commit-conventions.md](references/commit-conventions.md)                 | Atomic commits, message format, sizing, pre-commit, generated files |
| [release-process.md](references/release-process.md)                       | Semver, tagging, changelog                                          |
| [operations-and-diagnostics.md](references/operations-and-diagnostics.md) | Save point pattern, change summaries, git debugging, red flags      |

## Pre-Commit Hygiene (Quick)

```bash
git diff --staged                              # Review staged changes
git diff --staged | grep -i "password\|secret" # Check for secrets
npm test && npm run lint && npx tsc --noEmit   # Run checks
```

Automate with husky + lint-staged.

## Red Flags

- Large uncommitted changes / vague messages
- Formatting mixed with behavior changes
- No `.gitignore` or committing `node_modules/` / `.env`
- Long-lived branches diverging from main
- Force-pushing to shared branches
- Breaking change shipped as minor/patch
- Release with no tag or changelog entry

## Verification

Every commit:

- [ ] One logical thing, message `<type>: <desc>`
- [ ] Tests pass, no secrets
- [ ] `.gitignore` covers standard exclusions

Every release:

- [ ] Version bump matches change (breaking → major, additive → minor, fix → patch)
- [ ] Release tagged; version derived from tag
- [ ] Changelog has curated entry grouped by impact
