---
description: Prepare and execute a release with version bump and changelog
agent: ops-agent
---

Execute the release workflow for Gentle-Vanguard:

1. Check current version in `VERSION` file
2. Determine version bump type: $ARGUMENTS (patch/minor/major)
3. Run `npm run typecheck` to verify clean compilation
4. Run `npm run test:config && npm run test:workflows` to verify tests
5. Run `cd apps/web-dashboard && npm run build` to verify dashboard
6. Update VERSION file with new version
7. Update package.json version to match
8. Update CHANGELOG.md with new entry
9. Create git commit: `release: vX.Y.Z`
10. Create git tag: `vX.Y.Z`

Display: current version → new version, files changed, commit hash.
