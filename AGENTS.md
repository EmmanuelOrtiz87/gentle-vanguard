# Workspace Agent Bootstrap (Agnostic) ✅

Foundation agents start ready in ≤2 minutes with session tracking active.

## Quick Path (Startup)

1. Windows: `tools/session-autostart.cmd`
2. Linux/macOS/WSL: `bash ./tools/session-autostart.sh`
3. Config: `tools/session-autostart.config.json`

Default: auto-loads session, detects project, starts tracking.

## Session Tracking Rule ✅

When session tracking exists, initialize early:

| Setting | Value |
|---------|-------|
| `project` | `workspace_local` |
| `directory` | `c:\Workspace_local` |
| `session id` | `session-YYYY-MM-DD-XX` |

**Result**: Session active, tracking enabled.

## Reliability Rule ✅

| Status | Action |
|--------|--------|
| `READY` | Proceed |
| `PARTIAL` | Resolve before deep implementation |
| Release work | Use `full` mode |

**Result**: Reliable session, no false starts.

## Context Optimization (Token Efficiency) ✅

### Memory Tiering

| Tier | Retention | Purpose |
|------|-----------|---------|
| **Hot** | No compression | Active session |
| **Warm** | 90% (1 day) | Recent context |
| **Cold** | 70% (7 days) | Archive |

### Handoff Compression

**Trigger**: Agent-to-agent transfer  
**Command**: `tools/handoff-compress.ps1`  
**Preserves**: decisions, results, FIXMEs, status flags  
**Truncates**: verbose outputs, repeated patterns  
**Result**: ~30% size reduction

### Pre-Compact Hook

**Trigger**: Before context compaction (~25k tokens)  
**Command**:
```powershell
.\tools\pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90
```
**Preserves**: FIXME, TODO, BUG, DECISION, RESULT.

### Adaptive Skill Loading ✅

Skills auto-load based on project context:

| Signal | Skill | Status |
|--------|-------|--------|
| Angular component | angular-core, angular-spa | ✅ Loaded |
| React TSX | react-19 | ✅ Loaded |
| Go files | golang-api | ✅ Loaded |
| Docker files | docker-devops | ✅ Loaded |
| PowerShell scripts | workspace-automation | ✅ Loaded |
| Session management | session-lifecycle | ✅ Loaded |

**Result**: Relevant skills ready, no manual loading.

## Workspace-Specific Skills ✅

### Automation Skills``

| Skill | Trigger | Status |
|-------|---------|--------|
| `workspace-automation` | PowerShell scripts, scheduled tasks | ✅ Active |
| `session-lifecycle` | Session start/end, hooks, tracking | ✅ Active |

**Usage**: Auto-loaded when working with workspace automation.
**Load manually**:
```bash
Read skills/workspace-automation/SKILL.md before creating automation scripts
Read skills/session-lifecycle/SKILL.md before modifying session management
```

**Result**: Automation skills ready when needed.
