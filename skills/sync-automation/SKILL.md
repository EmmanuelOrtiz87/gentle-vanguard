---
name: sync-automation
description: Auto-sync private to public repo, filtering sensitive content
trigger: "sync", "public repo", "auto-sync"
---

# Sync Automation Skill

## Purpose

Automatically sync non-sensitive changes from private to public repo on each session or manually.

## Trigger

- Session end: Auto-sync to public repo
- Manual: `.\scripts\foundation\sync-public-repo.ps1`

## Files NOT Allowed in Public Repo

| Pattern | Reason |
|---------|--------|
| `scripts/security/*` | Security implementation |
| `config/security-*` | Security configs with keys |
| `.workspace/*` | Owner credentials |
| `skills/*orchestrator*` | Orchestrator internals |
| `skills/*security*` | Security skills |
| `docs/security/*` | Private security docs |
| `docs/sessions/*` | Session history |
| `docs/*strategic*` | Strategic decisións |

## Files Allowed in Public Repo

| Pattern | Reason |
|---------|--------|
| `README.md` | Public README |
| `docs/getting-started/*` | Onboarding |
| `docs/guides/*` | Public guides |
| `scripts/utilities/wf.ps1` | Main CLI |
| `scripts/foundation/bootstrap.ps1` | Bootstrap |
| `skills/*demo*/**` | Demo skills only |
| `config/cloud-agents.example.json` | Example config (no real keys) |

## Automation Integration

### Pre-commit Hook

The sync happens automatically on session end, but you can also configure git hooks:

```powershell
# Add to .git/hooks/post-commit (private repo)
.\scripts\foundation\sync-public-repo.ps1 -AutoCommit
```

### CI/CD (Future)

```yaml
# .github/workflows/sync.yml
on: [push]
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: .\scripts\foundation\sync-public-repo.ps1
```

## Commands

```powershell
# Dry run - see what would sync
.\scripts\foundation\sync-public-repo.ps1 -DryRun

# Actual sync
.\scripts\foundation\sync-public-repo.ps1

# Check what will be skipped
.\scripts\foundation\sync-public-repo.ps1 -Preview

# Force sync specific files
.\scripts\foundation\sync-public-repo.ps1 -Include "docs/getting-started/*"
```

## Skill Integration

When agent makes changes:

1. Agent completes task
2. Session end triggers sync
3. Sync script filters sensitive files
4. Changes copied to public repo
5. Agent can optionally push to public repo

---

**Triggers**: "sync", "public repo", "demo", "publish"

