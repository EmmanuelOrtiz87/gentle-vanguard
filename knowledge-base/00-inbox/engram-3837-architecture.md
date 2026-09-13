---
created: 2026-09-09 23:13:08
tags: [engram, architecture]
engram_id: 3837
type: architecture
---

# Academy: 11 ebooks + vista Store comercial

**What**: Expansión de Academy a 11 ebooks + vista comercial Store (#/store). Nuevos micro-ebooks: IA para Ventas, IA para RRHH, IA para Finanzas, IA para Marketing (7 capítulos cada uno).

**Why**: El usuario pidió seguir potenciando el stack y hacer operativa la estrategia de venta (eBooks como lead magnets). La vista Store convierte el catálogo en un escaparate comercial con export PDF directo por producto.

**Where**:
- `apps/academy-web/data/ebooks/ia-ventas/`, `ia-rrhh/`, `ia-finanzas/`, `ia-marketing/` — 4 ebooks nuevos (7 capítulos cada uno, ~17KB)
- `apps/academy-web/data/ebooks.js` — registry regenerado (11 ebooks)
- `apps/academy-web/app.js` — vista `viewStore()` (catálogo comercial con tarjetas de producto + botones export), ruta `#/store`, i18n store (es/en/pt)
- `apps/academy-web/index.html` — nav con link "Tienda"
- `apps/academy-web/academy-layout.css` — estilos `.store-card`, `.store-actions`, `.store-grid`
- `apps/academy-web/README.md` — sección Tienda + lista de ebooks actualizada

**Learned**: (1) La vista Store carga TODO el contenido (ebooks + toolkits) con Promise.all de ensureEbookContent/ensureToolkitContent antes de renderizar — 15 productos con 15 botones de export. (2) El patrón de expansión es escalable: manifest + skeleton + subagente de contenido + regenerar registry + validar. (3) El smoke test necesita el servidor activo y timeout amplio (con 11 ebooks tarda más). (4) Estado actual: 20 cursos + 11 ebooks (83 capítulos) + 4 toolkits (250 prompts + 34 plantillas + 34 emails + 26 automatizaciones + 17 casos) + Store con export PDF.

---
*Imported from Engram on 2026-09-10*
