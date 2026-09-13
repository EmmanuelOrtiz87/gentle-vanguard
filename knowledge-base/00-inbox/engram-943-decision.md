---
created: 2026-05-18 18:52:48
tags: [engram, decision]
engram_id: 943
type: decision
---

# CodeGraph integration into Gentle-Vanguard

**What**: Integrated CodeGraph (colbymchenry/codegraph v0.7.9) as a semantic code knowledge graph for the workspace
**Why**: Reduces agent exploration tool calls by ~92% and speeds up code understanding by ~71%. Agents can query symbols, call chains, imports, and impact analysis with 1-3 calls instead of 30-50+ grep/glob/read.
**Where**:
- opencode.json — added MCP server config (mcp.codegraph)
- .gitignore — added .codegraph/ exclusion
- skills/codegraph-skill/SKILL.md — new skill with triggers and usage docs
- skills/SKILL_INDEX.md — added to AI category and Quick Reference
- .atl/skill-registry.md — rebuilt with 132 skills
- Global install: @colbymchenry/codegraph@0.7.9
- better-sqlite3 installed in CodeGraph global dir (native backend active)
**Learned**:
- better-sqlite3 must be installed inside CodeGraph's global node_modules dir, not just workspace — copy from workspace node_modules and run npm install there
- WASM fallback works but is 5-10x slower; native backend confirmed working
- Index stats: 31 files, 360 nodes, 768 edges, 1.10 MB DB
- MCP config uses `codegraph serve --mcp` as local command
- .codegraph/ directory must be in .gitignore (local-only, regenerated)

---
*Imported from Engram on 2026-09-06*
