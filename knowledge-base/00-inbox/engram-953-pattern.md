---
created: 2026-05-18 23:32:12
tags: [engram, pattern]
engram_id: 953
type: pattern
---

# Deployment pipeline — PRs, exe build, public repo sync

**What**: Complete deployment pipeline executed — 2 PRs merged, 2 exe builds, 2 public repo syncs
**Why**: Ensured all changes (CodeGraph integration + autonomous learning) reach production
**Where**: GitHub PRs #121 and #122, dist/Gentle-Vanguard.exe v2.19.0 (2.74 MB), gentle-vanguard-public repo
**Learned**:
- Build pipeline: develop commit → PR → merge main → sync-to-public.ps1 → create-installer.ps1 → sync-to-public.ps1 again (with new exe)
- create-installer.ps1 encrypts 305 files, copies 134 skill stubs, compiles launcher with PS2EXE, generates NSIS installer
- sync-to-public.ps1 handles cleanup of plain-text artifacts, stashes before rebase, and auto-commits
- Public repo sync is idempotent — second run after exe build picks up the new exe

---
*Imported from Engram on 2026-09-06*
