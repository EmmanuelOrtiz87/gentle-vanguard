---
created: 2026-09-09 22:12:33
tags: [engram, architecture]
engram_id: 3831
type: architecture
---

# Academy: export PDF solo eBooks/Toolkits

**What**: Feature de exportación a PDF en Academy (apps/academy-web) — SOLO para eBooks y Toolkits, los cursos NO exportan (decisión explícita del usuario).

**Why**: El usuario pidió poder exportar cada micro-ebook, ebook premium y toolkit a PDF para entregarlos a clientes/estudiantes/empresas (estrategia de venta). Los cursos quedan excluidos de exportación.

**Where**:
- `apps/academy-web/app.js` — funciones `exportEbookPdf(eid)`, `exportToolkitPdf(tid)`, `ensurePrintRoot()`, `pdfCoverHtml()`, expuestas como `window.gvExportEbook`/`gvExportToolkit`; botones en viewEbookHome, viewEbookChapter (`.pdf-export-bar`) y viewToolkit
- `apps/academy-web/academy-print.css` — CSS de impresión dedicado (NUEVO): `@page A4`, `body.printing > *:not(#pdf-export-root)` oculta el shell, portada a página completa con marca GV, `page-break-before: always` entre capítulos, estilos para tablas/code/blockquotes/items
- `apps/academy-web/index.html` — link al CSS de impresión
- i18n: claves `exportPdf`, `exportPdfHint`, `pdfCover`, `pdfPages`, `pdfChapters`, `pdfSection`, `pdfItem` en es/en/pt

**Learned**: (1) El patrón es `window.print()` con un contenedor oculto `#pdf-export-root` poblado dinámicamente + clase `body.printing` + `@media print` CSS — 100% local-first sin dependencias. (2) `window.addEventListener('afterprint')` limpia la clase. (3) Para testear el flujo con Chrome headless: `--print-to-pdf` NO dispara el clic del botón — hay que simular el flujo (navegar al ebook → esperar carga async → llamar gvExportEbook) en una página de test con el shell completo de index.html (app.js falla si faltan elementos del topbar). (4) El PDF del ebook notebooklm-guia genera 13 páginas (portada + 6 capítulos); el toolkit genera 38 páginas. (5) GOTCHA: al iniciar python http.server con Start-Process, el workdir debe ser apps/academy-web o sirve directory listing en vez de index.html.

---
*Imported from Engram on 2026-09-09*
