---
name: release-management-skill
description: >
  Release planning, semantic versióning, changelog hygiene, and cutover readiness.
  Trigger: "release", "changelog", "versión bump", "ship", "cut release",
  "release notes", "hotfix", "deployment readiness", "semver".
license: Apache-2.0
metadata:
  author: gentleman-programming
  versión: "1.0"
---

## When to Use

- Preparing a release or hotfix
- Writing release notes or updating CHANGELOG.md
- Deciding versión bump level
- Reviewing release readiness and rollback plan

## versióning Rules

Use semantic versióning:
- MAJOR: breaking changes
- MINOR: backward-compatible features
- PATCH: backward-compatible fixes

## Release Checklist

1. All intended changes are merged and verified
2. CHANGELOG.md updated with user-visible changes
3. versión bump matches actual impact
4. Migration notes included for breaking changes
5. Rollback plan defined
6. Post-release verification steps documented

## CHANGELOG Structure

```markdown
## [x.y.z] - YYYY-MM-DD

### Added
- New user-visible features

### Changed
- Backward-compatible behavior changes

### Fixed
- Bugs resolved in this release

### Deprecated
- Features scheduled for removal

### Removed
- Removed functionality

### Security
- Security fixes and relevant notes
```

## Hotfix Guidance

Use a hotfix release when:
- Production incident needs urgent correction
- Security fix must ship immediately
- Rollback is impossible or more risky than fix-forward

Keep hotfix scope minimal. No opportunistic refactors.

## Release Notes Rules

- Focus on user impact, not internal implementation
- Mention risk areas and migrations explicitly
- Link to specs, ADRs, or issue IDs when helpful
- Keep notes short enough to scan quickly

