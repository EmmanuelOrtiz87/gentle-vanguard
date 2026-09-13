# academy-multi-course — TASKS

**Fase SDD**: TASKS. Tareas concretas con criterios de aceptación, agrupadas en 2 PRs chained (PR 3
= contenido aparte, fuera de scope de este SDD).

**Convención de IDs**: `T<PR>.<N>` donde PR = número de PR, N = número de tarea dentro del PR.

---

## PR 1 — Estructura + migración (shims legacy, sin cambio de comportamiento)

**Objetivo**: crear la estructura `data/courses/`, migrar el contenido de gentle-vanguard, agregar
shims legacy para mantener compatibilidad. NO se cambia comportamiento todavía.

**Estimación**: ~280-350 líneas (mayoría archivos movidos, no cambios). **Workload guard**: <400
líneas ✅.

### T1.1 — Crear estructura de carpetas

- **Acción**: crear `apps/academy-web/data/courses/gentle-vanguard/`.
- **Acción**: crear `apps/academy-web/data/shared/`.
- **AC**: `Get-ChildItem apps/academy-web/data/courses/gentle-vanguard/` muestra la carpeta vacía.

### T1.2 — Mover archivos de contenido (11 archivos)

- **Acción**: mover `data/content-*.js` (11 archivos) a `data/courses/gentle-vanguard/`.
- **AC**: `Get-ChildItem data/courses/gentle-vanguard/content-*.js | Measure-Object` = 11.

### T1.3 — Mover tracks.js

- **Acción**: mover `data/tracks.js` a `data/courses/gentle-vanguard/tracks.js`.
- **AC**: archivo existe en nueva ubicación, no existe en la vieja.

### T1.4 — Mover glossary.js

- **Acción**: mover `data/glossary.js` a `data/courses/gentle-vanguard/glossary.js`.
- **AC**: archivo existe en nueva ubicación.

### T1.5 — Mover demo-images.js y files.js

- **Acción**: mover `data/demo-images.js` y `data/files.js` a `data/shared/`.
- **AC**: archivos existen en `data/shared/`.

### T1.6 — Crear `course.json` para gentle-vanguard

- **Acción**: crear `data/courses/gentle-vanguard/course.json` con:

  ```json
  {
    "id": "gentle-vanguard",
    "title": "Gentle-Vanguard",
    "description": "Curso introductorio al stack de orquestación de agentes local-first: fundamentos, arquitectura, optimización, agentes, workflows, prompts y casos prácticos.",
    "language": "es",
    "level": "intermedio",
    "estimatedHours": 12,
    "tags": ["agentes", "ia", "stack", "local-first"],
    "files": {
      "tracks": "tracks.js",
      "content": [
        "content-fundamentos.js",
        "content-arquitectura.js",
        "content-optimizacion.js",
        "content-agentes.js",
        "content-workflows.js",
        "content-prompts.js",
        "content-automatizaciones.js",
        "content-laboratorio.js",
        "content-negocio.js",
        "content-casos-reales.js",
        "content-knowledge-base.js",
        "content-apps.js"
      ],
      "glossary": "glossary.js",
      "i18n": "i18n.js"
    },
    "version": "4.0.0"
  }
  ```

- **AC**: archivo parseable como JSON válido (test:
  `node -e "JSON.parse(require('fs').readFileSync('apps/academy-web/data/courses/gentle-vanguard/course.json'))"`
  exit 0).

### T1.7 — Crear `i18n.js` para gentle-vanguard

- **Acción**: extraer las keys de tracks de `app.js` I18N y crear
  `data/courses/gentle-vanguard/i18n.js`:

  ```js
  window.GV_COURSE_I18N = window.GV_COURSE_I18N || {};
  window.GV_COURSE_I18N['gentle-vanguard'] = {
    es: {
      fundamentals: 'Fundamentos',
      architecture: 'Arquitectura',
      optimization: 'Optimización',
      agents: 'Agentes',
      workflows: 'Workflows',
      prompts: 'Prompts',
      automations: 'Automatizaciones',
      laboratory: 'Laboratorio',
      business: 'Negocio',
      realCases: 'Casos reales',
      knowledgeBase: 'Knowledge Base',
      stackApps: 'Apps del stack',
    },
    en: {/* ... */},
    pt: {/* ... */},
  };
  ```

- **AC**: keys presentes para es/en/pt, mismas que en `app.js` I18N.

### T1.8 — Crear shims legacy en `data/`

- **Acción**: crear `data/tracks.js` con:

  ```js
  // LEGACY SHIM (will be removed in PR 2). See data/courses/gentle-vanguard/tracks.js.
  (function () {
    var s = document.createElement('script');
    s.src = 'data/courses/gentle-vanguard/tracks.js';
    document.head.appendChild(s);
  })();
  ```

- **Acción**: crear shims similares para `data/content-*.js` y `data/glossary.js` (12 shims).
- **AC**: cargar `#/` en el navegador NO debe romper; smoke test manual de 3 tracks + glosario.

### T1.9 — Crear `data/courses.js` registry

