---
created: 2026-05-29 01:32:41
tags: [engram, bugfix]
engram_id: 1199
type: bugfix
---

# OpenCode config validation — no custom props in tool configs

**What**: Fixed bug where `systemPromptOptimization` was added as a top-level property in `opencode.json`, causing OpenCode to crash at startup because it rejects unknown properties. Created separate `config/system-prompt-optimization.json`, restored `system-prompt-optimizer.ps1`, created `validate-opencode-config.ps1` validator, and added validation step in autostart pipeline. Also restored `self-diagnosis-autonomous.ps1` and `self-diagnosis.ps1` to `scripts/utilities/DIAGNOSIS/` that were deleted in refactor commit 2fb1939b.

**Why**: OpenCode validates its config JSON against its official schema (33 valid properties). Custom props cause startup failure. The root cause was putting custom config directly in the tool's config file instead of a separate file.

**Where**: config/system-prompt-optimization.json, config/opencode.schema.json, config/session-autostart.config.json, scripts/utilities/SYSTEM/system-prompt-optimizer.ps1, scripts/utilities/CONFIG/validate-opencode-config.ps1, scripts/utilities/DIAGNOSIS/self-diagnosis-autonomous.ps1, scripts/utilities/DIAGNOSIS/self-diagnosis.ps1, scripts/utilities/PROMPT/*.ps1 (5 scripts updated to read centralized config)

**Learned**: (1) NEVER add non-standard properties to tool config files (opencode.json, .cursorrules, etc.). Use config/*.json for custom config. (2) The refactor commit 2fb1939b deleted self-diagnosis scripts but the autostart pipeline still referenced them — need to validate pipeline steps after refactors. (3) Write-Host output is not captured by & capture (stream 6), use*>&1 to capture all streams in tests. (4) Added to AGENTS.md as Hard Rule.

---
*Imported from Engram on 2026-09-06*
