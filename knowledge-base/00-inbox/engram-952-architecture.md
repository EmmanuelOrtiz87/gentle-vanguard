---
created: 2026-05-18 23:32:08
tags: [engram, architecture]
engram_id: 952
type: architecture
---

# Autonomous learning system — 3-layer proactive lesson capture

**What**: Implemented 3-layer autonomous learning system — agents MUST save lessons to Engram proactively without waiting for user instruction
**Why**: Learning was reactive (only when user asked). Now it's proactive with automatic triggers at 3 levels
**Where**: CLAUDE.md (Core Rule #13), rules/NORMATIVAS-SESSION.md (sections 2.3 and 2.4), config/session-autostart.config.json (step 17), scripts/utilities/self-diagnosis-autonomous.ps1, scripts/utilities/session-learning-capture.ps1
**Learned**:
- Layer 1 (during session): CLAUDE.md Rule #13 mandates mem_save after bug fixes, gotchas, architecture decisions, integration patterns, breakages, config changes, performance insights
- Layer 2 (session close): NORMATIVAS-SESSION.md 2.4 steps 8-9 require session-learning-capture.ps1 and self-diagnosis-autonomous.ps1
- Layer 3 (session start): Autostart step 17 runs self-diagnosis proactively (config validation, CodeGraph staleness, skill registry, workspace cleanliness, hook syntax, critical scripts)
- session-learning-capture.ps1 scans git commits, logs, and metrics for lesson candidates
- self-diagnosis-autonomous.ps1 supports quick/full depth modes and outputs health score (0-100)

---
*Imported from Engram on 2026-09-06*
