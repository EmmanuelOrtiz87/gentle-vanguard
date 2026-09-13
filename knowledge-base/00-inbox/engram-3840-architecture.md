---
created: 2026-09-09 23:44:56
tags: [engram, architecture]
engram_id: 3840
type: architecture
---

# Academy: paquetes por audiencia + tracking exports + portada en PDF

**What**: Academy Store mejorada: paquetes por audiencia (derivados automáticamente de los toolkits), tracking de exportaciones en localStorage, y portada SVG incluida en los PDFs exportados.

**Why**: El usuario pidió conectar y potenciar el stack. Los paquetes hacen la Store un embudo de venta real; el tracking da visibilidad de qué productos se exportan; la portada en el PDF mejora la calidad del entregable.

**Where**:
- `apps/academy-web/app.js` — `recordExport()`/`exportStats()` (localStorage key `gv-academy-exports`, máx 200 eventos), `pdfCoverHtml()` acepta coverSrc, viewStore muestra paquetes (derivados de toolkit.links.course/ebook) + stats de exportación
- `apps/academy-web/academy-layout.css` — estilos `.paquete-card`, `.paquete-comps`, `.paquete-sep`, `.store-stats`
- `apps/academy-web/academy-print.css` — `.pdf-cover-img` (64mm, aspect 3/4) en la portada del PDF
- i18n: `paquetes`, `paqueteIncludes`, `exportsTracked`, `mostExported`, `planPrefix` (es/en/pt)
- `apps/academy-web/README.md` — sección Tienda ampliada

**Learned**: (1) Los paquetes se derivan de los toolkits (cada toolkit ya tiene links a curso+ebook) — cero datos duplicados, escalable automáticamente. (2) El tracking es best-effort con try/catch (localStorage puede no estar disponible). (3) El PDF con portada SVG genera 15 páginas para ia-ventas (portada + 7 capítulos). (4) Estado: 20 cursos + 11 ebooks + 8 toolkits + Store con 8 paquetes + 19 productos con portadas y export PDF.

---
*Imported from Engram on 2026-09-10*
