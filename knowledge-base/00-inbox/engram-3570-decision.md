---
created: 2026-09-01 09:45:30
tags: [engram, decision]
engram_id: 3570
type: decision
---

# archify como recurso nativo: scripts npm + skill + cliente CLI API

**What**: Completé la integración de archify como recurso nativo del stack: scripts npm del motor + skill + cliente CLI de la API REST. App funcionando y commiteada.

**Why**: Dar a los agentes/scripts del stack una vía nativa robusta para operar el motor de diagramas (no solo la UI).

**Where**:
- Raíz package.json: scripts `archify:render|compare|validate|cli|start|smoke|api`
- apps/archify/server/api-client.mjs: cliente CLI que usa la API REST (render/validate/delta/health/examples)
- skills/archify-studio/SKILL.md: skill con formato JSON IR exacto del motor

**Learned**:
- El CLI del motor (`archify.mjs`) tiene comandos `render` que funcionan (exit 0), pero `validate` y `compare` fallan con "final artifact checks" en este entorno headless (es un check extra del wrapper CLI). La vía confiable es la API de la app (usa los renderers directos) → por eso creé api-client.mjs.
- Comandos npm: `archify:render` y `archify:cli` usan el CLI; `archify:api` usa el cliente (confiable).
- Cliente CLI verificado E2E: health OK, validate → '✓ válido' (exit 0), render → artifact 715KB, delta → html 100KB.
- El server de la app se detiene a veces (no persiste como daemon estable entre sesiones) — relanzar con command-center POST /api/apps/archify/start.
- Commits: apps/ (app archify + api-client.mjs), repo raíz (package.json + skill).

---
*Imported from Engram on 2026-09-06*
