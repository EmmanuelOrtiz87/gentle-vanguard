---
created: 2026-06-12 12:47:08
tags: [engram, bugfix]
engram_id: 1409
type: bugfix
---

# CLAUDE.md restoration + path fixes across stack

**What**: Restored CLAUDE.md (deleted in 6b968bd0), created missing detect-tool.ps1 shim, fixed broken paths in validate-configs.ps1 and hooks-config.json

**Why**: CLAUDE.md deletion broke the orchestrator bootstrap — the AI model never received startup instructions (tool detection, pre-process-input, Phase A/B sequence). Without CLAUDE.md the stack was non-functional. Additionally, a prior re-structuring moved scripts into subdirectories (telemetry/, git/, setup/) but the configs still referenced old flat paths.

**Where**:
- CLAUDE.md — restored from 6b968bd0^ with path fix
- scripts/utilities/detect-tool.ps1 — created shim (delegates to setup/DETECT/detect-tool.ps1)
- scripts/utilities/utils/detect-tool.ps1 — path fix (utils/DETECT/ → setup/DETECT/)
- scripts/utilities/VALIDATE/validate-configs.ps1 — $Root path +3 critical script paths
- config/hooks-config.json — 3 script paths (TELEMETRY-METRICS/, GIT-VERSION-CONTROL/)

**Learned**:
- validate-configs.ps1 had $Root computed as Split-Path -Parent twice (only went to scripts/) instead of thrice (repo root). Script was moved from tools/ without updating internal paths.
- hooks-config.json stored paths from before the scripts/utilities/ to scripts/utilities/{telemetry,git,setup}/ restructure
- The session-agent must always check CLAUDE.md exists on session start — it's the bootstrap entry point that OpenCode auto-loads

---
*Imported from Engram on 2026-09-06*
