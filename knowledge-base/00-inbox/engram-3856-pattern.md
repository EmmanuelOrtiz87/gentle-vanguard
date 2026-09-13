---
created: 2026-09-10 04:53:11
tags: [engram, pattern]
engram_id: 3856
type: pattern
---

# GV Academy toolkit ia-finanzas-pro content.js

**What**: Generado el contenido completo de `apps/academy-web/data/toolkits/ia-finanzas-pro/content.js` (toolkit premium "IA para Finanzas Pro"): 5 secciones — prompts (50), plantillas (8), emails (8), automatizaciones (6), casos (4). Manifest `toolkit.json` intacto.
**Why**: El esqueleto `content.js` solo tenía el comentario placeholder; se pidió reemplazarlo con contenido real completo y copiable.
**Where**: apps/academy-web/data/toolkits/ia-finanzas-pro/content.js
**Learned**: (1) Schema por sección (por app.js:3249-3255): prompts usan `{title, prompt}`; plantillas/emails/automatizaciones/casos usan `{title, body}` con `\n` escapados (JS no permite newlines reales en strings de comillas dobles). (2) El tool write/edit falla truncando payloads JSON grandes en este entorno — hay que construir el archivo por partes con markers tipo `/*__PART_X__*/` y sucesivos edits, verificando el cierre al final (quedó un `]\n};` duplicado que hubo que limpiar). (3) Verificación: `node --check` + `node -e` cargando el archivo con `global.window={}` para contar items reales (50/8/8/6/4 OK).

---
*Imported from Engram on 2026-09-12*
