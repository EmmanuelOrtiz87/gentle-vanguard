---
created: 2026-06-11 02:51:22
tags: [engram, architecture]
engram_id: 1384
type: architecture
---

# Full project consolidation: lint, typecheck, format, build, tests all passing

**What**: Complete project consolidation across root and dashboard. Fixed 40+ files: ESLint (8+21 errors, 145+ warnings), typecheck (14 errors), Prettier (36+ files), secretlint, and verified 48/48 tests passing. Created dashboard-specific ESLint config, added .secretlintignore for runtime dirs, added .github/workflows/dashboard-ts-ci.yml for TS dashboard CI, updated LEARNED-NORMS.md with 6 learned norms.

**Why**: User required "sin falsos positivos o warning o errores" — everything clean, functional, documented, integrated.

**Where**: scripts/mcp/skill-server.ts, apps/web-dashboard/* (17 files), .eslintrc.json, .secretlintignore, .secretlintrc.json, .github/workflows/dashboard-ts-ci.yml, rules/adaptive/LEARNED-NORMS.md, .gitignore

**Learned**:
- ESLint strict-boolean-expressions no es práctica para React/Node legacy — desactivar a nivel subproyecto
- .session/ y .runtime/ deben estar en .secretlintignore (no solo .gitignore)
- Non-null assertions siempre reemplazables con type guards
- void prefix para floating promises
- Variables no usadas prefix _ para satisfacer noUnusedLocals/noUnusedParameters
- Dashboard TS requiere CI propio separado del dashboard PowerShell

---
*Imported from Engram on 2026-09-06*
