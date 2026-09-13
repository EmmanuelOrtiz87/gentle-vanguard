---
created: 2026-05-30 05:17:21
tags: [engram, architecture]
engram_id: 1230
type: architecture
---

# Nuevas normativas y scripts de integridad

**What**: 3 normativas nuevas + 2 scripts de verificación + CodeGraph reindexado con PowerShell. Todo integrado en health-check.

**Why**: El projecto tenía 50+ normativas pero sin verificación automatizada de cumplimiento, sin backup de engram, y CodeGraph no indexaba PowerShell.

**Where**:
- rules/NORMATIVA-OPTIMIZATION-STACK.md — 8 reglas: compresión, cache, modelo, tracking, pre-compact, notificaciones, tamaño cache
- rules/NORMATIVA-ENGRAIN-BACKUP.md — 5 reglas: backup post-sesión NDJSON, Git rollback, verificación semanal, retención
- rules/NORMATIVA-SISTEMA-INTEGRIDAD.md — meta-normativa: health check, optimization stack, CodeGraph fresco, backup, zero secrets
- scripts/validation/verify-optimization-stack.ps1 — 8 checks automatizados con -Quiet y -AsJson
- scripts/utilities/BACKUP-RESTORE/backup-engram.ps1 — 4 modos: backup (NDJSON), verify, restore, status. Git commit automático
- scripts/health-check/health-check.ps1 — nuevo componente Check-OptimizationStack integrado
- .codegraph/config.json — agregado **/*.ps1, **/*.psm1,**/*.psd1 al include
- docs/RESEARCH-SYNTHESIS.md — 345 líneas de investigación en 6 dominios

**Learned**:
- CodeGraph no soporta PowerShell natively (447 archivos "unsupported language"). Config incluye PS pero parser no existe. 50 archivos indexados (vs 27 antes) para JS/TS/Go/Python.
- PSScriptAnalyzer: 0 errores en scripts nuevos (solo warnings de Write-Host y "Check-" verbs, que son elecciones de diseño para CLI tools)
- Health check ALL PASS: 8 componentes verificados (MCP, Team, Session, Factory, SDD, pnpm, Lefthook, Optimization Stack)
- backup-engram.ps1 ejecutado: backup creado + Git init en .engram-data/ + verify PASS
- verify-optimization-stack.ps1: 8/8 reglas PASS (CLAUDE.md 42 líneas, cache 5.7KB, 0 glm-5, 13 qwen-3.6-plus, compression activa, token tracking OK, notificaciones disabled, cache < 5MB)

---
*Imported from Engram on 2026-09-06*
