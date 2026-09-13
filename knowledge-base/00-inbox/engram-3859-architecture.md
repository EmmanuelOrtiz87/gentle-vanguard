---
created: 2026-09-10 10:39:13
tags: [engram, architecture]
engram_id: 3859
type: architecture
---

# Academy: Verticales Pro Emprendedores y RRHH + Tier Pro en Store

**What**: Verticales Pro completadas: "Manual Práctico de IA para Emprendedores" (manual-ia-emprendedores, 14 capítulos, ~64KB) + "Manual Práctico de IA para RRHH" (manual-ia-rrhh, 14 capítulos, ~80KB) + toolkits "IA para Emprendedores Pro" (ia-emprendedores-pro) + "IA para RRHH Pro" (ia-rrhh-pro), ambos 50/8/8/6/4. Todos featured. Paquetes "Plan Emprendedores Pro" y "Plan RRHH Pro" creados automáticamente. Además: sección "Tier Pro" en la Store (destaca manuales premium + toolkits Pro con estilo .pro-card).

**Why**: El usuario pidió seguir potenciando el stack. Las verticales Pro completan el upgrade path para las 6 verticales principales; la sección Tier Pro hace visible el high ticket en la Store.

**Where**:
- `apps/academy-web/data/ebooks/manual-ia-emprendedores/` + `manual-ia-rrhh/` — ebooks premium (14 capítulos, featured)
- `apps/academy-web/data/toolkits/ia-emprendedores-pro/` + `ia-rrhh-pro/` — toolkits premium (50/8/8/6/4, featured)
- `apps/academy-web/data/ebooks.js` + `data/toolkits.js` — registries (16 ebooks + 13 toolkits)
- `apps/academy-web/data/*/cover.svg` — 29 portadas
- `apps/academy-web/app.js` — sección "Tier Pro" en viewStore (proEbooks type=premium + proToolkits id endsWith '-pro'), i18n storePro/storeProSub (es/en/pt)
- `apps/academy-web/academy-layout.css` — estilos .pro-card (borde purple + gradiente)
- `apps/academy-web/README.md` — ebooks premium + tabla de toolkits actualizada

**Learned**: (1) La sección Pro se deriva automáticamente: ebooks con type=premium + toolkits con id que termina en '-pro' — cero mantenimiento manual. (2) Store verificado: 13 paquete-cards + 11 pro-cards + 16 featured. (3) smoke 20/20 PASS. (4) Estado: 20 cursos + 16 ebooks (153 capítulos: 10 micro + 6 premium) + 13 toolkits (967 items) + 13 paquetes + Landing (home) con leads + Store con Tier Pro + dashboard con 2 paneles + 2 alertas.

---
*Imported from Engram on 2026-09-12*
