---
created: 2026-09-15 16:30:46
tags: [engram, architecture]
engram_id: 3921
type: architecture
---

# All GV apps homologated: shared shell + gv-cc-lang/gv-cc-theme

**What**: Completed homologation of ALL GV apps to shared shell + i18n keys. Created shared React Shell component in gv-design-system package.

**Why**: User requires all apps consistent: same shell, language selector (es/en/pt), dark/light theme, shared gv-cc-lang/gv-cc-theme keys.

**Where**:
- `packages/gv-design-system/src/react/Shell.tsx` — React Shell component (topbar + nav + lang dropdown + theme toggle + actions prop + footer). Supports href AND onClick nav items.
- `packages/gv-design-system/src/react/shell-only.ts` — shell-only export (avoids CSS imports from other components)
- `packages/gv-design-system/package.json` — added `./react/shell` export
- `apps/archify/src/App.tsx` — topbar replaced with `<Shell>` (6 tabs onClick + actions Importar/Nuevo/Guardar). Added file: dependency.
- `apps/content-cms/src/i18n.tsx` + `App.tsx` — gv-cms-lang → gv-cc-lang, gv-cms-theme → gv-cc-theme (with legacy mapping)
- `apps/academy-crm/src/i18n.ts` — gv-crm-lang → gv-cc-lang (theme already used gv-cc-theme)
- `apps/academy-landing/index.html` — full homologation: topbar + lang dropdown + theme toggle + i18n es/en/pt + light theme

**Learned**:
- React apps importing the package need `file:../../packages/gv-design-system` dependency + import from `@gentle-vanguard/design-system/react/shell` (NOT ./react which pulls CSS imports that break vite build)
- content-cms and academy-crm already had lang/theme UI — only needed key migration to shared keys
- All 10 apps now use gv-cc-lang/gv-cc-theme: academy-web, command-center, prompt-studio, gv-analytics, design-hub, archify, content-cms, academy-crm, academy-landing, web-dashboard (web-dashboard was already using shared keys per earlier audit)

---
*Imported from Engram on 2026-09-15*
