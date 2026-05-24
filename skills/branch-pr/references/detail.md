````markdown
## Test Plan

**Unit Tests**

```bash
go test ./...
```
````

**E2E Tests** (if applicable)

```bash
cd e2e && ./docker-test.sh
```

- [x] Scripts run without errors: `shellcheck scripts/*.sh`
- [x] Manually tested the affected functionality
- [x] Skills load correctly in target agent

```

### 6. Contributor Checklist

All boxes must be checked:
- [ ] PR is linked to an issue with `status:approved`
- [ ] PR stays within 400 changed lines, or has `size:exception` with rationale documented
- [ ] Added exactly one `type:*` label
- [ ] Ran shellcheck on modified scripts
- [ ] Skills tested in at least one agent
- [ ] Docs updated if behavior changed
- [ ] Conventional commit format
- [ ] No `Co-Authored-By` trailers

---

## Automated Checks (all must pass)

| Check | Job name | What it verifies |
|-------|----------|-----------------|
| PR Validation | `Check Issue Reference` | Body contains `Closes/Fixes/Resolves #N` |
| PR Validation | `Check Issue Has status:approved` | Linked issue has `status:approved` |
| PR Validation | `Check PR Has type:* Label` | PR has exactly one `type:*` label |
| CI | `Shellcheck` | Shell scripts pass `shellcheck` |

---

## Conventional Commits

Commit messages MUST match this regex:

```

^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+

```

**Format:** `type(scope): description` or `type: description`

- `type`  required, one of: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`
- `(scope)`  optional, lowercase with `a-z0-9._-`
- `!`  optional, indicates breaking change
- `description`  required, starts after `: `

Type-to-label mapping:

| Commit type | PR label |
|-------------|----------|
| `feat` | `type:feature` |
| `fix` | `type:bug` |
| `docs` | `type:docs` |
| `refactor` | `type:refactor` |
| `chore` | `type:chore` |
| `style` | `type:chore` |
| `perf` | `type:feature` |
| `test` | `type:chore` |
| `build` | `type:chore` |
| `ci` | `type:chore` |
| `revert` | `type:bug` |
| `feat!` / `fix!` | `type:breaking-change` |

Examples:
```

feat(scripts): add Codex support to setup.sh fix(skills): correct topic key format in sdd-apply
docs(readme): update multi-model configuration guide refactor(skills): extract shared persistence
logic chore(ci): add shellcheck to PR validation workflow perf(scripts): reduce setup.sh execution
time style(skills): fix markdown formatting test(scripts): add setup.sh integration tests
ci(workflows): add branch name validation revert: undo broken setup change feat!: redesign skill
loading system

````

---

## Commands

```bash
# Create branch
git checkout -b feat/my-feature main

# Run shellcheck before pushing
shellcheck scripts/*.sh

# Push and create PR
git push -u origin feat/my-feature
gh pr create --title "feat(scope): description" --body "Closes #N"

# Add type label to PR
gh pr edit <pr-number> --add-label "type:feature"
````