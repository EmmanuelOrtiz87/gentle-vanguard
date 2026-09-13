---
created: 2026-09-05 19:42:22
tags: [engram, architecture]
engram_id: 3684
type: architecture
---

# Prompt Studio v4 Gem Manager + normalización ramas

**What**: Normalización completa de ramas main/develop + evolución prompt-studio v4 (Gem Manager nativo local-first + Google OAuth + chat Gemini)

**Why**: El usuario pidió: (1) resolver todo lo pendiente para subir al repo y normalizar main/develop, (2) llevar prompt-studio al nivel de analytics/archify/academy con una sección nativa de "Gemas" (reemplazando "Guías"), con login Google y CRUD.

**Where**:
- Commits main: 833af859 (security stack ADR-027/28/29), 904e12c1 (ops/velocidad/delegación/release), 1dfe0b26 (docs/KB/churn). Ambos remotos en 1dfe0b26.
- docs/reference/PROMPT-STUDIO-GEMS.md (research Gems + diseño v4) y PROMPT-LIBRARY-BENCHMARK.md (sección v4) en develop (98308642, pusheado).
- apps/prompt-studio/server/server.ts (backend v4), src/App.tsx + i18n.ts (frontend v4) — app desacoplada (git propio, gitignored).

**Learned**:
- NO existe API oficial pública de CRUD de Gems de Gemini (ai.google.dev/gemini-api/docs/gems = 404 verificado por scrape). Acceso real = reverse-engineering sobre gemini.google.com con cookies __Secure-1PSID (documentado por HanaokaYuzu/Gemini-API, Apache-2.0). fetch_gems(include_hidden=True) lista las predefinidas ocultas; las predefinidas no se editan/eliminan.
- Las apps del stack SON desacopladas desde 09ecd09e (2026-08-31): apps/ gitignored, git propio. Solo los docs de referencia van al repo del stack.
- Patrón apps vs stack: el package.json raíz referencia scripts/apps/*/start.ts que NO existen (huérfanos); el ciclo de vida real es command-center (createAppsController) + start.sh nativo de cada app + src/ops/app-launcher.ts.
- Post-commit de pnpm reinstala y elimina el importer apps/archify del lockfile (apps/ desacoplada) → hay que git restore pnpm-lock.yaml tras cada commit si se quiere mantener 1:1.
- El logger del stack (src/utils/logger.ts) NO tiene .success — solo info/warn/error.
- runSync del stack (src/core/run-command.ts) no soporta throwOnError y no lanza; devuelve RunSyncResult.status.

---
*Imported from Engram on 2026-09-06*
