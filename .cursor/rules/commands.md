# Commands

Comandos de compilación, prueba y linting para el proyecto.

## Build

- `npm run build` (TypeScript)

## Test

- `npm test` — test suite completo
- `npm run stack:verify` — verificación rápida

## Lint / Validate

- Todos los JSONs se validan automáticamente via pre-commit hook (json-lint)
- `npm run stack:verify -- --fix` — homologación homologación

## Typecheck

- `npx tsc --noEmit` (TypeScript)
- Ver tipos después de cambios en archivos .ts

## Quality Gate completo

- `gv judgment-day` — revisión adversarial pre-merge
- `gv check` — verificación rápida del stack
