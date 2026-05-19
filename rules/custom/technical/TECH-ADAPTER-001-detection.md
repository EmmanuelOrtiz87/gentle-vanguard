# TECH-ADAPTER-001: Tool Detection and Adapter Selection

**Scope**: technical  
**ID**: TECH-ADAPTER-001  
**Version**: 1.0.0  
**Status**: Active

---

## Rule

All Gentle-Vanguard integrations MUST use the **enhanced detection system**
(`adapters/detection/enhanced-detect.ps1`) to:

1. **Identify the running tool/IDE** (VS Code, Cursor, Windsurf, Codex, etc.)
2. **Determine capability level** (MCP support, skills, subagents)
3. **Select appropriate adapter** (MCP Bridge vs Format Adapter)
4. **Log detection results** for telemetry

---

## Detection Priority

When multiple tools could be detected, use this priority (highest first):

1. **Windsurf** - Check `WINDSURF_` env or process name
2. **Codex** - Check `CODEX_` env or `TERM_PROGRAM`
3. **Antigravity** - Check `ANTIGRAVITY_` env
4. **OpenCode** - Check `OPENCODE_` env or process name
5. **Cursor** - Check `CURSOR_` env or process name
6. **VS Code** - Check `VSCODE_GIT_IPC_HANDLE` or `TERM_PROGRAM=vscode`
7. **JetBrains** - Check `JETBRAINS_IDE` or process name
8. **Terminal** - Fallback

---

## Adapter Selection Logic

```
IF tool supports MCP:
    USE MCP Bridge (adapters/mcp-bridge/)
ELSE IF format adapter exists for tool:
    USE format adapter (adapters/format-adapters/{tool}/)
ELSE:
    IMPLEMENT new adapter (see adapters/README.md)
```

---

## Required Environment Variables

The detection system checks these environment variables:

| Variable                | Tool            | Purpose                  |
| ----------------------- | --------------- | ------------------------ |
| `WINDSURF_`             | Windsurf        | Detection                |
| `CODEX_`                | Codex           | Detection                |
| `ANTIGRAVITY_`          | Antigravity     | Detection                |
| `OPENCODE_`             | OpenCode        | Detection                |
| `CURSOR_`               | Cursor          | Detection                |
| `VSCODE_GIT_IPC_HANDLE` | VS Code         | Detection                |
| `JETBRAINS_IDE`         | JetBrains       | Detection                |
| `GV_ROOT`               | Gentle-Vanguard | Root path for MCP Bridge |

---

## Output Format

Detection results MUST include:

```json
{
  "toolName": "windsurf",
  "confidence": "medium",
  "supportsMcp": false,
  "supportsSkills": false,
  "recommendation": "Use format adapter at adapters/format-adapters/windsurf-adapter"
}
```

---

## Enforcement

- **Pre-commit hook**: Validate detection script exists
- **Session start**: Run detection automatically
- **Telemetry**: Log detection results to `logs/tool-detection.log`

---

## Exceptions

None. All tools MUST be detected before adapter selection.

---

## References

- Detection script: `adapters/detection/enhanced-detect.ps1`
- MCP Bridge: `adapters/mcp-bridge/README.md`
- Format Adapters: `adapters/format-adapters/README.md`
- Examples: `adapters/docs/EXAMPLES.md`

---

**Created**: 2026-04-28  
**Last Modified**: 2026-04-28
