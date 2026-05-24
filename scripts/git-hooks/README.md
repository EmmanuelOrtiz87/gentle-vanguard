# Git Hooks — DEPRECATED

> **⚠️ DEPRECATED**: This directory is legacy. Hooks are now managed by **Lefthook** (`.lefthook.yml`).
>
> See `scripts/core/bootstrap.ps1` for automated Lefthook installation.

## Migration

| Old (scripts/git-hooks) | New (Lefthook) |
|-------------------------|----------------|
| `pre-commit` | `.lefthook.yml → pre-commit` |
| `commit-msg` | `.lefthook.yml → commit-msg` |
| `pre-push` | `.lefthook.yml → pre-push` |
| Manual install required | `bootstrap.ps1` installs lefthook + runs `lefthook install` |
| `core.hooksPath` override | Default `.git/hooks` (lefthook manages this) |

## What Lefthook Provides

- **post-commit**: Auto-syncs CodeGraph index after every commit
- **post-merge**: Auto-syncs CodeGraph index after every merge
- **pre-commit**: JSON lint, opencode validation, trufflehog scan
- **commit-msg**: Conventional commit enforcement
- **pre-push**: Audit sweep, orchestrator auto-fix, npm audit

## Why

Lefthook is cross-platform (Windows/Linux/macOS), faster, and supports parallel hook execution. Manual `core.hooksPath` configuration is no longer needed.

## Removal

This directory can be safely removed once all team members have migrated to Lefthook. Keep for now as reference.
