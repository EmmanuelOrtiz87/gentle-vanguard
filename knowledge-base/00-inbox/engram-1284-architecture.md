---
created: 2026-06-02 11:00:45
tags: [engram, architecture]
engram_id: 1284
type: architecture
---

# Release automation: NORMATIVAS-RELEASE + release-automation.ps1

**What**: Created comprehensive release automation pipeline: release-automation.ps1 (4-phase script: validate, build, sync, report) + NORMATIVAS-RELEASE.md (8 rules) + updated release.yml (CI blocks on VERSION/badge/CHANGELOG mismatch).

**Why**: Previous releases had repeated gaps: VERSION file not updated (stuck at 2.24.0), installer not rebuilt (old .exe from May 21 synced to public), README badges stale, public repo sync forgotten. Lessons learned were saved to engram but not enforced as rules.

**Where**:
- scripts/utilities/DEPLOYMENT/release-automation.ps1
- rules/NORMATIVAS-RELEASE.md
- .github/workflows/release.yml (updated with validate job)
- VERSION (2.24.0→2.26.0)
- docs/AGENTS.md (added references)

**Learned**:
1. Lessons learned MUST become normativas — engram-only storage is not enough. Created NORMATIVAS-RELEASE.md with 8 binding rules.
2. Release process must be automation-first: one command validates all (VERSION, README badges, CHANGELOG, footer, installer) before proceeding.
3. Installer MUST be rebuilt every release — the .exe bundles encrypted scripts. Old .exe ships stale code.
4. Public repo sync MUST be part of release, not a manual afterthought. sync-to-public.ps1 now called by release-automation.ps1 Phase 3.
5. CI/CD release.yml now BLOCKS (exit 1) if VERSION, README badges, or CHANGELOG don't align — no more warnings that get ignored.

---
*Imported from Engram on 2026-09-06*
