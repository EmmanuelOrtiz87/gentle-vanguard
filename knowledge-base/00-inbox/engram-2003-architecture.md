---
created: 2026-07-26 04:23:49
tags: [engram, architecture]
engram_id: 2003
type: architecture
---

# Nexus - Operational Database Identity

**What**: Created Nexus as the named operational database identity for Gentle-Vanguard. The DB file is `.runtime/gentle-vanguard.db` but its identity is "Nexus" — the central nervous system of the stack.

**Why**: The database needed a proper identity (like Engram, CodeGraph, Graphify). It stores ALL operational data: metrics, sessions, traces, events, alerts, feedback, response cache, contract results, skill usage, token usage, routing rules, and session scoring.

**Where**:
- rules/NEXUS-NORMATIVA.md — identity, lifecycle, guardrails, retention policy
- skills/nexus-database/SKILL.md — autonomous management skill
- AGENTS.md — documentation updated with full Nexus identity section
- src/Core/maintenance-watchtower.ts — fixed false positive (transient lock = WARN, corruption = FAIL)

**Learned**: The watchtower false positive was caused by spawnSync returning empty stdout when the DB is transiently locked by another process (Dashboard WS server), while execSync in db-health.ts throws and gets caught cleanly. Fixed by checking r.status/r.error/stderr before reporting FAIL.

---
*Imported from Engram on 2026-09-06*
