---
created: 2026-09-09 23:53:15
tags: [engram, architecture]
engram_id: 3841
type: architecture
---

# Academy: vista de paquete + export PDF combinado

**What**: Vista de paquete dedicada (#/paquete/:id) con export PDF combinado en Academy. Cada paquete (derivado de toolkit.links) muestra sus 3 componentes (curso + ebook + toolkit) con links y export individual, más un botón "Exportar paquete PDF" que genera un PDF combinado (portada + índice + capítulos del ebook + secciones del toolkit).

**Why**: El usuario pidió conectar y potenciar el stack. Los paquetes por audiencia ya existían como cards en la Store; ahora tienen vista dedicada y entregable PDF combinado — completa el embudo de venta.

**Where**:
- `apps/academy-web/app.js` — `viewPaquete(tid)` (hero con portada, 3 componentes con links/export individual, stats), `exportPaquetePdf(tid)` (portada + índice + ebookHtml + tkHtml en print root), ruta `#/paquete/:tid`, `window.gvExportPaquete`, Store cards enlazan a la vista de paquete
- `apps/academy-web/academy-layout.css` — estilos `.paquete-comps-list`, `.paquete-comp`, `.paquete-comp-icon`, `.paquete-comp-title`
- i18n: `paqueteView`, `paqueteComponents`, `exportPaquete`, `paqueteExportHint`, `paqueteIndex`, `backToPaquetes` (es/en/pt)
- `apps/academy-web/README.md` — sección Tienda ampliada

**Learned**: (1) El PDF combinado de paquete genera 64 páginas para ia-emprendedores (portada + índice + ebook 50-prompts + toolkit 100 prompts/plantillas/emails/automatizaciones/casos). (2) viewPaquete hace await de ensureToolkitContent + ensureEbookContent (del ebook linkeado) antes de renderizar. (3) Los paquetes se derivan de los toolkits — la vista y el export funcionan automáticamente para cualquier toolkit nuevo. (4) Estado: 20 cursos + 11 ebooks + 8 toolkits + 8 paquetes con vista dedicada y export combinado.

---
*Imported from Engram on 2026-09-10*