- **Acción**: crear `apps/academy-web/data/courses.js`:

  ```js
  // Registry de cursos. Para agregar uno nuevo, agregar entrada acá.
  window.GV_COURSES = [{ id: 'gentle-vanguard', path: 'data/courses/gentle-vanguard/' }];
  ```

- **AC**: archivo existe, parseable, accesible vía `window.GV_COURSES` después de cargarlo en
  `index.html`.

### T1.10 — Cargar `data/courses.js` en `index.html`

- **Acción**: agregar `<script src="data/courses.js"></script>` en `index.html` (antes de `app.js`).
- **AC**: smoke test manual; `window.GV_COURSES` está definido en consola.

### T1.11 — Smoke test PR 1

- **Acción**: ejecutar `npm run dev` desde `apps/academy-web/`.
- **Acción**: abrir `http://127.0.0.1:4173/` en navegador.
- **AC**:
  - ✅ La home muestra los 12 tracks de gentle-vanguard (sin cambio visible).
  - ✅ Click en un track abre su home.
  - ✅ Click en una lección abre la lección.
  - ✅ El glosario muestra los términos esperados.
  - ✅ i18n funciona.
  - ✅ Tema dark/light funciona.
  - ✅ DevTools console: 0 errores, 0 warnings nuevos.

### T1.12 — Commit

- **Acción**: commit con mensaje:

  ```
  refactor(academy-web): estructura data/courses/ + shims legacy (PR 1/2)

  - Crea data/courses/gentle-vanguard/ con manifest course.json
  - Migra 11 archivos de contenido + tracks + glossary + i18n
  - Crea data/shared/ para assets cross-curso
  - Crea data/courses.js registry
  - Mantiene shims legacy en data/ para no romper comportamiento

  Sin cambios de UX. PR 2 hará el refactor real.
  ```

---

## PR 2 — Refactor app.js para multi-curso

**Objetivo**: router consciente de "curso", selector en topbar, redirects legacy, búsqueda y
progreso scoped.

**Estimación**: ~300-400 líneas en `app.js` + ~30 líneas en `index.html`. **Workload guard**: <400
líneas ✅ (con review de las moves de PR 1 ya commiteadas).

### T2.1 — Agregar `state.courseId` y carga de curso

- **Acción**: en `app.js`, agregar al estado global:

  ```js
  const state = {
    courseId: localStorage.getItem('gv-academy-active-course') || null,
    // ...
  };
  ```

- **Acción**: implementar `loadCourse(courseId)` que:
  1. Busca en `window.GV_COURSES`.
  2. Fetch `course.json` (async).
  3. Inyecta `<script>` tags para tracks/content/glossary/i18n.
  4. Compone `window.GV_CURRENT_COURSE`.
  5. Persiste en `localStorage gv-academy-active-course`.
- **AC**: `console.log(window.GV_CURRENT_COURSE)` después de `loadCourse('gentle-vanguard')` muestra
  tracks, content, glossary, i18n.

### T2.2 — Refactor del router

- **Acción**: actualizar el parser de hash para reconocer:
  - `#/` → view='courses'
  - `#/courses` → view='courses'
  - `#/course/:cid` → view='course-home'
  - `#/course/:cid/track/:tid` → view='track'
  - `#/course/:cid/lesson/:tid/:lid` → view='lesson'
  - `#/course/:cid/glosario` → view='glossary'
  - `#/demo` → view='demo' (sin cambio)
- **AC**: navegar entre las 6 vistas funciona, sin error en consola.

### T2.3 — Implementar redirects legacy

- **Acción**: en el parser de hash, antes de procesar la vista, detectar URLs legacy y redirigir:
  - `#/track/:tid` → `location.replace('#/course/gentle-vanguard/track/' + tid)`
  - `#/lesson/:tid/:lid` → `location.replace('#/course/gentle-vanguard/lesson/' + tid + '/' + lid)`
  - `#/glosario` → `location.replace('#/course/gentle-vanguard/glosario')`
- **AC**: navegar a 5 URLs legacy redirige correctamente sin romper el botón "atrás" (verificar
  history API).

### T2.4 — Renderizar home como catálogo de cursos

- **Acción**: cuando `view='courses'`, renderizar cards de `window.GV_COURSES`.
- **Acción**: para cada curso, leer su manifest (lazy) y mostrar: id, título, descripción, número de
  tracks, horas estimadas.
- **AC**: `#/` muestra al menos 1 card (gentle-vanguard) con metadata correcta.

### T2.5 — Renderizar course home

- **Acción**: cuando `view='course-home'`, llamar `loadCourse(courseId)` y luego renderizar la lista
  de tracks del curso activo.
- **AC**: `#/course/gentle-vanguard` muestra los 12 tracks con sus lecciones contadas.

### T2.6 — Agregar selector de curso en topbar

- **Acción**: en `index.html`, agregar `<div class="gv-course-selector">` con
  `<button id="course-toggle">` y `<ul id="course-menu" hidden>`.
- **Acción**: en `app.js`, implementar `renderCourseSelector()` que:
  1. Lista los cursos de `window.GV_COURSES`.
  2. Marca el curso activo.
  3. onClick → `loadCourse(newId)` + `location.hash = '#/course/' + newId`.
