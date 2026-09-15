---
created: 2026-09-12 22:51:43
tags: [engram, architecture]
engram_id: 3890
type: architecture
---

# content-cms autonomo: BD propia + vendors + migracion one-time

**What**: apps/content-cms refactorizada para autonomía total: BD SQLite propia (server/db.ts estilo archify, env CMS_DB_PATH/CMS_RUNTIME_DIR/CMS_LEGACY_DB_PATH), schema vendido en server/db-migrations.ts (DDL de migración 018_content_os idempotente + tabla local content_os_events), ContentOSRepo/engine/provider-hub vendidos bajo server/, rutas .runtime movidas a apps/content-cms/.runtime resueltas desde import.meta.url, migración one-time desde Nexus (filas content_* + archivos de media con reescritura de path + settings.json/connectors.json), vite.config con server 127.0.0.1:5175 strictPort, README corregido con lista real de endpoints.
**Why**: hacer la app comercializable sin depender de ../../web-dashboard ni src/ raíz.
**Where**: apps/content-cms/server/{db.ts,db-migrations.ts,scheduler.ts,settings.ts,connectors.ts,video-pipeline.ts,server.ts,server.test.ts}, server/database/ContentOSRepo.ts, server/content-operations/engine.ts, server/integrations/provider-hub.ts, config/content-operations/platforms.json, content/operations/master-manifest.json (todos bajo apps/content-cms).
**Learned**: better-sqlite3/@types resuelven desde node_modules raíz del workspace sin declararse en el package.json de la app (convención archify). MigrationRunner solo tiene 018_content_os tocando tablas content_*. Bug latente corregido: POST /api/items con variante sin format generaba String(undefined)="undefined" y violaba CHECK de content_variants. La instancia vieja en :3787 siguió usando Nexus; el primer arranque real (port 3798) migró 3 items/7 variants/2 media/8 slots/9 publish_log y reescribió paths de media correctamente.

---
*Imported from Engram on 2026-09-14*
