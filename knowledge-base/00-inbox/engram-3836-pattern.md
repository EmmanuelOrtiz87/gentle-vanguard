---
created: 2026-09-09 23:09:38
tags: [engram, pattern]
engram_id: 3836
type: pattern
---

# GV Academy micro-ebooks ia-ventas e ia-finanzas

**What**: Generados los contenidos completos de 2 micro-ebooks de GV Academy: ia-ventas (7 capítulos, 80 min) e ia-finanzas (7 capítulos, 79 min), reemplazando los esqueletos de content.js en apps/academy-web/data/ebooks/.
**Why**: Pedido del usuario para poblar los manifests existentes (ebook.json) sin tocar manifest/app.js/index.html.
**Where**: apps/academy-web/data/ebooks/ia-ventas/content.js y apps/academy-web/data/ebooks/ia-finanzas/content.js (ambos untracked/ignored en git).
**Learned**: El formato correcto es window.GV_EBOOK_CONTENT['<id>'] = { chapters:[{id,title,minutes,md}] } con md como JSON string con \n escapados (NO template literals). El md subset soportado por app.js renderMarkdown: ##/###, **bold**, *italic*, ==highlight==, listas, tablas con separador | :--- |, code fences ```text y blockquotes > **Analogía**:. No usar :::diagram, HTML ni imágenes. Generé los archivos con un script serializador (JSON.stringify) para evitar errores de escape; node --check pasó en ambos. Los archivos data/ebooks/*/content.js no están trackeados en git (ls-files vacío) por lo que git status del área no los muestra.

---
*Imported from Engram on 2026-09-10*
