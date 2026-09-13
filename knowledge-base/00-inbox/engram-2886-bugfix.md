---
created: 2026-08-19 03:01:00
tags: [engram, bugfix]
engram_id: 2886
type: bugfix
---

# README governance 0 errores + fix sync public + limpieza API keys PowerShell

**What**: Completados los pendientes del stack: (1) validación README gobernanza a 0 errores con números reales, (2) fix del sync public que pisaba el README público, (3) limpieza de API keys hardcodeadas del perfil PowerShell.
**Why**: El usuario pidió avanzar con todo lo pendiente y operar con todas las herramientas de forma segura.
**Where**: src/validate-readme.ts, README.md, README-PUBLIC.md, .github/workflows/auto-update.yml, C:\Users\emman\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
**Learned**:
- validate-readme.ts contaba agents desde auto-delegation.json (19) cuando la fuente real es opencode.json (21 agents); skills solo contaba skills/ (175) cuando el total real es 263 (skills/ + .opencode/skills). Fix: leer opencode.json primero con fallback al método anterior, y sumar ambas carpetas de skills.
- README.md privado necesitaba secciones con patrones exactos case-sensitive: Agent Ecosystem, Key Capabilities, Development, CI/CD Pipeline, Project Status, Key Documentation + mínimo 3 diagramas Mermaid + stats correctos.
- GOTCHA CRÍTICO: sync-to-public.ts copia README-PUBLIC.md del repo privado → README.md del público. Si editas el README público directamente, el próximo sync lo pisa. La fuente de verdad del README público es README-PUBLIC.md en el repo privado.
- El perfil de WindowsPowerShell del usuario tenía 5 líneas con API keys hardcodeadas de LITTELMOTT (sk-prod-...). Eliminadas y reemplazadas por lectura segura desde variable de entorno de usuario.
- auto-update.yml ahora tiene workflow_dispatch con inputs tag/version para regenerar el manifest manualmente.
- Estado verificado: watchtower 95/95 PASS, typecheck OK, lint OK, tests 5/5 OK, validate-readme --repo both PASS.

---
*Imported from Engram on 2026-09-06*
