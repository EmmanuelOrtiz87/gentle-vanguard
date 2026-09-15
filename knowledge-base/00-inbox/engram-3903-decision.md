---
created: 2026-09-13 18:45:40
tags: [engram, decision]
engram_id: 3903
type: decision
---

# Normalización: Content CMS → Content Studio (canónico)

**What**: Normalización de nombre de la app de contenido: "Content CMS" → "Content Studio" en todo el stack operativo. Nombre canónico = Content Studio (el que usa la propia app en UI/i18n/index.html/README). "content-cms" queda como id técnico de carpeta.

**Why**: El usuario notó inconsistencia: command-center decía "Content CMS" pero la app se autodenomina "Content Studio". Además "Content CMS" es redundante (CMS = Content Management System → "Content Content Management System").

**Where**: apps/command-center/server.ts (name), apps/command-center/README.md (2 refs), scripts/app-manager.sh, src/core/process-hygiene.ts (2 labels), apps/design-hub/README.md, apps/design-hub/src/documentation/docs/implementation-summary.html, docs/design/08-visual-normalization-audit.md, docs/brand/IMPLEMENTATION-SUMMARY.md, docs/marketing/GV-SPEECH-PLAYBOOK-2026-09.md, apps/content-cms/server/db.ts + db-migrations.ts (headers), docs/apps/HOMOLOGACION-UX-2026-09-06.md (2 refs), docs/adr/ADR-0030 (nota de renombrado añadida, sin reescribir historia).

**Learned**: 
- ADRs son registros históricos inmutables — se les añade nota de renombrado, no se reescriben.
- knowledge-base/00-inbox/ es histórico — no se toca.
- El command-center se reinicia con Start-Process node --import tsx apps/command-center/server.ts (puerto 8090).
- Verificado: API del CC muestra "cms: Content Studio" ✅. Typecheck command-center exit 0. Apps limpias de "Content CMS" (grep en apps/ = 0 resultados).
- El Vite del CRM (4791) tiende a morirse — relanzar con Start-Process node node_modules/vite/bin/vite.js --host 127.0.0.1 --port 4791 en apps/academy-crm.

**Done**: 
- ✅ 13 archivos actualizados a Content Studio
- ✅ ADR-0030 con nota de renombrado (historia preservada)
- ✅ Command-center reiniciado y verificado (muestra Content Studio)
- ✅ Typecheck command-center exit 0
- ✅ Stack completo operativo: CMS (3787/5175), CRM (4792/4791), CC (8090)

**Pending**: nada crítico. Opcional: actualizar docs/presentations/*.html (archivados) si se quiere consistencia total.

---
*Imported from Engram on 2026-09-14*
