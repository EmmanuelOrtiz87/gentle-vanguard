# Content Operations Integration Status

**Branch:** `develop` (integrado vía PR #159) **Base:** `develop`

## Completed

- Offline-first `ContentJob` domain contract.
- Manifest at `content/operations/master-manifest.json` — **21 jobs reales** del sprint de
  lanzamiento `GROWTH-EXPERIMENT-001` (18/08 → 01/09/2026).
- Platform capability registry at `config/content-operations/platforms.json` (11 plataformas).
- Validation and packet generation in `src/content-operations/engine.ts`:
  - State machine con `TRANSITIONS`, `canTransition()` y `transition()` inmutable.
  - `loadPlatformRegistry()` + validación contra registry (plataforma, approvalRequired, media →
    asset).
  - Validación de fecha `YYYY-MM-DD` y campos obligatorios (theme, contentType, status).
  - `packageJob()` idempotente (no reescribe paquetes existentes con el mismo contenido).
  - `saveManifest()` para persistir transiciones.
- CLI completo en `src/content-operations/cli.ts` (8 comandos: list, validate, prepare, status,
  report, transition, export, help) con filtros `--date/--platform/--id/--status`.
- Unit coverage en `tests/unit/content-operations.test.ts` — **15 tests PASS**.
- Offline export implementation at `src/content-operations/export-kit.ts`.
- Architecture and implementation directives (docs/operations/).
- Assets reales del calendario en `docs/presentations/social-assets/` (21 PNGs).
- npm scripts: `content:list`, `content:validate`, `content:prepare`, `content:status`,
  `content:report`, `content:export`, `content:test`.
- No remote credentials or API calls.
- Import-safe engine: importing the library does not execute a publication workflow.

## Verification (ejecutada)

```powershell
npm run typecheck        # 0 errores
npm run lint             # 0 errores
npm run content:test     # 15/15 PASS
npm test                 # 5/5 suites PASS
npx tsx src/content-operations/cli.ts list      # 21 jobs
npx tsx src/content-operations/cli.ts validate  # 21/21 valid
npx tsx src/content-operations/cli.ts prepare   # 21/21 empaquetados
npx tsx src/content-operations/cli.ts transition --id=GV-2026-08-18-LINKEDIN --to=VALIDATED  # OK
npx tsx src/content-operations/cli.ts transition --id=GV-2026-08-18-X --to=PUBLISHED         # rechazado (DRAFT→PUBLISHED inválido)
npx tsx src/content-operations/cli.ts export    # ZIP offline generado
```

## Existing capabilities to consolidate

The stack already contains:

- `src/marketing-agent.ts`
- `src/tools/social-poster.ts`
- `docs/presentations/resources-index.html`
- `src/cli/gv.ts`
- dashboard, health/watchtower, security, audit and database infrastructure

The next integration must reuse those capabilities instead of duplicating them.

## Offline verification

The content workflow must remain useful without network access:

```powershell
npx tsx src/content-operations/cli.ts list --date=2026-08-18
npx tsx src/content-operations/cli.ts validate
npx tsx src/content-operations/cli.ts prepare --date=2026-08-18
npx tsx src/content-operations/export-kit.ts
```

Remote publication is intentionally out of scope until each provider adapter has been implemented
and tested against its current official API requirements.

## Acceptance gates for merge

- [x] CI green.
- [x] Typecheck green.
- [x] Lint green.
- [x] Content unit tests green (15/15).
- [x] Existing regression suites green (5/5).
- [x] No duplicate publishing path introduced.
- [x] No secrets added.
- [x] CMS integration design reviewed.

## Post-merge phases

1. Integrate the manifest with the existing marketing agent.
2. Refactor social-poster to consume the manifest rather than maintaining a second content model.
3. Add CMS read/review controls.
4. Expose `gv content` commands from the main CLI.
5. Add scheduler/queue and audit events.
6. Implement official adapters one provider at a time.
7. Add publication evidence and metrics.
8. Add feedback-to-content iteration.
9. Export the complete offline project kit, not only the content subsystem.
