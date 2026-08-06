# GAPS-BACKLOG — Pool de Incidencias y Gaps Identificados

> **Propósito:** Rastrear todo lo que no funciona correctamente, está desactualizado, tiene
> comportamiento errático, o necesita revisión. Cada entrada incluye criticidad y etiquetas para
> priorizar según amerite.
>
> **Formato:** issues identificados con severidad y contexto para resolver.
>
> **Source of Truth:** El backlog operacional vive en **Nexus DB** (`.runtime/gentle-vanguard.db`,
> tabla `backlog_items`). Este archivo .md es un snapshot de documentación. Para consultas en tiempo
> real, usar `npm run backlog:list`, `npm run backlog:search`, o `npm run backlog:stats`. Ver
> `apps/web-dashboard/server/database/repositories/BacklogRepo.ts` para la implementación.
>
> **Última actualización:** 2026-07-29

---

## Estados

| Estado         | Significado                       |
| -------------- | --------------------------------- |
| 🔴 OPEN        | Identificado, sin resolver        |
| 🟡 IN PROGRESS | En proceso de resolución          |
| 🟢 RESOLVED    | Corregido y verificado            |
| ⚪ WONT FIX    | Decidido no resolver por ahora    |
| 🔵 BACKLOG     | Posible mejora futura, no urgente |

---

## Issues

### GAP-001: Presentations reference .ps1 scripts that no longer exist

<!-- ID: GAP-001 | Created: 2026-07-29 | Severity: HIGH -->

**Severidad:** 🔴 HIGH **Etiquetas:** `doc-sync` `presentations` `ps1-migration`

**Descripción:** Las páginas `dashboard.html`, `quickstart.html` y `security-governance.html` en
`docs/presentations/` referencian comandos `.ps1` que ya fueron migrados a TypeScript y eliminados.

**Archivos afectados:**

- `docs/presentations/dashboard.html` — referencias a `dashboard-start.ps1`,
  `dashboard-ws-autostart.ps1`, `dashboard-stop.ps1`
- `docs/presentations/quickstart.html` — mismas referencias
- `docs/presentations/security-governance.html` — referencias a `audit-pipeline.ps1`

**Acción:** Reemplazar todas las referencias `.ps1` por sus equivalentes en `npx tsx` o comandos
npm.

**Resolución:** ✅ RESOLVED — 2026-07-29

---

### GAP-002: config/tool-profiles/CLAUDE.md references non-existent PS1 scripts

<!-- ID: GAP-002 | Created: 2026-07-29 | Severity: CRITICAL -->

**Severidad:** 🔴 CRITICAL **Etiquetas:** `agent-config` `claude-md` `broken-reference`

**Descripción:** El archivo `config/tool-profiles/CLAUDE.md` (perfil de tool para el agente)
contiene 5 comandos `pwsh` que referencian scripts que ya no existen:

1. `scripts\utilities\DETECT\detect-tool.ps1`
2. `src/pre-process-input.ts`
3. `src/self-diagnosis.ts`
4. `codegraph-semantic-search.ps1` (referencia en regla 14)
5. `scripts\utilities\semantic-search.ps1`
6. `review-workload-guard.ps1`

**Impacto:** Si un agente nuevo sigue esta CLAUDE.md al pie de la letra, falla en el primer comando
y no puede operar.

**Acción:** Reemplazar todas las referencias por sus equivalentes en TypeScript (`npx tsx`).

**Resolución:** ✅ RESOLVED — 2026-07-29

---

### GAP-003: NORMATIVAS-ARCHITECTURE.md says "TypeScript 7.4+ mandatory"

<!-- ID: GAP-003 | Created: 2026-07-29 | Severity: HIGH -->

**Severidad:** 🔴 HIGH **Etiquetas:** `policy` `ps1-migration` `outdated`

**Descripción:** La línea 22 de `rules/NORMATIVAS-ARCHITECTURE.md` dice textual:

> TypeScript 7.4+ mandatory; avoid PSCustomObject (use [PSCustomObject] or hashtable)

Esto contradice la TYPESCRIPT-FIRST-POLICY y está obsoleto desde la migración a TS.

**Acción:** Reemplazar con referencia a TYPESCRIPT-FIRST-POLICY y eliminar el mandato PS1.

