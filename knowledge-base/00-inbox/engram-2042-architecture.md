---
created: 2026-07-27 04:49:03
tags: [engram, architecture]
engram_id: 2042
type: architecture
---

# Stack evolution roadmap — semantic tool selection, swarm, error memory

**What**: Analyzed 10 external articles (Fast Mode, Agent Teams, LSP, Bun v1.3.9, Redis semantic caching, SmartStack, token optimization strategies, IBM prompt engineering, AWS semantic tool selection, mattpocock/skills) against the current Gentle-Vanguard stack. Produced prioritized gap analysis and 3-sprint roadmap.

**Why**: The user requested cross-referencing external knowledge to identify what's missing and make it native — all learnings must be built into the stack.

**Where**: Key affected files: src/team-orchestrator.ts, src/skills/skill-router.ts, src/nexus/NexusDatabase.ts, apps/web-dashboard/src/components/

**Learned**:
- Semantic tool selection with FAISS can reduce tokens by ~89% (from 1557 to 275 per call) and prevent 86.4% of tool-selection hallucinations — highest-impact, lowest-effort win.
- Parallel swarm mode (Leader-Worker with Git worktrees) is the #1 speed bottleneck — team-orchestrator.ts is sequential.
- Error memory pattern (bug → root cause → fix, read before proposing changes) eliminates repeated debugging — simple to implement in Nexus.
- SmartStack achieves 38% token reduction with CLAUDE.md + error memory + standards — our Engram + session pipeline is equivalent but fragmented.
- LSP integration via MCP would give agent IDE-level navigation but is lower priority than semantic selection and parallelism.

---
*Imported from Engram on 2026-09-06*
