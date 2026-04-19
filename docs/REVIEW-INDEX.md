# Review Skill Index (7 Dimensiones)

## Descripción

Esta matriz define los skills y chequeos automáticos que cubren las 7 dimensiones de revisión:

1. Seguridad (Critical)
2. Calidad (High)
3. Arquitectura (Medium)
4. Testing (Medium)
5. Diseño API (Medium)
6. Documentación (Low)
7. Flujo Git (Low)

Los hooks automáticos (pre-commit, pre-push) invocan los scripts de chequeo correspondientes. Cada skill tiene reglas REJECT, REQUIRE y PREFER documentadas en su SKILL.md.

Para detalles y ejemplos de cada dimensión, ver los archivos en `skills/` y los scripts en `scripts/hooks/`.

| Trigger (patrón) | Skill | Dimensión | Severidad |
|------------------|-------|-----------|-----------|
| *                | security-skill        | Seguridad      | Critical   |
| *.js, *.ts, *.go | quality-skill         | Calidad        | High       |
| *                | architecture-skill    | Arquitectura   | Medium     |
| *                | testing-skill         | Testing        | Medium     |
| api/*, controllers/* | api-design-skill   | API            | Medium     |
| *.md, *.py, *.js | documentation-skill   | Documentación  | Low        |
| *                | gitflow-skill         | Gitflow        | Low        |

- Cada skill contiene reglas REJECT, REQUIRE, PREFER.
- Los hooks automáticos invocan los chequeos según severidad.
