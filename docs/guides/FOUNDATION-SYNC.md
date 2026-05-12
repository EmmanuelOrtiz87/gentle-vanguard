# Foundation Sync Guide

This guide explains exactly how Foundation sync behaves in consumer repositories.

## Scope

`foundation-sync` does **not** update the whole repository. It only evaluates and updates files
listed in `config/foundation-sync.json` under `assets`.

If a file is not listed in `assets`, sync does not touch it.

## Source vs Consumer Role

`config/foundation-sync.json` defines a repository role:

1. `role: source`

- This repository is the Foundation source.
- `foundation-sync` exits early with no file sync.

2. `role: consumer`

- This repository consumes Foundation-managed assets.
- `foundation-sync` compares and optionally updates listed assets.

## Asset Strategy

Each asset can define a `strategy`:

1. `replace` (default)

- If drift is detected, `apply` overwrites local target file with source file.
- Local custom content in that managed file can be lost.

2. `preserve-local`

- Keep local target file unchanged.
- Useful for project-specific customizations.

## Command Modes

1. `check`

- Detects drift only.
- No file changes.

2. `apply`

- Applies updates for drifted assets with `replace` strategy.

3. `apply -CreatePR`

- Creates a sync branch.
- Commits managed updates.
- Pushes branch and opens a PR (when `gh` is available).

4. `-Force`

- Allows apply when the working tree has local changes.
- Use with caution.

## Recommended Safe Workflow

1. Run check first:

```powershell
.\scripts\utilities\wf.ps1 foundation-sync
```

2. Review drifted files and strategy (`replace` vs `preserve-local`).
3. Adjust `config/foundation-sync.json` before apply if needed.
4. Ensure a clean working tree before apply:

```powershell
# Option A: Commit your changes
git add .
git commit -m "chore: save local changes"

# Option B: Stash temporarily
git stash push -u -m "pre-foundation-sync"
```

5. Apply with PR for traceability:

```powershell
.\scripts\utilities\wf.ps1 foundation-sync apply -CreatePr
```

6. Review PR and merge.

## Will Custom Files Be Lost?

Only in this case:

1. The file is listed in `assets`.
2. Its strategy resolves to `replace`.
3. You run `apply`.

Custom files outside managed assets are not touched.

## Consumer Manifest Example

```json
{
  "schemaversión": 1,
  "role": "consumer",
  "foundationPath": "../foundation",
  "fromversión": "0.2.0",
  "toversión": "0.2.1",
  "assets": [
    {
      "source": "scripts/utilities/wf.ps1",
      "target": "scripts/utilities/wf.ps1",
      "strategy": "replace"
    },
    {
      "source": "AGENTS.md",
      "target": "AGENTS.md",
      "strategy": "preserve-local"
    }
  ]
}
```

## Related Files

1. `scripts/utilities/UTILITIES/foundation-sync.ps1`
2. `config/foundation-sync.json`
3. `scripts/utilities/wf.ps1`
