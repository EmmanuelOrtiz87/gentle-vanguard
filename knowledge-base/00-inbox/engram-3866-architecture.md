---
created: 2026-09-10 20:49:56
tags: [engram, architecture]
engram_id: 3866
type: architecture
---

# Academy: og-cover.png + catalog.json exportable

**What**: og-cover.png generado (259KB, 1200×630) para compatibilidad real con redes sociales + catálogo JSON exportable (catalog.json) con counts, pricing por tier y los 52 productos con metadata completa.

**Why**: El og:image SVG no funciona en la mayoría de plataformas sociales — el PNG lo hace compartible. El catalog.json hace el catálogo consumible por integraciones externas (CRM, checkout, agregadores) sin scraping.

**Where**:
- `apps/academy-landing/covers/og-cover.png` — NUEVO: 259KB, generado con chrome --headless --screenshot del SVG
- `apps/academy-landing/catalog.json` — NUEVO: counts + pricing (4 tiers: ebook-micro $29, ebook-premium $49, toolkit $49, course-base $40) + products (courses con level/hours/categories, ebooks con type/pages/audience/priceTier, toolkits con includes/links/priceTier)
- `apps/academy-web/scripts/build-landing.mjs` — generación de catalog.json agregada al script
- `apps/academy-landing/README.md` — sección Catálogo JSON

**Learned**: (1) Chrome headless screenshot de SVG local funciona con file:// URI — el PNG se genera en temp y se copia. (2) El catalog.json es la fuente machine-readable del catálogo — los priceTiers derivados en los manifests se propagan automáticamente. (3) El pricing está centralizado en catalog.json (no en cada manifest) — cambiar precios = editar una sola vez. (4) Verificado: counts correctos, 4 pricing tiers, 52 productos con metadata completa.

---
*Imported from Engram on 2026-09-12*
