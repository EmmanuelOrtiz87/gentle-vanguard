---
name: branch-pr
description: Create pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review.
triggers:
  - pull request
  - pr
  - branch
  - open pr
  - prepare pr
license: Apache-2.0
metadata:
  author: gentleman-programming (ported to Gentle-Vanguard)
  version: "2.0"
---

# Branch & PR Skill

## When to Use

Load this skill whenever you need to:

- Create a branch for a new fix or feature
- Open a pull request on the Gentle-Vanguard repository (`EmmanuelOrtiz87/gentle-vanguard`)
- Prepare changes for review

## Critical Rules

1. **Every PR MUST link an approved issue** — `Closes/Fixes/Resolves #<N>` in the PR body, and that issue MUST have `status:approved`. PRs without this are **automatically rejected** by CI.
2. **Exactly one `type:*` label** — apply exactly ONE type label to the PR. CI will reject PRs with zero or multiple type labels.
3. **400-line review budget** — keep PRs within 400 changed lines (`additions + deletions`) or request/obtain maintainer-applied `size:exception` with rationale documented.
4. **Automated checks must pass** — typecheck, lint, and test suites before merge.
5. **No `Co-Authored-By` trailers** — never add AI attribution to commits.
6. **No force-push to main/master** — protected branch.

## Workflow

```
1. Confirm the issue has status:approved
   gh issue view <N> --repo EmmanuelOrtiz87/gentle-vanguard

2. Create a branch from main using the naming convention below

3. Implement changes following specs and design

4. Run checks locally (typecheck + lint + tests)

5. Commit using Conventional Commits format

6. Open a PR referencing the issue
   → Add exactly ONE type:* label
   → Fill in the PR body using the template

7. All automated checks must pass before merge
```

---

## Branch Naming

Branch names **must** match this pattern:

```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$
```

| Type | Example |
|------|---------|
| `feat/` | `feat/user-login` |
| `fix/` | `fix/duplicate-observation-insert` |
| `docs/` | `docs/api-reference-update` |
| `refactor/` | `refactor/extract-query-sanitizer` |
| `chore/` | `chore/bump-pnpm-lock` |
| `style/` | `style/fix-linter-warnings` |
| `perf/` | `perf/optimize-catalog-loading` |
| `test/` | `test/add-pipeline-coverage` |
| `build/` | `build/update-pipeline-config` |
| `ci/` | `ci/add-e2e-docker-job` |
| `revert/` | `revert/undo-model-picker-change` |

**Rules:**

- All lowercase
- Use hyphens, dots, or underscores as separators (no spaces, no uppercase)
- Description must be short and descriptive

---

## PR Body Format

The PR body must follow the template at `.github/PULL_REQUEST_TEMPLATE.md`. All sections are required unless marked optional.

```markdown
## 🔗 Linked Issue

Closes #<N>

## 🏷️ PR Type

- [ ] `type:bug` — Bug fix (non-breaking change that fixes an issue)
- [ ] `type:feature` — New feature (non-breaking change that adds functionality)
- [ ] `type:docs` — Documentation only
- [ ] `type:refactor` — Code refactoring (no functional changes)
- [ ] `type:chore` — Build, CI, or tooling changes
- [ ] `type:breaking-change` — Breaking change

## 📝 Summary

<!-- Clear description of what this PR does and why. -->

## 📂 Changes

| File / Area | What Changed |
|-------------|-------------|
| `path/to/file` | Brief description |

## 🧪 Test Plan

**Typecheck**
```bash
npx tsc --noEmit
```

**Lint**
```bash
npm run lint
```

**Tests**
```bash
npm run test:config
```

- [ ] Typecheck passes (`npx tsc --noEmit`)
- [ ] Lint passes (`npm run lint`)
- [ ] Tests pass
- [ ] Manually tested locally

## ✅ Contributor Checklist

- [ ] PR is linked to an issue with `status:approved`
- [ ] PR stays within 400 changed lines, or I have requested/obtained maintainer-applied `size:exception` with rationale documented
- [ ] I have added the appropriate `type:*` label to this PR
- [ ] Typecheck passes (`npx tsc --noEmit`)
- [ ] Lint passes (`npm run lint`)
- [ ] I have updated documentation if necessary
- [ ] My commits follow Conventional Commits format
- [ ] My commits do not include `Co-Authored-By` trailers
```

---

## Automated Checks

These checks run on every PR and **all must pass** before merge:

| Check | What It Verifies | How to Fix |
|-------|-----------------|------------|
| **Check PR Cognitive Load** | PR stays within 400 changed lines (`additions + deletions`) or has `size:exception` | Split the PR, or request/obtain maintainer-applied `size:exception` and document the rationale |
| **Check Issue Reference** | PR body contains `Closes/Fixes/Resolves #N` | Add `Closes #<N>` to the PR body |
| **Check Issue Has `status:approved`** | Linked issue has been approved by a maintainer | Wait for maintainer to add `status:approved` to the issue |
| **Check PR Has `type:*` Label** | Exactly one `type:*` label is applied to the PR | Ask a maintainer to add the correct label; remove extras |
| **Typecheck** | `npx tsc --noEmit` passes | Fix TypeScript errors before pushing |
| **Lint** | `npm run lint` passes | Fix lint errors before pushing |
| **Tests** | Stack test suites pass | Fix failing tests before pushing |

---

## Conventional Commits

Commit messages **must** match this pattern:

```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+
```

### Format

```
<type>(<optional-scope>)!: <description>

[optional body]

[optional footer]
```

### Allowed Types

| Type | Purpose | PR Label |
|------|---------|----------|
| `feat` | New feature | `type:feature` |
| `fix` | Bug fix | `type:bug` |
| `docs` | Documentation only | `type:docs` |
| `refactor` | Code change (no behavior change) | `type:refactor` |
| `chore` | Maintenance, dependencies, tooling | `type:chore` |
| `style` | Formatting, linting (no logic change) | `type:chore` |
| `perf` | Performance improvement | `type:feature` |
| `test` | Adding or updating tests | `type:chore` |
| `build` | Build system or external deps | `type:chore` |
| `ci` | CI configuration | `type:chore` |
| `revert` | Reverts a previous commit | matches reverted type |

### Breaking Changes

Add `!` after the type/scope:

```
feat(cli)!: rename --config flag to --config-file

BREAKING CHANGE: the --config flag has been renamed to --config-file.
```

Breaking changes map to `type:breaking-change` label.

### Examples

```
feat(tui): add progress bar to installation steps
fix(agent): correct agent detection on macOS
docs: update contributing guide
chore(deps): bump typescript to latest
refactor(pipeline): extract step executor
style: fix linter warnings in catalog package
perf(system): cache OS detection result
test(installer): add coverage for catalog step execution
build: update pipeline config for arm64
ci: split unit and e2e test jobs
revert: undo model picker redesign
feat(cli)!: change default config path
```

---

## Commands

### Setup

```bash
# Confirm issue is approved before starting
gh issue view <N> --repo EmmanuelOrtiz87/gentle-vanguard

# Create branch
git checkout main && git pull
git checkout -b fix/<short-description>
```

### Testing Locally

```bash
# Typecheck
npx tsc --noEmit

# Lint
npm run lint

# Stack test suites
npm run test:config
npm run test:workflows
npm run test:research
```

### Open a PR

```bash
gh pr create \
  --repo EmmanuelOrtiz87/gentle-vanguard \
  --title "fix(agent): correct agent detection on Linux" \
  --body "$(cat <<'EOF'
## 🔗 Linked Issue

Closes #42

## 🏷️ PR Type

- [x] `type:bug` — Bug fix (non-breaking change that fixes an issue)

## 📝 Summary

Fixes agent binary detection failing on Linux when HOME is not set.

## 📂 Changes

| File / Area | What Changed |
|-------------|-------------|
| `src/agent-detection.ts` | Added HOME env var fallback |

## 🧪 Test Plan

- [x] Typecheck passes (`npx tsc --noEmit`)
- [x] Lint passes (`npm run lint`)
- [x] Manually tested locally

## ✅ Contributor Checklist

- [x] PR is linked to an issue with `status:approved`
- [x] PR stays within 400 changed lines, or I have requested/obtained maintainer-applied `size:exception` with rationale documented
- [x] I have added the appropriate `type:*` label to this PR
- [x] Typecheck passes (`npx tsc --noEmit`)
- [x] Lint passes (`npm run lint`)
- [x] I have updated documentation if necessary
- [x] My commits follow Conventional Commits format
- [x] My commits do not include `Co-Authored-By` trailers
EOF
)"
```

### Check PR Status

```bash
gh pr checks --repo EmmanuelOrtiz87/gentle-vanguard <PR-number>
gh pr view --repo EmmanuelOrtiz87/gentle-vanguard <PR-number>
```

### Add a Label

```bash
gh pr edit <PR-number> --repo EmmanuelOrtiz87/gentle-vanguard --add-label "type:bug"
```
