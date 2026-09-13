---
created: 2026-09-09 23:27:00
tags: [engram, pattern]
engram_id: 3838
type: pattern
---

# GV Academy toolkits ia-finanzas e ia-marketing completados

**What**: Generados los contenidos completos de 2 toolkits de GV Academy en apps/academy-web/data/toolkits/: ia-finanzas y ia-marketing, reemplazando los esqueletos content.js.
**Why**: Los toolkits necesitaban sus 5 secciones (prompts/plantillas/emails/automatizaciones/casos) con 50/8/8/6/4 items respectivamente.
**Where**: apps/academy-web/data/toolkits/ia-finanzas/content.js y ia-marketing/content.js. No se tocó toolkit.json ni app.js.
**Learned**: (1) Schema consumido por app.js: sección prompts usa items con `prompt`; plantillas/emails/automatizaciones/casos usan items con `body`. (2) Nunca escribir nuevas líneas reales dentro de strings JSON `"body"` — usar SIEMPRE `\n` escapado: ocurrió un SyntaxError en node --check por un salto de línea real en una tabla de plantilla (detectado con un script que rastrea strings abiertas por línea). (3) Referencia de formato completa: data/toolkits/ia-emprendedores/content.js (las otras contienen solo esqueletos). (4) node --check es la verificación mandataria de la tarea.

---
*Imported from Engram on 2026-09-10*
