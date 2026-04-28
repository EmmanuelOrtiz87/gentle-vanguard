# Adapter Architecture

**Date**: 2026-04-28  
**Version**: 1.0.0  
**Status**: 🚧 In Development

---
## Overview

The Adapter Layer enables **any AI tool/IDE** to use Foundation capabilities, regardless of whether they support the Agent Skills standard.

---
## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FOUNDATION CORE                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   7D Review  │  │  SDD Workflow │  │  Engram Mem  │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Subagents   │  │  Skills (65+) │  │  Token Guard │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Exposes via
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   ADAPTER LAYER                                    │
│                                                                   │
│  ┌──────────────────┐    ┌──────────────────┐                  │
│  │   MCP BRIDGE     │    │  FORMAT ADAPTERS │                  │
│  │   (Recommended)  │    │                  │                  │
│  │                  │    │  ┌────────────┐ │                  │
│  │ ✅ Universal    │    │  │ Windsurf    │ │                  │
│  │ ✅ Standard     │    │  └────────────┘ │                  │
│  │ ✅ Future-proof │    │  ┌────────────┐ │                  │
│  │                  │    │  │ Codex       │ │                  │
│  │ MCP Protocol    │    │  └────────────┘ │                  │
│  │ (stdin/stdout)  │    │  ┌────────────┐ │                  │
│  │                  │    │  │ Antigravity  │ │                  │
│  └──────────────────┘    │  └────────────┘ │                  │
│                          └──────────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Used by
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     AI TOOLS & IDES                                │
│                                                                   │
│  ✅ Claude Code    ✅ Cursor      ✅ VS Code + Cline             │
│  ✅ OpenCode       ✅ Copilot    ✅ Continue.dev                 │
│  🚧 Windsurf       🚧 Codex      🚧 Antigravity                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────────┘
```

---
## Adapter Types

### 1. MCP Bridge (Primary Solution)

**Location**: `adapters/mcp-bridge/`

Converts Foundation into an **MCP Server** that any MCP-compatible tool can use.

**Benefits**:
- ✅ Universal (any MCP client)
- ✅ Standard protocol (future-proof)
- ✅ Exposes all Foundation capabilities
- ✅ Token-efficient (MCP handles context)

**Exposed Tools**:
- `foundation_review` - 7D code review
- `foundation_audit` - Workspace audit
- `foundation_delegate` - Subagent delegation
- `foundation_health` - Health check
- `foundation_session_start/end` - Session management
- `foundation_skill_list/load` - Skill management

**MCP Clients Supported**:
- Windsurf (via MCP config)
- Codex (via MCP config)
- Antigravity (if MCP-compatible)
- Claude Desktop
- Cursor
- OpenCode
- Any tool with MCP support

---
### 2. Format Adapters (Fallback Solution)

**Location**: `adapters/format-adapters/{tool}-adapter/`

Translates between Foundation's standard format and tool-specific formats.

**When to use**: Tool doesn't support MCP but has its own plugin system.

| Adapter | Input Format | Output Format | Status |
|---------|--------------|---------------|--------|
| `windsurf-adapter/` | Foundation SKILL.md | Windsurf plugin | 🚧 Pending |
| `codex-adapter/` | Foundation tools | OpenAI functions | 🚧 Pending |
| `antigravity-adapter/` | Foundation context | Mission Control | 🚧 Pending |

---
## Data Flow

### MCP Bridge Flow

```
Tool (Windsurf, Codex, etc.)
    │
    │ MCP Protocol (stdin/stdout)
    ▼
MCP Bridge Server (adapters/mcp-bridge/)
    │
    │ Calls Foundation CLI/Scripts
    ▼
Foundation Core (7D Review, SDD, Engram, etc.)
```

### Format Adapter Flow

```
Tool (Windsurf, Codex, etc.)
    │
    │ Tool-specific format
    ▼
Format Adapter (adapters/format-adapters/)
    │
    │ Translates to Foundation format
    ▼
Foundation Core (via CLI/Scripts)
```

---
## Detection System

**Script**: `adapters/detection/enhanced-detect.ps1`

Detects running tool and recommends adapter:

| Tool | Detection Method | Confidence | MCP Support |
|------|-----------------|------------|-------------|
| VS Code / Cline | `VSCODE_GIT_IPC_HANDLE` | High | ✅ |
| OpenCode | `OPENCODE_` env vars | High | ✅ |
| Cursor | `CURSOR_` env vars | High | ✅ |
| Windsurf | `WINDSURF_` env vars | Medium | 🚧 Research |
| Codex | `CODEX_` env vars | Medium | ❌ |
| Antigravity | `ANTIGRAVITY_` env vars | Low | ❌ |
| JetBrains | `JETBRAINS_IDE` | Medium | ❌ |
| Terminal | `TERM_PROGRAM` | Low | ❌ |

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

| Component | Status | Priority | Notes |
|-----------|--------|----------|-------|
| MCP Bridge Server | ⏳ Pending | HIGH | Main server implementation |
| MCP Tools (6 tools) | ⏳ Pending | HIGH | review, audit, delegate, etc. |
| Enhanced Detection | ✅ Ready | HIGH | In `adapters/detection/` |
| Windsurf Adapter | ⏳ Pending | MEDIUM | Research plugin format |
| Codex Adapter | ⏳ Pending | LOW | OpenAI function calling |
| Antigravity Adapter | ⏳ Pending | LOW | Mission Control API |
| Documentation | ✅ In Progress | HIGH | This file complete |
| Rule TECH-ADAPTER-001 | ✅ Active | HIGH | Enforces detection |

---
## Next Steps

1. **Implement MCP Bridge** (highest priority - covers 80% of use cases)
2. **Complete enhanced detection** testing
3. **Create format adapters** for remaining tools
4. **Update compatibility matrix** with new capabilities
5. **Test end-to-end** with Windsurf, Codex, Antigravity

---
**Author**: Foundation Team  
**Last Updated**: 2026-04-28
