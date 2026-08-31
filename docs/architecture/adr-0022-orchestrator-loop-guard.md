# ADR-0022: Orchestrator Loop Guard — Native Anti-Loop Protection

**Status:** Accepted (2026-08-31)  
**Context:** F2.3 sessions hit degenerative planning loops (30+ identical intent lines without tool
execution). External research (Azure AI Agent Design Patterns, 2026) mandates iteration caps +
fallback for every orchestration pattern.

## Decision

Introduce `src/core/orchestrator-loop-guard.ts` as a pure, stateful guard with 4 detectors:

| Detector         | Threshold                     | Action                         |
| ---------------- | ----------------------------- | ------------------------------ |
| intent-loop      | 3 identical intents           | Emit tool or ask clarification |
| tool-loop        | 3 identical tool fingerprints | Change args / escalate         |
| ping-pong        | A-B-A-B                       | Consolidate / human decision   |
| stalled-progress | 8 steps without side-effect   | Force write/check              |

`OrchestratorLoopGuard` is framework-agnostic (no I/O), test-covered (5 tests), and CLI-runnable. It
implements the Azure guidance:

> _“To guard against infinite tool-call loops, set iteration limits.”_ (Single-agent)  
> _“Set an iteration cap to prevent infinite refinement loops, and define fallback behavior”_
> (Maker-checker)  
> _“The manager agent watches for excessive stalls ... and guards against infinite remediation
> loops.”_ (Magentic)

## Research Absorption (Native)

- **Source:**
  `https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns`
  scraped via native `src/web/web-crawler-cli.ts` (dual-provider: Jina+DDG+Bing, no API key) on
  2026-08-31. Markdown cached in `graphify-out/` not needed; knowledge distilled into guard
  thresholds and ADR.
- **Stack-native retrieval:** Guard thresholds align with `src/orchestration/adaptive-steps.ts` (max
  80 steps) and `src/core/process-hygiene.ts` (stale detection). No external runtime dependency.

## Consequences

- Orchestrator and subagents can instantiate `new OrchestratorLoopGuard()` before a turn and call
  `shouldBreak()` — if `break:true`, they **must not** emit another identical intent.
- Watchtower component `process-hygiene` already covers daemon loops; this guard covers **reasoning
  loops** (new failure class).
- Future: wire guard into `src/orchestration/adaptive-steps.ts` `--resume` flow and into
  `src/session/session-autostart.ts` pipeline as soft WARN.

## Alternatives Considered

- Heuristic-only codemod fix (rejected: fragile, file-specific)
- External LLM-based loop detector (rejected: adds latency/cost, violates local-first ADR-0017)

## Verification

- `npx vitest run tests/unit/orchestrator-loop-guard.test.ts` → 5/5 pass
- `npx tsc --noEmit` → 0 errors
- `npm run watchtower:health` → 102/104 PASS (unchanged)