**Resolución:** ✅ RESOLVED — 2026-07-29

---

### GAP-004: Session autostart pipeline sometimes slow/timeout

<!-- ID: GAP-004 | Created: 2026-07-29 | Severity: MEDIUM -->

**Severidad:** 🟡 MEDIUM **Etiquetas:** `performance` `pipeline` `startup`

**Descripción:** `session-autostart.ts` ejecuta múltiples pasos lazy en background. En ocasiones el
pipeline tarda >30s en completarse, especialmente cuando CodeGraph o Engram tienen que reindexar. No
hay feedback visual al usuario durante la espera.

**Contexto:** Observado en múltiples sesiones. Los pasos son non-blocking pero el pipeline completo
puede demorar.

**Posible solución:** Agregar indicador de progreso o timeout por paso. O migrar a ejecución
secuencial con feedback.

**Estado:** 🔴 OPEN

---

### GAP-005: Dashboard WS server requires manual port config

<!-- ID: GAP-005 | Created: 2026-07-29 | Severity: LOW -->

**Severidad:** 🟢 LOW **Etiquetas:** `dashboard` `usability` `config`

**Descripción:** El dashboard WS server necesita `WS_PORT` env var o usa puerto fijo. En entornos
con múltiples instancias puede haber conflicto. `dashboard-common.ps1` tiene `Get-FreePort()` pero
está en PS1 (no migrado a TS).

**Estado:** 🔴 OPEN

---

### GAP-006: No hay health.html (PAGE 10) en presentations

<!-- ID: GAP-006 | Created: 2026-07-29 | Severity: MEDIUM -->

**Severidad:** 🟡 MEDIUM **Etiquetas:** `presentations` `missing-page` `book`

**Descripción:** El book de presentaciones tiene 10 páginas en el navbar pero la página 10 (Stack
Health & Metrics / health.html) no ha sido creada. En index.html está marcada como "próximamente".

**Acción:** Crear `health.html` con métricas de salud del stack (82/82 watchtower, 19/19 tests,
etc.).

**Estado:** 🔴 OPEN

---

### GAP-007: Pre-commit hook stale (.git/hooks/pre-commit-prompt-optimize.ps1)

<!-- ID: GAP-007 | Created: 2026-07-29 | Severity: MEDIUM -->

**Severidad:** 🟡 MEDIUM **Etiquetas:** `git-hooks` `stale-file` `cleanup`

**Descripción:** El archivo `.git/hooks/pre-commit-prompt-optimize.ps1` es un hook antiguo que
referencia `scripts\utilities\semantic-compression.ps1` (que ya no existe). No es ejecutado por
lefthook (los hooks reales están gestionados por lefthook), pero está presente y puede causar
confusión.

**Acción:** Eliminar el archivo stale.

**Resolución:** ✅ RESOLVED — 2026-07-29

---

### GAP-008: npm test timeout en CI (19 tests, a veces >120s)

<!-- ID: GAP-008 | Created: 2026-07-29 | Severity: LOW -->

**Severidad:** 🟢 LOW **Etiquetas:** `testing` `performance` `ci`

**Descripción:** En algunas ejecuciones, `npm test` toma más de 120s. El test-runner ejecuta 19
suites secuencialmente. No está claro si es por IO, red, o algún test específico.

**Posible solución:** Agregar logs de timing por suite para identificar cuál demora.

**Estado:** 🔵 BACKLOG

---

## Triage Flow

```
Nuevo gap identificado
    ↓
¿Es CRITICAL o HIGH? ──SÍ──→ Resolver inmediatamente
    ↓ NO
¿Es MEDIUM? ──SÍ──→ Agendar próxima sesión
    ↓ NO
¿Es LOW? ──SÍ──→ Mover a BACKLOG
    ↓ NO
¿Es mejora futura? ──SÍ──→ Agregar a BACKLOG
```

## Métricas

| Estado         | Cantidad |
| -------------- | -------- |
| 🔴 OPEN        | 3        |
| 🟡 IN PROGRESS | 0        |
| 🟢 RESOLVED    | 4        |
| ⚪ WONT FIX    | 0        |
| 🔵 BACKLOG     | 1        |
| **Total**      | **8**    |
