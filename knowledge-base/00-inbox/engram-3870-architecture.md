---
created: 2026-09-11 03:54:56
tags: [engram, architecture]
engram_id: 3870
type: architecture
---

# CRM Studio: refactor visual al design system GV estándar

**What**: Refactor visual completo del CRM Studio para usar el design system estándar GV. El CRM pasó de un sidebar lateral custom a la estructura estándar gv-topbar + gv-footer con logo oficial, theme toggle light/dark, language dropdown en topbar, y tokens estándar de academy-tokens-v2.css.

**Why**: El usuario reportó que el CRM no tenía la misma visual que las otras apps — no tenía topbar, footer, logo, theme toggle, ni la disposición estándar. Usaba tokens inventados en vez del design system compartido.

**Where**:
- `apps/academy-crm/src/tokens.css` — copia de academy-tokens-v2.css (tokens estándar con light mode)
- `apps/academy-crm/src/shell.css` — NUEVO: gv-topbar, gv-brand (logo.svg + wordmark + gv-shell-context), gv-footer, gv-icon-btn, gv-lang-dropdown, theme toggle, responsive
- `apps/academy-crm/public/logo.svg` — logo oficial copiado desde academy-web/assets
- `apps/academy-crm/src/App.tsx` — reescrito: gv-topbar (brand + nav + controls) → crm-main → gv-footer
- `apps/academy-crm/src/styles.css` — reescrito: solo estilos CRM-specific con tokens estándar
- `apps/academy-crm/src/main.tsx` — importa tokens.css → shell.css → styles.css
- `apps/command-center/server.ts` — renombrado "Academy CRM" → "CRM Studio"

**Learned**: (1) El shell estándar GV es: gv-topbar (sticky glass + gradiente border) → gv-brand (logo.svg 32px + wordmark con gradiente + gv-shell-context con nombre de app) → nav horizontal → controls (lang dropdown + theme toggle) → main → gv-footer. (2) El theme toggle usa data-theme attribute en el html element + localStorage (gv-cc-theme). (3) Los tokens estándar incluyen light mode overrides en :root[data-theme='light']. (4) El CRM-specific CSS (kanban, cards, modals, calendar) usa los tokens estándar (--gv-glass, --gv-glass-border-subtle, --gv-radius-lg, etc.) en vez de valores hardcodeados. (5) Verificado: topbar ✓, logo ✓ (200, 2306 bytes), wordmark ✓, CRM Studio ✓, nav 4 secciones ✓, lang dropdown con 3 idiomas ✓, theme toggle ✓, footer ✓, dashboard content en español ✓, datos reales ✓.

---
*Imported from Engram on 2026-09-12*
