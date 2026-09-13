---
created: 2026-06-06 19:30:16
tags: [engram, architecture]
engram_id: 1347
type: architecture
---

# Full audit remediation — scripts reorg, metrics/ft rewrite, push

**What**: Complete project audit and remediation of Gentle-Vanguard: 92 files examined, all identified issues fixed, committed and pushed to origin/main

**Why**: Repo had massive corruption in key scripts (metrics-server.ps1: 4 nested copies, ft-evaluator.ps1: 8 concatenated copies), deprecated directories still tracked, flat uppercase scripts directory hard to navigate, skill-server.ts execute_skill was non-functional (empty Promise), dashboard had simulated/mock data, InteractiveDocs was 2 trivial tutorials

**Where**:
- scripts/metrics/metrics-server.ps1: ~2000→229 lines
- scripts/utilities/FINE-TUNING/ft-evaluator.ps1: 427→82 lines  
- scripts/mcp/skill-server.ts: functional SKILL.md YAML frontmatter parsing + execSync
- apps/web-dashboard/server/real-data.ts: real tokens, sessions, MCP perf, health routing
- apps/web-dashboard/src/components/InteractiveDocs.tsx: 10 real doc sections
- scripts/utilities/: 79 uppercase dirs → 20 lowercase-kebab directories
- deprecated/: entire directory deleted from git
- .lefthook.yml: YAML fixed, configs consolidated
- hooks/: 5 broken paths fixed (karpathy-enforcer, normative-audit, pre-commit, validate-readme)

**Learned**:
- lefthook pre-commit hooks (karpathy-enforcer, normative-audit) blocked commit due to broken paths from script reorganization → had to fix hooks/ files with updated paths
- PowerShell `& 'scripts/utilities/resilience-handler.ps1'` was the entry point for both hooks
- validate-readme.ps1 ended up in `scripts/utilities/validate/` (not `utils/`)
- Commit 1465b441 had 320 files changed, 2,571 insertions, 25,596 deletions
- Pushed to https://github.com/EmmanuelOrtiz87/gentle-vanguard.git

---
*Imported from Engram on 2026-09-06*
