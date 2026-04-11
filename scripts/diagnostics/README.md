# Diagnostics Scripts

| Script | Purpose |
|---|---|
| system-diagnostics.ps1 | Full diagnostics with optional auto-repair |
| system-diagnostics.sh | Shell wrapper for diagnostics |
| validate-script-governance.ps1 | Policy gate for script registry and startup smoke checks |

## Run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\diagnostics\validate-script-governance.ps1
```
