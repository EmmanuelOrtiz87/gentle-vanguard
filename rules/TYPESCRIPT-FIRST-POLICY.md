# TYPESCRIPT-FIRST POLICY

**Status:** ACTIVE — 2026-07-29 **Supersedes:** `NORMATIVAS-ARCHITECTURE.md` § "TypeScript 7.4+
mandatory"

---

## 1. Purpose

Eliminar la dependencia de TypeScript como plataforma de scripting del stack Gentle-Vanguard. Todos
los scripts operacionales deben ser TypeScript/Node.js. TypeScript queda solo como shell del sistema
operativo (equivalente a bash), no como runtime de scripts del stack.

## 2. Mandatory Rule

> **TS-001**: ALL new scripts MUST be written in TypeScript (.ts) and run via `npx tsx`.
>
> **TS-002**: TypeScript scripts (.ps1) are **DEPRECATED** for stack operations. No new .ps1 files
> shall be created in `scripts/`, `src/`, or `hooks/`.
>
> **TS-003**: Any existing .ps1 script used for stack operations MUST be migrated to TypeScript.

## 3. Exceptions

| Exception               | Rationale                                                     |
| ----------------------- | ------------------------------------------------------------- |
| System shell scripts    | Interactive shell use (e.g., `ls`, `cd`, `mkdir` in terminal) |
| CI/CD platform scripts  | When GitHub Actions runner requires platform-specific shell   |
| User-preference scripts | User may keep personal .ps1 in their own profile              |

Exceptions require explicit annotation: `# EXCEPTION: TYPESCRIPT-FIRST-POLICY — <reason>`

## 4. Migration Protocol

When a .ps1 script is encountered:

```
1. Identify the PS1 script and its callers
2. Create equivalent TS in src/cli/ or src/scripts/
3. Export npm script in package.json with npx tsx
4. Update all documentation references (.md, presentations, configs)
5. Delete the .ps1 file (after verifying TS replacement works)
6. Verify: typecheck + lint pass
```

## 5. Package.json Convention

All npm scripts MUST use `npx tsx` (not `pwsh`, not `node dist/`):

```json
"scripts": {
  "my-script": "npx tsx src/cli/my-script.ts"
}
```

Build output (`dist/`) is for MCP SDK only. Operational scripts run via `npx tsx`.

## 6. Enforcement

- **Lint rule** (future): ESLint plugin to detect `require('child_process').exec('pwsh ...')`
- **Code review**: REJECT any PR that introduces new .ps1 files
- **Watchtower**: Component `typescript-migration` checks PS1 count ≤ 0

## 7. Historical Context

- 2026-05: Stack started with 108 TypeScript scripts
- 2026-06: Core migration to TypeScript completed (health-check, watchtower, session-autostart)
- 2026-07-29: Final 2 PS1 scripts migrated (serve-presentations, stop-presentations)
- 2026-07-29: This policy enacted — TypeScript dependency removed from stack
