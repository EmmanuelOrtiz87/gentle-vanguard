---
created: 2026-07-30 13:08:04
tags: [engram, architecture]
engram_id: 2262
type: architecture
---

# stack-verify architecture and design decisions

**What**: Created a comprehensive 4-layer stack verification system: dependency-validator (25 checks) → stack-verify (30 checks orchestrator) → stack-setup (one-command install)

**Why**: A new user needs ONE command to verify and install everything the stack needs. But this should NOT run every session — only on first install. Ongoing health is monitored by watchtower.

**Where**:
- `src/dependency-validator.ts` — 25 checks in 4 categories (CORE/STACK/OPTIONAL/PLATFORM)
- `src/stack-verify.ts` — 4-layer orchestrator (deps → platform → services → integrity)
- `src/stack-setup.ts` — one-command first-time install (6 steps)

**Learned**:
1. **Layer architecture**: Machine deps (12 binary checks) → Platform (13 file/dir checks) → Services (3 port pings) → Integrity (3 module checks) = ~30 total
2. **Import vs subprocess**: Using `npx tsx` in a `spawnSync` subprocess is unreliable on Windows (timeouts). Solution: dynamic import of the validator module directly with `await import('./dependency-validator.js')` and guard `isMain` to prevent side effects
3. **Optional flag**: Platform checks should support `optional: true` for non-critical components (like lefthook hooks) — show as WARN not FAIL
4. **Graphify**: The knowledge graph JSON uses `links` not `edges` for relationships between nodes
5. **Nexus DB health**: Direct SQLite magic bytes check (`0x53 0x51 0x4C` = "SQL") is more reliable than running the db:health script

---
*Imported from Engram on 2026-09-06*
