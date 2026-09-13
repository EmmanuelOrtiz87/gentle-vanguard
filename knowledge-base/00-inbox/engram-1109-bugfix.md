---
created: 2026-05-24 12:45:08
tags: [engram, bugfix]
engram_id: 1109
type: bugfix
---

# CodeGraph stale index — fix permanente completo

**What**: Fix permanente del warning de CodeGraph index >30min obsoleto. Implementado con 3 capas: (1) hooks post-commit/post-merge via lefthook, (2) fix en codegraph-sync-autostart.ps1 para detectar correctamente frescura en SQLite WAL mode, (3) scheduled task horaria desde terminal elevada.

**Why**: El índice de CodeGraph se quedaba obsoleto (~3.3 días) generando warnings en cada inicio de sesión. Causa raíz: freshness check solo miraba codegraph.db pero SQLite WAL mode escribe en .db-wal.

**Where**:
- .lefthook.yml — hooks post-commit + post-merge
- config/lefthook.yml — hooks espejados  
- scripts/utilities/codegraph-sync-autostart.ps1 — freshness check con max(WAL, SHM, DB)
- skills/codegraph-skill/SKILL.md — sección Auto-Sync via Git Hooks
- rules/NORMATIVAS-DEVOPS.md — sección 6.1
- Scheduled Task: "Gentle-Vanguard-CodeGraph-Sync" (cada hora, 8-8)
- CLAUDE.md + AGENTS.md — param -UserInput corregido

**Learned**: codegraph sync via hook funciona con -Force. SQLite WAL mode requiere revisar .db-wal + .db-shm timestamps, no solo .db. ScheduledTask con -Once -RepetitionInterval, no -Daily.

---
*Imported from Engram on 2026-09-06*
