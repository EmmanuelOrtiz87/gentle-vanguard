---
created: 2026-08-31 17:49:12
tags: [engram, architecture]
engram_id: 3516
type: architecture
---

# Namespace --gv-*reservado al canónico; dashboard renombra sus vars a --dash-*

**What**: Namespace collision resuelta (commit d7b108e9): el dashboard definía sus propias variables --gv-*(13 vars: --gv-panel #ffffff, --gv-teal #087f78, --gv-text #163247 — tema claro teal) con valores DISTINTOS a las del design system canónico (--gv-text #ffffff, --gv-muted #6b7280 — colisión en --gv-text y --gv-muted). Renombradas a --dash-* (37 usages, 1 archivo: apps/web-dashboard/src/styles/index.css). El namespace --gv-*queda reservado exclusivamente para el canónico.
**Why**: Si el dashboard alguna vez importa gv-design-system.css, las variables chocarían y romperían su tema claro.
**Where**: apps/web-dashboard/src/styles/index.css
**Learned**: (1) REGLA: el prefijo --gv-* en variables CSS está RESERVADO para assets/gv-design-system.css — las apps que definan variables propias deben usar su propio prefijo (--dash-* dashboard, etc.). (2) El dashboard es light-first con teal (#087f78) — su identidad visual difiere del dark navy/cyan del resto; unificarlo requeriría un re-skin mayor (riesgo, no solicitado). (3) Verificación de colisiones de namespaces: grep de definiciones --prefijo- en cada app vs el canónico antes de cualquier import compartido.

---
*Imported from Engram on 2026-09-06*
