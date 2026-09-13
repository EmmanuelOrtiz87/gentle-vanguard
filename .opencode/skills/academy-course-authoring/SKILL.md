---
name: academy-course-authoring
description: Contrato completo para crear cursos nativos de GV Academy (apps/academy-web). Use cuando se pida crear, ampliar o auditar cursos de la academia: estructura de archivos, patrones JS obligatorios, subset de markdown soportado, registro y validación. Triggers: "curso academy", "nuevo curso", "GV_TRACKS", "GV_CONTENT", "course.json", "academy course".
---

# GV Academy — Contrato de autoría de cursos

Fuente de verdad: `apps/academy-web/data/courses/<id>/`. Referencia completa de calidad:
`data/courses/ia-fundamentos/` (10 tracks, ~80 lecciones).

## 1. Estructura de archivos (por curso)

```
data/courses/<course-id>/
├── course.json          # manifest (única fuente de verdad del registro)
├── tracks.js            # window.GV_TRACKS['<course-id>'] = [{id,type,title,desc}]
├── content-<track>.js   # 1 archivo por track: window.GV_CONTENT['<track-id>'] = {lessons:[...]}
├── glossary.js          # window.GV_GLOSSARY['<course-id>'] = [{term,cat,def}]
└── i18n.js              # window.GV_COURSE_I18N['<course-id>'] = {es,en,pt} con key por track
```

## 2. course.json (manifest)

```json
{
  "id": "<course-id>",              // DEBE == nombre del directorio
  "title": "Título visible",
  "description": "2-3 líneas",
  "language": "es",
  "level": "inicial|intermedio|avanzado|de 0 a 100",
  "estimatedHours": 12,
  "tags": ["..."],
  "files": {
    "tracks": "tracks.js",
    "content": ["content-<track>.js", "..."],
    "glossary": "glossary.js",
    "i18n": "i18n.js"
  },
  "version": "1.0.0"
}
```

## 3. tracks.js

```js
window.GV_TRACKS = window.GV_TRACKS || {};
window.GV_TRACKS['<course-id>'] = [
  { "id": "<track-id>", "type": "curso", "title": "...", "desc": "1-2 líneas" }
];
```

## 4. content-<track>.js (patrón EXACTO — dos asignaciones)

```js
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT['<track-id>'] = {
  lessons: [
    {
      "id": "<lesson-id>",          // kebab-case, único dentro del track
      "title": "Título de la lección",
      "minutes": 12,                 // 8-16 típico
      "type": "curso",
      "md": "## ...markdown..."
    }
  ]
};
// CIERRE OBLIGATORIO: agrega las lecciones al agregado del curso
window.GV_CONTENT['<course-id>'] = window.GV_CONTENT['<course-id>'] || { lessons: [] };
window.GV_CONTENT['<course-id>'].lessons.push(...window.GV_CONTENT['<track-id>'].lessons);
```

## 5. Subset de markdown soportado (app.js)

- `## / ### / ####` headings; `**bold**`; `*italic*`; `==highlight==` (amarillo)
- Listas `-` y numeradas `1.`; tablas `| a | b |` con separador `| :--- |`
- Code fences ```text /```python / ```sql /```html / ```css /```javascript
- Blockquote `> **Analogía**: ...`
- Diagramas: `:::diagram <nombre>:::` — SOLO nombres existentes en el renderer
  (ver `scripts/` o app.js; si no hay diagrama para el tema, OMITIR la línea —
  un diagrama inexistente rompe el render)
- Sin HTML crudo, sin imágenes externas (offline-first)

## 6. Calidad didáctica (estándar ia-fundamentos)

- Cada lección: 1.5-4KB de md. Estructura: gancho → explicación con analogías
  → tabla/ejemplo de código → errores comunes → mini-ejercicio o checklist.
- Código ejecutable y comentado; ejemplos progresivos (simple → real).
- Español neutro; términos técnicos con traducción entre paréntesis la primera vez.
- 6-10 lecciones por track; 5-8 tracks por curso.

## 7. glossary.js

```js
window.GV_GLOSSARY = window.GV_GLOSSARY || {};
window.GV_GLOSSARY['<course-id>'] = [
  { "term": "Término", "cat": "tecnico|ia|negocio|web|datos", "def": "1-2 frases" }
];
```

20-40 términos por curso, orden alfabético.

## 8. i18n.js (3 locales OBLIGATORIOS, key por track-id)

```js
window.GV_COURSE_I18N = window.GV_COURSE_I18N || {};
window.GV_COURSE_I18N['<course-id>'] = {
  "es": { "<track-id>": "Título ES", ... },
  "en": { "<track-id>": "Title EN", ... },
  "pt": { "<track-id>": "Título PT", ... }
};
```

## 9. Registro y validación (SIEMPRE al terminar)

```bash
cd apps/academy-web
node scripts/build-courses-registry.mjs     # regenera data/courses.js
node scripts/validate-multi-course.mjs      # debe salir 0 failures
node scripts/smoke-academy.mjs              # smoke opcional
```

El validador exige: manifest embebido == course.json, todos los archivos parsean
(`node --check`), lecciones cargadas en GV_CONTENT[course-id], glosario con patrón
por-curso, i18n con 3 locales y key por cada track.

## 10. Errores comunes

- Olvidar el cierre `push(...)` en content-*.js → lecciones no aparecen.
- `manifest.id` ≠ nombre de directorio → warning del registry.
- Usar `:::diagram X:::` con X inexistente → render roto.
- i18n sin los 3 locales o sin key de algún track → FAIL del validador.
- Comillas sin escapar dentro de strings JS largos → usar template literals
  NO: el formato usa strings JSON con `\n` escapados (ver archivos de referencia).
