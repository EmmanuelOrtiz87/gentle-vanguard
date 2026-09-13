---
created: 2026-09-09 23:37:14
tags: [engram, architecture]
engram_id: 3839
type: architecture
---

# Academy: 8 toolkits + portadas SVG generadas

**What**: Expansión de Academy a 8 toolkits + generador de portadas SVG con marca GV. Nuevos toolkits: IA para Ventas, IA para RRHH, IA para Finanzas, IA para Marketing (50/8/8/6/4 cada uno). Portadas para los 19 productos (11 ebooks + 8 toolkits).

**Why**: El usuario pidió seguir potenciando el stack y hacer la Store más comercial. Los toolkits completan la matriz producto-ebook-toolkit; las portadas hacen que la Store se vea como un escaparate real.

**Where**:
- `apps/academy-web/data/toolkits/ia-ventas/`, `ia-rrhh/`, `ia-finanzas/`, `ia-marketing/` — 4 toolkits nuevos (50 prompts + 8 plantillas + 8 emails + 6 automatizaciones + 4 casos)
- `apps/academy-web/data/toolkits.js` — registry regenerado (8 toolkits)
- `apps/academy-web/scripts/build-covers.mjs` — NUEVO: genera portadas SVG 1200×1600 (3:4) con fondo #0F1115, gradiente #A78BFA→#22D3EE, brand "GENTLE VANGUARD ACADEMY", badge de tipo, título envuelto, subtítulo y metadatos
- `apps/academy-web/data/ebooks/*/cover.svg` + `data/toolkits/*/cover.svg` — 19 portadas generadas
- `apps/academy-web/app.js` — Store muestra portadas (`.store-cover`), heroes de ebook/toolkit muestran portada (`.hero-cover`), onerror oculta si falta
- `apps/academy-web/academy-layout.css` — estilos `.store-cover` (aspect-ratio 3/4) y `.hero-cover` (150px)
- `apps/academy-web/README.md` — tabla de 8 toolkits + sección Portadas

**Learned**: (1) El generador de portadas es stack-native: lee los manifests y produce SVG deterministas sin LLM — escalable a cualquier producto nuevo. (2) Las portadas se referencian por convención (`<id>/cover.svg`) con onerror fallback — no requieren campo en el manifest. (3) Estado actual: 20 cursos + 11 ebooks (83 capítulos) + 8 toolkits (561 items) + 19 productos en Store con portadas y export PDF.

---
*Imported from Engram on 2026-09-10*
