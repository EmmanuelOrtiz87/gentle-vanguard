---
created: 2026-09-10 05:00:45
tags: [engram, pattern]
engram_id: 3857
type: pattern
---

# GV Academy ebook manual-ia-finanzas content.js generado

**What**: Generé el contenido completo del ebook premium "Manual Práctico de IA para Finanzas" (14 capítulos, ~80KB de markdown) en apps/academy-web/data/ebooks/manual-ia-finanzas/content.js, reemplazando el esqueleto.
**Why**: Tarea de generación de contenido para GV Academy; el ebook.json manifest no se tocó.
**Where**: apps/academy-web/data/ebooks/manual-ia-finanzas/content.js
**Learned**: El patrón correcto es window.GV_EBOOK_CONTENT['<id>'] = { chapters: [{id,title,minutes,md}] }. Los strings md DEBEN ser JSON strings con \n escapados (nunca template literals). Para archivos grandes (~85KB) un Write tool directo falla por límite de tamaño: la solución robusta es escribir marcas capXX.md como archivos planos + un build script que los ensambla con JSON.stringify (escapado automático y correcto), luego node --check. Los ```text code fences dentro del md son legítimos (no son template literals JS). La escritura final usó 83.5KB de archivo y pasó node --check desde apps/academy-web.

---
*Imported from Engram on 2026-09-12*
