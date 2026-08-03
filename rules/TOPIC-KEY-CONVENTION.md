# TOPIC-KEY-CONVENTION — Convención de Claves Temáticas para Engram

**Versión:** 1.0 | **Vigente desde:** July 14, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Estandarizar las claves temáticas (topic keys) usadas en `mem_save` y `mem_suggest_topic_key` para
garantizar consistencia, trazabilidad y colisiones mínimas en el almacenamiento de memoria Engram.

## 2. Formato

```
<area>/<subject>
```

- `area`: dominio funcional en minúsculas (ej: `architecture`, `bugfix`, `config`, `security`)
- `subject`: nombre corto del tema, kebab-case (ej: `model-router`, `checkpoint-manager`)
- Sin espacios, mayúsculas, ni caracteres especiales — solo letras ASCII, números y guiones

## 3. Claves Requeridas

| Clave Temática                  | Propósito                                  |
| ------------------------------- | ------------------------------------------ |
| `architecture/auth`             | Decisiones de autenticación y autorización |
| `architecture/session-pipeline` | Diseño del pipeline de sesión              |
| `config/model-router`           | Cambios en enrutamiento de modelos         |
| `config/eval-gates`             | Thresholds y configuración de compuertas   |
| `bugfix/checkpoint-manager`     | Fallas y correcciones en checkpoint        |
| `bugfix/engram-sync`            | Problemas de sincronización de memoria     |
| `security/secrets`              | Gestión de secretos y credenciales         |
| `security/audit`                | Trazas de auditoría y cumplimiento         |
| `ops/dashboard-ws`              | WebSocket y salud del dashboard            |
| `ops/auto-heal`                 | Reglas de auto-recuperación                |
| `testing/coverage`              | Cobertura y requisitos de prueba           |
| `migration/ps1-to-ts`           | Migración de TypeScript a TypeScript       |

## 4. Validación

- Expresión regular: `/^[a-z][a-z0-9-]+\/[a-z][a-z0-9-]+$/`
- Longitud máxima: 60 caracteres
- No puede terminar con `/`
- `area` debe pertenecer a la lista aprobada (architecture, bugfix, config, security, ops, testing,
  migration, decision, discovery, pattern, learning)

## 5. Ejemplos

| Uso                       | Topic Key Correcto           | Incorrecto                  |
| ------------------------- | ---------------------------- | --------------------------- |
| Decisión de modelo        | `architecture/model-routing` | `Arquitectura/ModelRouting` |
| Bug en snapshot           | `bugfix/snapshot-manager`    | `bugs/snapshot`             |
| Config de CI/CD           | `config/ci-self-heal`        | `config/ci-self-heal.json`  |
| Descubrimiento de patrón  | `discovery/retry-backoff`    | `RETRY_BACKOFF`             |
| Migración de health-check | `migration/ps1-to-ts`        | `ps1-to-ts` (sin area)      |

## 6. Excepciones

- Claves legacy existentes se mantienen pero no se replican en nuevos saves
- Proyectos externos al ecosistema Gentle-Vanguard pueden usar su propio namespace
