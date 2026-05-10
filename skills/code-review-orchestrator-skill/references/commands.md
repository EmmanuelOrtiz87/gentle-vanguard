## Quick Reference

| Command                      | Description                     |
| ---------------------------- | ------------------------------- |
| `wf review`                  | Full review (all 7 dimensions)  |
| `wf review --scope security` | Security only                   |
| `wf review --scope quality`  | Quality only                    |
| `wf review --scope testing`  | Testing only                    |
| `wf review --scope docs`     | Documentation only              |
| `wf review --scope api`      | API design only                 |
| `wf review --scope git`      | Git workflow only               |
| `wf review --scope quick`    | Security + Quality (fast, ~30s) |
| `wf review --scope full`     | Alias for 'all'                 |
| `wf review --report`         | Generate detailed report        |
| `wf review --track`          | Export issues to CSV            |
| `wf review --verbose`        | Verbose output                  |

## Scope Selection Flow

```
wf review
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