- **Acción**: agregar CSS para `.gv-course-selector` en `academy-layout.css` (consistente con
  `.gv-lang-dropdown`).
- **AC**: el selector aparece en el topbar, funciona el cambio de curso, persiste entre recargas.

### T2.7 — Refactor búsqueda con scope

- **Acción**: en `app.js`, función de búsqueda, cambiar:
  - Antes: `Object.values(CONTENT).flatMap(...)` + `GLOSSARY`.
  - Después: `Object.values(window.GV_CURRENT_COURSE.content).flatMap(...)` +
    `window.GV_CURRENT_COURSE.glossary`.
- **AC**: búsqueda en gentle-vanguard solo muestra resultados de gentle-vanguard; búsqueda en IA
  solo muestra resultados de IA.

### T2.8 — Refactor progreso con scope

- **Acción**: cambiar keys localStorage:
  - Antes: `gv-academy-progress-<trackId>` (asumiendo) o similar.
  - Después: `gv-academy-progress-<courseId>-<trackId>` o `gv-academy-progress-<courseId>` (objeto
    con track completions).
- **Acción**: implementar `migrateLegacyProgress()` que migra keys legacy la primera vez.
- **AC**: marcar lección en gentle-vanguard no afecta progreso de IA; al volver a gentle-vanguard,
  el progreso se mantiene.

### T2.9 — Refactor i18n

- **Acción**: en `app.js`, función `t(key)`, primero buscar en `I18N[locale]`, luego en
  `window.GV_CURRENT_COURSE.i18n[locale]`, luego fallback a `I18N.es`.
- **Acción**: eliminar las keys de tracks de `I18N` en `app.js` (ahora viven en el manifest del
  curso).
- **AC**: cambiar locale actualiza los tracks del curso activo.

### T2.10 — Eliminar shims legacy

- **Acción**: eliminar los 12 shims creados en T1.8 (`data/tracks.js`, `data/content-*.js`,
  `data/glossary.js`).
- **AC**: `Get-ChildItem apps/academy-web/data/*.js` solo muestra `courses.js` y los de `shared/`.

### T2.11 — Bump de versión

- **Acción**: `package.json` versión 3.8.2 → 4.0.0.
- **Acción**: `STACK_VERSION` en `app.js` v3.9.0 → v4.0.0.
- **AC**: visible en la UI (footer o home).

### T2.12 — Actualizar README

- **Acción**: actualizar la descripción principal y agregar sección "Cursos disponibles".
- **AC**: el README refleja el modelo multi-curso.

### T2.13 — Smoke test PR 2 (completo)

- **Acción**: ejecutar los 12 puntos del checklist de EXPLORE.
- **AC**: todos los AC1-AC10 de SPEC.md se cumplen.
- **AC**: 0 errores, 0 warnings en DevTools console.
- **AC**: DevTools Network: total JS transferido < 200KB.

### T2.14 — Commit + push

- **Acción**: commit con mensaje:

  ```
  feat(academy-web): multi-curso con selector y manifests (PR 2/2)

  - App.js: router consciente de courseId, loadCourse(), selector, redirects legacy
  - Búsqueda y progreso con scope por curso
  - i18n de tracks movido a data/courses/<curso>/i18n.js
  - Elimina shims legacy de data/
  - Bump a v4.0.0
  - README actualizado

  Refactor SDD academy-multi-course. Chained PR de #1.
  ```

---

## PR 3 — Contenido IA Fundamentos (FUERA de scope de este SDD)

**Objetivo**: crear el primer curso nuevo "IA — Fundamentos (nivel 1)" con track semilla de 8-12
lecciones.

**Trabajo**: contenido, no del shell. Se hace aparte, después de mergeados PR 1 y PR 2.

**Track semilla propuesto** (a refinar cuando se haga):

1. Prompting esencial (anatomía, few-shot, CoT, structured output)
2. LLMs y tokens (qué es un LLM, ventana de contexto, costo)
3. Contexto y memoria (system prompt, ventana, RAG básico)
4. Alucinaciones y grounding (cómo mitigar, evaluación)
5. RAG básico (vector stores, embeddings, retrieval)
6. Agentes y tool use (function calling, agentic loops)
7. Evaluación introductoria (métricas, A/B, regression)
8. Seguridad y guardrails básicos (prompt injection, content filters)
9. Patrones de prompt (template, role, persona)
10. Costos y optimización (modelos, cache, batching)

**Estimación**: 8-12 clases, ~2-3 sesiones de trabajo de contenido.

---

## Convenciones para el worker que ejecute

- **Lenguaje**: español (consistente con el resto de academy-web).
- **Estilo de código**: vanilla JS, sin frameworks, mismo estilo que el código actual.
- **Sin mocks**: todo contenido de archivos reales.
- **DS v2**: NO tocar los CSS `-v2.css`. Si se necesita CSS nuevo, agregar a `academy-layout.css`.
- **Smoke test**: obligatorio antes de commit.
- **Reviews**: cada PR pasa por un fresh reviewer (no el mismo agent que escribió).
