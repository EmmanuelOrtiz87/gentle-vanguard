---
created: 2026-05-24 12:36:41
tags: [engram, bugfix]
engram_id: 1108
type: bugfix
---

# CodeGraph auto-sync hooks + docs

**What**: Agregados hooks post-commit y post-merge en .lefthook.yml y config/lefthook.yml para sincronizar automáticamente el índice de CodeGraph después de cada commit/merge. Actualizada documentación en SKILL.md y NORMATIVAS-DEVOPS.md.

**Why**: El índice de CodeGraph se quedaba obsoleto (>30min), generando warnings en cada inicio de sesión. Solo se sincronizaba al iniciar sesión, no después de cambios.

**Where**:
- .lefthook.yml (post-commit + post-merge)
- config/lefthook.yml (post-commit + post-merge)
- skills/codegraph-skill/SKILL.md (nueva sección Auto-Sync via Git Hooks)
- rules/NORMATIVAS-DEVOPS.md (sección 6.1 CodeGraph Index Auto-Sync)

**Learned**: El script codegraph-post-modification-sync.ps1 necesita -Force para post-commit porque tras el commit git status queda limpio (0 files changed) y skips sin -Force. También: lefthook.yml en raíz es el que ejecuta, config/lefthook.yml es copia de referencia.

---
*Imported from Engram on 2026-09-06*
