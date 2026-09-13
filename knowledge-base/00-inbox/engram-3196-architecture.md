---
created: 2026-08-28 00:09:15
tags: [engram, architecture]
engram_id: 3196
type: architecture
---

# Wired delegateWithGuardrail into production delegation paths

**What**: The unified guardrail orchestrator (`delegateWithGuardrail` in `src/agent-delegator.ts`) was defined and tested but NEVER called in production — the real delegation path used plain `delegate()`, making the orchestrator dead code. Wired it into the actual delegation entry points so failures are classified, recorded as incidents, and surfaced with corrective guidance instead of blind retry.

**Why**: Pending item 2 from the guardrail plan — the orchestrator needed to be operational in production, not just defined.

**Where**:
- `src/route-and-delegate.ts`: main routing entry now uses `delegateWithGuardrail()` (was `delegate()`)
- `src/agent-delegator.ts`: CLI `--agent` path uses `delegateWithGuardrail()` (GGA benefits automatically since it spawns this CLI)
- `src/model-broker.ts`: delegation catch block records incidents via `evaluateFailure()`
- `src/guardrail-orchestrator.ts`: added `/unknown agent/i` and `/agent.*not (found|registered|configured)/i` signatures to `config` category (real learning: "Unknown agent: X" was falling into `unknown`, 2 of 3 real incidents)
- `tests/unit/guardrail-orchestrator.test.ts`: updated + added test cases

**Learned**:
- Commit `227883ad` on main.
- The incident log `.session/guardrails/incidents.jsonl` now accumulates real data (learning loop operational).
- Windows test flakiness: running guardrail-orchestrator.test.ts + anti-loop-guard.test.ts together occasionally fails with EPERM on temp dir cleanup (subprocess file-handle race). Passes individually and on retry — pre-existing infra issue, not logic.
- `model-broker.ts` delegate() is a SIMULATED delegation (no real subprocess spawn), so guardrail there records incidents but doesn't affect real delegation.
- `gga.ts` spawns `agent-delegator.ts` CLI as subprocess → benefits automatically from the CLI fix.

---
*Imported from Engram on 2026-09-06*
