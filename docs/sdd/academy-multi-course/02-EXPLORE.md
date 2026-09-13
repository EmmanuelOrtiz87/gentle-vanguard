# academy-multi-course — EXPLORE

**Fase SDD**: EXPLORE. Entender el problema, mapear el sistema actual, identificar restricciones.

## Necesidad del usuario

1. Hoy `apps/academy-web/` es un curso web SOLO de gentle-vanguard.
2. El usuario quiere convertirlo en un **centro de estudio multi-tema** tipo Udemy, donde cada
   "tema" es un curso publicable.
3. **Gentle-Vanguard debe ser uno de los cursos** (manteniendo el contenido actual intacto y las
   URLs compatibles).
4. El **primer curso nuevo** es "IA — Fundamentos (nivel 1)": track semilla de 8-12 clases con
   texto + diagramas (sin video/audio, alineado con el formato actual).
5. **Referencia funcional**: Udemy (catálogo de cursos, índice de lecciones, glosario). NO se
   replican features de LMS (auth, certificados, pagos, evaluaciones).

## Modelo de datos actual (acoplamiento a gentle-vanguard)

| Aspecto      | Estado actual                                            | Acoplamiento                      |
| ------------ | -------------------------------------------------------- | --------------------------------- |
| Tracks       | `window.GV_TRACKS` plano, 12 entries                     | IDs y titles hardcoded gentle-vg  |
| Contenido    | `window.GV_CONTENT[trackId]`, 11 archivos `content-*.js` | Track IDs y lesson IDs acoplados  |
| Glosario     | `window.GV_GLOSSARY` plano, ~600 líneas                  | Términos 100% del stack gentle-vg |
| i18n         | `I18N.es/en/pt` en `app.js`                              | Keys de tracks dentro del I18N    |
| Topbar       | 12 `<a href="#/track/...">` hardcoded en `index.html`    | Lista de tracks acoplada al HTML  |
| Home         | Renderiza cards de tracks desde `GV_TRACKS`              | Sin selector de curso             |
| Router       | `#/track/:id`, `#/lesson/:track/:lesson`, `#/glosario`   | Sin nivel "curso" en la URL       |
| Búsqueda     | Global sobre todos los tracks + glosario                 | Sin scope por curso               |
| Progreso     | localStorage por track (lesson completions)              | Sin scope por curso               |
| Demo / Files | `window.GV_DEMO_IMAGES`, `window.GV_FILES`               | Compartidos, no asociados a curso |

## Restricciones

1. **Sin build, sin dependencias**: el shell debe seguir siendo HTML/JS/CSS plano servido por
   `python -m http.server`. NO agregar frameworks.
2. **DS v2 Premium**: mantener el sistema visual canónico. No introducir nuevos tokens ni colores.
3. **LOCAL-FIRST**: nada de auth, sync remoto, ni llamadas a backend. localStorage OK.
4. **Compatibilidad URLs**: las URLs actuales (`#/track/fundamentos`,
   `#/lesson/fundamentos/que-es-gentle-vanguard`, `#/glosario`) deben seguir funcionando vía
   redirect (no romper bookmarks, ni links en docs, ni links externos en redes/docs existentes).
5. **i18n**: 3 locales deben seguir funcionando (es/en/pt). Las keys de tracks actuales se
   mantienen, las nuevas se agregan al manifest de cada curso.
6. **Sin sobre-ingeniería**: el refactor debe ser el mínimo necesario para soportar multi-curso +
   agregar el curso IA. No construir un LMS.
7. **Workload guard**: >400 líneas de cambios → chained PRs (regla DELEGATION-RULES).

## Riesgos identificados

