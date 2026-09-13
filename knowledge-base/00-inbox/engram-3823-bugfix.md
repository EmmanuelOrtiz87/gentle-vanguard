---
created: 2026-09-09 20:07:59
tags: [engram, bugfix]
engram_id: 3823
type: bugfix
---

# Fix ventanas fantasmas: windowsHide en spawn/execSync directos de apps

**What**: Revisión exhaustiva de ventanas fantasmas (ghost windows) en Windows completada. Escaneo de 450 matches de patrones potenciales en src/scripts/apps/packages/tests, filtrado de falsos positivos, verificación de casos críticos leyendo código real. Gaps reales corregidos: (1) apps/prompt-studio/server/server.ts:1165 spawn directo detached sin windowsHide (CRÍTICO — login de import de gemas); (2) apps/academy-web/scripts/validate-multi-course.mjs 4× execSync node --check sin windowsHide; (3) packages/gv-design-system/src/cli/sync.ts:142 execSync pnpm link sin windowsHide.
**Why**: Usuario reportó ventanas fantasmas persistentes y pidió revisión exhaustiva del gap (stack + apps).
**Where**: apps/prompt-studio/server/server.ts (windowsHide:true en spawn), apps/academy-web/scripts/validate-multi-course.mjs (4 execSync con windowsHide), packages/gv-design-system/src/cli/sync.ts (windowsHide en execSync). Commit 2a7ffe5f (packages/).
**Learned**: (1) El stack core es SÓLIDO: run()/runNpxTsx/runSync/runSyncShell tienen windowsHide:true por defecto (DEFAULT_OPTIONS/DEFAULT_SYNC_OPTIONS); schtasks usan wscript VBS oculto; scripts .cmd/.bat usan node --import tsx directo; test run-command-hidden 2/2 PASS. (2) Los gaps reales están en APPS/PAQUETES que usan spawn/execSync DIRECTOS sin windowsHide — el patrón a vigilar. (3) /apps/ es git-ignored: los fixes de prompt-studio y validate-multi-course son locales; solo packages/ se commitea. (4) Falsos positivos del scanner: db.exec() (SQLite), branches macOS/Linux (open/xdg-open), referencias en docs/comentarios, npx.cmd en comentarios.

---
*Imported from Engram on 2026-09-09*
