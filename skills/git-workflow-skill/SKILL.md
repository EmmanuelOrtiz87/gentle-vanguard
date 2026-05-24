---
name: git-workflow-skill
description: Use when managing git branches, commits, pull requests, merge conflicts, or git workflows. Triggers: "git branch", "git merge", "conflict", "pull request", "commit", "rebase", "cherry-pick", "stash".
---

# Git Workflow Skill

## Purpose

Standardize git usage, branch strategies, commit conventions, and collaborative workflows across
projects.

## Branch Strategy

```
main (production)
   develop (integration)
        feature/user-authentication
        feature/payment-integration
        bugfix/login-error
        release/v1.2.0
```

| Branch      | Purpose                 | Protection            |
| ----------- | ----------------------- | --------------------- |
| `main`      | Production code         | Required PR + review  |
| `develop`   | Integration branch      | Required PR + review  |
| `feature/*` | New features            | PR after completion   |
| `bugfix/*`  | Bug fixes               | PR after completion   |
| `release/*` | Release preparation     | Direct commit allowed |
| `hotfix/*`  | Urgent production fixes | Direct commit allowed |

## Enforcement Profile (Repository Runtime)

1. Direct push to `main` and `develop` is blocked by default.
2. Branch names must follow GitFlow patterns: `feature/*`, `bugfix/*`, `chore/*`, `hotfix/*`,
   `release/*`.
3. PR base mapping is enforced:

- `feature/*`, `bugfix/*`, `chore/*` -> `develop`
- `hotfix/*`, `release/*` -> `main`

4. Override for protected direct push is allowed only with explicit environment variable
   `GITFLOW_ALLOW_PROTECTED_PUSH=1`.

## Commit Convention (Conventional Commits)

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type       | Description                 |
| ---------- | --------------------------- |
| `feat`     | New feature                 |
| `fix`      | Bug fix                     |
| `docs`     | Documentation only          |
| `style`    | Formatting, no code change  |
| `refactor` | Code change, no feature/fix |
| `test`     | Adding tests                |
| `chore`    | Maintenance, deps update    |
| `perf`     | Performance improvement     |
| `ci`       | CI/CD changes               |
| `build`    | Build system changes        |
| `revert`   | Revert previous commit      |

### Examples

```bash
feat(auth): add OAuth2 login with Google

Closes #123
Breaks: #456 (use JWT refresh instead)
```

```bash
fix(api): handle null response from payment provider

The payment provider sometimes returns null instead of
an error object. Added null check to prevent crash.
```

## Branch Naming

```
feature/add-user-profile-page
feature/US-123-user-profile
bugfix/fix-login-timeout
bugfix/gh-456-login-error
hotfix/security-patch-cve-2024
release/v1.2.0
chore/update-dependencies
```

## Daily Workflow

```bash
# Start fresh
git checkout develop

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)