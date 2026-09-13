---
created: 2026-09-09 20:19:12
tags: [engram, bugfix]
engram_id: 3824
type: bugfix
---

# Gap ventanas fantasmas: npx tsx en lefthook + configs → node --import tsx

**What**: Gap principal de ventanas fantasmas encontrado y corregido: el stack usaba `npx tsx` en ~119 ocurrencias de configs e instrucciones que se ejecutan en Windows. AGENTS.md prohíbe `npx tsx` (el CLI de tsx relanza el script como proceso NIETO sin windowsHide → consola visible). Fix: migración masiva a `node --import tsx` (in-process loader, oculto). Archivos: .lefthook.yml v3.2 (13 hooks — se ejecutan en CADA commit/push), config/agents.json (20 executionCommand), config/orchestrator.json (18 scripts), config/quality-gates.json (16 gates), config/tool-profiles/ (15), .opencode/commands (6), .zcode/commands (4), .opencode/agents (16, locales), .opencode/skills/references (10, locales), config/sre-error-budgets.json (1).
**Why**: Usuario reportó ventanas fantasmas persistentes; la revisión exhaustiva previa (spawn/execSync directos) no encontró el gap real — estaba en los hooks de git y configs.
**Where**: .lefthook.yml, config/*.json, .opencode/commands, .zcode/commands, config/tool-profiles/. Commit 0fcab58f (18 archivos trackeados). Los .opencode/agents y skills/references son git-ignored (locales).
**Learned**: (1) El gap NO estaba en el stack core (run-command tiene windowsHide por defecto) ni en los spawn directos (ya corregidos en ronda anterior) — estaba en los HOOKS DE GIT (lefthook) y configs que los agentes ejecutan literalmente. (2) `npx tsx` es el anti-patrón #1 en Windows: npx.cmd → tsx CLI (cli.mjs) → node script (nieto sin windowsHide) = consola visible. `node --import tsx` corre el script EN el proceso spawned. (3) Verificación implícita: el commit 0fcab58f pasó por los 14 hooks de lefthook con node --import tsx sin errores. (4) Los hooks post-commit (codegraph-sync, hashline-snapshot) funcionan con el nuevo comando.

---
*Imported from Engram on 2026-09-09*
