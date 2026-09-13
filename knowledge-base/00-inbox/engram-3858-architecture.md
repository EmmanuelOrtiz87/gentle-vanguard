---
created: 2026-09-10 05:03:28
tags: [engram, architecture]
engram_id: 3858
type: architecture
---

# Academy: Verticales Pro Ventas y Finanzas

**What**: Verticales Pro completadas: "Manual Práctico de IA para Ventas" (manual-ia-ventas, 14 capítulos, ~90KB) + "Manual Práctico de IA para Finanzas" (manual-ia-finanzas, 14 capítulos, ~82KB) + toolkits "IA para Ventas Pro" (ia-ventas-pro) + "IA para Finanzas Pro" (ia-finanzas-pro), ambos 50/8/8/6/4. Todos featured. Paquetes "Plan Ventas Pro" y "Plan Finanzas Pro" creados automáticamente.

**Why**: El usuario pidió seguir potenciando el stack. Las verticales Pro completan el upgrade path (micro-ebook lead magnet → toolkit → premium high ticket) para las verticales de mayor demanda.

**Where**:
- `apps/academy-web/data/ebooks/manual-ia-ventas/` + `manual-ia-finanzas/` — ebooks premium (14 capítulos cada uno, featured)
- `apps/academy-web/data/toolkits/ia-ventas-pro/` + `ia-finanzas-pro/` — toolkits premium (50/8/8/6/4, featured, links a manuales)
- `apps/academy-web/data/ebooks.js` + `data/toolkits.js` — registries regenerados (14 ebooks + 11 toolkits)
- `apps/academy-web/data/ebooks/*/cover.svg` + `data/toolkits/*/cover.svg` — 25 portadas
- `apps/academy-web/README.md` — ebooks premium + tabla de toolkits actualizada

**Learned**: (1) El patrón Pro es escalable: manifest premium + skeleton + subagente + registry + portada + paquete automático. (2) Store verificado: 11 paquete-cards + 12 store-cards (featured). (3) smoke 20/20 PASS. (4) Estado: 20 cursos + 14 ebooks (125 capítulos: 10 micro + 4 premium) + 11 toolkits (815 items) + 11 paquetes + Landing (home) con leads + Store + dashboard con 2 paneles + 2 alertas.

---
*Imported from Engram on 2026-09-12*
