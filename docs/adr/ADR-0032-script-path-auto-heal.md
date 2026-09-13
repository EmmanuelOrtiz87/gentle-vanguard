# ADR-0032 — Auto-heal de rutas de scripts en configs del pipeline (self-improvement)

Fecha: 2026-09-06 · Estado: aceptado · Componentes: `session-autostart`, `script-path-heal`,
`maintenance-watchtower`

## Status

Accepted — implementado (session-autostart sin warnings, 2026-09-06).

## Context

Las migraciones PS1→TS movieron scripts a carpetas de dominio (`src/knowledge/`, `src/ops/`,
`skills/`, …), pero `config/session-autostart.config.json` conservó rutas top-level legacy
(`src/<name>.ts`). Resultado: 3 lazy steps (`knowledge-base-init`, `engram-auto-reindex`,
`engram-auto-update`) emitían `[WARN] Script not found` en **cada arranque** de sesión y **nunca
ejecutaban** su funcionalidad — un gap silencioso de operación (KB sin init, RAG sin reindex,
updates sin check). El usuario exigió: arranque sin warnings/gaps, y que el stack se auto-evalúe y
auto-repare de forma nativa (auto-mejora), no que un humano persiga warnings uno a uno.

Además, la validación manual reveló que estados de trabajo previos podían quedar sin persistir
(edición multi-archivo reportada como aplicada pero ausente en disco) — reforzando la necesidad de
monitoreo proactivo de integridad.

## Decision

1. **Módulo puro y testeable** `src/core/script-path-heal.ts` (side-effect-free; todo IO vía
   opciones):
   - `indexScriptPaths(root, dir)` — índice basename→ruta relativa de todos los `.ts` bajo `src/`,
     single-pass, profundidad máx. 8, separadores normalizados `/`.
   - `resolveScriptPath(root, script, index?)` — devuelve la ruta si existe; si no, resuelve por
     basename; fallback a la ruta original.
   - `healStepScriptPaths(root, config, opts)` — parchea la config **en memoria** (el run actual usa
     la ruta corregida), **persiste** la corrección en el JSON con backup `.bak` (reparación
     durable), y escribe reporte de no-resolubles a `.runtime/autostart-missing-scripts.json`. Todo
     IO best-effort (nunca aborta el pipeline).
2. **`session-autostart` consume el módulo** (wrapper delgado: cache del índice por run + audit
   event `config.autoheal` + logging). `executeStep` y `startLazyStep` resuelven vía
   `resolveScriptPath` como red de seguridad. Como el heal persiste la corrección, una config sanada
   **no vuelve a advertir** en sesiones siguientes.
3. **Watchtower monitorea residuos**: nuevo `checkMissingScripts()` (componente `configs`) que lee
   el reporte del heal: PASS si no existe/está vacío; WARN con lista de ids si hay scripts sin
   resolver; WARN si el reporte es inválido. Detecta wiring roto no auto-reparable entre sesiones.
4. **Root fix**: las 3 rutas rotas corregidas en `config/session-autostart.config.json`
   (`src/knowledge/*.ts`) + referencias documentales actualizadas (ROADMAP, STACK-STATUS-REPORT,
   headers de scripts).

## Alternativas descartadas

- **Solo corregir las 3 rutas a mano**: resuelve el síntoma actual pero no la clase de problema; la
  próxima migración volvería a romper configs sin detección ni auto-reparación.
- **Fail-fast en arranque si hay rutas rotas**: convierte un WARN en bloqueo — castiga arranques por
  problemas reparables y rompe el arranque local-first.
- **Lógica inline en session-autostart.ts**: funcionaba pero duplicaba código no testeable (el
  módulo se detectó duplicado por pérdida de persistencia entre sesiones). El módulo puro es la
  única fuente de verdad, cubierto por 11 tests unitarios.
- **Reescribir el config en cada arranque sin backup**: arriesga corrupción; el patrón `.bak` +
  reescritura solo cuando hay correcciones mantiene traza y reversibilidad.

## Consecuencias

- El arranque queda **sin warnings** por configs rotas y **sin pasos fantasma**: o bien el script se
  ejecuta (ruta real resuelta) o bien queda reportado para monitoreo.
- Cualquier drift futuro de rutas (migraciones, renombrados) es **auto-reparado y persistido** en la
  primera ejecución, con vista en el audit trail (`config.autoheal`) y monitoreo en watchtower.
- Los watchtower checks pasaron de 124 a 125; estado verificado 125/125 PASS (0 WARN/FAIL).
- El patrón es extensible a otros configs que referencien scripts (hooks, commands, MCP) — mejora
  candidata registrada.

## Verificación

- Tests unitarios `tests/unit/script-path-heal.test.ts` (11 casos, sandbox fs): indexado,
  normalización de separadores, resolución por basename, no-touch, persistencia con `.bak`, reporte
  de no-resolubles, respeto de `enabled=false`, healing solo en memoria.
- Arranque en vivo re-verificado tras el refactor: 31/31 steps OK, 77/81 lazy lanzados (4 deduped),
  **0 WARN/ERROR/"Script not found"**, `[READY]`.
- Watchtower `checkMissingScripts` validado en ambas ramas: PASS sin reporte y WARN con reporte
  inyectado (`1 unresolved: ghost-step`).
- `tsc --noEmit` exit 0 · `npm run lint` 0 warnings · intégration `session-autostart` 3/3 PASS.
