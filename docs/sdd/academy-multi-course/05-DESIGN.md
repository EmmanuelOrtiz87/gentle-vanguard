# academy-multi-course — DESIGN

**Fase SDD**: DESIGN. Diseño técnico de implementación, contratos, file tree final.

## File tree final

```
apps/academy-web/
├── index.html                         # MODIFICADO: agrega <script src="data/courses.js">
│                                      # y dropdown de selector de curso en topbar
├── app.js                             # MODIFICADO: carga manifests, router con courseId,
│                                      # selector, redirects legacy, búsqueda scoped,
│                                      # progreso por curso
├── academy-style-v2.css               # SIN CAMBIOS (DS v2 canónico)
├── academy-tokens-v2.css              # SIN CAMBIOS
├── academy-atmosphere-v2.css          # SIN CAMBIOS
├── academy-components-v2.css          # SIN CAMBIOS
├── academy-layout.css                 # SIN CAMBIOS (excepto si selector requiere CSS;
│                                      # en tal caso, agregar regla aquí, no en -v2.css)
├── academy-motion.css                 # SIN CAMBIOS
├── assets/                            # SIN CAMBIOS
│   ├── logo.svg
│   ├── logo-icon.svg
│   ├── logo-mono-light.svg
│   └── logo-mono-dark.svg
├── data/                              # MODIFICADO
│   ├── courses.js                     # NUEVO: registry que importa manifests
│   ├── courses/                       # NUEVO
│   │   ├── gentle-vanguard/           # NUEVO (migración del contenido actual)
│   │   │   ├── course.json            # NUEVO: manifest
│   │   │   ├── tracks.js              # MOVIDO desde data/tracks.js
│   │   │   ├── content-fundamentos.js # MOVIDO desde data/
│   │   │   ├── content-arquitectura.js# MOVIDO
│   │   │   ├── content-optimizacion.js# MOVIDO
│   │   │   ├── content-agentes.js     # MOVIDO
│   │   │   ├── content-workflows.js   # MOVIDO
│   │   │   ├── content-prompts.js     # MOVIDO
│   │   │   ├── content-automatizaciones.js # MOVIDO
│   │   │   ├── content-laboratorio.js # MOVIDO
│   │   │   ├── content-negocio.js     # MOVIDO
│   │   │   ├── content-casos-reales.js# MOVIDO
│   │   │   ├── content-knowledge-base.js # MOVIDO
│   │   │   ├── content-apps.js        # MOVIDO
│   │   │   ├── glossary.js            # MOVIDO
│   │   │   └── i18n.js                # NUEVO: {es: {fundamentals: '...'}, en: {...}, pt: {...}}
│   │   └── ia-fundamentos/            # NUEVO (PR 3, contenido aparte)
│   │       ├── course.json
│   │       ├── tracks.js
│   │       ├── content-prompting.js
│   │       ├── content-llm-tokens.js
│   │       ├── ... (8-12 lecciones)
│   │       ├── glossary.js
│   │       └── i18n.js
│   ├── shared/                        # NUEVO (opcional, assets cross-curso)
│   │   └── demo-images.js             # MOVIDO desde data/demo-images.js
│   └── files.js                       # MOVIDO a shared/ (decidir en PR 1)
├── package.json                       # MODIFICADO: bump 3.8.2 → 4.0.0
├── README.md                          # MODIFICADO: actualizar descripción
├── start.sh / stop.sh                 # SIN CAMBIOS
└── scripts/                           # SIN CAMBIOS
```

## Contratos

### `course.json` schema

```json
{
  "id": "string (slug único, kebab-case)",
  "title": "string (título en idioma por defecto del curso)",
  "description": "string (descripción corta, 1-2 oraciones)",
  "language": "string (idioma por defecto: 'es' | 'en' | 'pt')",
  "level": "string ('introductorio' | 'intermedio' | 'avanzado')",
  "order": "string[] (orden de tracks, opcional, default = orden de tracks.js)",
  "estimatedHours": "number (estimado total del curso)",
  "tags": "string[] (tags para búsqueda/filtro futuro)",
  "files": {
    "tracks": "string (path relativo, default 'tracks.js')",
    "content": "string[] (paths relativos, default auto-detect)",
    "glossary": "string (path relativo, default 'glossary.js')",
    "i18n": "string (path relativo, default 'i18n.js')"
  },
  "version": "string (semver del contenido del curso, default '1.0.0')"
}
```

