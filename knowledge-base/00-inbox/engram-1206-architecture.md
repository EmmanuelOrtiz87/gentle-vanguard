---
created: 2026-05-29 03:57:28
tags: [engram, architecture]
engram_id: 1206
type: architecture
---

# MCP Skill Server + pnpm migration

**What**: Implemented MCP server exposing 142+ skills as MCP tools via @modelcontextprotocol/sdk. Server at scripts/mcp/skill-server.ts → dist/scripts/mcp/skill-server.js. Registers 3 tools: list_skills, get_skill, search_skills. Resources: skill://registry and skill://{name}. Migrated from npm to pnpm with --ignore-scripts as security normative.

**Why**: Enable any MCP-compatible AI tool (opencode, claude-code, cursor) to query and invoke skills directly via MCP protocol, eliminating tool lock-in. pnpm + --ignore-scripts eliminates supply-chain risk from malicious postinstall scripts.

**Where**: scripts/mcp/skill-server.ts, dist/scripts/mcp/skill-server.js, opencode.json#mcp.skill-server, rules/NORMATIVA-PNPM-SECURITY.md, package.json (engines + packageManager + build:mcp)

**Learned**:
- @modelcontextprotocol/sdk v1.29.0 works with TypeScript 6.0 and ES modules
- ROOT path must go 3 levels up from dist/scripts/mcp/
- pnpm migration is straightforward: remove package-lock.json + node_modules, run pnpm install --ignore-scripts
- Registry parser needed filtering to exclude non-skill rows (paths, "File" agent, etc.)
- Server responds correctly to tools/list and tools/call via stdio JSON-RPC

---
*Imported from Engram on 2026-09-06*
