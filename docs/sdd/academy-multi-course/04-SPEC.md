# academy-multi-course — SPEC

**Fase SDD**: SPEC. Especificación formal del refactor multi-curso de academy-web.

## Problem statement

`apps/academy-web/` es hoy un curso web estático dedicado exclusivamente a gentle-vanguard (12
tracks, 11 archivos de contenido, glosario global). El usuario necesita convertirlo en un **centro
de estudio multi-tema** donde cada tema es un curso publicable, con gentle-vanguard como un curso
más y un curso nuevo "IA — Fundamentos" como primera adición. La transformación debe mantener
compatibilidad total con URLs, i18n (es/en/pt), tema dark/light, y DS v2 Premium, sin agregar build,
dependencias, ni backends (modelo LOCAL-FIRST / ADR-0017).

## Scope

### Incluido

1. Registro de cursos (`data/courses.js`) con carga de manifests JSON.
2. Estructura `data/courses/<curso>/` con `course.json` + tracks + content + glossary + i18n.
3. Migración completa de los 12 tracks + 11 archivos de contenido + glosario de gentle-vanguard a
   `data/courses/gentle-vanguard/`.
4. Selector de curso en topbar (dropdown) con persistencia en localStorage.
5. Router actualizado: `#/course/:cid/track/:tid`, `#/course/:cid/lesson/:tid/:lid`,
   `#/course/:cid/glosario`, `#/courses` (catálogo), `#/` (home de academy = catálogo).
6. Redirects legacy desde URLs viejas (12 tracks + 1 glosario + 1 home) a URLs nuevas.
7. Búsqueda con scope por curso activo.
8. Progreso con scope por curso (migración de keys localStorage).
9. Glosario por curso (no global).
10. i18n de nombres de tracks movido al manifest de cada curso (no más en `app.js`).
11. Chained PRs (PR 1 estructura+migración, PR 2 refactor app.js, PR 3 contenido IA).

### Excluido (fuera de scope)

1. Auth, pagos, certificados, evaluaciones, matrículas (NO es un LMS).
2. Backend, sync remoto, sync entre devices.
3. Editor de contenido desde la UI.
4. Sincronización con Obsidian/Engram (compatible a futuro, no implementado).
5. Glosario global cross-curso.
6. Modo "presentador" para videollamadas.
7. Búsqueda cross-curso (queda como P2 con toggle "todos los cursos").
8. i18n de nuevos cursos más allá de es/en/pt.
9. Refactor del renderer Markdown (sigue siendo subset).
10. Cambios al DS v2 (sigue canónico, sin nuevos tokens).

## Non-goals

- **No es un LMS**: no hay calificaciones, certificados, ni matrículas. El README del repo debe
  seguir diciendo "Sitio estático; no es un LMS".
- **No es una plataforma de video/audio**: el formato sigue siendo texto + diagrama, consistente con
  el renderer actual.
- **No compite con Udemy**: no replicamos su superficie. Solo el patrón "catálogo de cursos + índice
  de lecciones + glosario".

## Functional requirements

| #   | Requerimiento                                                              | Prioridad   |
| --- | -------------------------------------------------------------------------- | ----------- |
| F1  | La home de academy-web muestra un catálogo de cursos disponibles           | MUST        |
| F2  | Click en un curso → home del curso con sus tracks                          | MUST        |
| F3  | Selector de curso en topbar permite cambiar de curso sin pasar por la home | MUST        |
| F4  | URLs modernas: `#/course/:cid/track/:tid`                                  | MUST        |
| F5  | URLs legacy redirigen a su equivalente moderno sin error                   | MUST        |
| F6  | Cada curso es autocontenido en `data/courses/<curso>/`                     | MUST        |
| F7  | El manifest `course.json` describe metadata, orden y archivos del curso    | MUST        |
| F8  | Agregar un curso nuevo no requiere modificar `app.js` ni `courses.js`      | MUST        |
| F9  | Búsqueda solo busca en el curso activo                                     | MUST        |
| F10 | Progreso (lesson completions) está scoped por curso                        | MUST        |
| F11 | Glosario del curso activo está disponible en `#/course/:cid/glosario`      | MUST        |
| F12 | i18n (es/en/pt) traduce los tracks del curso activo                        | MUST        |
| F13 | Tema dark/light funciona igual que antes                                   | MUST        |
| F14 | DS v2 Premium se mantiene sin cambios visuales                             | MUST        |
| F15 | El primer curso nuevo "ia-fundamentos" aparece en el catálogo              | MUST (PR 3) |
| F16 | "ia-fundamentos" tiene un track semilla de 8-12 lecciones                  | MUST (PR 3) |

## Non-functional requirements

| #   | Requerimiento                                                   | Target                                |
| --- | --------------------------------------------------------------- | ------------------------------------- |
| N1  | Carga inicial de academy-web                                    | < 500ms (local)                       |
| N2  | Cambio de curso (sin recargar página)                           | < 200ms                               |
| N3  | Tamaño JS total del shell                                       | < 200KB                               |
| N4  | Sin warnings de DevTools console en navegación normal           | 0                                     |
| N5  | Accesibilidad: navegación por teclado, ARIA labels, contraste   | WCAG 2.1 AA                           |
| N6  | Compatibilidad navegadores                                      | Chrome 120+, Firefox 120+, Safari 17+ |
| N7  | Sin mock data: todo contenido proviene de archivos reales       | 100%                                  |
| N8  | Sin dependencias externas (mantener shell 0-deps)               | 0                                     |
| N9  | Sin frameworks (mantener vanilla JS)                            | 0                                     |
| N10 | Auditoría de design-system del shell sigue clean (9→0 findings) | mantener                              |

