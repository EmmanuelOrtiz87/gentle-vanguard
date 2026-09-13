---
created: 2026-09-09 21:43:22
tags: [engram, architecture]
engram_id: 3829
type: architecture
---

# Academy v4.1: categorías + eBooks + Toolkit

**What**: Reorganización completa de GV Academy (apps/academy-web) a v4.1.0: (1) taxonomía de categorías en los 20 cursos, (2) nueva sección eBooks con 7 ebooks, (3) nueva sección Toolkit con 1 kit completo.

**Why**: El usuario pidió encapsular el scope de los cursos con etiquetas (IA Aplicada, Software & Programación, Infraestructura/Redes/Ciberseguridad, Negocios/Productividad/Transformación Digital) y agregar eBooks + Toolkit como estrategia de venta (lead magnets para atraer personas, estudiantes y empresas — NO se promueven a cursos completos).

**Where**:
- `apps/academy-web/data/courses/*/course.json` — campo `categories` (array) en los 20 cursos
- `apps/academy-web/data/ebooks/` — 7 ebooks: 6 micro (20-40 pág) + 1 premium (manual-ia-profesionales, 120 pág, 14 capítulos)
- `apps/academy-web/data/toolkits/ia-emprendedores/` — 100 prompts + 10 plantillas + 10 emails + 8 automatizaciones + 5 casos
- `apps/academy-web/app.js` — filtros por categoría (chips), vistas viewEbooks/viewEbookHome/viewEbookChapter/viewToolkits/viewToolkit, rutas #/ebooks #/ebook/:eid #/ebook/:eid/chapter/:chid #/toolkits #/toolkit/:tid
- `apps/academy-web/scripts/build-ebooks-registry.mjs`, `build-toolkits-registry.mjs`, `validate-ebooks-toolkits.mjs` (nuevos)
- `apps/academy-web/index.html` — nav con eBooks/Toolkit, script tags de registries

**Learned**: (1) Los content.js de ebooks/toolkits NO se cargan con script tags estáticos — se inyectan dinámicamente con `injectScript()` (patrón loadCourse) vía `ensureEbookContent()`/`ensureToolkitContent()` con Set de cache. (2) El renderer de markdown NO soporta `*italic*` (se imprime literal) — usar solo **bold**, ==highlight==, backticks. (3) Los manifests embebidos en registries permiten file:// sin CORS. (4) Formato content.js: `window.GV_EBOOK_CONTENT['<id>'] = { chapters: [...] }` y `window.GV_TOOLKIT_CONTENT['<id>'] = { sections: [...] }` con items que usan `prompt` (prompts) o `body` (plantillas/emails/automatizaciones/casos).

---
*Imported from Engram on 2026-09-09*
