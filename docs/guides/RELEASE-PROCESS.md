# Release Process

## Versioning

Foundation follows [Semantic Versioning](https://semver.org/):

- **MAJOR (x.0.0)**: Breaking changes
- **MINOR (0.x.0)**: New features, no breaking changes
- **PATCH (0.0.x)**: Bug fixes, documentation, minor improvements

## Release Checklist

### 1. Prepare

```powershell
# Ensure working tree is clean
git status

# Run full test suite
npm test

# Run audit
.\skills\foundation-audit-skill\scripts\audit-sweep.ps1 -Scope full
```

### 2. Update Version

```powershell
# Update VERSION file
# Update CHANGELOG.md — move [Unreleased] → [X.Y.Z] - YYYY-MM-DD
# Update version badges in README.md, docs/README.md, marketing/*
# Update TUI installer version in foundation-installer-tui.ps1
```

### 3. Commit & Tag

```powershell
git add -A
git commit -m "chore: release vX.Y.Z - <summary of changes>"
git tag -a vX.Y.Z -m "vX.Y.Z: <summary>"
```

### 4. Merge to Develop

```powershell
git checkout develop
git merge main --no-edit
git checkout main
```

### 5. Push

```powershell
git push origin main
git push origin develop
git push origin vX.Y.Z
```

### 6. Sync Public Repo

```powershell
.\scripts\utilities\DEPLOYMENT\sync-to-public.ps1
```

Then from the public repo:

```powershell
git tag vX.Y.Z
git push origin vX.Y.Z
```

### 7. Create GitHub Release (Optional)

```powershell
gh release create vX.Y.Z --title "vX.Y.Z" --notes "See CHANGELOG.md"
```

## Branch Strategy

- `main` — stable, production-ready
- `develop` — integration branch (fast-forward from main on release)
- `feat/*` — feature branches
- `fix/*` — bug fix branches
- `chore/*` — maintenance branches

See [BRANCH-STRATEGY.md](BRANCH-STRATEGY.md) for full details.
