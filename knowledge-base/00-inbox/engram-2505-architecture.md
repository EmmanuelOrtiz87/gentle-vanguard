---
created: 2026-08-04 14:04:16
tags: [engram, architecture]
engram_id: 2505
type: architecture
---

# Adaptive step scaling + auto-reassignment bridge

**What**: Built the auto-reassignment + adaptive step-scaling layer for the orchestrator.
**Why**: Subagents were configured with `steps: 6` (only 6 tool calls), so they exhausted their budget during exploration and never completed edits. User asked for automatic step scaling instead of manual discovery.
**Where**:
- `src/adaptive-steps.ts` — estimates required steps from task complexity (proactive `--estimate`/`--auto`) and bumps limit on exhaustion (reactive `--resume <agent> --task_id <id>`). Caps at 80. Rounding fixed (was producing fractional steps).
- `src/recommend-agent.ts` — bridge that queries the adaptive routing table and returns best agent (override → domain entry → static fallback). Cold start returns static map.
- `src/adaptive-router.ts` (existing) — builds routing table from execution history.
- `opencode.json` + `.opencode/agents/*.md` — raised all subagent `steps` from 6 to 20-40 by role (sdd-apply=40, sdd-explore/design/verify=30, sia=35, orchestrator=24).
- `config/session-autostart.config.json` — added lazy step `adaptive-steps` (104 total steps).
- `package.json` — added `steps:status`, `steps:estimate`, `recommend:agent`.
- `rules/ADAPTIVE-REASSIGNMENT-NORMATIVA.md` — documents the pattern.
**Learned**: The root cause of failed delegation was the `steps: 6` config limit, NOT the prompt or cache. Resume with `task_id` preserves context and is preferred over re-delegating from scratch. Adaptive router needs ≥3 data points per agent before generating overrides; cold start uses static fallback.

---
*Imported from Engram on 2026-09-06*
