# Branching Strategy

## Trunk-Based Development (Recommended)

Keep `main` always deployable. Work in short-lived feature branches that merge back within 1-3 days.
Long-lived development branches are hidden costs — they diverge, create merge conflicts, and delay
integration. DORA research consistently shows trunk-based development correlates with
high-performing engineering teams.

```
main ──●──●──●──●──●──●──●──●──●──  (always deployable)
        ╲      ╱  ╲    ╱
         ●──●─╱    ●──╱    ← short-lived feature branches (1-3 days)
```

This is the recommended default. Teams using gitflow or long-lived branches can adapt the principles
(atomic commits, small changes, descriptive messages) to their branching model — the commit
discipline matters more than the specific branching strategy.

- **Dev branches are costs.** Every day a branch lives, it accumulates merge risk.
- **Release branches are acceptable.** When you need to stabilize a release while main moves
  forward.
- **Feature flags > long branches.** Prefer deploying incomplete work behind flags rather than
  keeping it on a branch for weeks.

## Feature Branches

```
main (always deployable)
  │
  ├── feature/task-creation    ← One feature per branch
  ├── feature/user-settings    ← Parallel work
  └── fix/duplicate-tasks      ← Bug fixes
```

- Branch from `main` (or the team's default branch)
- Keep branches short-lived (merge within 1-3 days) — long-lived branches are hidden costs
- Delete branches after merge
- Prefer feature flags over long-lived branches for incomplete features

## Branch Naming

```
feature/<short-description>   → feature/task-creation
fix/<short-description>       → fix/duplicate-tasks
chore/<short-description>     → chore/update-deps
refactor/<short-description>  → refactor/auth-module
```

## Working with Worktrees

For parallel AI agent work, use git worktrees to run multiple branches simultaneously:

```bash
# Create a worktree for a feature branch
git worktree add ../project-feature-a feature/task-creation
git worktree add ../project-feature-b feature/user-settings

# Each worktree is a separate directory with its own branch
# Agents can work in parallel without interfering
ls ../
  project/              ← main branch
  project-feature-a/    ← task-creation branch
  project-feature-b/    ← user-settings branch

# When done, merge and clean up
git worktree remove ../project-feature-a
```

Benefits:

- Multiple agents can work on different features simultaneously
- No branch switching needed (each directory has its own branch)
- If one experiment fails, delete the worktree — nothing is lost
- Changes are isolated until explicitly merged
