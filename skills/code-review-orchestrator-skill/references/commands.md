## Quick Reference

| Command                      | Description                     |
| ---------------------------- | ------------------------------- |
| `gv review`                  | Full review (all 7 dimensions)  |
| `gv review --scope security` | Security only                   |
| `gv review --scope quality`  | Quality only                    |
| `gv review --scope testing`  | Testing only                    |
| `gv review --scope docs`     | Documentation only              |
| `gv review --scope api`      | API design only                 |
| `gv review --scope git`      | Git workflow only               |
| `gv review --scope quick`    | Security + Quality (fast, ~30s) |
| `gv review --scope full`     | Alias for 'all'                 |
| `gv review --report`         | Generate detailed report        |
| `gv review --track`          | Export issues to CSV            |
| `gv review --verbose`        | Verbose output                  |

## Scope Selection Flow

```
gv review
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

