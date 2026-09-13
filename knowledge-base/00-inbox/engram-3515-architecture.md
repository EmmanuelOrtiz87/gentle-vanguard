---
created: 2026-08-31 17:41:49
tags: [engram, architecture]
engram_id: 3515
type: architecture
---

# CMS migrado al design system canónico (fuente única real)

**What**: Migración profunda de CMS al design system canónico completada (commit e585bc63): styles.css importa assets/gv-design-system.css directamente, shell renombrado a clases .gv-*(grid-bg→gv-grid-bg, topbar→gv-topbar, panel→gv-panel, etc.), variables --color-* unificadas a --gv-*, duplicaciones eliminadas (styles.css 833→545 líneas, -450/+209). De paso corrigió residuos off-brand que quedaban en grid/glows del CMS (#a78bfa/#22d3ee → #a855f7/#00bfff canónicos). Textos terciarios de Content OS extraídos a i18n.ts.
**Why**: Fuente única de verdad real — los cambios futuros al design system se propagan a todas las apps que lo importan sin tocar cada copia.
**Where**: apps/content-cms/src/styles.css, App.tsx, contentos.tsx
**Learned**: (1) Estado de migración al canónico: prompt-studio ✅ importa directo, CMS ✅ migrado (estrategia A2: import + rename a .gv-* + dedupe), academy usa snapshot documentado (estática no puede importar fuera de su root), analytics queda como origen/referencia sin migrar (173 refs propias — riesgo alto, valor bajo), dashboard Tailwind-based parcial. (2) La migración A2 (import + rename + dedupe) es el patrón para las apps restantes. (3) Verificación clave: comparar valores computados ANTES de borrar duplicados — el canónico manda, documentando diferencias.

---
*Imported from Engram on 2026-09-06*
