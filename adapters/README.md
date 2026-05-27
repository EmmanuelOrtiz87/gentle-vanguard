# Adapters & Integration Layer

**Purpose**: Bridge Gentle-Vanguard capabilities to tools outside the Agent Skills standard
(Windsurf, Codex, Antigravity, etc.)

---

## Structure

```
adapters/
 README.md                    # This file
 format-adapters/            # Format translators for non-standard tools
    windsurf-adapter/      # Windsurf format adapter
    codex-adapter/         # OpenAI Codex adapter
    antigravity-adapter/   # Antigravity Mission Control adapter
    README.md              # Format adapters guide
 docs/
    ARCHITECTURE.md        # Adapter architecture
    COMPATIBILITY-MATRIX.md# Updated compatibility matrix
    IMPLEMENTATION-GUIDE.md# How to implement new adapters
 detection/
     enhanced-detect.ps1    # Enhanced IDE/tool detection
```

---

**Codex** (OpenAI-compatible endpoint):

```bash
# Use format-adapter as proxy
node adapters/format-adapters/codex-adapter/proxy.js
```

---

## Detection Capabilities

The enhanced detection system identifies:

| Tool            | Detection Method                               | Confidence |
| --------------- | ---------------------------------------------- | ---------- |
| VS Code / Cline | `VSCODE_GIT_IPC_HANDLE`, `TERM_PROGRAM=vscode` | High       |
| OpenCode        | `OPENCODE_` env vars, process name             | High       |
| Cursor          | `CURSOR_` env vars, process name               | High       |
| Windsurf        | `WINDSURF_` env vars, process name             | Medium     |
| Codex           | `CODEX_` env vars, terminal detection          | Medium     |
| Antigravity     | `ANTIGRAVITY_` env vars                        | Low        |
| JetBrains       | `JETBRAINS_IDE`, process detection             | Medium     |
| Terminal        | `TERM_PROGRAM`, fallback                       | Low        |

---

## Adapter Types

### 1. MCP Bridge (Recommended)

Converts Gentle-Vanguard into an **MCP Server** that any MCP-compatible tool can use.

**Benefits**:

- Universal compatibility (any MCP client)
- Standard protocol (future-proof)
- Exposes all Gentle-Vanguard capabilities
- Token-efficient (MCP handles context)

**Exposed Tools**:

- `gentle-vanguard_review` - 7D code review
- `gentle-vanguard_audit` - Workspace audit
- `gentle-vanguard_delegate` - Subagent delegation
- `gentle-vanguard_health` - Health check
- `gentle-vanguard_session` - Session management

---

### 2. Format Adapters

Translates between Gentle-Vanguard's standard format and tool-specific formats.

**When to use**: Tool doesn't support MCP but has its own plugin system.

| Adapter             | Input Format             | Output Format           |
| ------------------- | ------------------------ | ----------------------- |
| windsurf-adapter    | Gentle-Vanguard SKILL.md | Windsurf plugin format  |
| codex-adapter       | Gentle-Vanguard tools    | OpenAI function calling |
| antigravity-adapter | Gentle-Vanguard context  | Mission Control format  |

---

## Rule: ADAPTER-001

**All adapters must**:

1. Preserve token efficiency (no unnecessary context expansion)
2. Log all translations (for debugging)
3. Handle errors gracefully (fallback to basic mode)
4. Respect Gentle-Vanguard's memory tiering
5. Support the detection system

---

## Implementation Status

| Component           | Status      | Notes                                         |
| ------------------- | ----------- | --------------------------------------------- |
| MCP Bridge Server   | ✅ Ready    | Main server implemented (server.ts, tools.ts) |
| Windsurf Adapter    | ✅ Ready    | Plugin format converter complete              |
| Codex Adapter       | ✅ Ready    | OpenAI function calling format complete       |
| Antigravity Adapter | ✅ Ready    | Mission Control integration complete          |
| Enhanced Detection  | ✅ Ready    | Variables env corregidas                      |
| Documentation       | ✅ Complete | Multi-tool guide created                      |

---

## Next Steps

1. **Implement MCP Bridge** (highest priority - covers 80% of use cases)
2. **Enhance detection** in `detect-ide-session.ps1`
3. **Create format adapters** for remaining tools
4. **Update compatibility matrix** with new capabilities
5. **Test end-to-end** with Windsurf, Codex, Antigravity

---

**Generated**: 2026-04-28  
**Version**: 1.0.0  
**Status**: In Development
