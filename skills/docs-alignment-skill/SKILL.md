---
name: docs-alignment
description: >
  Keep documentation in sync with code and workflow changes. Trigger: "docs", "documentation",
  "update docs", "doc sync"
metadata:
  source: GV-native
---

# Documentation Alignment Skill

## Purpose

Keep documentation synchronized with every code and workflow change.

## Docs Map

| File               | Covers                                    |
| ------------------ | ----------------------------------------- |
| `README.md`        | Installation, usage, CLI flags, providers |
| `CONTRIBUTING.md`  | Dev setup, contribution workflow, testing |
| `docs/guides/*.md` | User guides and how-tos                   |

## Change Doc Rules

| If you change...               | Update...             |
| ------------------------------ | --------------------- |
| A CLI flag (add/remove/rename) | README.md flags table |
| A provider (behavior change)   | README.md             |
| Test structure or commands     | CONTRIBUTING.md       |
| Install/uninstall behavior     | README.md             |
| Hook behavior                  | README.md             |

## Critical Rules

- NEVER reference CLI flags or commands that don't exist in code
- NEVER let a PR with behavior changes ship without updating docs
- Docs must describe FINAL state, not journey
- Code examples in docs must be tested and accurate

## Verification Checklist

Before submitting a PR with code changes:

```
[ ] Does this change affect any CLI flags?       update README.md
[ ] Does this change affect provider behavior?   update README.md
[ ] Does this add/remove a config option?        update README.md
[ ] Are all code examples still accurate?        verify manually
```

## Anti-patterns

```
# BAD  README shows old flag
README: --cache-dir
Code: --cache-path   was renamed

# BAD  docs reference non-existent script
README: "run setup.sh"   setup.sh doesn't exist
```
