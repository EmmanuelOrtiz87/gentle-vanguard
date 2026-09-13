---
created: 2026-08-15 01:31:18
tags: [engram, architecture]
engram_id: 2837
type: architecture
---

# Optimización 4 frentes + fix delegación kimi-2-5

**What**: Optimización completa de los 4 frentes de consumo (inicio/cierre de sesión, delegación, cache) + fix crítico de delegación rota + 3 presentaciones nuevas.
**Why**: El usuario pidió operar con todas las herramientas al 100% y optimizar el consumo de tokens/contexto del stack.
**Where**:
- Fix crítico: 21 `.opencode/agents/*.md` + `config/model-fallback.json`, `model-health.json`, `correction-rules.json`, `model-health-registry.json` → `opencode/deepseek-v4-flash-free` (kimi-2-5 no existe)
- Frente 1+2: `src/session-close-orchestrator.ts` (KILL_TARGETS + Token Ingest optional + sub-fase cleanup-active-session), `config/token-budget-guard.json` (daily 5M→13M), `src/token-ingest.ts` (token.current_session), `src/session-cleanup-start.ts` (flag -SkipSessionInit), `config/session-autostart.config.json` (habilitados session-cleanup + post-autostart-consistency-check como lazy)
- Frente 3+4: `src/agent-delegator.ts` + `src/route-and-delegate.ts` (compressDelegationLossless, mode:'input', umbral 200 chars), `src/response-cache.ts` (SEMANTIC_CACHE_THRESHOLD 0.85→0.9 + MIN_SEMANTIC_INPUT_TOKENS 40)
- Windows bugs: `src/agents/sdd-apply.ts` + `sdd-verify.ts` (resolveNpm() npm.cmd + shell:true)
- Residuales: `src/gga.ts`, `model-fallback-orchestrator.ts`, `smart-model-router.ts`, `smart-task-wrapper.ts`, `universal-task-wrapper.ts` (kimi-2-5 → opencode/deepseek-v4-flash-free)
- Presentaciones: `docs/presentations/commands.html` (266 scripts), `glossary.html` (280 términos), `study-material.html` (42 conceptos), `index.html` (nav + book-cards + sec_optimization), `assets/js/i18n-extra.js` (merge sin conflictos), `src/cli/validate-presentations.ts` (MAIN_PRESENTATIONS +3)
**Learned**:
1. El task tool de opencode cachea las definiciones de agentes al inicio de sesión — los fixes en disco aplican en la SIGUIENTE sesión. Agentes built-in (explore/general) siempre funcionan.
2. Node spawn() en Windows: `.cmd` shims (npm.cmd) requieren shell:true, y `spawn('npm')` da ENOENT — usar npm.cmd.
3. TF-IDF cosine con vocabulario pequeño sesga inputs cortos a ~87% similitud (falso positivo del cache semántico) — umbral 0.9 + mínimo 40 tokens.
4. compressStructural mode:'input' es lossless (protege razonamiento); compressPrompt es lossy (no usar en delegación).
5. Verificación final: typecheck ✅, lint ✅, watchtower 95/95 PASS, db HEALTHY (23 tablas/39261 rows), presentations 14/14 PASS, tests 24/24 + 2/2 + 5/5.

---
*Imported from Engram on 2026-09-06*
