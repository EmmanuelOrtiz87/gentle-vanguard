---
created: 2026-07-27 05:33:08
tags: [engram, architecture]
engram_id: 2053
type: architecture
---

# Sprint 1-2 complete: LSP MCP + error memory + semantic cache + summarize-wipe

**What**: Completed full stack evolution: P0 (semantic tool selection + parallel swarm) → P1 (error memory + semantic cache) → P2 (LSP MCP server + summarize & wipe). All pushed to develop in 3 commits.

**Why**: User requirement to operate with all tools available — if a capability is missing, build it natively into the stack rather than relying on external tools.

**Where**:
- src/mcp/mcp-lsp-server.ts — 8 LSP tools (LanguageService API)
- src/summarize-wipe.ts — context compaction engine
- src/error-memory.ts — error memory pattern with embeddings
- src/response-cache.ts — semantic cache TF-IDF fallback
- src/skills/skill-router.ts — TF-IDF semantic router (419 skills)
- src/team-orchestrator.ts — Leader-Worker swarm mode
- apps/web-dashboard/server/database/manager.ts — migrations 004-005
- config/mcp-registry.json — 3 MCP servers registered
- config/session-autostart.config.json — summarize-wipe pipeline step

**Learned**:
- LanguageService API is more reliable than tsserver IPC for MCP integration
- TF-IDF tokenizer must be shared across skill-router, response-cache, and error-memory for consistency
- TextSpan positions (start/length) need getLineAndCharacterOfPosition for line:col display
- summarize-wipe auto detected 525K tokens, compacted to 138K (74% reduction)
- Skill embeddings at .atl/skill-embeddings.json must be refreshed periodically (was 60h stale)

---
*Imported from Engram on 2026-09-06*
