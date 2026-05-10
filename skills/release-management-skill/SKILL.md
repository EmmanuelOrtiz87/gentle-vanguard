---
name: release-management-skill
description: "Trigger: release, changelog, version bump, ship, cut release, release notes, hotfix, deployment readiness, semver. Release planning, semantic versioning, changelog hygiene, and cutover readiness."
---

## Activation Contract

Use when input matches trigger words or user asks about release planning, version bumps, changelog updates, hotfixes, or release readiness.

## Hard Rules

- MUST use semver: MAJOR (breaking), MINOR (feature), PATCH (fix)
- MUST update CHANGELOG.md before every release
- MUST include migration notes for breaking changes
- MUST define a rollback plan before cutover
- MUST keep hotfix scope minimal — no opportunistic refactors
- MUST focus release notes on user impact, not implementation details

## Decision Gates

| Gate | Condition | Action |
|------|-----------|--------|
| Bump level | Breaking change? | MAJOR |
| Bump level | New backward-compatible feature? | MINOR |
| Bump level | Backward-compatible bug fix? | PATCH |
| Release type | Production incident or security fix? | Hotfix (fast-track) |
| Release type | Standard release? | Normal pipeline |

## Execution Steps

1. Verify all intended changes merged and verified
2. Update CHANGELOG.md with user-visible changes
3. Bump version per semver rules
4. Write migration notes for breaking changes
5. Define rollback plan
6. Document post-release verification steps

## Output Contract

Return version bumped, CHANGELOG additions, migration notes, rollback plan, and post-release verification steps.

## References

- `references/CHANGELOG-template.md` — CHANGELOG entry format