### `data/courses.js` registry

```js
// Registry: lista de cursos disponibles.
// Para agregar un curso nuevo, agregar una entrada acá.
// El orden es el orden de aparición en el catálogo (home).
window.GV_COURSES = [
  { id: 'gentle-vanguard', path: 'data/courses/gentle-vanguard/' },
  { id: 'ia-fundamentos',   path: 'data/courses/ia-fundamentos/' }
];
```

### `data/courses/<curso>/i18n.js`

```js
// i18n específico del curso (nombres de tracks).
// Estructura: { es: { <trackId>: '<título en español>' }, en: {...}, pt: {...} }
// Las keys de UI globales de academy (home, search, etc.) siguen en app.js.
window.GV_COURSE_I18N = window.GV_COURSE_I18N || {};
window.GV_COURSE_I18N['gentle-vanguard'] = {
  es: { fundamentos: 'Fundamentos', /* ... */ },
  en: { fundamentos: 'Fundamentals', /* ... */ },
  pt: { fundamentos: 'Fundamentos', /* ... */ }
};
```

### Carga dinámica de curso

```js
// app.js, función loadCourse(courseId):
// 1. Lee manifest desde <path>/course.json (vía fetch en http://, vía XHR en file://).
// 2. Carga tracks.js, content-*.js, glossary.js, i18n.js (vía <script> tags inyectados).
// 3. Compone en window.GV_CURRENT_COURSE = { manifest, tracks, content, glossary, i18n }.
// 4. Re-renderiza la vista activa.
```

## Cambios en `app.js`

### Estado global (agregar)

```js
const state = {
  courseId: localStorage.getItem('gv-academy-active-course') || null,
  trackId: null,
  lessonId: null,
  view: 'home' | 'course-home' | 'track' | 'lesson' | 'glossary' | 'courses' | 'demo',
  // ...
};
```

### Router (refactor)

```js
// Antes:
// #/ → home (catálogo de tracks)
// #/track/:tid → track home
// #/lesson/:tid/:lid → lesson
// #/glosario → glossary

// Después:
// #/ → courses (catálogo de cursos) — antes era home de gentle-vanguard
// #/courses → courses (alias de #/)
// #/course/:cid → course home (catálogo de tracks del curso)
// #/course/:cid/track/:tid → track home
// #/course/:cid/lesson/:tid/:lid → lesson
// #/course/:cid/glosario → glossary del curso
// #/demo → demo (sin cambio)

// Redirects legacy (parser):
// #/track/:tid → #/course/gentle-vanguard/track/:tid
// #/lesson/:tid/:lid → #/course/gentle-vanguard/lesson/:tid/:lid
// #/glosario → #/course/gentle-vanguard/glosario
```

### Carga de curso (nueva)

```js
async function loadCourse(courseId) {
  // 1. Buscar el curso en window.GV_COURSES.
  // 2. Verificar si ya está cargado (cache).
  // 3. Si no, fetch el manifest.
  // 4. Inyectar <script> tags para tracks/content/glossary/i18n.
  // 5. Esperar a que se ejecuten (Promise + script.onload).
  // 6. Componer window.GV_CURRENT_COURSE.
  // 7. Re-renderizar.
}
```

### Selector de curso (nueva)

```js
function renderCourseSelector() {
  // Renderiza un <select> o dropdown en el topbar.
  // Lista los cursos de window.GV_COURSES.
  // Marca el curso activo.
  // onChange → loadCourse(newId) + navigate to #/course/<newId>.
}
```

### Búsqueda (refactor)

```js
// Antes: busca en CONTENT (todos los tracks) + GLOSSARY (global).
// Después: busca en window.GV_CURRENT_COURSE.content + window.GV_CURRENT_COURSE.glossary.
```

### Progreso (refactor)

```js
// Antes: localStorage keys 'gv-academy-progress' (o similar).
// Después: localStorage key 'gv-academy-progress-<courseId>'.
// Migración: si existe la key legacy, copiar a la nueva del curso gentle-vanguard.
```

## Cambios en `index.html`

```html
<!-- Agregar en el <head> o antes de </body>: -->
<script src="data/courses.js"></script>

<!-- Agregar en el topbar (después de .brand): -->
<div class="gv-course-selector">
  <button id="course-toggle" aria-haspopup="listbox">Curso actual</button>
  <ul id="course-menu" role="listbox" hidden>
    <!-- dinámico, renderizado por app.js -->
  </ul>
</div>
```

