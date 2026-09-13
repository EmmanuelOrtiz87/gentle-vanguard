---
created: 2026-05-21 23:24:35
tags: [engram, architecture]
engram_id: 992
type: architecture
---

# Final optimizations: skill size enforcement + complete stability

**What**: Completed full stack optimization. Fixed 12 silent bugs, automated session lifecycle (0 manual steps), created skill size auditor, added 12 missing agents to model routing, fixed dual routing bug, added per_agent_budget to realistic 3000, integrated skill-size-check into autostart pipeline.

**Why**: 56% of skills exceeded size limits (max 1000 tokens, actual up to 7143). Budget guard was set to 750 tokens when real usage is 2-10x that. Dual routing made session close non-deterministic. 58 empty catch blocks hid all errors.

**Where**: 19 files modified, 3 created across the entire stack. Key: config/auto-delegation.json (SESSION-CLOSE removed), config/model-routing.json (+12 agents), config/orchestrator.json (per_agent_budget), config/session-autostart.config.json (+size-check step), scripts/utilities/check-skill-sizes.ps1 (NEW), rules/NORMATIVAS-SESSION.md (0 manual steps), .atl/skill-registry.md (phantoms removed).

**Learned**:
1. Shadow functions (Write-Error/Write-Warning redefined as Write-Host) are the most dangerous pattern — they hide errors from every downstream caller.
2. PowerShell iterates JSON properties in non-deterministic order — dual keyword routing always has a bug.
3. 56% of skills exceed size limits but no one noticed because there was no auditor. Now check-skill-sizes.ps1 runs at every session start.
4. per_agent_budget: 750 was unrealistic — skills average 2000+ tokens. Changed to 3000 with overage warning.

---
*Imported from Engram on 2026-09-06*
