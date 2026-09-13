# academy-multi-course — SDD case

Spec-Driven Development para convertir `apps/academy-web/` en un centro de estudio multi-curso, con
gentle-vanguard como uno de los cursos y "IA — Fundamentos" como primer curso nuevo.

## Fases

| #   | Fase    | Estado        | Archivo                        |
| --- | ------- | ------------- | ------------------------------ |
| 1   | INIT    | ✅ completada | [01-INIT.md](01-INIT.md)       |
| 2   | EXPLORE | ✅ completada | [02-EXPLORE.md](02-EXPLORE.md) |
| 3   | PROPOSE | ✅ completada | [03-PROPOSE.md](03-PROPOSE.md) |
| 4   | SPEC    | ⏳ pendiente  | [04-SPEC.md](04-SPEC.md)       |
| 5   | DESIGN  | ⏳ pendiente  | [05-DESIGN.md](05-DESIGN.md)   |
| 6   | TASKS   | ⏳ pendiente  | [06-TASKS.md](06-TASKS.md)     |
| 7   | APPLY   | ⏳ pendiente  | (chained PRs)                  |
| 8   | VERIFY  | ⏳ pendiente  | (fresh reviewer)               |
| 9   | ARCHIVE | ⏳ pendiente  | (al cierre)                    |

## Decisiones a tomar antes de APPLY

1. **Versión final**: bumpear `package.json` de v3.8.2 → v4.0.0 (breaking change de URLs sin
   redirect).
2. **Versionado de apps**: sub-repos por app / monorepo full / working tree (decisión del usuario,
   no bloqueante para SDD, sí para commits).
3. **Estrategia de redirects legacy**: silent redirect en router vs. mostrar mensaje "esta URL fue
   movida" la primera vez. Recomiendo silent.
4. **Búsqueda cross-curso**: incluir toggle "buscar en todos los cursos" en PR 2 o dejarlo para P2.
5. **i18n keys de UI nuevos** (no de tracks): "selectCourse", "courses", "allCourses", etc. Decidir
   nombres antes de SPEC.

## Resumen ejecutivo

- **Hoy**: `apps/academy-web/` es un curso web SOLO de gentle-vanguard (12 tracks, 11 archivos de
  contenido, glosario global, i18n acoplado).
- **Mañana**: `apps/academy-web/` es un **catálogo de cursos publicables**. Cada curso = carpeta
  autocontenida con manifest. URLs cambian a `#/course/<cid>/track/<tid>` con redirects legacy.
- **Primer curso nuevo**: "IA — Fundamentos" con track semilla de 8-12 lecciones (contenido se
  trabaja aparte, en PR 3).
- **Approach recomendado**: Opción B (manifests JSON), chained PRs.