## Acceptance criteria

### AC1 — Catálogo de cursos

- ✅ Al abrir `#/`, se ven cards de los cursos disponibles (mínimo 1: gentle-vanguard).
- ✅ Cada card tiene: id, título, descripción, número de tracks, duración estimada.
- ✅ Click en una card navega a `#/course/<cid>`.

### AC2 — Selector de curso

- ✅ El topbar tiene un dropdown con la lista de cursos disponibles.
- ✅ El curso activo está marcado con un check (✓).
- ✅ Cambiar de curso navega a `#/course/<nuevo-cid>` y persiste en
  `localStorage gv-academy-active-course`.

### AC3 — Navegación dentro de un curso

- ✅ `#/course/gentle-vanguard` muestra los 12 tracks.
- ✅ `#/course/gentle-vanguard/track/fundamentos` muestra la home del track.
- ✅ `#/course/gentle-vanguard/lesson/fundamentos/que-es-gentle-vanguard` muestra la lección.
- ✅ Botones prev/next funcionan entre lecciones del mismo curso.

### AC4 — Compatibilidad legacy

- ✅ `#/track/fundamentos` redirige a `#/course/gentle-vanguard/track/fundamentos`.
- ✅ `#/lesson/fundamentos/que-es-gentle-vanguard` redirige a
  `#/course/gentle-vanguard/lesson/fundamentos/que-es-gentle-vanguard`.
- ✅ `#/glosario` redirige a `#/course/gentle-vanguard/glosario`.
- ✅ Los redirects son transparentes (no rompen el botón "atrás" del navegador).
- ✅ Smoke test: navegar las 12 URLs legacy + 3 URLs nuevas sin error.

### AC5 — Búsqueda

- ✅ El input de búsqueda solo busca en el curso activo.
- ✅ Resultados muestran: track, lección, término del glosario, todos scoped al curso.
- ✅ Mensaje "sin resultados" si no hay matches.

### AC6 — Progreso por curso

- ✅ Marcar una lección como completada persiste en `localStorage gv-academy-progress-<courseId>`.
- ✅ Usuarios existentes (con keys legacy) tienen su progreso migrado la primera vez.
- ✅ El progreso NO se comparte entre cursos (un curso no afecta al otro).

### AC7 — Glosario por curso

- ✅ `#/course/gentle-vanguard/glosario` muestra el glosario de gentle-vanguard.
- ✅ Filtro vivo funciona.
- ✅ Términos del glosario están categorizados (`ia|tecnico|negocio|stack` u otros válidos para el
  curso).

### AC8 — i18n

- ✅ Selector es/en/pt funciona.
- ✅ Los tracks del curso activo se traducen correctamente.
- ✅ Las keys de UI de academy (home, search, etc.) se traducen.
- ✅ i18n de academy-web sigue en `app.js`; i18n de tracks vive en el curso.

### AC9 — DS v2 sin cambios

- ✅ `academy-tokens-v2.css`, `academy-atmosphere-v2.css`, `academy-style-v2.css`,
  `academy-components-v2.css`, `academy-layout.css`, `academy-motion.css` no se modifican.
- ✅ Auditoría impecable: 0 nuevos findings.

### AC10 — Smoke test completo

- ✅ `npm run dev` arranca sin errores.
- ✅ 12 puntos del checklist de EXPLORE se cumplen.
- ✅ No hay warnings en DevTools console.
- ✅ Performance budget se cumple (N1, N2, N3).

## BDD scenarios (resumen)

### Escenario 1: Usuario nuevo visita academy

```
Given un usuario que abre academy-web por primera vez
When carga la página
Then ve el catálogo de cursos
And puede hacer click en "Gentle-Vanguard"
And ve los 12 tracks del curso
And puede navegar lecciones
```

### Escenario 2: Usuario cambia de curso

```
Given un usuario navegando en el curso gentle-vanguard
When hace click en el selector de curso y elige "IA — Fundamentos"
Then la URL cambia a #/course/ia-fundamentos
And ve los tracks de IA
And el selector persiste su elección para la próxima sesión
```

### Escenario 3: URL legacy redirige

```
Given un usuario con un bookmark a #/track/fundamentos
When hace click en el bookmark o pega la URL
Then el navegador navega a #/course/gentle-vanguard/track/fundamentos
And ve la página de Fundamentos sin error
```

### Escenario 4: Búsqueda con scope

```
Given un usuario en el curso IA — Fundamentos
When escribe "prompting" en el buscador
Then solo ve resultados del curso IA
And no ve resultados de gentle-vanguard
```

### Escenario 5: Progreso por curso

```
Given un usuario que completó 5 lecciones de gentle-vanguard
When cambia a IA — Fundamentos
Then el progreso de IA empieza en 0
And al volver a gentle-vanguard, sus 5 lecciones siguen marcadas
```

### Escenario 6: i18n de tracks

```
Given un usuario con locale "en"
When navega a un track de gentle-vanguard
Then ve el nombre del track en inglés (no en español)
And al cambiar a locale "es", ve el nombre en español
```
