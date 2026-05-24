git pull --rebase

# Create feature branch
git checkout -b feature/my-feature

# Work and commit
git add .
git commit -m "feat(scope): description"

# Sync with develop
git fetch origin
git rebase origin/develop

# Push and create PR
git push -u origin feature/my-feature
```

## Handling Merge Conflicts

```bash
# During rebase
git rebase origin/develop
# Conflict detected

# 1. Fix conflicts
git add file1.js file2.js

# 2. Continue rebase
git rebase --continue

# 3. Force push (after confirming)
git push --force-with-lease

# Alternative: merge instead of rebase
git checkout feature/my-feature
git merge develop
# Fix conflicts
git add .
git commit
git push
```

## Pull Request Checklist

- [ ] Branch is up-to-date with target
- [ ] Tests pass locally
- [ ] Commits follow convention
- [ ] PR description is clear
- [ ] Related issues are linked
- [ ] Documentation updated
- [ ] No secrets committed

## PR Template

```markdown
## Summary

Brief description of changes.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing

How was this tested?

## Screenshots (if applicable)

## Checklist

- [ ] My code follows the style guidelines
- [ ] I have performed self-review
- [ ] I have commented complex code
- [ ] I have updated documentation
```

## Useful Aliases

```bash
# Add to ~/.gitconfig or ~/.gitconfig

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --graph --oneline --decorate --all
    amend = commit --amend --no-edit
    undo = reset --soft HEAD~1
    clean-branches = !git branch --merged | grep -v '\\*\\|main\\|develop' | xargs -r git branch -d
```

## Common Commands Reference

```bash
# Sync
git fetch --all
git pull --rebase

# Branching
git checkout -b feature/name
git push -u origin feature/name

# Committing
git add -p  # Stage patches
git commit --amend
git rebase -i HEAD~3  # Interactive rebase

# Merging
git merge --no-ff feature/name
git merge --squash feature/name

# Tags
git tag v1.0.0
git tag -a v1.0.0 -m "versión 1.0.0"
git push origin v1.0.0

# Stash
git stash
git stash pop
git stash list
git stash drop

# History
git log --oneline --graph --all
git blame file.js
git show commit-id
```