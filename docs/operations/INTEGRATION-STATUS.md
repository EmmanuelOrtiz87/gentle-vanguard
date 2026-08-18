# Content Operations Integration Status

**Branch:** `feat/content-operations-engine`
**Base:** `develop`

## Completed in this branch

- Offline-first `ContentJob` domain contract.
- Manifest at `content/operations/master-manifest.json`.
- Platform capability registry at `config/content-operations/platforms.json`.
- Validation and packet generation in `src/content-operations/engine.ts`.
- Unit coverage in `tests/unit/content-operations.test.ts`.
- Offline export script at `scripts/content-operations/export-kit.ps1`.
- Architecture and implementation directives.
- No remote credentials or API calls.
- Import-safe engine: importing the library does not execute a publication workflow.

## Existing capabilities to consolidate

The stack already contains:

- `src/marketing-agent.ts`
- `src/social-poster.ts`
- `docs/presentations/resources-index.html`
- `src/cli/gv.ts`
- dashboard, health/watchtower, security, audit and database infrastructure

The next integration must reuse those capabilities instead of duplicating them.

## Verification sequence

Run from the repository root:

```powershell
pnpm install
pnpm typecheck
pnpm lint
pnpm format:check
npx tsx --test tests/unit/content-operations.test.ts
pnpm test:config
pnpm test:workflows
pnpm secretlint
```

For a broader verification:

```powershell
pnpm test
pnpm stack:verify:quick
pnpm health:check:quiet
```

## Offline verification

The content workflow must remain useful without network access:

```powershell
npx tsx src/content-operations/cli.ts list --date=2026-08-18
npx tsx src/content-operations/cli.ts validate
npx tsx src/content-operations/cli.ts prepare --date=2026-08-18
powershell -ExecutionPolicy Bypass -File scripts/content-operations/export-kit.ps1
```

Remote publication is intentionally out of scope until each provider adapter has been implemented and tested against its current official API requirements.

## Acceptance gates for merge

- [ ] CI green.
- [ ] Typecheck green.
- [ ] Lint green.
- [ ] Formatting green.
- [ ] Content unit tests green.
- [ ] Existing regression suites green.
- [ ] No duplicate publishing path introduced.
- [ ] No secrets added.
- [ ] CMS integration design reviewed.

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
