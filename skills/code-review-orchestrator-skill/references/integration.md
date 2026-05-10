## Git Hooks

```
.git/hooks/
 pre-commit               Auto-installed
    pre-commit-review.ps1 (or .sh)
 pre-push                Optional
 commit-msg              Optional (conventional commits)
```

## CI/CD Integration

```yaml
# GitHub Actions Example
- name: Code Review
  run: |
    ./scripts/utilities/wf.ps1 review --scope all --report
    ./scripts/utilities/wf.ps1 review --track

- name: Upload Review Report
  uses: actions/upload-artifact@v7
  with:
    name: code-review-report
    path: docs/code-reviews/
```
