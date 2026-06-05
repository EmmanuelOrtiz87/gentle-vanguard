# NORMATIVA: Release Process

## Pipeline (Canonical)

```
release-automation.ps1
  ├── Phase 1: Validate VERSION, badges, CHANGELOG, prerequisites
  ├── Phase 2: build/create-installer.ps1
  │     ├── build/protect-gentle-vanguard.ps1   (encrypt scripts)
  │     ├── ps2exe (optional)                    (compile launcher .ps1 → .exe)
  │     └── makensis.exe                         (NSIS → dist/Gentle-Vanguard.exe)
  └── Phase 3: sync-to-public.ps1               (dist/Gentle-Vanguard.exe → public repo)
```

**Output artifact:** `dist/Gentle-Vanguard.exe` — single NSIS installer, AES-256 encrypted. **Sync
target:** Public repo root as `Gentle-Vanguard.exe`.

## 1. Release Automation MUST Be Used

Every release MUST go through `scripts/utilities/DEPLOYMENT/release-automation.ps1`. Manual tagging
without automation is PROHIBITED.

`build/create-installer.ps1` is called internally by `release-automation.ps1` and MUST NOT be
invoked directly for releases. The entry point is always `release-automation.ps1`.

### Superseded / Deprecated

The following scripts are DEPRECATED and MUST NOT be used for releases:

- `scripts/utilities/DEPLOYMENT/create-release.ps1` — had parameter mismatch, used wrong output path
  (`releases/` instead of `dist/`)
- `scripts/utilities/DEPLOYMENT/compile-ps2exe.ps1` — general-purpose utility only, NOT part of
  release pipeline

## 2. VERSION File Is Source of Truth

The `VERSION` file at repo root is the canonical version. All badges, footers, CHANGELOG entries,
and installer metadata MUST match VERSION. If they diverge, the release MUST be blocked.

### Files validated before release:

- `VERSION` — canonical version string
- `README.md` — badge `Version-*` and footer `v*.*.*`
- `README-PUBLIC.md` — badge `Version-*` and footer `v*.*.*`
- `CHANGELOG.md` — entry `[X.Y.Z]` for this version
- `dist/Gentle-Vanguard.exe` — rebuilt for each release

## 3. Installer MUST Be Rebuilt Every Release

`build/create-installer.ps1` MUST run during every release. The resulting `dist/Gentle-Vanguard.exe`
from a PREVIOUS build is NEVER valid for a NEW release. Rationale: the .exe bundles encrypted
scripts — if scripts changed between releases, the old .exe ships stale code.

## 4. Public Repo Sync Is Mandatory — ALL Branches

After every release, `sync-to-public.ps1` MUST run to propagate:

- `README-PUBLIC.md` → public repo's `README.md`
- `dist/Gentle-Vanguard.exe` → public repo's `Gentle-Vanguard.exe`
- CI workflow adaptations (branch triggers: develop → main)

A release is NOT complete until the public repo is synced.

### 4.1 All Remote Branches MUST Be Synced

The script syncs to EVERY remote branch (`main`, `develop`, etc.), not just the default HEAD. Each
branch gets an identical, independent sync via `git reset --hard origin/$branch` before file copy
operations. This guarantees no branch falls behind.

### 4.2 Pre-Flight Health Check

Before each sync, run `scripts/utilities/DEPLOYMENT/check-public-repo-health.ps1` to validate:

- Both `main` and `develop` branches exist and are reachable
- All branches have a recent commit (within 14 days)
- No branch is more than 1 commit behind the other after sync

If the health check fails, the release MUST be blocked until resolved.

## 5. Prerequisites Check

Before ANY release step, validate:

- `scripts/utilities/DEPLOYMENT/release-automation.ps1` exists (entry point)
- `build/create-installer.ps1` exists (build script)
- `build/protect-gentle-vanguard.ps1` exists (encryption)
- NSIS (makensis.exe) is installed
- Working tree is clean (no uncommitted changes)
- `VERSION` file content matches the intended release version
- All version badges align with VERSION file (README.md, README-PUBLIC.md, presentation)
- `CHANGELOG.md` has an entry for the release version

If any prerequisite fails, the release MUST abort.

## 6. Post-Release Verification

After release + sync, the following MUST be verified manually or via automation:

- GitHub Release exists at `https://github.com/EmmanuelOrtiz87/gentle-vanguard/releases/tag/vX.Y.Z`
- Public repo shows correct version badge
- `git log --oneline origin/main -1` matches the release commit
- Public repo `README.md` footer shows correct version

## 7. Lessons Learned Integration

After every release, review `engram mem_search "release|lessons learned"` for any past release
failures. If new issues are discovered, this NORMATIVA MUST be updated before closing the release.

## 8. Violation Consequences

Releasing without automation, skipping installer rebuild, or skipping public repo sync is a CRITICAL
violation. The release MUST be rolled back and re-done through the automated pipeline.

---

See also: `scripts/utilities/DEPLOYMENT/release-automation.ps1`,
`scripts/utilities/DEPLOYMENT/sync-to-public.ps1`,
`scripts/utilities/DEPLOYMENT/check-public-repo-health.ps1`
