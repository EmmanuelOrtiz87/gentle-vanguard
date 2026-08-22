---
name: validate-stack
description:
  Validate the full Gentle-Vanguard stack. Run verification steps for TypeScript components, session
  pipeline, hooks, and RDD system.
triggers:
  - validate
  - stack verify
  - verify stack
  - check stack
  - validation
---

# Validate Stack

Run these verifications in order to validate the Gentle-Vanguard stack v4.0+ (TypeScript-first).

> **Note**: Scripts PowerShell (.ps1) fueron migrados a TypeScript (.ts). Ver AGENTS.md líneas
> 273-284.

## 1. Package JSON Validation

```bash
node -e "JSON.parse(require('fs').readFileSync('package.json')); console.log('✓ package.json is valid JSON')"
```

Expected: No errors, ✓ package.json is valid JSON.

## 2. Opencode Config Validation

```bash
node -e "JSON.parse(require('fs').readFileSync('opencode.json')); console.log('✓ opencode.json is valid JSON')"
```

Expected: No errors, ✓ opencode.json is valid JSON.

## 3. TypeScript Compilation Check

```bash
npm run typecheck 2>&1
```

Expected: Only warnings (TS6133 - unused vars), no errors.

## 4. Session Autostart (TypeScript)

```bash
npm run session:autostart:detached
```

Expected: Returns in ~1.3s, log at `.runtime/autostart-detached-*.log`.

## 5. Health Check Full

```bash
npm run health:check
```

Expected: 25+ PASS, failures should be non-critical.

## 6. RDD Risk Classification Test

```bash
npm run rdd:risk -- --staged --json
```

Expected: JSON output with tier, score, reviewLenses.

## 7. Database Health (Nexus)

```bash
npm run db:health
```

Expected: SQLite integrity PASS, 23 tables, migrations OK.

## 8. Watchtower Health

```bash
npm run watchtower:health 2>&1
```

Expected: 60 checks PASS, components OK.

## 9. Working Tree Status

```bash
git status --short
```

Expected: Clean or only expected files changed.

## Expected Results Summary

| Check             | Expected                |
| ----------------- | ----------------------- |
| package.json      | Valid JSON              |
| opencode.json     | Valid JSON              |
| typecheck         | No errors (warnings OK) |
| session autostart | Starts successfully     |
| health:check      | 25/29+ PASS             |
| rdd:risk          | Returns valid JSON      |
| db:health         | SQLite integrity OK     |
| watchtower        | Components healthy      |

## Legacy PS1 Scripts (Deprecated)

Los siguientes archivos fueron **eliminados** después de migración a TS:

- `scripts/editing/hashline.ps1` → `src/hashline.ts`
- `scripts/utilities/pre-process-input.ps1` → `src/pre-process-input.ts`
- `scripts/utilities/session/session-start-optimized.ps1` → `src/session-autostart.ts`
- `scripts/maintenance/maintenance-watchtower.ps1` → `src/core/maintenance-watchtower.ts`

## Documentation

- `AGENTS.md` - Lineas 273-284: Migración PS1→TS
- `CHANGELOG.md` - Linea 95: 108 PS1 scripts eliminados
- `rules/RDD-NORMATIVA.md` - Sistema RDD nativo
