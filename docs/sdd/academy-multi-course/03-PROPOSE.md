# academy-multi-course — PROPOSE

**Fase SDD**: PROPOSE. Tres opciones de arquitectura con tradeoffs explícitos. Recomendación al
final.

---

## Opción A — Refactor mínimo (mover archivos, agregar selector)

**Idea**: cada curso vive en `data/courses/<curso>/{tracks.js, content-*.js, glossary.js, i18n.js}`.
Selector de curso en topbar (dropdown). URLs explícitas con redirects legacy.

**Estructura:**

```
data/
├── courses.js                        # registry plano
├── courses/
│   ├── gentle-vanguard/              # migración del contenido actual
│   │   ├── tracks.js
│   │   ├── content-fundamentos.js
│   │   ├── ... (10 más)
│   │   ├── glossary.js
│   │   └── i18n.js
│   └── ia-fundamentos/               # curso nuevo (a crear después)
│       └── ...
```

**Pros**:

- Cambio más pequeño y surgical.
- Mantiene la estructura familiar de los archivos `content-*.js`.
- Riesgo bajo de regresión en el renderer.

**Contras**:

- Si después queremos sincronizar contenido con Obsidian/Engram, hay que refactorear otra vez (no
  hay manifest que describa el curso como unidad).
- Registry plano en `courses.js` requiere editar ese archivo para agregar un curso (no es
  self-contained).
- Si el curso IA tiene su propio glosario y el usuario quiere cross-glosario, hay que agregar lógica
  nueva.

**Esfuerzo APPLY**: ~400-500 líneas, 1 sesión.

---

## Opción B — Refactor con manifests JSON (RECOMENDADA)

**Idea**: cada curso es un paquete autocontenido con un `course.json` (manifest) que describe
metadata, orden, idioma, dependencias, y dónde encontrar tracks/content/ glossary/i18n.
`data/courses.js` carga los manifests y el app.js los usa.

**Estructura:**

```
data/
├── courses.js                        # registry que importa manifests
├── courses/
│   ├── gentle-vanguard/
│   │   ├── course.json               # {id, title, desc, lang, order, ...}
│   │   ├── tracks.js                 # tracks del curso
│   │   ├── content-fundamentos.js    # lecciones
│   │   ├── ... (10 más)
│   │   ├── glossary.js
│   │   └── i18n.js
│   └── ia-fundamentos/
│       ├── course.json
│       ├── tracks.js
│       ├── content-prompting.js
│       ├── ... (8-12 lecciones)
│       ├── glossary.js
│       └── i18n.js
```

**Manifest ejemplo (`course.json`):**

```json
{
  "id": "ia-fundamentos",
  "title": "IA — Fundamentos (nivel 1)",
  "description": "Curso introductorio de IA: prompting, LLMs, contexto, RAG, agentes, evaluación.",
  "language": "es",
  "level": "introductorio",
  "order": [
    "prompting",
    "llm-tokens",
    "contexto",
    "alucinaciones",
    "rag",
    "agentes",
    "evaluacion",
    "seguridad"
  ],
  "estimatedHours": 6,
  "tags": ["ia", "llm", "rag", "agentes"],
  "files": {
    "tracks": "tracks.js",
    "content": ["content-prompting.js", "content-llm-tokens.js", "..."],
    "glossary": "glossary.js",
    "i18n": "i18n.js"
  }
}
```

**Pros**:

- Cada curso es **autocontenido y clonable**: para agregar un curso nuevo, copy-paste la carpeta y
  editar el manifest. No hay que tocar `app.js` ni `courses.js`.
- **Futuro-compatible** con sincronización Obsidian/Engram: el manifest es la unidad de intercambio.
- Registry `courses.js` solo lista IDs; los detalles están en cada manifest.
- Permite lazy-loading de cursos (cargar solo el curso activo).

**Contras**:

- Un poco más de código nuevo (loader de manifests, validador).
- Hay que validar el JSON en runtime (riesgo de typo en un manifest).

**Esfuerzo APPLY**: ~500-700 líneas, dividido en 2 PRs (ver "Plan de ejecución").

---

## Opción C — Refactor agresivo + Markdown runtime

**Idea**: cursos en archivos `.md` con frontmatter YAML, parseados en runtime por un mini-parser.
Reemplaza `content-*.js` por `*.md` con metadata.

**Estructura:**

```
data/
├── courses/
│   ├── gentle-vanguard/
│   │   ├── course.md                 # manifest en frontmatter
│   │   ├── tracks/
│   │   │   ├── fundamentos.md
│   │   │   └── arquitectura.md
│   │   ├── lessons/
│   │   │   ├── que-es-gentle-vanguard.md
│   │   │   └── ... (muchos .md)
│   │   └── glossary.md
```

