---
created: 2026-05-29 04:38:12
tags: [engram, architecture]
engram_id: 1209
type: architecture
---

# Team Mode — multi-agent parallel orchestrator

**What**: Implemented Team Mode orchestrator at scripts/team-mode/team-orchestrator.ps1. Accepts task + optional skill list, queries MCP Skill Server for skill routing (search_skills), launches sub-agents in parallel PowerShell jobs with configurable MaxParallel/Timeout. Collects results, handles timeouts/failures, synthesizes unified report. Writes per-skill logs to .session/team-mode/.

**Why**: Enable true parallel multi-agent execution for complex tasks. Bridges the gap between single-agent delegation and full parallel orchestration.

**Where**: scripts/team-mode/team-orchestrator.ps1, .session/team-mode/ (runtime logs)

**Learned**:
- DryRun flag supports testing without execution
- PowerShell Start-Job/Wait-Job pattern works for parallel sub-agents
- MCP Skill Server provides skill routing search
- Sub-agents separated by skill boundaries for clean parallelism

---
*Imported from Engram on 2026-09-06*
