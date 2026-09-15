---
created: 2026-09-15 15:46:11
tags: [engram, architecture]
engram_id: 3915
type: architecture
---

# Design Hub shell homologation + i18n system

**What**: Homologated the Design Hub shell to match all GV apps: language selector (es/en/pt) + dark/light theme toggle + content i18n system for all 8 pages.

**Why**: User reported missing language/theme buttons and inconsistent English text when Spanish was selected. All GV apps must share the same shell, design tokens, and i18n infrastructure.

**Where**: 
- `apps/design-hub/src/scripts/shell.js` — rewritten: lang (gv-cc-lang), theme (gv-cc-theme), breadcrumb labs, i18n-content.js loading + gv:locale-changed event
- `apps/design-hub/src/scripts/i18n-content.js` — NEW: ~180 keys × 3 languages (es/en/pt), namespaces per page
- `apps/design-hub/public/gv-shell.css` — light theme, lang-dropdown, theme-toggle, controls, back link
- `apps/design-hub/src/styles/main.css` — light theme overrides + removed broken @import
- All 8 page HTMLs with data-i18n attributes

**Learned**: 
- Shared GV keys: gv-cc-lang (es/en/pt) and gv-cc-theme (light/dark)
- i18n pattern: data-i18n / data-i18n-html / data-i18n-suffix / data-i18n-placeholder / data-i18n-aria
- Dynamic JS pages need gv:locale-changed custom event dispatched by shell.js
- Total: 6 namespace groups × ~30 keys each × 3 idiomas

---
*Imported from Engram on 2026-09-15*
