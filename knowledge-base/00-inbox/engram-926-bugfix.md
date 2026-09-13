---
created: 2026-05-17 04:41:39
tags: [engram, bugfix]
engram_id: 926
type: bugfix
---

# Fixed 8 broken Join-Path file references

**What**: Fixed 8 broken Join-Path references across 5 files in the gentle-vanguard codebase. All paths were pointing to non-existent files due to directory restructuring (scripts/gentle-vanguard/ moved to scripts/foundation/, and subdirectories like SKILLS-TOOLS, UTILITIES were introduced under scripts/utilities/).

**Why**: Scripts referenced files at paths that no longer existed, causing silent failures or errors at runtime.

**Where**:
- scripts/diagnostics/system-diagnostics.ps1:98,284,291
- scripts/adaptive/karpathy-enforcer.ps1:11,16-25
- hooks/post-checkout.ps1:44
- scripts/validation/update-all.ps1:68,168
- scripts/utilities/platform-compat.ps1:11

**Learned**:
- karpathy-enforcer.ps1 had the worst issue: `$repoRoot` was used in the param block default value but NEVER defined anywhere in the script. Fixed by adding repoRoot computation and moving FailureLearningDb init to body.
- SKILLS-TOOLS/ subdirectory under scripts/utilities/ contains install-engram.ps1 and ensure-tools-active.ps1
- UTILITIES/ subdirectory under scripts/utilities/ contains auto-init-dev-environment.ps1
- scripts/foundation/ contains bootstrap.ps1 and sync-skills.ps1 (not scripts/gentle-vanguard/)
- bootstrap-workspace.ps1, engram-policy.ps1, export-profile.ps1, import-profile.ps1, failure-learning-system.ps1, karpathy-orchestrator.ps1, and auto-delegation-wrapper.ps1 had correct Join-Path references already

---
*Imported from Engram on 2026-09-06*
