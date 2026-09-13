---
created: 2026-05-18 19:13:49
tags: [engram, decision]
engram_id: 945
type: decision
---

# ASCII banner integration across CLI and TUI

**What**: Integrated the GENTLE VANGUARD ASCII art banner across all entry points: Go TUI (model-router-tui), session-autostart.cmd, session-autostart.ps1, gv.ps1 version command, and gentle-vanguard-installer-tui.ps1. Replaced old placeholder ASCII art in installer TUI.

**Why**: User requested the title banner be visible in both CLI and TUI interfaces for consistent branding.

**Where**:
- scripts/utilities/model-router-tui/main.go — renderBanner() (full 6-line), renderCompactBanner() (1-line title + subtitle), added to all 10 view functions
- scripts/utilities/session-autostart.cmd — added 6-line echo banner before session start
- scripts/utilities/session-autostart.ps1 — added Write-Host colored banner
- scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1 — added banner to 'version' command
- scripts/utilities/gentle-vanguard-installer-tui.ps1 — replaced old header with new banner

**Learned**: Go TUI uses two banner variants: full (viewLoading) and compact (all other views). The compact banner uses "GENTLE VANGUARD" text + subtitle line to avoid overwhelming navigation screens.

---
*Imported from Engram on 2026-09-06*
