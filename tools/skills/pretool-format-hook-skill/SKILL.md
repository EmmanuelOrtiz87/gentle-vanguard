---
name: pretool-format-hook
description: >
  PreToolUse auto-format hook that runs linter/formatter before AI agent accesses files.
  Eliminates wasted tokens on formatting discussions.
  Trigger: "auto-format", "pretool", "format hook", "format before save"
---

## Purpose
Run linter/formatter **before** AI agent reads saved files to avoid:
- Wasted tokens on "fix indentation"
- "Code has formatting issues" responses
- Manual formatting feedback loops

## Usage

```powershell
# Format single file
.\hooks\pre-tool-format.ps1 -FilePath ".\src\index.ts"

# Dry run (preview)
.\hooks\pre-tool-format.ps1 -FilePath ".\src\index.ts" -DryRun

# Verbose
.\hooks\pre-tool-format.ps1 -FilePath ".\src\index.ts" -Verbose
```

## Supported Languages

| Extension | Formatter |
|-----------|-----------|
| `.ps1` | PowerShell Format |
| `.ts` | Prettier + ESLint |
| `.js` | Prettier + ESLint |
| `.py` | Black + Ruff |
| `.go` | gofmt |
| `.rs` | rustfmt |
| `.json` | JSON formatter |
| `.md` | Prettier |

## Cost Savings

**Per formatting fix:** ~1,000 tokens → ~50 tokens (hook only)

## Integration

See [docs/guides/PRETOOL-FORMAT-HOOK.md](../../docs/guides/PRETOOL-FORMAT-HOOK.md) for:
- OpenCode integration
- Claude Code integration
- VS Code tasks
- Troubleshooting
