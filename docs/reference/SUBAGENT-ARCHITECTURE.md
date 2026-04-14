# Subagent Architecture

## 1. Purpose

Define a parallel, token-efficient execution model for the Foundation orchestrator by splitting work into specialized subagents with bounded context.

## 2. Design Principles

1. Minimize context per subagent using scoped task packets.
2. Execute independent tasks in parallel whenever dependencies allow it.
3. Keep a single coordinator responsible for plan, merge, and final decisions.
4. Enforce strict output contracts so results can be merged with low token cost.
5. Persist only durable findings to memory; avoid full transcript replay.

## 3. Agent Topology

### 3.1 Coordinator

Responsibilities:

1. Build execution graph.
2. Split task into lanes.
3. Dispatch subagents in parallel.
4. Merge outputs and resolve conflicts.
5. Produce final response and action summary.

### 3.2 Worker Lanes

1. Discovery lane:
- Searches files, symbols, references.
- Produces a compact fact pack.

2. Implementation lane:
- Applies code changes for assigned slice.
- Returns changed files, rationale, and validation intent.

3. Validation lane:
- Runs tests/lint/build for assigned slice.
- Returns pass/fail evidence and regressions.

4. Governance lane:
- Checks docs, scripts, policies, and release readiness.
- Returns compliance findings and required fixes.

## 4. Execution Graph

## 4.1 Phase A - Plan

1. Coordinator receives objective.
2. Creates lane packets with constraints and acceptance criteria.
3. Assigns dependency labels:
- independent
- depends-on:<lane>

## 4.2 Phase B - Parallel Execution

1. Run all independent lanes concurrently.
2. If a lane fails, coordinator decides retry, fallback, or stop.
3. Dependent lanes start only when prerequisites are complete.

## 4.3 Phase C - Merge

1. Merge by file ownership first.
2. Resolve conflicts by priority:
- validation safety
- functional correctness
- style/documentation
3. Emit final consolidated result.

## 5. Token Optimization Strategy

1. Task packet size budget per lane: 1.5k to 2.5k characters.
2. Include only:
- objective
- touched file list
- required symbols
- acceptance checks
3. Exclude full chat history.
4. Use context-pack artifacts for state handoff between batches.
5. Return compact structured output (no narrative unless requested).

## 6. Subagent Output Contract

Each lane must return:

1. lane_id
2. status: success | failed | blocked
3. files_touched
4. findings_or_changes (max 8 bullets)
5. validation_result
6. next_action

## 7. Parallelism Policy

1. Max parallel lanes by risk level:
- low: 4
- medium: 3
- high: 2
2. Default lane timeout: 8 minutes.
3. Retry policy: 1 retry for transient failures.
4. Stop policy: hard stop on security-critical findings.

## 8. Suggested Session Workflow

1. Generate compact baseline:

```powershell
./scripts/utilities/wf.ps1 context-pack "<objective>"
```

2. Set response mode for compressed operations:

```powershell
./scripts/utilities/wf.ps1 response-mode ultra
```

3. Execute coordinator-led parallel slices.

4. Regenerate context pack after merge milestone.

5. Run review and audit only once after consolidated merge.

## 9. Governance and Safety

1. No lane may push directly to remote.
2. Coordinator is the only role that approves final publish.
3. All validation evidence must be attached before final sign-off.
4. Reset/demo scripts may use cleanup mode, but release workflows cannot skip governance checks.

## 10. Adoption Plan

1. Start with demo and docs/review tasks (low risk).
2. Extend to refactor and feature slices once stable.
3. Keep architecture and orchestrator config aligned.
4. Track cycle time and token consumption per run for tuning.

## 11. Advanced Token Controls

1. Packet budget guardrails:
- Keep lane packets between 1.5k and 2.5k characters.
- Hard cap context files per lane to avoid prompt bloat.

2. Deduplication policy:
- Collapse equivalent findings before merge.
- Keep only one canonical finding per root cause.

3. Discovery caching:
- Cache read-only discovery facts for short TTL windows.
- Reuse cached facts when file hashes are unchanged.

4. Auto-compaction policy:
- Regenerate context pack every 2 completed lanes or major merge.
- Never replay full transcript to workers.

5. Merge compression:
- Coordinator receives structured lane outputs only.
- Narrative detail is optional and requested on-demand.

## 12. Metrics to Track

1. Tokens per completed lane.
2. Tokens per merged file.
3. Reused cached discovery ratio.
4. Duplicate finding reduction ratio.
5. End-to-end cycle time versus baseline.

## 13. Token Alert and Continuity Playbook

1. Soft alert (>= soft threshold):
- Continue with compact mode.
- Split work into smaller slices.
- Prefer context-pack plus compact-start before next lane.

2. Hard alert (>= hard threshold):
- Stop non-essential parallel lanes.
- Execute closure-safe flow to avoid blocked session.
- Preserve state and handoff context before ending.

3. Mandatory alert details:
- Current estimated tokens.
- Used tokens today.
- Projected budget percentage.
- Exact threshold reached.
- Suggested alternatives with runnable commands.

4. Mandatory Engram continuity:
- Engram must be available for all guarded flows.
- If missing, alert must include install path and launcher fallback.
- Session closure should always include an Engram-supported handoff option.

## 14. Operator Commands

1. Manual budget check:

```powershell
./scripts/utilities/wf.ps1 token-guard
./scripts/utilities/wf.ps1 token-guard publish
```

2. Engram readiness and usage:

```powershell
./scripts/utilities/wf.ps1 install-engram
./scripts/utilities/run-engram.ps1 --help
```
