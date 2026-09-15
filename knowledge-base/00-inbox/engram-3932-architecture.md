---
created: 2026-09-15 18:19:57
tags: [engram, architecture]
engram_id: 3932
type: architecture
---

# Fixes nativos shell.css compartido: wordmark Gentle blanco + botón idioma homologado 13px (10 apps)

**What**: Final homologation pass + definitive fixes to the shared shell.css, propagated natively to all 10 apps.

**Why**: User reported 3 visual inconsistencies: (1) "Gentle" in the archify wordmark rendered cyan/turquoise instead of white; (2) the language button icon in gv-analytics wasn't the homologated one; (3) the language button font-size varied per-app (some bigger, covered the button).

**Where** (all native in `packages/gv-design-system/src/shell/shell.css` — the shared shell, so fixes propagate to EVERY app on rebuild):
1. **Wordmark**: `.gv-brand-wordmark` flips to `color: var(--gv-text, #e8eef4) !important` (white) + `background:none` so "Gentle" is always white; only `.gv-brand-wordmark span` keeps the gradient (Vanguard) — with `!important` + high specificity + `.gv-brand-wordmark a` variants to beat per-app overrides (archify had its own `.ar-brand-name span` gradient painting the whole wordmark cyan).
2. **Language button glyph**: fixed `.gv-lang-dropdown-menu button` font-size to a consistent homologated size (13-13.5px) + line-height so it never overflows the button across apps.
3. Verified the homologated pattern `.gv-lang-dropdown` + `.gv-icon-btn` (13px) is the canonical; archify wordmark verified live (8097) showing white "Gentle" + gradient "Vanguard".

**Learned**: 
- The root cause was each app shipping its OWN copy of shell styles (archify's `App.css` re-declared `.ar-brand-name span` with its own gradient), so fixes had to be applied per-app. Moving them into the shared shell.css makes the fix native + DRY: ONE file rebuild → 10 apps fixed.
- Build: running `npm run build:components` in archify dir incorrectly triggers `build:mcp` on the design-system package — use the package's own build script.
- All 10 apps now use shared `gv-cc-lang` / `gv-cc-theme` keys with es/en/pt + dark/light; verified live with Playwright (8096-8099 + analytics), academy-landing shows topbar + hero ES + hero EN + light theme, all homologated.

---
*Imported from Engram on 2026-09-15*
