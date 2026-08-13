# Service Validator

## Description

Validates all Gentle-Vanguard service dependencies.

## Commands

```bash
# Validate only
npx tsx src/tools/service-validator.ts
<!-- REF-OBSOLETA: src/tools/service-validator.ts no existe (ruta migrada o eliminada) -->

# Validate with auto-fix
npx tsx src/tools/service-validator.ts --fix
<!-- REF-OBSOLETA: src/tools/service-validator.ts no existe (ruta migrada o eliminada) -->
```

## Validations

- ✅ Node.js version (>=20)
- ✅ pnpm installed
- ✅ Dependencies present
- ✅ Ports available
- ✅ Environment variables
- ✅ Git remote configured

## Exit Codes

- 0: All validations passed
- 1: Some validations failed