## Cambios en CSS (si son necesarios)

Si el selector de curso requiere estilos nuevos, agregarlos en `academy-layout.css`
(NO en los CSS `-v2.css` por el waiver brand y porque el DS v2 es canónico).

```css
/* En academy-layout.css, agregar al final: */
.gv-course-selector {
  /* diseño consistente con .gv-lang-dropdown existente */
}
```

## Cambios en `package.json`

```diff
- "version": "3.8.2"
+ "version": "4.0.0"
```

## Cambios en `README.md`

Actualizar la descripción para reflejar el modelo multi-curso:
- "Academia local-first multi-curso" en lugar de "el curso web local-first para
  aprender Gentle-Vanguard".
- Agregar sección "Cursos disponibles" con tabla de cursos actuales.
- Mantener las advertencias de "no es un LMS".

## Diagrama de flujo de carga

```
┌─────────────┐
│   Browser   │
│ carga #/    │
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│ app.js init          │
│  ├─ lee gv-cc-lang   │
│  ├─ lee gv-cc-theme  │
│  └─ lee gv-academy-  │
│     active-course    │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Carga courses.js     │
│ → window.GV_COURSES  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────┐
│ Router parsea hash       │
│ #/ → view = 'courses'    │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Renderiza catálogo de    │
│ cursos (cards)           │
└──────┬───────────────────┘
       │
       ▼ usuario click "Gentle-Vanguard"
       │
       ▼
┌──────────────────────────┐
│ navigate #/course/gv     │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ loadCourse('gv')         │
│  ├─ fetch course.json    │
│  ├─ inject <script> tags │
│  ├─ compose GV_CURRENT_* │
│  └─ state.courseId = 'gv'│
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Renderiza course home    │
│ (catálogo de tracks)     │
└──────────────────────────┘
```

## Migración de localStorage

```js
// app.js, al iniciar (idempotente):
function migrateLegacyProgress() {
  const LEGACY_KEYS = ['gv-academy-progress', 'gv-academy-completed'];
  for (const oldKey of LEGACY_KEYS) {
    const data = localStorage.getItem(oldKey);
    if (data) {
      const newKey = 'gv-academy-progress-gentle-vanguard';
      if (!localStorage.getItem(newKey)) {
        localStorage.setItem(newKey, data);
      }
      localStorage.removeItem(oldKey); // opcional: limpiar legacy
    }
  }
}
```

## Decisiones de diseño (rationale)

| Decisión                                              | Rationale                                                |
| ----------------------------------------------------- | --------------------------------------------------------- |
| `data/courses.js` lista plana, no auto-discovery      | Simple, predecible, sin race conditions                    |
| `course.json` con `files` apunta a paths              | Permite reorganizar archivos sin tocar el manifest        |
| `i18n.js` por curso (no por track)                    | Reduce fragmentación, un objeto por curso                 |
| Carga de curso vía `<script>` injection               | Sin fetch async para cada archivo, simple, file:// OK     |
| `courseId` en URL explícito                           | Evita ambigüedad si dos cursos tuvieran un track con mismo id |
| Redirects silent en router (no mostrar mensaje)       | UX limpio, no rompe botón "atrás"                         |
| Glosario por curso (no global)                        | Coherente con el scope de curso                            |
| Selector en topbar (no en home)                       | Acceso rápido sin pasar por la home                       |
| `localStorage gv-academy-active-course`               | Consistente con convenciones del stack (`gv-*`)           |
| Migración idempotente de localStorage                 | Usuarios existentes no pierden progreso                   |

## Compatibilidad con Obsidian/Engram (futuro)

El manifest `course.json` ya es la unidad de intercambio. Cuando se implemente sync:
1. Cada curso se sincroniza como una carpeta.
2. El manifest se actualiza con metadata de sync (lastSyncedAt, etc.).
3. El contenido (`content-*.js`) se puede regenerar desde notas de Obsidian.

No requiere refactor del shell.

## Workload guard

Cada PR se mantiene <400 líneas:
- **PR 1** (estructura + migración): ~280-350 líneas (mayoría son archivos movidos
  sin cambios, no cuentan como "changed lines" en el diff estadístico).
- **PR 2** (refactor app.js): ~300-400 líneas (cambios en app.js + index.html).
- **PR 3** (contenido IA): trabajo de contenido, no del shell (sin límite estricto).

Total del shell refactor: <800 líneas divididas en 2 PRs.
