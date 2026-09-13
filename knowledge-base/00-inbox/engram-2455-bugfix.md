---
created: 2026-08-01 15:28:02
tags: [engram, bugfix]
engram_id: 2455
type: bugfix
---

# Remediación completa vulnerabilidades dashboard: 16→0

**What**: Remediadas las 16 vulnerabilidades de dependencias de apps/web-dashboard hasta 0. Upgrade mayor de vite 5.4.21→6.4.3 y react-router 7.18.2→8.3.0 aplicados vía overrides del pnpm-workspace.yaml del dashboard.

**Why**: pnpm audit detectó 16 vulnerabilidades (12 high): minimatch ReDoS (3), esbuild dev server, vite fs.deny bypass/path traversal/NTLM (3), react-router RSC CSRF, postcss, shell-quote, brace-expansion, js-yaml, ws, prettier, @types/node, autoprefixer, concurrently, jest-dom.

**Where**: apps/web-dashboard/pnpm-workspace.yaml (overrides + minimumReleaseAgeExclude + allowBuilds), apps/web-dashboard/package.json (onlyBuiltDependencies), apps/web-dashboard/pnpm-lock.yaml (regenerado)

**Learned**:
1. El fix NO fue individual por paquete sino un upgrade mayor combinado: vite 6.4.3 resuelve los 3 advisories de vite + el de esbuild (vite 6 pincha esbuild 0.24+); react-router 8.3.0 resuelve el CSRF.
2. El build pasó sin problemas con vite 6.4.3 + @vitejs/plugin-react 4.7.0 + react-router 8.3.0 (17 chunks, 3.30s). Los major-bumps eran seguros en este proyecto.
3. Tests 32/32 pass, typecheck/lint/test:config de la raíz todos verdes tras el upgrade.
4. Los overrides con rangos condicionales del yaml funcionan cuando se resuelve completo (borrar lockfile + node_modules/.pnpm y reinstalar).

---
*Imported from Engram on 2026-09-06*
