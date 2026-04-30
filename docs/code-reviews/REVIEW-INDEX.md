# Review Skill Index (7 Dimensiones)

## Descripcin

Esta matriz define los skills y chequeos automticos que cubren las 7 dimensiones de revisin:

1. Seguridad (Critical)
2. Calidad (High)
3. Arquitectura (Medium)
4. Testing (Medium)
5. Diseo API (Medium)
6. Documentacin (Low)
7. Flujo Git (Low)

Los hooks automticos (pre-commit, pre-push) invocan los scripts de chequeo correspondientes. Cada skill tiene reglas REJECT, REQUIRE y PREFER documentadas en su SKILL.md.

Para detalles y ejemplos de cada dimensin, ver los archivos en `skills/` y los scripts en `scripts/hooks/`.

| Trigger (patrn) | Skill | Dimensin | Severidad |
|------------------|-------|-----------|-----------|
| *                | security-skill        | Seguridad      | Critical   |
| *.js, *.ts, *.go | quality-skill         | Calidad        | High       |
| *                | architecture-skill    | Arquitectura   | Medium     |
| *                | testing-skill         | Testing        | Medium     |
| api/*, controllers/* | api-design-skill   | API            | Medium     |
| *.md, *.py, *.js | documentation-skill   | Documentacin  | Low        |
| *                | gitflow-skill         | Gitflow        | Low        |

- Cada skill contiene reglas REJECT, REQUIRE, PREFER.
- Los hooks automticos invocan los chequeos segn severidad.
