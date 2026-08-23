---
name: branch-pr
description: >
  PR creation workflow for Agent Teams Lite following the issue-first enforcement system. Trigger:
  When creating a pull request, opening a PR, or preparing changes for review.

triggers:
  - pull request
  - pr
  - branch
  - open pr
  - prepare pr
license: Apache-2.0
metadata:
  author: gentle-vanguard
  version: '2.0'
  source: GV-native
---

## When to Use

Use this skill when:

- Creating a pull request for any change
- Preparing a branch for submission
- Helping a contributor open a PR

---

## Critical Rules

1. **Every PR MUST link an approved issue** no exceptions
2. **Every PR MUST have exactly one `type:*` label**
3. **Automated checks must pass** before merge is possible
4. **Blank PRs without issue linkage will be blocked** by GitHub Actions
5. **400-line review budget** — keep PRs within 400 changed lines (`additions + deletions`) or
   request/obtain maintainer-applied `size:exception` with rationale documented
6. **No `Co-Authored-By` trailers** — never add AI attribution to commits
7. **No force-push to main/master** — protected branch

---

## Workflow

```
1. Verify issue has `status:approved` label
2. Create branch: type/description (see Branch Naming below)
3. Implement changes with conventional commits
4. Run shellcheck on modified scripts
5. Open PR using the template
6. Add exactly one type:* label
7. Wait for automated checks to pass
```

---

## Branch Naming

Branch names MUST match this regex:

```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$
```

**Format:** `type/description` lowercase, no spaces, only `a-z0-9._-` in description.

| Type        | Branch pattern           | Example                         |
| ----------- | ------------------------ | ------------------------------- |
| Feature     | `feat/<description>`     | `feat/user-login`               |
| Bug fix     | `fix/<description>`      | `fix/zsh-glob-error`            |
| Chore       | `chore/<description>`    | `chore/update-ci-actions`       |
| Docs        | `docs/<description>`     | `docs/installation-guide`       |
| Style       | `style/<description>`    | `style/format-scripts`          |
| Refactor    | `refactor/<description>` | `refactor/extract-shared-logic` |
| Performance | `perf/<description>`     | `perf/reduce-startup-time`      |
| Test        | `test/<description>`     | `test/add-setup-coverage`       |
| Build       | `build/<description>`    | `build/update-shellcheck`       |
| CI          | `ci/<description>`       | `ci/add-branch-validation`      |
| Revert      | `revert/<description>`   | `revert/broken-setup-change`    |

---

## PR Body Format

The PR template is at `.github/PULL_REQUEST_TEMPLATE.md`. Every PR body MUST contain:

### 1. Linked Issue (REQUIRED)

```markdown
Closes #<issue-number>
```

Valid keywords: `Closes #N`, `Fixes #N`, `Resolves #N` (case insensitive). The linked issue MUST
have the `status:approved` label.

### 2. PR Type (REQUIRED)

Check exactly ONE in the template and add the matching label:

| Checkbox            | Label to add           |
| ------------------- | ---------------------- |
| Bug fix             | `type:bug`             |
| New feature         | `type:feature`         |
| Documentation only  | `type:docs`            |
| Code refactoring    | `type:refactor`        |
| Maintenance/tooling | `type:chore`           |
| Breaking change     | `type:breaking-change` |

### 3. Summary

1-3 bullet points of what the PR does.

### 4. Changes Table

```markdown
| File           | Change       |
| -------------- | ------------ |
| `path/to/file` | What changed |
```

### 5. Test Plan

```markdown
- [ ] Typecheck passes (`npx tsc --noEmit`)
- [ ] Lint passes (`npm run lint`)
- [ ] Relevant test suites pass (`npm run test:config`, `npm run test:workflows`, etc.)
```

---

## Contributor Checklist

- [ ] PR is linked to an issue with `status:approved`
- [ ] PR stays within 400 changed lines, or I have requested/obtained maintainer-applied
      `size:exception` with rationale documented
- [ ] I have added the appropriate `type:*` label to this PR
- [ ] Typecheck passes (`npx tsc --noEmit`)
- [ ] Lint passes (`npm run lint`)
- [ ] I have updated documentation if necessary
- [ ] My commits follow Conventional Commits format
- [ ] My commits do not include `Co-Authored-By` trailers

---

## Automated Checks

These checks run on every PR and **all must pass** before merge:

| Check                                  | What It Verifies                                                            | How to Fix                                                                                                                  |
| -------------------------------------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Check PR Cognitive Load**            | PR stays within 400 changed lines (`additions + deletions`) or has `size:exception` | Split the PR, or request/obtain maintainer-applied `size:exception` and document the rationale                              |
| **Check Issue Reference**              | PR body contains `Closes/Fixes/Resolves #N`                                 | Add `Closes #<N>` to the PR body                                                                                            |
| **Check Issue Has `status:approved`**  | Linked issue has been approved by a maintainer                              | Wait for maintainer to add `status:approved` to the issue                                                                    |
| **Check PR Has `type:*` Label**        | Exactly one `type:*` label is applied to the PR                             | Ask a maintainer to add the correct label; remove extras                                                                    |
| **Typecheck**                          | `npx tsc --noEmit` passes                                                   | Fix TypeScript errors before pushing                                                                                        |
| **Lint**                               | `npm run lint` passes                                                       | Fix lint errors before pushing                                                                                              |
| **Tests**                              | Stack test suites pass                                                      | Fix failing tests before pushing                                                                                            |

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

| Type      | Purpose                             | PR Label               |
| --------- | ----------------------------------- | ---------------------- |
| `feat`    | New feature                         | `type:feature`         |
| `fix`     | Bug fix                             | `type:bug`             |
| `docs`    | Documentation only                  | `type:docs`            |
| `refactor`| Code change (no behavior change)    | `type:refactor`        |
| `chore`   | Maintenance, dependencies, tooling  | `type:chore`           |
| `style`   | Formatting, linting (no logic change)| `type:chore`          |
| `perf`    | Performance improvement             | `type:feature`         |
| `test`    | Adding or updating tests            | `type:chore`           |
| `build`   | Build system or external deps       | `type:chore`           |
| `ci`      | CI configuration                    | `type:chore`           |
| `revert`  | Reverts a previous commit           | matches reverted type  |

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
  --body "Closes #<N>"
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

---

> **Referencia detallada**: [references/detail.md](references/detail.md)

## Examples

Concrete usage drawn from this skill's own documentation:

```
1. Verify issue has `status:approved` label
2. Create branch: type/description (see Branch Naming below)
3. Implement changes with conventional commits
4. Run shellcheck on modified scripts
5. Open PR using the template
6. Add exactly one type:* label
7. Wait for automated checks to pass
```
