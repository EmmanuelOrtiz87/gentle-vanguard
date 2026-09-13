---
created: 2026-06-11 14:27:13
tags: [engram, architecture]
engram_id: 1391
type: architecture
---

# Engram backup safeguard stack completed

**What**: Completed the full Engram backup safeguard stack — 4 scripts, zero errors, zero warnings, 48/48 tests passing

**Why**: Needed corruption-proof safeguard stack with pre-verification, SHA256 checksums, byte-level SQLite header validation, AES-256 encrypted metadata, and authorization guard for critical operations

**Where**:
- `scripts/utilities/ops/BACKUP-RESTORE/backup-engram.ps1` — core backup/restore/verify (pre-integrity-check, SHA256 checksums, byte-level SQLite header)
- `scripts/utilities/memory/ENGRAM/engram-integrity-check.ps1` — health check (magic bytes 53 51 4c 69... instead of System.Data.SQLite)
- `scripts/utilities/memory/ENGRAM/engram-change-guard.ps1` — authorization guard for critical operations
- `scripts/adaptive/auto-backup-orchestrator.ps1` — orchestration with AES-256 metadata encryption
- `config/session-autostart.config.json` — scheduling steps (engram-integrity + engram-backup)
- `rules/HAND-WRITTEN-NORMS.md` — NORM-008 updated with real stack

**Learned**:
- UTF-8 accented characters (Ó, ó, Á, í) in PowerShell string literals cause cascading parse errors on Windows — always use ASCII 7-bit in .ps1 files
- System.Data.SQLite.SQLiteConnection assembly is NOT available in bare runtime — use byte-level SQLite header check (first 16 bytes) instead
- Em dash — (U+2014) in PowerShell strings causes parse errors — replace with " -- "
- Root path detection: `Split-Path -Parent` count must match the script's directory depth
- `templates/config` will always fail typecheck/lint — it's a template project without node_modules (expected, safe to ignore)

**Verified**: All 4 scripts exit 0, pnpm format:check passes, pnpm -r lint passes (templates/config excluded), secretlint zero errors, 48/48 tests passed

---
*Imported from Engram on 2026-09-06*
