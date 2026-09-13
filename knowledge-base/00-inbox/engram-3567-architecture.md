---
created: 2026-09-01 04:43:37
tags: [engram, architecture]
engram_id: 3567
type: architecture
---

# apps/archify — app nativa de diagramas interactivos (motor Archify absorbido)

**What**: Implementé `apps/archify` — app nativa GV que absorbe el motor de diagramas interactivos de sistemas de tt-a1i/archify (MIT v2.16.0, ~39k stars).

**Why**: El stack no tenía una app dedicada de diagramación/visualización de arquitectura interactiva (solo CLI diagram-renderer y diagram-design skill estático). Archify aporta visor interactivo + delta/PR-proof + exports.

**Where**:
- `apps/archify/engine/` — motor Archify absorbido (renderers/schemas/delta/assets/bin/migrations/recipes/references/brand-marks/examples), zero-dep JS .mjs
- `apps/archify/server/server.ts` — API REST (tsx, puerto 4790): /api/health, /api/render, /api/validate, /api/delta, /api/examples
- `apps/archify/server/smoke.mjs` — smoke test end-to-end
- `apps/archify/src/` — frontend React (Vite 8, React 18, TS 6): App.tsx (Estudio/Delta/Biblioteca), api.ts, library.ts, branding GV
- `apps/command-center/server.ts` — APPS_REGISTRY + AppId + processes para app 'archify' (API 4790 + Vite 5179)
- `apps/command-center/tests/command-center.test.ts` — actualizado a "six normal managed apps"
- `skills/archify-studio/SKILL.md` — skill GV

**Learned**:
- El motor usa node:fs/node:path y corre como CLI con top-level await → NO se importa en navegador; el server lo invoca como subproceso `node` oculto (windowsHide) y devuelve el artifact HTML autocontenido
- Verificado: POST /api/render devuelve artifact ~715KB con <!DOCTYPE html>; POST /api/validate → {valid:true}; POST /api/delta → html + receipt (99KB)
- App se registró correctamente: test "exposes the six normal managed apps" pasa
- El test command-center "starts and stops a stopped app" falla por timeout de 5s pre-existente (usa academy, no relacionado con archify)
- Las apps del monorepo NO están trackeadas por git (apps/ en .gitignore) — se gestionan con git propio
- Dependencias de app: `pnpm install --ignore-workspace` (instalación standalone)
- Para actualizar motor: clonar tt-a1i/archify y copiar archify/ → apps/archify/engine/ (ver ENGINE-README.md)

---
*Imported from Engram on 2026-09-06*