| #   | Riesgo                                                     | Mitigación                                                 |
| --- | ---------------------------------------------------------- | ---------------------------------------------------------- |
| 1   | i18n acoplado al topbar (12 keys de tracks)                | Mover keys de tracks al manifest del curso; app.js compone |
| 2   | Búsqueda global podría dar resultados cross-curso confusos | Scope por curso activo, toggle "todos los cursos" opcional |
| 3   | Glosario global tiene ~600 líneas acopladas a gentle-vg    | Glosario por curso + glosario global opcional más adelante |
| 4   | Progreso localStorage no tiene scope por curso             | Migrar key a `gv-academy-progress-<cursoId>`               |
| 5   | Versionado de apps en el aire (sub-repos vs monorepo)      | Decidir antes de APPLY (afecta cómo se commitea)           |
| 6   | HTML/JS monolítico (1500+ líneas en app.js)                | Refactor en chained PRs, sin reescritura total             |
| 7   | DS v2 ya auditado y limpio (9→0 findings)                  | NO tocar academy-layout.css, academy-*-v2.css, etc.        |
| 8   | Contenido actual valioso, no se debe perder                | Smoke test manual con cada PR + checklist de URLs          |

## Dependencias con otros sistemas

- **Obsidian/Engram**: el contenido del curso IA podría originarse en el vault del usuario. El
  refactor debe ser compatible con sincronización futura (estructura `data/courses/<curso>/...` ya
  es apta para sync vía `engram-data`).
- **Graphify/CodeGraph**: academy-web no está en el grafo (vanilla). No requiere re-indexado.
- **Watchtower**: academy-web aparece en 96 checks. El refactor no debe romper los checks existentes
  (probable: start.sh, stop.sh, package.json).
- **Design Hub**: no relacionado. El DS v2 está canónico.
- **Command Center**: academy-web aparece en `apps/command-center` como una app on-demand. Su API/UI
  no cambia (sigue arrancando con `npm run dev` en :4173).

## Alcance del refactor (mínimo viable)

**Incluido**:

- Selector de curso en header (dropdown).
- Registry de cursos (`data/courses.js`).
- Estructura `data/courses/<curso>/` con manifest + tracks + content + glossary + i18n.
- Router actualizado: `#/course/:cid/track/:tid`, `#/course/:cid/lesson/:tid/:lid`.
- Redirects legacy (`#/track/:id` → `#/course/gentle-vanguard/track/:id`).
- Búsqueda con scope por curso activo.
- Progreso con scope por curso.
- Migración de los 12 tracks + 11 archivos de contenido + glosario completo a
  `data/courses/gentle-vanguard/`.
- Curso nuevo `data/courses/ia-fundamentos/` con track semilla (a crear en fase posterior, contenido
  aparte).

**Excluido** (queda para futuras iteraciones):

- Backend, auth, pagos, certificados, evaluaciones.
- Editor de contenido desde la UI.
- Sincronización con Obsidian/Engram (compatible a futuro, no implementado).
- Glosario global cross-curso.
- Progreso sync entre devices.
- Modo "presentador" para videollamadas (se puede hacer manualmente abriendo la lección, sin feature
  nueva).

## Compatibilidad URLs — matriz de redirects

| URL legacy                       | URL nueva                                               |
| -------------------------------- | ------------------------------------------------------- |
| `#/`                             | `#/` (sin cambio, ahora muestra catálogo de cursos)     |
| `#/track/fundamentos`            | `#/course/gentle-vanguard/track/fundamentos`            |
| `#/track/arquitectura`           | `#/course/gentle-vanguard/track/arquitectura`           |
| `#/lesson/fundamentos/que-es-gv` | `#/course/gentle-vanguard/lesson/fundamentos/que-es-gv` |
| `#/glosario`                     | `#/course/gentle-vanguard/glosario`                     |
| `#/demo`                         | `#/demo` (sin cambio, sigue siendo global)              |

## Smoke test post-APPLY (checklist)

1. `npm run dev` arranca sin errores.
2. Home muestra catálogo de cursos (cards).
3. Click en "Gentle-Vanguard" → home del curso con sus 12 tracks.
4. Click en "IA — Fundamentos" → home del curso con sus tracks (cuando exista).
5. Navegación prev/next funciona dentro de cada curso.
6. Búsqueda solo busca en el curso activo.
7. Glosario de gentle-vanguard muestra los términos esperados.
8. i18n funciona (selector es/en/pt, traducciones de tracks del curso activo).
9. Tema dark/light funciona.
10. URLs legacy redirigen correctamente (testear al menos 5 URLs).
11. localStorage de progreso no se rompe para usuarios existentes (migración de keys).
12. Profiler de DevTools no muestra errores ni warnings.
