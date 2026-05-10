# Audit System

The `.audit` directory contains structured records of AI-assisted development activity.

## Quick Reference

| Command                | When       | Result                   |
| ---------------------- | ---------- | ------------------------ |
| `init-workspace.ps1`   | Start work | Session begins           |
| `finalize-session.ps1` | End work   | Audit + metrics captured |

## Files Generated

- `sessions/*.json` - Individual session records
- `metrics/daily.json` - Today's metrics
- `metrics/weekly.json` - This week's metrics
- `reports/weekly-*.md` - Weekly reports (Sun/Mon)

## See Also

- `docs/audit-system.md` - Full documentation
