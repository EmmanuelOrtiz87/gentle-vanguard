---
created: 2026-09-08 18:25:08
tags: [engram, decision]
engram_id: 3791
type: decision
---

# Identidad v2.0 cerrada: breadcrumb homologado 100% + propagate exit-code fix + 5 commits

**What**: Cierre de la identidad v2.0 APPLICATION FINAL (ADR-0033). El agente previo dejó hechos el markup+CSS del breadcrumb en prompt-studio y gv-analytics antes de quedarse sin crédito; esta sesión lo verificó, alineó el fallback de color al canon (#a78bfa), corrigió el exit code de apps/design-hub/tools/propagate.js (process.exit(1) cuando failed>0 o copied===0), y arregló src/cli/gv.ts cmdProposals que usaba r.code inexistente en RunSyncResult (campo correcto: r.status + r.error). Verificación visual con Chrome headless: design-hub :8095, prompt-studio :5176, gv-analytics :5174 — breadcrumb "GentleVanguard | APP NAME" homologado en las 3. 5 commits en develop (97364802 brand, eaf10a26 cli, c2a5f631 router+provider-hub, 7230fed6 marketing, cf73c0be kb), tree limpio.
**Why**: El resumen del agente previo listaba 4 pendientes (breadcrumb 2 apps, exit code CLI, typecheck+lint, Engram) que había que validar y cerrar.
**Where**: apps/design-hub/tools/propagate.js, src/cli/gv.ts, apps/prompt-studio/src/styles.css, apps/gv-analytics/src/styles.css, assets/brand/, packages/gv-design-system/
**Learned**: 1) apps/ está gitignoreado por ADR apps-desacopladas — los cambios de apps viven solo local, los commits cubren assets/docs/packages/src. 2) Chrome headless en Windows exige ruta absoluta en --screenshot y virtual-time-budget congela animaciones CSS (mejor captura sin él). 3) El CLI gv es `npx tsx src/cli/gv.ts proposals propagate|status` (no `brand`). 4) build-tokens.ts regenera snapshots de gv-shell.css hacia assets/ y apps/design-hub/public/.

---
*Imported from Engram on 2026-09-08*
