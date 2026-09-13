---
created: 2026-08-31 17:40:28
tags: [engram, architecture]
engram_id: 3513
type: architecture
---

# CMS canonical design system migration

**What**: Migrated apps/content-cms to import assets/gv-design-system.css, renamed shell classes to gv-*and removed duplicated canonical tokens/shell/control CSS; mapped all --color-* variables to canonical --gv-* names and extracted Content OS visible status/label strings into i18n.ts.
**Why**: Eliminate CMS design-system duplication without touching other apps.
**Where**: apps/content-cms/src/styles.css, App.tsx, contentos.tsx, i18n.ts
**Learned**: Canonical shell differs visually from legacy CMS values: grid/glows use #a855f7/#00bfff instead of #a78bfa/#22d3ee; topbar uses rgba(13,17,23,.88) instead of rgba(18,18,18,.88); canonical panel/button geometry and gradients now govern. CMS styles reduced from 833 to 545 lines. Checks passed: CMS typecheck/lint/test (40/40)/build, root tsc, Prettier, HTTP CSS includes gv classes and excludes old shell/vars. No commit made.

---
*Imported from Engram on 2026-09-06*
