---
created: 2026-09-13 00:24:31
tags: [engram, pattern]
engram_id: 3892
type: pattern
---

# Patrón tests vitest apps standalone (prompt-studio / academy-crm)

**What**: Suites vitest para apps/prompt-studio (HTTP-level) y apps/academy-crm (repo-level + HTTP-level), con BDs en tmp dirs y puertos efímeros.
**Why**: Ambas apps no tenían tests. prompt-studio es un monolito sin exports (server arranca a escuchar al import), así que se testea spawn-eando `node --import tsx server/server.ts` como child con env PROMPT_STUDIO_DATA_DIR (tmp) + PROMPT_STUDIO_PORT (puerto libre via net listen(0)). academy-crm tiene createCrmRepo testeable in-process.
**Where**: apps/prompt-studio/server/server.test.ts, apps/academy-crm/server/{repo,server}.test.ts, apps/academy-crm/server/db.ts (nuevo env CRM_DB_PATH estilo GVA_DB_PATH).
**Learned**: vitest NO está declarado en estas apps pero resuelve hoisted desde el root (patrón gv-analytics, `vitest run` en scripts). apps/academy-crm y apps/prompt-studio NO son miembros de pnpm-workspace.yaml pero node resuelve tsx/vitest/@types/node caminando hasta el node_modules raíz. Persistencia se testea matando el child y re-spawn-eando sobre el mismo tmp dir. Puerto libre: net server listen(0) → close → reutilizar puerto.

---
*Imported from Engram on 2026-09-14*
