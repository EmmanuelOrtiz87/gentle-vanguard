# Repository Rename Migration

This guide documents how to migrate from `gentleman-foundation` to `foundation` safely across
machines and local clones.

## Current State

1. New canonical repository name: `foundation`
2. Existing public mirror repository: `foundation-public`

## Migration Checklist

1. Rename repository on GitHub.
2. Update local remote URLs on every machine.
3. Verify branch protections or rulesets after rename.
4. Validate sync workflows still target `foundation-public`.

## Local Remote Migration

Use this script in each machine where you have local clones:

```powershell
.\scripts\utilities\DEPLOYMENT\migrate-foundation-remotes.ps1
```

Dry run mode:

```powershell
.\scripts\utilities\DEPLOYMENT\migrate-foundation-remotes.ps1 -DryRun
```

## Sync Configuration for foundation-public

`sync-public.yml` now supports repository variables:

1. `PUBLIC_REPO` (example: `EmmanuelOrtiz87/foundation-public`)
2. `PUBLIC_REPO_DEFAULT_BRANCH` (optional override)

If variables are missing, workflow defaults remain safe.

## Validation Commands

```powershell
git remote -v
gh repo view EmmanuelOrtiz87/foundation --json name,url,defaultBranchRef
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1
```

## Notes

1. Rename does not migrate branch rules automatically in all cases.
2. Re-check branch rulesets after the rename.
3. For public repositories, keep untrusted PR jobs on GitHub-hosted runners.