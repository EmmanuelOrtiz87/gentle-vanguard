## Quick Reference

| Command                      | Description                     |
| ---------------------------- | ------------------------------- |
| `foundation review`                  | Full review (all 7 dimensions)  |
| `foundation review --scope security` | Security only                   |
| `foundation review --scope quality`  | Quality only                    |
| `foundation review --scope testing`  | Testing only                    |
| `foundation review --scope docs`     | Documentation only              |
| `foundation review --scope api`      | API design only                 |
| `foundation review --scope git`      | Git workflow only               |
| `foundation review --scope quick`    | Security + Quality (fast, ~30s) |
| `foundation review --scope full`     | Alias for 'all'                 |
| `foundation review --report`         | Generate detailed report        |
| `foundation review --track`          | Export issues to CSV            |
| `foundation review --verbose`        | Verbose output                  |

## Scope Selection Flow

```
foundation review
    |
    +-- --scope required
    |       |
    |       +-- all (7 dims)     security (1 dim)
    |       +-- quality (1 dim)  testing (1 dim)
    |       +-- quick (2 dims)   docs (1 dim)
    |       +-- api (1 dim)      git (1 dim)
    |
    +-- (default) all
    +-- --help
```

## Performance Estimates

| Scope    | Dimensions | Est. Time |
| -------- | ---------- | --------- |
| quick    | 2          | ~30s      |
| security | 1          | ~15s      |
| quality  | 1          | ~15s      |
| all      | 7          | ~2-5min   |

_Times vary based on project size and disk I/O_
