# Development Workflow

## Overview

This document defines the standardized development workflow for all projects using Gentleman Foundation.

## Branch Strategy

```
main (production)
     ↑
develop (integration)
     ↑
feature/* / bugfix/* / chore/*
```

### Branch Types

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production code | Required PR + review |
| `develop` | Integration | Required PR + review |
| `feature/*` | New features | PR after completion |
| `bugfix/*` | Bug fixes | PR after completion |
| `chore/*` | Maintenance | PR after completion |
| `hotfix/*` | Urgent fixes | Direct commit allowed |
| `release/*` | Release preparation | Direct commit allowed |

### GitFlow Enforcement

1. Protected branch direct push (`main`, `develop`) is blocked by default.
2. Allowed branch naming is enforced: `feature/*`, `bugfix/*`, `chore/*`, `hotfix/*`, `release/*`.
3. Expected PR base is enforced:
- `feature/*`, `bugfix/*`, `chore/*` -> `develop`
- `hotfix/*`, `release/*` -> `main`

## Session Workflow

### 1. Start Session

```markdown
1. mem_context              # Check memory
2. git status              # Current branch
3. Load skills             # Based on stack
4. Present status          # Project, todos, next step
```

### 2. During Work

```markdown
1. Execute with loaded skills
2. Update todos
3. Verify each step
4. Run tests locally
```

### 3. Before End

```markdown
1. wf.ps1 review           # Code review
2. wf.ps1 audit           # Audit document
3. Validate specification
4. Ask: Create PR?
5. wf.ps1 publish         # Full publish flow with gated merge decision
```

## Commit Convention

```
<type>(<scope>): <description>

feat:     New feature
fix:      Bug fix
docs:     Documentation
refactor: Code refactoring
test:     Adding tests
chore:    Maintenance
ci:       CI/CD changes
```

### Examples

```bash
feat(auth): add OAuth2 login
fix(api): handle null response
test(dashboard): add metrics tests
docs(readme): update installation
```

## Code Review Process

### Trigger Points

- Before any PR
- Manual: `wf.ps1 review`
- Automatic: Pre-commit hook

### 7 Dimensions

| # | Dimension | Scope | Auto | Blocking |
|---|----------|-------|------|----------|
| 1 | Security | Secrets, vulnerabilities | Yes | CRITICAL/HIGH |
| 2 | Quality | Code smells, patterns | Yes | HIGH |
| 3 | Architecture | Structure, design | No | MEDIUM |
| 4 | Testing | Coverage, quality | No | MEDIUM |
| 5 | Documentation | README, comments | No | LOW |
| 6 | API Design | REST, validation | No | MEDIUM |
| 7 | Git Workflow | Commits, branches | No | LOW |

### Severity Actions

| Severity | Icon | Action | Blocking |
|----------|------|--------|----------|
| CRITICAL | [X] | Block immediately | Yes |
| HIGH | [!]️ | Must fix before PR | Yes |
| MEDIUM | [-] | User choice | No |
| LOW | [*] | Optional | No |

### Findings Decision

```
CRITICAL/HIGH found:
-> Must fix before proceeding

MEDIUM found:
-> Option A: Fix now (recommended)
-> Option B: Fix after PR
-> Option C: Document as tech debt

LOW found:
-> Optional fixes
-> Can proceed with PR
```

## Audit Document

Generated automatically with `wf.ps1 audit`.

### Structure

```markdown
# Audit Document - [DATE]

## Summary
## Git Information
## Commits
## Tests Status
## Findings
## Specification
## Next Steps
```

## Pull Request Process

### Checklist

- [ ] All tests pass
- [ ] Code review completed
- [ ] No CRITICAL/HIGH findings
- [ ] Audit document generated
- [ ] Specification validated
- [ ] Documentation updated

### PR Description Template

See: `templates/PULL_REQUEST_TEMPLATE.md`

### PR Merging

```bash
# Squash merge (recommended for feature branches)
gh pr merge --squash

# Merge with commit (for release branches)
gh pr merge --admin --merge
```

### Controlled Publish Decision

Use `wf.ps1 publish` for end-to-end execution with governance gates:

1. If validations pass with no alerts, PR merge is authorized automatically.
2. If alerts are detected, a summary + suggestions are shown.
3. If suggestions are accepted, automated fixes are applied and the flow re-runs.
4. If suggestions are rejected, a final explicit confirmation is required to merge with gaps under developer responsibility.
5. Every decision path is documented in `docs/sessions/*-publish-decision.md`.

## Automation

### Scripts

| Script | Purpose |
|--------|---------|
| `wf.ps1 review` | Run code review |
| `wf.ps1 audit` | Generate audit document |
| `wf.ps1 pr` | Create PR template |
| `wf.ps1 push` | Prepare for push |
| `wf.ps1 publish` | Validate, summarize alerts, apply suggestions, and merge according to decision policy |
| `wf.ps1 status` | Show current status |

### Hooks

| Hook | Trigger | Actions |
|------|---------|---------|
| `pre-commit` | `git commit` | Secrets scan, format check |
| `pre-push` | `git push` | GGA + GitFlow policy + governance + homologation drift gate |
| `commit-msg` | `git commit` | Commit message validation |

## Tools

### CLI Tools

```powershell
# Workflow CLI
.\scripts\utilities\wf.ps1 <command>

# Foundation CLI
gf validate
gf list
gf update
gf check
```

### Git Aliases

Add to `~/.gitconfig`:

```ini
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --graph --oneline --decorate --all
```

## Best Practices

### Do

- Always create feature branches
- Run `wf.ps1 review` before PR
- Generate audit document on push
- Use conventional commits
- Keep PRs small and focused
- Update documentation

### Don't

- Commit directly to main/develop
- Skip code review
- Push without audit
- Leave CRITICAL/HIGH findings
- Merge PRs without approval

## Quick Reference

```bash
# Start work
git checkout -b feature/my-feature

# During work
.\scripts\utilities\wf.ps1 review
go test ./...
npm test

# Before commit
git add .
git commit -m "feat(scope): description"

# Before push
.\scripts\utilities\wf.ps1 audit
git push -u origin feature/my-feature

# Create PR
gh pr create
```

## Support

- Foundation: `~/.gentleman/`
- Documentation: `docs/`
- Skills: `.skills/`
- Scripts: `scripts/`
