# Pull Request Workflow Standards

**Version:** 1.0.0
**Last updated:** 2026-05-14
**Applies to:** All repositories in the gentle-vanguard ecosystem

---

## 1. PR Lifecycle

```
Create PR → Auto-checks (CI) → Review → Address feedback → Approve → Merge → Cleanup
```

| Stage | Owner | Gates |
|-------|-------|-------|
| **Create** | Author | Linter, tests, `agent-verify.ps1` |
| **Auto-checks** | CI | Quality gates (28 checks) |
| **Review** | Reviewer(s) | `rules/CODE-REVIEW-STANDARDS.md` |
| **Address** | Author | All CRIT/WARN resolved or acknowledged |
| **Approve** | Reviewer | No blocking items |
| **Merge** | Author (or admin) | Branch up to date, all checks pass |
| **Cleanup** | Author | Delete branch, update issues |

---

## 2. PR Template

Every PR description MUST follow this structure:

```markdown
## Summary
<!-- One paragraph: what does this PR do? Why? -->

## Type
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation
- [ ] Test
- [ ] Chore
- [ ] Breaking change

## Changes
<!-- List specific files changed and what changed in each -->
- `path/to/file.ps1` — Added validation for X
- `path/to/other.ps1` — Fixed edge case in Y

## Testing
<!-- How was this tested? -->
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing performed

## AI-Generated Code
- [ ] This PR contains AI-generated code
- [ ] AI code has been reviewed per CODE-REVIEW-STANDARDS.md

## References
<!-- Link to issues, tickets, or related PRs -->
Closes #ISSUE_NUMBER
```

---

## 3. Branch Requirements

| Branch | Source | Target | Protection |
|--------|--------|--------|------------|
| `feature/*` | `develop` | `develop` | Linter + tests + 1 review |
| `fix/*` | `develop` | `develop` | Linter + tests |
| `docs/*` | `develop` | `develop` | Linter |
| `release/*` | `develop` | `main` + `develop` | Linter + tests + 2 reviews + security |
| `hotfix/*` | `main` | `main` + `develop` | Linter + tests + 1 review + admin approval |

### Branch Naming
- `feature/description` — new functionality
- `fix/description` — bug fixes
- `docs/description` — documentation only
- `refactor/description` — code restructuring
- `test/description` — test-only changes
- `chore/description` — tooling, CI, dependencies
- `release/version` — release branch (e.g., `release/v2.13.0`)

---

## 4. PR Size Limits

| Metric | Limit | Action |
|--------|-------|--------|
| Files changed | ≤ 20 | Split into multiple PRs if exceeded |
| Lines changed | ≤ 1000 | Split into multiple PRs if exceeded |
| Commits per PR | ≤ 15 | Squash if exceeded |

Exceptions: generated files, lockfiles, data files.

---

## 5. Merge Strategies

| Branch Type | Strategy | Rationale |
|-------------|----------|-----------|
| `feature/*` → `develop` | Squash merge | Clean linear history |
| `fix/*` → `develop` | Squash merge | Clean linear history |
| `release/*` → `main` | Merge commit | Preserves release boundary |
| `release/*` → `develop` | Merge commit | Preserves release boundary |
| `hotfix/*` → `main` | Merge commit | Preserves hotfix boundary |
| `hotfix/*` → `develop` | Merge commit | Preserves hotfix boundary |

---

## 6. Required Status Checks

Before merge, these MUST pass:
- [ ] All quality gates (28 checks)
- [ ] Code review approval (per level)
- [ ] Branch up to date with target
- [ ] No merge conflicts
- [ ] `agent-verify.ps1` — 16/16 passed
- [ ] No secrets detected
- [ ] SDD gate passed (feature branches only)

---

## 7. PR Etiquette

- **Title**: Conventional commit prefix (`feat:`, `fix:`, `docs:`, etc.)
- **Description**: Fill out the template — no empty PRs
- **Scope**: One feature/fix per PR — no scope creep
- **Draft PRs**: Use GitHub Draft PR for work-in-progress
- **Self-review**: Run through checklist before requesting reviewers
- **Response time**: Address feedback within 24h; reviewers respond within 8h
- **Rebasing**: Rebase onto target branch before requesting review
- **Force push**: NEVER force push to shared branches (`develop`, `main`, `release/*`)

---

## 8. References

| Resource | Path |
|----------|------|
| Code Review Standards | `rules/CODE-REVIEW-STANDARDS.md` |
| Dev Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Git Workflow | `skills/git-workflow-skill/SKILL.md` |
| Commit Hygiene | `skills/commit-hygiene-skill/SKILL.md` |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_

