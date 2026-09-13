---
created: 2026-09-09 21:19:53
tags: [engram, bugfix]
engram_id: 3827
type: bugfix
---

# Micro-ebooks GV Academy content.js generados

**What**: Reescribí los 6 content.js esqueleto de micro-ebooks de la GV Academy (`apps/academy-web/data/ebooks/`) con contenido completo, reemplazando el array `chapters` vacío.
**Why**: El usuario pidió generar el contenido de 6 ebooks: 50-prompts-emprendedores, chatgpt-docentes, ia-administracion, excel-ia, notebooklm-guia, ia-estudiantes. Sólo se tocan los content.js; ebook.json/app.js intactos.
**Where**: apps/academy-web/data/ebooks/{50-prompts-emprendedores,chatgpt-docentes,ia-administracion,excel-ia,notebooklm-guia,ia-estudiantes}/content.js
**Learned**:
- Formato: `window.GV_EBOOK_CONTENT['<id>'] = { chapters: [{id,title,minutes,md}] }` con md como JSON string de una sola línea con \n escapados (como data/courses/ia-fundamentos). Prohibido template literals.
- El renderer de app.js (renderMarkdown en línea 1892 + inline en 1800) NO procesa `*italic*` (asterisco simple se imprime literal); sí soporta `**bold**`, `==highlight==`, backticks inline (que pueden convertirse en file-chip si matchea un path conocido), code fences, tablas, listas, blockquotes y `---`. Por eso evité cursivas.
- Las comillas dobles dentro de md rompen node --check (SyntaxError Unexpected identifier). Fuga detectada en notebooklm-guia cap-6 (No "recuerda") y corregida; hay que escribir \n y escapar/evitar comillas dobles.
- Validación en PowerShell: los backticks se mangan con las comillas dobles del shell; creé helper en C:\Users\emman\AppData\Local\Temp\opencode\check-ebooks.js que valida syntax + chapters>=6 + fences balanceadas.
- ebook 50-prompts-emprendedores: cap-2..6 = 8 prompts (16 fences) y cap-7 = 10 prompts (20 fences) = 50 prompts exactos.

---
*Imported from Engram on 2026-09-09*
