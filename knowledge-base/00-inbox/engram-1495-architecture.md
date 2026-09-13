---
created: 2026-07-08 04:25:15
tags: [engram, architecture]
engram_id: 1495
type: architecture
---

# v7.1 Dashboard UI refinement committed and pushed

**What**: Implemented and pushed v7.1 Dashboard UI refinement. Commit 85f62373. 4 files changed, 137 insertions, 59 deletions. Push successful to origin/develop. Build verified: 0 TS errors.

**Why**: Close v7.1 roadmap items: UX refinement, live updates, engram source integration in Knowledge Panel.

**Where**:
- modified: apps/web-dashboard/src/components/KnowledgePanel.tsx (added engram source with Braces icon/red badge, relevance color bar, Ctrl+Enter shortcut, auto-search on source toggle, error state with retry, Refresh button, loading skeleton)
- modified: apps/web-dashboard/src/components/MultiRepoView.tsx (auto-refresh 30s with setInterval + silent polling, last checked Clock timestamp, error state with retry)
- modified: CHANGELOG.md, docs/ROADMAP.md (v7.1.0 entries, header update, milestones)

**Learned**: When adding a new source type to KnowledgePanel, all 3 places must be updated: SOURCE_CONFIG (icon/label/color), default sources array, and the description text. The useRef + setInterval cleanup pattern with useEffect return is essential to prevent memory leaks on unmount.

---
*Imported from Engram on 2026-09-06*
