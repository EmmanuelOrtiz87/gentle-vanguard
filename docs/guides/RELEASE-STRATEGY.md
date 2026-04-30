# Foundation Release Strategy

## Overview

This document defines how Gentleman Foundation versions, releases, and manages backward compatibility across versions.

## Semantic Versioning (SemVer 2.0.0)

Foundation adheres to **[Semantic Versioning](https://semver.org/)**: `MAJOR.MINOR.PATCH`

```
v1.0.0
           PATCH: bug fixes, security patches, minor improvements
       MINOR: backward-compatible new features, governance enhancements
   MAJOR: breaking changes, architecture shifts, incompatible APIs
```

### Version Increment Rules

| Scenario | When | Example |
|----------|------|---------|
| MAJOR bump | Breaking changes to CLI, script API, or governance model | v1.0.0  v2.0.0 (new release strategy) |
| MINOR bump | New skills, new SDD policy, new features, governance clarifications | v1.0.0  v1.1.0 (SDD gate tightened) |
| PATCH bump | Bug fixes, security patches, documentation corrections | v1.0.0  v1.0.1 (fixed wf.ps1 bug) |

### Examples

-  **v1.0.0  v1.1.0**: Add 5 new skills; upgrade to SDD enforcement via CI gate (new but backward-compatible)
-  **v1.1.0  v1.1.1**: Fix wf.ps1 path issue; security patch in pre-commit (bug fixes)
-  **v1.1.1  v2.0.0**: Change branch strategy from `develop+main` to trunk-based; remove `scripts/project/` folder (architecture shift)

## Release Cadence & Types

### Release Types

#### 1. **Stable Release (Recommended)**
- Created from `main` branch
- Tag format: `v1.0.0`, `v1.2.0`, `v2.1.0`
- Process: develop on `develop`  merge to `main`  tag  GitHub Release
- Supported for at least 3 subsequent minor versions
- **Current strategy**: Quarterly stable releases

#### 2. **Prerelease (Optional)**
- Created from feature branches or `develop`
- Tag format: `v1.1.0-beta.1`, `v1.1.0-rc.1`
- For broad early testing before stable release
- Not recommended for production use
- Visibility: Pre-releases listed separately on GitHub

#### 3. **Hotfix Release (Urgent)**
- Created from `main` for critical security/stability issues
- Branch: `hotfix/issue-description`
- PATCH version bump (e.g., v1.0.0  v1.0.1)
- Merged back to `main` and `develop`
- Process: hotfix on branch  PR to main  tag  PR same commit to develop

## Breaking Changes & Deprecation Policy

### Deprecation Path

When removing or changing a feature:

1. **Announce deprecation** in CHANGELOG under current version: "Deprecated: `wf old-cmd` will be removed in v2.0.0"
2. **Emit warnings** in CLI/scripts when deprecated feature is used
3. **Maintain for 2+ minor versions** (e.g., deprecate in v1.1, remove in v2.0, but support in v1.2, v1.3)
4. **Document migration path** in MIGRATION.md

### Breaking Change Examples

**Scenario 1: CLI Command Removed**
```
v1.0.0: wf verify                          (stable)
v1.1.0: Deprecate wf verify in favor of wf validate
        wf verify still works with warning
v1.2.0: wf verify still works with warning (support continues)
v2.0.0: wf verify removed completely       (breaking change in MAJOR)
```

**Scenario 2: Governance Model Changes**
```
v1.0.0: SDD optional (advisory only)
v1.1.0: SDD mandatory for PRs (breaking for strict enforcement)
         Warrant MINOR bump because it's a governance change, not API change
```

## Compatibility & Support Matrix

| Version | Status | Support Until | Go | Node | Python | PowerShell |
|---------|--------|---------------|----|------|--------|------------|
| v1.0.0  | Stable | v1.3 released | 1.19+ | 18+ | 3.9+ | 7+ |
| v1.1.0+ | Stable | TBD | 1.19+ | 18+ | 3.9+ | 7+ |
| v2.0.0  | Future | TBD | 1.20+ | 20+ | 3.11+ | 7+ |

**Support Rule**: Maintain backward compatibility for at least 2 minor versions after a breaking change is announced.

## Branch Strategy for Release

### Git Flow (Current)

```
main (production branch)        GitHub Release points here
  
   Merged from: develop

develop (integration branch)  
  
   Feature branches (feature/*, bugfix/*, chore/*)
  
Hotfix (if critical)
hotfix/*    main  (tag)
           develop
```

### Release Process (Develop  Main  Tag)

```bash
# 1. Ensure develop is ready
git checkout develop
git pull origin develop

# 2. Update CHANGELOG: [Unreleased]  [1.0.0]
# (manually edit or use script)

# 3. Create release PR from develop to main
git checkout -b release/v1.0.0
git add CHANGELOG.md
git commit -m "chore(release): prepare v1.0.0"
git push origin release/v1.0.0

# Use gh or GitHub UI to create PR: release/v1.0.0  main

# 4. Merge PR (squash or merge commit both ok)
gh pr merge <number> --squash

# 5. Tag on main
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release v1.0.0: First stable release"
git push origin v1.0.0

# 6. GitHub Release created automatically (or manual)
gh release create v1.0.0 --generate-notes

# 7. Sync back to develop (optional but recommended)
git checkout develop
git merge main
git push origin develop
```

## Checklist Before Release

See [`RELEASE-CHECKLIST.md`](./RELEASE-CHECKLIST.md) for pre-release validation.

**Minimum**:
- [ ] CHANGELOG updated with all changes
- [ ] All governance tests pass
- [ ] Documentation updated
- [ ] No uncommitted changes on `develop`

## Versioning Governance

### Who Decides Version Number?

- **Project Lead** (you) decides and documents in CHANGELOG before release
- **AI Agent** (me) implements the release process
- **Consumers** (Dashboard) pin to a specific version or use "latest v1.*"

### Where Version is Declared

- `git tag v1.0.0`  Primary source of truth in Git
- `CHANGELOG.md`  What changed in this version
- `version.txt` (optional)  Can store version for scripts if needed

### No Hardcoded Version in Code

Foundation does NOT store version in `scripts/utilities/wf.ps1` or source files.
- Reason: Sync risk between code and git tags
- Instead: Query git tag at runtime if needed: `git describe --tags --abbrev=0`

## FAQ

**Q: When should I release?**
- After completing a significant feature set (3-5 items from backlog)
- When governance or architecture changes require documentation
- For security patches: immediately as v1.0.1 hotfix

**Q: Can I skip versions?**
- No. Always increment sequentially (v1.0.0  v1.1.0  v2.0.0)
- Reason: Consumers rely on predictable upgrade paths

**Q: What if develop is behind main?**
- Normally shouldn't happen; merge release back to develop after tagging
- If it does: `git merge main` on develop and push

**Q: How do consumers use this?**
- **Pin version**: `git clone... && git checkout v1.0.0`
- **Latest stable**: Clone main directly
- **Follow minor updates**: Pin to v1.* and update manually or via sync

---

**Next**: See [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md) for step-by-step release validation.
