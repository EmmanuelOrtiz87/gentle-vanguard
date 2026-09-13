---
created: 2026-07-26 04:34:48
tags: [engram, decision]
engram_id: 2004
type: decision
---

# Engram marked CRITICAL + Nexus fully integrated

**What**: Changed Engram-local and Engram-global from NO to SI (critical) in RECOVERY-NORMATIVA.md. Completed full integration of Nexus operational DB identity.

**Why**: Engram stores persistent memory — decisions, bugs, architecture, conventions, agent/skill performance, and stack historical context. Without it, the stack loses its "north" and cannot make informed decisions based on past actions. This is critical infrastructure, just like CodeGraph and Nexus.

**Where**:
- rules/RECOVERY-NORMATIVA.md — Engram marked SI (critical), Nexus listed as critical component
- skills/SKILL_INDEX.md — nexus-database-skill entry added
- src/Skills/skill-router.ts — 10 triggers for nexus-database routing

**Learned**: The router had a duplicate key `'gentle-vanguard'` that was overriding the first definition. Had to remove the duplicate so both gentle-vanguard-audit and nexus-database skills match when querying "gentle-vanguard.db". The router uses `queryLower.includes(keyword)` which means keyword ordering matters — the LAST definition wins in JavaScript objects.

---
*Imported from Engram on 2026-09-06*
