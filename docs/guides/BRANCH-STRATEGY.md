# Branch Strategy

## Main Branches

| Branch    | Purpose                                                              | Lifetime  |
| --------- | -------------------------------------------------------------------- | --------- |
| `main`    | Stable, production-ready code. Protected by pre-push hooks.          | Permanent |
| `develop` | Integration branch. Fast-forward merged from `main` on each release. | Permanent |

## Supporting Branches

| Branch      | Purpose                      | Lifetime              | Merges To     |
| ----------- | ---------------------------- | --------------------- | ------------- |
| `feat/*`    | New features                 | Until merged          | `main` via PR |
| `fix/*`     | Bug fixes                    | Until merged          | `main` via PR |
| `chore/*`   | Maintenance, CI, docs        | Until merged          | `main` via PR |
| `release/*` | Release preparation (legacy) | Deprecated — use tags | —             |

## Workflow

```mermaid
gitGraph
   commit
   branch develop
   checkout develop
   branch feat/new-feature
   commit
   commit
   checkout main
   merge feat/new-feature
   checkout develop
   merge main
```

1. **Create branch** from `main`: `feat/description`, `fix/issue-id`, `chore/description`
2. **Develop and test**: Run `npm test`, verify pre-commit hooks pass
3. **Submit PR** to `main`: Use conventional commit title, include description
4. **Merge**: Via PR with CI checks passing
5. **Release**: Tag `main`, fast-forward `develop`

## Rules

- `main` must always be releasable (all tests pass, 0 audit issues)
- Feature branches should be short-lived (days, not weeks)
- Squash merge recommended for PRs to keep history clean
- Delete branch after merge
