---
created: 2026-05-22 04:28:59
tags: [engram, bugfix]
engram_id: 1008
type: bugfix
---

# Fixed dashboard export PDF/PNG and slide layouts

**What**: Fixed dashboard PDF/PNG export and presentation slide layouts
**Why**: PDF showed "file not found" (temp HTML with window.print() interfered with --print-to-pdf); PNG showed "No active section" popup (wrong JS selector .section.active instead of .sec.active)
**Where**: scripts/metrics/metrics-server.ps1
**Learned**:
- --print-to-pdf uses @media print automatically, no JS window.print() needed
- --screenshot uses screen media, need CSS inject for hidden sections
- JS querySelector('.section.active') fails when class is .sec.active
- Edge/Chrome --virtual-time-budget ensures page is fully rendered before screenshot

---
*Imported from Engram on 2026-09-06*
