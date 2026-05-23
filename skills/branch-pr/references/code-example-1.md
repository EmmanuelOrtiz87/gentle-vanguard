# Code Example 1

From: SKILL.md

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
