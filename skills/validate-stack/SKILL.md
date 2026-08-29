---
name: validate-stack
aliases: ["validate-stack"]
description:
  Validate the full Gentle-Vanguard stack. Run verification steps for TypeScript components, session
  pipeline, hooks, and RDD system.
  
triggers:
  - validate
  - stack verify
  - verify stack
  - check stack
  - validation
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T01:46:58.304Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\validate-stack\SKILL.md
  version: "1.0.0"
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

- `C:/Workspace_local/gentle-vanguard/src/tools/hashline.ts` → `src/tools/hashline.ts`
- `C:/Workspace_local/gentle-vanguard/src/tools/pre-process-input.ts` → `src/tools/pre-process-input.ts`
- `C:/Workspace_local/gentle-vanguard/src/session-start-optimized.ts` → `src/session/session-autostart.ts`
- `C:/Workspace_local/gentle-vanguard/src/core/maintenance-watchtower.ts` → `src/core/maintenance-watchtower.ts`

## Documentation

- `AGENTS.md` - Lineas 273-284: Migración PS1→TS
- `CHANGELOG.md` - Linea 95: 108 PS1 scripts eliminados
- `rules/RDD-NORMATIVA.md` - Sistema RDD nativo

## Usage

Use **validate-stack** when a task matches its triggers (validate - stack verify - verify stack - check stack - validation).

Purpose: Validate the full Gentle-Vanguard stack.

## Examples

Concrete usage drawn from this skill's own documentation:

```bash
node -e "JSON.parse(require('fs').readFileSync('package.json')); console.log('✓ package.json is valid JSON')"
```
