# ADR-0018: Content Operations Engine (Native TS, Offline-First)

## Status

Accepted

## Date

2026-08-18

## Context

El stack acumulaba capacidades de contenido dispersas y sin un flujo operativo unificado:

- `src/marketing-agent.ts` — generación de copy multilingüe y por plataforma.
- `src/social-poster.ts` — plantillas, plataformas y tracking básico.
- `docs/presentations/resources-index.html` — CMS local / punto de interacción humano.

Cada pieza mantenía su propio modelo de contenido, sin una fuente de verdad común, sin estados
auditables y sin un pipeline reproducible (plan → validar → empaquetar → revisar → aprobar →
publicar → medir). Además, el lanzamiento público del proyecto (sprint de visibilidad de 15 días,
18/08 → 01/09/2026) requiere operar 21 publicaciones reales en 6 plataformas (LinkedIn, X,
Instagram, YouTube, Discord) con assets dimensionados por plataforma.

### Opciones consideradas

| Opción                                                  | Pros                                                                                                                               | Cons                                                                 | Decisión      |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- | ------------- |
| Framework de publicación externo (Buffer/Hootsuite)     | Publicación multi-plataforma lista                                                                                                 | SaaS, costos, sin control del pipeline, datos fuera del stack        | ❌ Rechazada  |
| Scripts sueltos por plataforma                          | Rápido de escribir                                                                                                                 | Sin estados, sin validación, sin idempotencia, no reproducible       | ❌ Rechazada  |
| **Content Operations Engine nativo TS (offline-first)** | Cero dependencias nuevas, manifest como fuente de verdad, state machine auditable, idempotente, funciona sin red, patrón del stack | Publicación remota requiere adapters por plataforma (fase posterior) | ✅ **CHOSEN** |

## Decision

**Implementar un Content Operations Engine nativo en TypeScript puro** (`src/content-operations/`)
que define un contrato de dominio `ContentJob` y un pipeline offline-first:

- **`master-manifest.json`** (`content/operations/`) — fuente de verdad: 21 jobs reales del sprint
  de lanzamiento `GROWTH-EXPERIMENT-001` (fecha, plataforma, tema, copy, CTA, asset, estado).
- **`platforms.json`** (`config/content-operations/`) — registry de capacidades por plataforma
  (mode: adapter/manual/native-repo, media, approvalRequired).
- **`engine.ts`** — state machine
  (`DRAFT → VALIDATED → PACKAGED → REVIEW → APPROVED → PUBLISHED → MEASURED`, `FAILED → DRAFT`),
  `canTransition()`/`transition()` inmutable, validación contra registry, `packageJob()`
  idempotente, `saveManifest()`.
- **`cli.ts`** — 8 comandos: list, validate, prepare, status, report, transition, export, help.
- **`export-kit.ps1`** — exporta el kit offline ZIP en Windows.
- **Assets** — 21 PNGs dimensionados por plataforma en `docs/presentations/social-assets/`.

### Principios de diseño

- **Local-first**: empaquetar funciona sin Internet; la publicación remota es una fase posterior con
  adapters por plataforma.
- **Human-in-the-loop**: `APPROVED` es gate obligatorio para publicación remota.
- **Idempotencia**: `packageJob()` no reescribe paquetes existentes con el mismo contenido (evita
  publicaciones duplicadas por reintentos).
- **Auditabilidad**: cada transición de estado puede reconstruirse desde el manifest.
- **Sin secretos en Git**: el engine no contiene credenciales ni llama APIs remotas.
- **Import-safe**: importar la librería no ejecuta ningún workflow de publicación.

### Comandos

```bash
npm run content:list       # listar jobs (--date, --platform, --id, --status)
npm run content:validate   # validar contra manifest + registry
npm run content:prepare    # empaquetar offline (idempotente)
npm run content:status     # resumen de estados
npm run content:report     # reporte markdown
npm run content:export     # kit offline ZIP
npm run content:test       # tests unitarios (15)
```

## Consequences

### Positivas

- Fuente de verdad única para contenido (manifest) con estados auditables.
- Pipeline reproducible y verificable offline (validate → prepare → export).
- 21 jobs reales del sprint de lanzamiento operativos desde el día 1.
- Cero dependencias nuevas; patrón nativo TS del stack.
- Base lista para adapters oficiales por plataforma (fase 4 de evolución).

### Negativas / Pendientes

- La publicación remota automática requiere implementar adapters por plataforma (LinkedIn, X,
  YouTube, etc.) contra sus APIs oficiales — fuera de alcance en esta fase.
- El CMS local (`resources-index.html`) aún no consume el manifest directamente (fase 2).
- `marketing-agent.ts` y `social-poster.ts` aún no se refactorizan para consumir el manifest (fase
  2/3) — riesgo de modelos duplicados hasta entonces.

## Referencias

- `docs/operations/CONTENT-OPERATIONS-ENGINE.md`
- `docs/operations/IMPLEMENTATION-DIRECTIVE.md`
- `docs/operations/INTEGRATION-STATUS.md`
- `src/content-operations/engine.ts`, `src/content-operations/cli.ts`
- `tests/unit/content-operations.test.ts` (15 tests)
- `content/operations/master-manifest.json` (21 jobs)
- `config/content-operations/platforms.json` (11 plataformas)
