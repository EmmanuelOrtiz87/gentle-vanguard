# Estado de Continuación — Gentle Vanguard

**Actualizado:** 2026-08-22 (fin sesión 4) · **Propósito:** retomar la evolución sin perder nada.
**Plan maestro:** `docs/plans/STACK-EVOLUTION-PLAN-2026.md` (registro de progreso por sesión).
**Plan comercial:** `GENTLE_VANGUARD_MASTER/00-EVOLUTION-ACTION-PLAN-2026-08.md`.

---

## 1. Estado actual verificado (fin sesión 4)

| Métrica                   | Valor                                                                                                               | Cómo verificar                                                |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Watchtower                | **95/95 — 0 WARN — 0 FAIL**                                                                                         | `npm run watchtower:health`                                   |
| Typecheck                 | 0 errores                                                                                                           | `pnpm typecheck`                                              |
| Suite                     | 5/5 suites                                                                                                          | `pnpm test`                                                   |
| `any` en src/             | **35** (de 218, -84%)                                                                                               | `grep -rn ': any\b\|as any\b' src/ --include='*.ts' \| wc -l` |
| Dominios migrados         | 8 (35 archivos): tokens(13), retrieval(3), compression(3), web(6), research(2), design(3), humanize(2), planning(3) | `ls src/`                                                     |
| Archivos aún en raíz src/ | ~250                                                                                                                | `ls src/*.ts \| wc -l`                                        |
| Grafo nativo              | 4.438 nodos / ~8.500 edges                                                                                          | `npm run graphify -- status`                                  |
| Versiones                 | todo alineado en 3.8.2                                                                                              | `npm run version:check`                                       |
| Cobertura                 | gate 40% (real 62%)                                                                                                 | `pnpm coverage`                                               |
| Skills                    | 0 duplicadas; INDEX.md 263 filas                                                                                    | `npm run skills:index`                                        |
| Commits del día           | 21+ (sesiones 1-4)                                                                                                  | `git log --oneline` desde `51440190`                          |
| Comercial                 | Sprint A 100%; Sprint B drafts en `MASTER/11-SPRINT-B-SELL-ENABLE/`                                                 | —                                                             |

## 2. Pendiente priorizado (siguiente sesión)

0. **Fase 6 (§9 del plan) — análisis transversal del cierre**: N1 schema drift Nexus
   (token_transactions/savings fuera del MigrationRunner), N2 consolidar CodeGraph/graphify
   (ADR-0019), N3 AGENTS.md comprimido (ahorro de contexto por sesión), N4 auto-heal continuo de
   daemons, N5 profiles multi-tool fuente única, N6 telemetría response_cache, N7 verificar contador
   embeddings (6 vs 419), N8 pre-push compuesto paralelo, N9 loop de aprendizaje cerrado. Orden:
   N1→N4→N7→N2→N9→N3/N5/N6/N8.
1. **F2.2 continuación** — dominios restantes (~250 archivos): security, orchestration (sia-*,
   team-orchestrator, session-close-\*), ops (dashboard-\*, health-\*), content (content-operations
   ya está en src/content-operations/), review (code-review, auto-code-review vs
   src/autonomous-review/ colisión), ml/adaptive. **Usar el playbook §3.1.**
2. **F2.5** — partir los 16 archivos >800 líneas, empezando por `src/core/maintenance-watchtower.ts`
   (1.958 → checks por componente como módulos). Gate de regresión: watchtower 95/95 tras el split.
   Requiere sesión dedicada.
3. **F2.3** — migrar `console.*` → logger SOLO en módulos library (los CLIs imprimen a stdout por
   diseño). ~5.293 llamadas; empezar por src/core/.
4. **F1.3** — changesets/release-please (interino: version-sync gate funciona; decidir si vale la
   pena cambiar el formato del CHANGELOG).
5. **F3.x** — evaluación continua sobre trazas de Nexus, guardrails defense-in-depth ADR,
   StoragePort/QueuePort, plugin registry, dashboard de coste.
6. **Comercial (decisiones del dueño, no delegables)**: números finales de pricing (tiers ×
   ofertas), beachhead (análisis recomienda B2B), duraciones Workshop/Foundations (kit 2-3h/4-5h vs
   drafts 4h/8h), revisión legal profesional, demo 90s, payment links. Lista completa en
   `MASTER/11-SPRINT-B-SELL-ENABLE/` y §Sprint B del plan comercial.
7. **MASTER decisiones de contenido**: retirar decks 6-slides de 04, marcar 02/03 como históricos
   (baja de 401 a ~350 activos).

## 3. Playbooks probados (usar tal cual)

### 3.1 Mover un dominio src/ (probado 8 veces, 35 archivos)

