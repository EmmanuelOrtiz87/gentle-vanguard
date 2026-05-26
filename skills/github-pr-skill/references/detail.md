```bash
gh pr create --title "feat(dashboard): add analytics" --body "$(cat <<'EOF'
## Summary
- Add real-time analytics dashboard

## Changes
- Created AnalyticsProvider
- Added LineChart, BarChart components

## Testing
- [x] Unit tests for components
- [x] Manual testing complete

## Screenshots
![Dashboard](https://placeholder.com/dashboard.png) <!-- TODO: Add actual screenshot -->

Closes #123
EOF
)"
```

### Draft PR

```bash
gh pr create --draft \
  --title "wip: refactor auth" \
  --body "Work in progress"
```

### PR with Reviewers and Labels

```bash
gh pr create \
  --title "feat(api): add rate limiting" \
  --body "Adds rate limiting to API" \
  --reviewer "user1,user2" \
  --label "enhancement,api"
```

---

## Commands

```bash
# Create PR
gh pr create --title "type(scope): desc" --body "..."

# Create with web editor
gh pr create --web

# View PR status
gh pr status

# View diff
gh pr diff

# Check CI status
gh pr checks

# Merge with squash
gh pr merge --squash

# Add reviewer
gh pr edit --add-reviewer username
```

---

## Anti-Patterns

### Don't: Vague Titles

```bash
# Bad
gh pr create --title "fix bug"
gh pr create --title "update"

# Good
gh pr create --title "fix(auth): prevent session timeout"
```

### Don't: Giant PRs

```bash
# Bad: 50 files, 2000+ lines in one PR

# Good: Split into logical PRs
# PR 1: feat(models): add User model
# PR 2: feat(api): add user endpoints
# PR 3: feat(ui): add user pages
```

### Don't: Empty Descriptions

```bash
# Bad
--body "Added feature"

# Good
--body "## Summary
- What you did and why

## Changes
- Specific changes

Closes #123"
```

---

## Quick Reference

| Task         | Command                                  |
| ------------ | ---------------------------------------- |
| Create PR    | `gh pr create -t "type: desc" -b "body"` |
| Draft PR     | `gh pr create --draft`                   |
| Web editor   | `gh pr create --web`                     |
| Add reviewer | `--reviewer user1,user2`                 |
| Add label    | `--label bug,high-priority`              |
| Link issue   | `Closes #123` in body                    |
| View status  | `gh pr status`                           |
| Merge squash | `gh pr merge --squash`                   |

## Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI Manual](https://cli.github.com/manual/gh_pr_create)
