---
created: 2026-08-06 04:44:52
tags: [engram, decision]
engram_id: 2561
type: decision
---

# PROPUESTA: Unificar Flujo Engram

**Problem**: Stack relies on OpenCode plugin auto-behavior for session lifecycle. Works on OpenCode, FAILS silently on Claude/Cline/Cursor/etc.

**Root Cause**:
- session-autostart.ts: NO explicit engram_mem_session_start call
- session-close-orchestrator.ts: Only HTTP API (fallback), no explicit MCP engram_mem_session_end
- Assumes plugin does it automatically (only true for OpenCode)

**Current State**:
- OpenCode: Plugin auto-starts, HTTP API closes - WORKS
- Other tools: NO auto-start, HTTP close may fail - SILENT FAIL

**Proposed Solution**:
1. Add engram_mem_session_start EXPLICIT call at start of session-autostart.ts
2. Add engram_mem_session_summary + engram_mem_session_end EXPLICIT calls in session-close-orchestrator.ts (before HTTP fallback)
3. Use HTTP API ONLY as fallback if MCP fails
4. All tools use IDENTICAL flow via MCP (never rely on auto-behavior)

**Architecture**:
- Start: session-autostart.ts → MCP engram_mem_session_start
- During: Direct mem_save, mem_search (MCP tools)
- End: session-close-orchestrator.ts → MCP engram_mem_session_summary → MCP engram_mem_session_end → HTTP API (fallback)

**Benefits**:
- Works identically on ALL tools (OpenCode, Claude, Cline, Cursor, etc.)
- Complete traceability
- No silent failures
- Easy to debug (explicit errors)

**Next Action**: Implement explicit MCP calls in both scripts.

---
*Imported from Engram on 2026-09-06*