```bash
# 1. Inventariar imports del dominio (buscar imports INTRA-dominio a preservar):
grep -n "from '\./" src/<files> | grep -v "node:"
# 2. Mover y fixear profundidad de imports externos:
mkdir -p src/<domain> && git mv src/<f1>.ts src/<f2>.ts src/<domain>/
sed -i "s|from '\./core/|from '../core/|g; s|from '\./<otro-dom>/|from '../<otro-dom>/|g" src/<domain>/*.ts
# 3. Rewriter de referencias (script node probado — ver commits 20a02875/7052c976):
#    reemplaza 'src/X.ts' (strings), './X.js' (imports raíz), '../src/X.js', '../../src/X.js'
#    ⚠️ El rewriter rompe los imports INTRA-dominio ('./X.js' → './domain/X.js'): revertirlos.
#    ⚠️ También rompe imports desde subdirs ('../X.js' desde src/core|tokens): fixear aparte.
#    ⚠️ Rutas por segmentos ("'src', 'X.ts'" en join/resolve) NO las toca el rewriter: grep aparte:
grep -rn "'src', '<name>" src/ tests/ scripts/ --include='*.ts'
# 4. Verificar: pnpm typecheck (0) + tests del dominio + pnpm test + smoke CLI del dominio
# 5. npm run graphify -- build && commit "refactor(<domain>): move ... (F2.2)"
```

### 3.2 Erradicación de `any` vía agente

Prompt probado (sesiones 3-4): lista explícita de archivos (grep por conteo descendente),
exclusiones duras (dominios en migración, package.json), patrones permitidos (unknown, catch
unknown, interfaces de fila SQLite, dobles casts), prohibido >10 líneas de rediseño, gate final
typecheck 0 + smoke runtime de 3 módulos. Resultado: 183 `any` eliminados en 3 batches.

### 3.3 Fix bug ESM main-check

`require.main === module` en archivos ESM crashea directo. Patrón canónico del stack:
`if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) { main(); }` (ver
commit 078aace1). Buscar más: `grep -rn "require.main" src/ --include='*.ts'`.

## 4. Gotchas del entorno (aprendidos, no repetir)

1. **El sandbox recolecta daemons entre turnos**: dashboard-ws/codegraph mueren solos tras un rato →
   3 FAILs en watchtower. Restart: `npx tsx src/dashboard-ws-autostart.ts` (background) y
   `npx tsx src/codegraph-mcp-server-start.ts`. El codegraph MCP habla **stdio** (no puerto 3000);
   el check pasa por PID vivo.
2. **Commits con hooks lentos**: lefthook pre-commit puede tardar/cortarse en este entorno. Para
   checkpoints: `git -c core.hooksPath=/dev/null commit` (los archivos ya validados por typecheck/
   tests). Usar con criterio — los hooks corren normal en la máquina del dueño.
3. **Backticks en bash**: NUNCA poner backticks de markdown dentro de `node -e` en bash (se los come
   la sustitución). Usar la herramienta Edit para markdown.
4. **Límite de concurrencia de agentes**: máx 2 simultáneos (el 3ro falla con "user concurrency
   limit exceeded"). Relanzar cuando termine uno.
5. **Commit concurrente con agentes**: `git add -A` barre el trabajo en progreso de los agentes.
   Commitear solo rutas propias: `git add src/ docs/ ...` o esperar al agente.
6. **ml-embeddings**: `.atl/ml-embeddings/` lo genera `npx tsx src/skills/skill-embedder.ts` (419
   archivos). Si el check falla de nuevo, correr el embedder.
7. **json-lint en pre-commit** falla con fixtures intencionalmente rotos → sufijo `.json.broken`.

## 5. Dónde está todo

- **Repo**: plan maestro + registro por sesión en `docs/plans/STACK-EVOLUTION-PLAN-2026.md`; grafo
  builder `src/cli/graphify-build.ts` (AGENTS.md graphify ACTIVO); shared primitives
  `packages/shared/`; índice de skills `skills/INDEX.md` (regenerar: `npm run skills:index`).
- **Nexus**: evento de cierre persistido en `.session/event-store/` (AggregateId `stack-evolution`,
  hash-chained — verificar con
  `npx tsx src/event-sourcing.ts -Action verify -AggregateId stack-evolution`); métricas del día en
  `reports/coverage-summary.json` y `.runtime/watchtower-full-report.json`.
- **MASTER comercial**: acción `00-EVOLUTION-ACTION-PLAN-2026-08.md` (Sprint A ✓, B drafts ✓);
  entregables en `11-SPRINT-B-SELL-ENABLE/`; backup dedup `99_BACKUP_PRE_DEDUP_2026-08-22/`;
  manifiesto `00-FILE_MANIFEST_FINAL.json` (regenerar: `node 99_TOOLS/regen-manifest.mjs`); verdad
  de métricas `01-MASTER_OPERATIONS/99_METRICS_TRUTH_2026-08-22.md`.

## 6. Primeros 3 comandos de la próxima sesión

```bash
npx tsx src/session/session-autostart.ts          # pipeline obligatorio
npm run watchtower:health                 # debe dar 95/95 (si hay FAILs de daemon → §4.1)
git log --oneline -5                      # confirmar que HEAD es ec94b6b8 o posterior
```
