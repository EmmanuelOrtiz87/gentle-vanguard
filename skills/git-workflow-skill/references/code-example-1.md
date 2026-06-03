# Code Example 1

From: SKILL.md

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
