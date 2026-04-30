# Adapters & Integration Layer

**Purpose**: Bridge Foundation capabilities to tools outside the Agent Skills standard (Windsurf, Codex, Antigravity, etc.)

---
## Structure

```
adapters/
 README.md                    # This file
 mcp-bridge/                 # MCP Server exposing Foundation as MCP
    server.ts               # Main MCP server implementation
    tools.ts               # Foundation tools exposed via MCP
    resources.ts            # Context/resources exposed
    package.json           # Node.js dependencies
    README.md              # MCP Bridge documentation
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
## Quick Start

### 1. Start MCP Bridge (exposes Foundation to any MCP client)

```bash
cd adapters/mcp-bridge
npm install
npm run build
npm start
```

### 2. Configure your tool to use the MCP server

**Windsurf** (`~/.windsurf/mcp.json`):
```json
{
  "mcpServers": {
    "foundation": {
      "command": "node",
      "args": ["/path/to/adapters/mcp-bridge/dist/server.js"]
    }
  }
}
```

**Codex** (OpenAI-compatible endpoint):
```bash
# Use format-adapter as proxy
node adapters/format-adapters/codex-adapter/proxy.js
```

---
## Detection Capabilities

The enhanced detection system identifies:

| Tool | Detection Method | Confidence |
|------|-----------------|------------|
| VS Code / Cline | `VSCODE_GIT_IPC_HANDLE`, `TERM_PROGRAM=vscode` | High |
| OpenCode | `OPENCODE_` env vars, process name | High |
| Cursor | `CURSOR_` env vars, process name | High |
| Windsurf | `WINDSURF_` env vars, process name | Medium |
| Codex | `CODEX_` env vars, terminal detection | Medium |
| Antigravity | `ANTIGRAVITY_` env vars | Low |
| JetBrains | `JETBRAINS_IDE`, process detection | Medium |
| Terminal | `TERM_PROGRAM`, fallback | Low |

---
## Adapter Types

### 1. MCP Bridge (Recommended)

Converts Foundation into an **MCP Server** that any MCP-compatible tool can use.

**Benefits**:
-  Universal compatibility (any MCP client)
-  Standard protocol (future-proof)
-  Exposes all Foundation capabilities
-  Token-efficient (MCP handles context)

**Exposed Tools**:
- `foundation_review` - 7D code review
- `foundation_audit` - Workspace audit
- `foundation_delegate` - Subagent delegation
- `foundation_health` - Health check
- `foundation_session` - Session management

---
### 2. Format Adapters

Translates between Foundation's standard format and tool-specific formats.

**When to use**: Tool doesn't support MCP but has its own plugin system.

| Adapter | Input Format | Output Format |
|---------|--------------|---------------|
| windsurf-adapter | Foundation SKILL.md | Windsurf plugin format |
| codex-adapter | Foundation tools | OpenAI function calling |
| antigravity-adapter | Foundation context | Mission Control format |

---
## Rule: ADAPTER-001

**All adapters must**:
1. Preserve token efficiency (no unnecessary context expansion)
2. Log all translations (for debugging)
3. Handle errors gracefully (fallback to basic mode)
4. Respect Foundation's memory tiering
5. Support the detection system

---
## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| MCP Bridge Server |  Pending | Main server implementation |
| Windsurf Adapter |  Pending | Plugin format research needed |
| Codex Adapter |  Pending | OpenAI-compatible endpoint |
| Antigravity Adapter |  Pending | Mission Control integration |
| Enhanced Detection |  Ready | Based on `detect-ide-session.ps1` |
| Documentation |  In Progress | This README complete |

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
**Status**:  In Development
