---
created: 2026-09-15 15:46:19
tags: [engram, decision]
engram_id: 3918
type: decision
---

# Labs: read-only experiments with export and back navigation

**What**: Design Hub Labs are read-only experiments with clear banners, back navigation via shell breadcrumb, and export to files (JSON/MD).

**Why**: User needed clarity on labs behavior: what they are, can they go back, what happens with changes, can they export.

**Where**: visual-comparison (banner + Download .md), compare-v1-v2-v3 (banner + Exportar decisiones .json), v3-showcase (banner archived), labs index (updated scope banner)

**Learned**: shell.js detects isLabPage and injects "← Back to Labs" link. CSS .lab-readonly-banner uses yellow (#fbbf24). compare-v1-v2-v3 persists to localStorage (decisions + picks). visual-comparison report modal has Download .md button.

---
*Imported from Engram on 2026-09-15*
