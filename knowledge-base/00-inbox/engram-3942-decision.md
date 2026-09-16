---
created: 2026-09-15 23:03:07
tags: [engram, decision]
engram_id: 3942
type: decision
---

# archify: restart limpio verificado + decisión mantener standalone

**What**: (1) Restart limpio del server de archify verificado: stop.sh + start.sh nativos, server :4790 responde 200, UI completa (topbar, 13px, backdrop blur, 6 tabs) con el node_modules restaurado. (2) DECISIÓN: archify se mantiene standalone (fuera del workspace pnpm raíz).
**Why**: Ambos lockfiles son v9.0 (integrables), pero reestructurar el layout de deps de una app funcionando sin necesidad real viola el principio de cambios quirúrgicos. El gotcha del install silencioso ya está documentado en el stack manual, así que el riesgo operativo está mitigado.
**Where**: apps/archify/* (standalone), docs/stack-manual-full.md (sección Shell React compartido — ya documenta el cómo).
**Learned**: (a) El restart de archify con stop.sh/start.sh nativos funciona y es la vía correcta (NORM-TS-001). (b) Si en el futuro se integra archify al workspace: lockfiles compatibles v9.0, better-sqlite3 ya está en allowBuilds del root — el costo principal es re-verificar el build nativo y el layout. (c) Integración queda como opción futura documentada, no como deuda.

---
*Imported from Engram on 2026-09-16*
