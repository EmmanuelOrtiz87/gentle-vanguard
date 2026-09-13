---
created: 2026-05-20 02:43:44
tags: [engram, architecture]
engram_id: 961
type: architecture
---

# Metrics pipeline, public repo sync, .exe rebuild

**What**: Implemented comprehensive metrics/audit/reporting pipeline with live dashboard, git-clean data artifacts, and standardized nomenclature. Then committed, pushed to both repos, and rebuilt the .exe installer.

**Why**: User requested real-time metrics visibility, automated reporting, and full deployment pipeline (private + public repos).

**Where**:
- scripts/metrics/collector.ps1 — ETL pipeline with 6 collectors
- scripts/metrics/live-feed.ps1 — continuous loop, 15s cycle
- scripts/metrics/dashboard-render.ps1 — 6-section HTML + Canvas charts
- rules/NORMATIVAS-REPORTING.md — standards for nomenclature & architecture
- build/create-installer.ps1 — rebuilt Gentle-Vanguard.exe v2.19.0
- scripts/utilities/sync-public-repo.ps1 — public repo sync mechanism

**Learned**:
- Public remote at gentle-vanguard-public was ahead of local (auto-sync commits), required force-push via sync script
- NSIS (makensis.exe) and ps2exe both available for .exe builds
- Git filters in .gitattributes handle CRLF→LF normalization
- collector.ps1 uses ValidateSet for Scope param (full,sessions,token,live,git,pr,cost)

---
*Imported from Engram on 2026-09-06*
