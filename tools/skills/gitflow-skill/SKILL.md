---
name: gitflow
description: Git flow governance skill - enforces branch strategy and commit conventions
---

# Gitflow Skill

REJECT if:
- Commits to protected branches (main/master) without PR
- Commit messages not following conventional commits

REQUIRE:
- Feature branches for new work
- PR review before merge to main

PREFER:
- Descriptive, atomic commits