**Pros**:

- Contenido editable como texto plano, fácil de escribir y versionar.
- Más cerca del flujo "ebooks" que el usuario mencionó.
- Diff-friendly en Git.

**Contras**:

- **Refactor más grande** (~1000+ líneas, riesgo de regresión alto).
- Hay que escribir un parser Markdown + loader async (fetch).
- Renderer actual soporta un subset limitado; pasarse a Markdown completo es otro proyecto.
- Perderíamos el `:::diagram id:::` como control flow declarativo (habría que reimplementar el
  lookup de diagramas).
- **No lo recomiendo** para esta iteración.

**Esfuerzo APPLY**: 2-3 sesiones, alto riesgo.

---

## Recomendación: OPCIÓN B

Justificación:

1. **Balance correcto**: complejidad adicional mínima (un loader de JSON), beneficio alto (cursos
   autocontenidos, fácil clonar para agregar más).
2. **Alineado con el stack**: el stack ya trabaja con manifests JSON para design-system, MCP
   servers, etc. Es la convención nativa.
3. **Compatible con Obsidian/Engram futuro**: el manifest es la unidad de sync.
4. **Esfuerzo acotado**: con chained PRs (regla workload guard), 2 PRs cubriendo cada uno <400
   líneas, sin regresión.
5. **Riesgo bajo**: la estructura de datos por curso es la misma que ya tenemos; solo cambia el
   nivel "curso" arriba.

---

## Plan de ejecución (Opción B, con chained PRs)

### PR 1 — Estructura + migración (~250-350 líneas)

**Objetivo**: crear la estructura `data/courses/` y mover el contenido de gentle-vanguard sin
cambiar comportamiento.

1. Crear `data/courses/gentle-vanguard/` con los archivos movidos.
2. Crear `data/courses/gentle-vanguard/course.json` con el manifest.
3. Crear `data/courses/gentle-vanguard/i18n.js` con las keys de tracks (`fundamentals`,
   `architecture`, etc.) extraídas de `app.js`.
4. Mantener `data/tracks.js` y `data/content-*.js` como **shims legacy** que re-exportan desde
   `data/courses/gentle-vanguard/` (compatibilidad con smoke test legacy).
5. `app.js` carga ambas fuentes (legacy + nuevo), sin cambiar nada del comportamiento.
6. **Verificación**: `npm run dev` + smoke test manual. No debe haber cambio visible.

### PR 2 — Refactor app.js para multi-curso (~300-400 líneas)

**Objetivo**: router y navegación conscientes de "curso", selector en topbar.

1. Refactor `app.js`: el router pasa a usar `state.courseId` además de trackId.
2. Selector de curso en topbar (`index.html` agrega dropdown).
3. Redirects legacy en el router (`#/track/:id` → `#/course/gentle-vanguard/track/:id`).
4. Búsqueda con scope por curso activo.
5. Progreso localStorage migrado a `gv-academy-progress-<courseId>`.
6. Glosario por curso (no global).
7. Eliminar shims legacy de PR 1.
8. **Verificación**: smoke test completo (12 puntos del checklist de EXPLORE).

### PR 3 — Contenido IA Fundamentos (después, aparte)

**Objetivo**: curso nuevo `ia-fundamentos` con track semilla.

1. Crear `data/courses/ia-fundamentos/` con `course.json`, `tracks.js`, contenido de 8-12 lecciones,
   glosario, i18n.
2. Verificar que aparece en el catálogo de la home.
3. Verificar navegación completa.
4. (Trabajo de contenido, no de código del shell).

### Reviewers / delegation

Cada PR con un **fresh reviewer** (regla PR rule de DELEGATION-RULES).

APPLY se delega a un `worker` con scope bounded por PR. Yo (padre) valido y commiteo.

---

## Riesgos finales del approach

| #   | Riesgo                                            | Mitigación                                                |
| --- | ------------------------------------------------- | --------------------------------------------------------- |
| 1   | Migrar 11 archivos de contenido puede perder algo | Smoke test exhaustivo por URL                             |
| 2   | localStorage key change puede borrar progreso     | Script de migración de keys en `app.js`                   |
| 3   | 12 keys de i18n acopladas al topbar               | Mover a `i18n.js` del curso, app.js compone               |
| 4   | DS v2 podría romperse si tocamos CSS              | NO tocar `academy-*-v2.css`, solo `index.html` y `app.js` |
| 5   | Workload guard (>400 líneas)                      | Chained PRs ya definidos                                  |
| 6   | Versionado de apps en el aire                     | Decidir antes de empezar APPLY                            |
| 7   | El curso IA aún no existe (contenido a crear)     | PR 1 y 2 no dependen de él; PR 3 es aparte                |
