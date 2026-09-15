---
created: 2026-09-15 15:46:16
tags: [engram, bugfix]
engram_id: 3917
type: bugfix
---

# gv-analytics: aligned to shared gv-cc-lang/gv-cc-theme

**What**: Fixed gv-analytics to use shared GV keys instead of proprietary gv-analytics-locale/gv-analytics-theme. Also fixed locale persistence bug.

**Why**: Proprietary keys broke the shared i18n system. Locale was read from localStorage but never written back.

**Where**: `apps/gv-analytics/src/i18n.tsx` (Locale type pt-BR→pt, reads/writes gv-cc-lang, setLocale persists) and `apps/gv-analytics/src/App.tsx` (gv-cc-theme)

**Learned**: useState initializer reads localStorage but raw setter doesn't persist back — must wrap in custom setter. Legacy mapping: old 'pt-BR' value maps to new 'pt'.

---
*Imported from Engram on 2026-09-15*
