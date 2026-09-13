---
created: 2026-08-02 04:47:22
tags: [engram, bugfix]
engram_id: 2466
type: bugfix
---

# Migración PS1→TS completa + 5 referencias rotas corregidas en workflows GitHub

**What**: Completada la revisión de la migración PS1→TS y corregidas 5 referencias rotas en 3 workflows de GitHub que apuntaban a scripts PS1 ya eliminados.
1. `src/sync-to-public.ts` — NUEVO archivo: migración TS del script `sync-to-public.ps1` (305 líneas) que fue eliminado en el commit 8d6ed7dd sin equivalente TS (hueco real de la migración). Copia archivos public-safe al repo público, limpia scripts internos, adapta workflows develop→main, soporta --skip-push y push multi-branch. Verificado con dry-run.
2. `.github/workflows/sync-public.yml` — paths trigger y paso de sync actualizados: PS1 → `npx tsx src/sync-to-public.ts --private-repo ... --public-repo ... --public-repo-slug ... --skip-push`
3. `.github/workflows/reusable-governance.yml` — job `normative` migrado: `pwsh auto-norm-enforcer.ps1 -Trigger` → `npx tsx src/auto-norm-enforcer.ts --check` con setup pnpm/node (ubuntu-latest, Node 22, pnpm 11.15.1, patrón real de ci.yml)
4. `.github/workflows/dashboard-auto-refresh.yml` — el PS1 `generate-dashboard.ps1` ya no existe (arquitectura SPA live). Migrado a `npx tsx src/generate-management-report.ts --on-demand --output-dir reports` generando `MANAGEMENT-REPORT-<mes>.csv`.

**Why**: La migración PS1→TS eliminó los scripts pero no actualizó los workflows de CI/CD → referencias rotas que fallarían silenciosamente en GitHub.

**Where**: src/sync-to-public.ts (nuevo), .github/workflows/{sync-public,reusable-governance,dashboard-auto-refresh}.yml

**Learned**:
- `pnpm tsx` NO es válido — el repo usa `npx tsx` (convención verificada en package.json)
- El `auto-norm-enforcer.ts` usa args `--check/--apply/--report`, no `-Trigger` del PS1
- Los scripts de deployment están ENCRIPTADOS (.enc) en scripts/utilities/ops/DEPLOYMENT — no se pueden invocar directamente
- SHAs de actions del repo: checkout@f548e57e54, pnpm/action-setup@b906affcce, setup-node@e51e5fe84f
- Validación: `npm run test:workflows` (2 tests) + `npx tsx src/workflow-lint.ts <files>` — ambos pasan
- Gate de calidad: typecheck + lint verdes tras todos los cambios

---
*Imported from Engram on 2026-09-06*
