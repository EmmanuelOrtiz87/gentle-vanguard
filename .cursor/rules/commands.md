# Commands

Comandos de compilación, prueba y linting para el proyecto.

## Build

- `npm run build` (TypeScript)
- `cd adapters/mcp-bridge && npm run build` (MCP Bridge)

## Test

- `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validation/run-tests.ps1` — test suite
  completo
- `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1` — verificación
  rápida

## Lint / Validate

- Todos los JSONs se validan automáticamente via pre-commit hook (json-lint)
- `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validation/homologate-workspace.ps1` —
  homologación

## Typecheck

- `npx tsc --noEmit` (TypeScript)
- Ver tipos después de cambios en archivos .ts

## Quality Gate completo

- `gv judgment-day` — revisión adversarial pre-merge
- `gv verify` — verificación rápida del stack
