---
created: 2026-07-28 05:02:58
tags: [engram, architecture]
engram_id: 2122
type: architecture
---

# Ecosistema de validación y cierre autónomo de sesión

**What**: Implementación completa del ecosistema de validación y cierre autónomo de sesión para Gentle-Vanguard. Creados 3 nuevos módulos y expandido el orquestador existente.

**Why**: Sesiones previas no tenían validación al cierre — no se detectaban cross-references rotos, archivos temporales huérfanos, errores/warnings pendientes, ni deuda técnica. El cierre era incompleto.

**Where**:
- `src/temp-file-registry.ts` — Sistema de registro de archivos temporales con ciclo de vida (temporary → authorized-pending → permanent) y CLI completo
- `src/session-close-validator.ts` — Validador profundo 3 modos (quick/deep/full) con SCORE 0-100, cross-refs con comment-stripping, temp files, error/warning scan, unused files, completitud, deuda técnica
- `src/session-close-orchestrator.ts` — Expandido a 7 fases: PRE-CLOSE → PRE-VALIDATE → PERSIST → BACKUP → AUDIT → CLEANUP → VERIFY. Incluye phasePreValidate(), temp cleanup, process killer (CodeGraph MCP, Dashboard WS, Timeout Daemon), y soporte --validate
- `config/session-autostart.config.json` — Pipeline steps: session-scoring-close, session-close-orchestrator (lazy), session-close-validator (lazy)
- `rules/SESSION-CLOSE-NORMATIVA.md` — Protocolo formal de 6 fases
- `rules/RECOVERY-NORMATIVA.md` — Puntos de restauración y referencias al flujo de cierre

**Learned**:
- Los "broken imports" (54 iniciales) eran JSDoc comments, no código real → solution: comment-stripping antes de escanear
- En Windows, paths usan backslash → usar `Math.max(lastIndexOf('/'), lastIndexOf('\\'))`
- ESM convention: imports usan `.js` pero fuente es `.ts` → mapear `.js`→`.ts`
- Tracing span files pueden tener nombres variables → buscar dinámicamente `.jsonl`
- Typecheck final: 0 errores. Health check: 35/35 PASS. Validator SCORE: 100/100.

---
*Imported from Engram on 2026-09-06*
