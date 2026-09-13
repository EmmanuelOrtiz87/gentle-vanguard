---
created: 2026-05-31 20:16:20
tags: [engram, architecture]
engram_id: 1247
type: architecture
---

# ECC-inspired stack enhancements

**What**: Implemented 6 ECC-inspired stack enhancements for Gentle-Vanguard

**Where**:
- Created: `scripts/instinct/scoring-instinct.ps1`, `scripts/gateguard/gateguard-mcp.ps1`, `scripts/optimization/context-budget-audit.ps1`
- Modified: `config/model-routing.json` (v1.1.0), `config/behavior-prompts.json`, `scripts/health-check/health-check.ps1`

**Details**:
1. **scoring-instinct.ps1** — ECC-inspired instinct scoring for Engram observations. Accepts pipeline or params, validates schema, outputs confidence/evidence/domain metadata. Supports `-Validate` switch.
2. **gateguard-mcp.ps1** — Pre-execution validation gate for MCP servers. Tracks failure history (3 consecutive = unhealthy), supports retry with backoff, returns structured result `{Server, Status, LatencyMs, LastFailure}`.
3. **model-routing.json** — Added `routing_thresholds` (fast_cheap→strong_reasoning escalation rules + retry_strategy) and `cost_tracking` (daily/session budget limits with hard cap).
4. **context-budget-audit.ps1** — Scans skills/rules/config for token usage, flags files over threshold, ranks by savings potential. Output: Console/Json/CSV.
5. **behavior-prompts.json** — Added `research-ops` evidence protocol prompt for evidence-first research agents.
6. **health-check.ps1** — Added `Check-GateGuard` and `Check-CostTracking` functions, expanded ValidateSet, integrated into "all" switch. All 10 components pass.

**Learned**: GateGuard state file needs hashtable conversion from JSON PSCustomObject. Output JSON must be joined across lines before parsing. `Write-Error` conflicts with `$ErrorActionPreference = "Stop"` in parent scripts — use JSON output instead.

---
*Imported from Engram on 2026-09-06*
