---
created: 2026-09-10 03:28:23
tags: [engram, architecture]
engram_id: 3844
type: architecture
---

# Academy: Store rediseñada (combos + destacados, sin repetición)

**What**: Rediseño de la Store de Academy: dejó de replicar la biblioteca completa (19 productos) y ahora muestra SOLO combos (8 paquetes) + destacados (6 productos curados con flag `featured: true`). La biblioteca completa vive en #/ebooks y #/toolkits.

**Why**: El usuario cuestionó la repetición: "¿tiene sentido tener distribuido en pantallas individuales ebook y toolkit y que en tienda se replique todo?" — correcto, la Store debe ser un escaparate comercial (lo mejor), no el stock completo.

**Where**:
- `apps/academy-web/data/ebooks/{manual-ia-profesionales,50-prompts-emprendedores,excel-ia,ia-marketing}/ebook.json` — `featured: true`
- `apps/academy-web/data/toolkits/{ia-emprendedores,ia-profesionales}/toolkit.json` — `featured: true`
- `apps/academy-web/data/ebooks.js` + `data/toolkits.js` — registries regenerados
- `apps/academy-web/app.js` — viewStore reescrito: hero stats (paquetes/destacados/productos totales), sección Paquetes (8 combos), sección Destacados (6 featured), links a biblioteca (#/ebooks, #/toolkits). i18n: `storeFeatured`, `storeFeaturedSub` (es/en/pt)
- `apps/academy-web/README.md` — sección Tienda actualizada

**Learned**: (1) La arquitectura correcta: Store = escaparate comercial (combos + destacados curados), eBooks/Toolkits = biblioteca completa. Sin repetición. (2) El flag `featured: true` en manifests es la forma stack-native de curar productos — escalable y configurable por producto. (3) Verificado: 8 paquete-cards + 6 store-cards (featured), NotebookLM (no featured) ya NO aparece en la Store. (4) Estado: 20 cursos + 11 ebooks + 8 toolkits + Store con 8 combos + 6 destacados.

---
*Imported from Engram on 2026-09-10*
