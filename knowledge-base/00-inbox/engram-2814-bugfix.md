---
created: 2026-08-14 03:04:57
tags: [engram, bugfix]
engram_id: 2814
type: bugfix
---

# Fixed broken CLI guard in 33 files - Windows pathToFileURL

**What**: Fix sistémico del guard de ejecución CLI en Windows: 33 archivos usaban `import.meta.url === \`file://${process.argv[1]}\`` que NO normaliza rutas Windows (process.argv[1] llega con backslashes, import.meta.url usa forward slashes) → el guard nunca coincidía → main() nunca se ejecutaba → los CLIs eran no-ops silenciosos
**Why**: Se detectó al probar self-healing-db.ts y circuit-breaker-v2.ts --status que no imprimían nada; el fix manual reveló el patrón en 40+ archivos
**Where**: src/auto-url-fix.ts (nuevo auto-fixer), 33 archivos corregidos (auto-step-recovery, core/*, mcp/fetch-server, multi-channel-alert, model-broker, token-spike-guard, session-persist, process-cleanup, etc.), src/core/maintenance-watchtower.ts (checkCliGuard anti-regresión, 95/95 PASS)
**Learned**: (1) El patrón correcto es `process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href`; (2)`new URL('file://'+p).href` también normaliza en Node; (3) la comparación directa de strings NO; (4) 8 archivos ya usaban new URL(...).href (correcto); (5) el watchtower ahora detecta regresiones; (6) al hacer smoke tests de process-cleanup se mataron dashboard-ws y codegraph — restaurar con dashboard-ws-autostart.ts y codegraph-mcp-server-start.ts

---
*Imported from Engram on 2026-09-06*
