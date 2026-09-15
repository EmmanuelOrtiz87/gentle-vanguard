---
created: 2026-09-15 15:49:36
tags: [engram, architecture]
engram_id: 3919
type: architecture
---

# Pending: homologate archify/content-cms/academy-crm/academy-landing

**What**: Audit of remaining apps for homologation. 4 apps lack the shared GV shell (language/theme buttons + gv-cc-lang/gv-cc-theme keys).

**Why**: All GV apps must be homologated per NORM-APP-001.

**Where**: 
- archify (React): has 2 i18n files, 2 theme files — but NO gv-lang-dropdown, NO gv-theme-toggle, NO gv-cc keys in index.html
- content-cms (React): has 7 i18n files, 3 theme files — same gap
- academy-crm (React): has 7 i18n files, 1 theme file — same gap
- academy-landing (static): has i18n but no lang/theme buttons

**Learned**: These are React apps (Vite) with their own i18n/theme mechanisms. Homologation requires adding the shared shell pattern (gv-cc-lang/gv-cc-theme keys + language dropdown + theme toggle) — a deeper refactor than the vanilla Design Hub. PENDING: needs per-app work in future sessions.

---
*Imported from Engram on 2026-09-15*
