# ADR-0023: Guardrails Defense-in-Depth — Llama Guard 3 + NeMo (F3.2)

**Status:** Accepted (2026-08-31)  
**Context:** F3.2 requires input/output moderation for LLM, RAG and agent tool-use. External
research (20.5k tokens via native `web-crawler` Jina+DDG+Bing) shows NeMo Guardrails + Llama Guard 3
as the production pair.

## Research Absorption (Native)

**Sources (via `src/web/web-crawler-cli.ts` + `src/research/research-trends-cli.ts`, no API key):**

- `docs.nvidia.com/nemo/guardrails/configure-guardrails/guardrail-catalog/third-party/llama-guard` —
  NeMo out-of-the-box Llama Guard for input/output moderation, Jailbreak Rail > self-check in
  testing, pipeline with two LLM tasks (Input Moderation + Output Moderation).
- `medium.com/data-science-collective/essential-guide-to-llm-guardrails-llama-guard-nemo` —
  Moderation Rails pipeline: Input Moderation (Jailbreak Rail), Output Moderation (SelfCheck), both
  framed as tasks for a well-aligned LLM.
- `aidefense.dev/posts/llm-guardrails-implementation/` — input validation, output filtering,
  monitoring, NeMo vs Guardrails AI vs Llama Guard comparison.

**Stack-native retrieval:** `20.572 → 20.572 tokens` via `jina-reader` fallback (dual-provider, zero
cost, local-first ADR-0017). No external runtime dependency.

## Decision

Implement `src/security/guardrails/` as **soft WARN first, hard block later** (like loop-guard
ADR-0022), defense-in-depth:

| Layer  | Rail                    | Model                             | When                        |
| ------ | ----------------------- | --------------------------------- | --------------------------- |
| Input  | Jailbreak Rail          | Llama Guard 3 (or heuristic stub) | Before LLM call             |
| Output | SelfCheck + Llama Guard | Same                              | After LLM call, before tool |
| Tool   | Allowlist + rate-limit  | NeMo Colang                       | Before `agent.invokeTool`   |

**Pipeline (NeMo Colang style):**

```
user_input → [Input Rail: Llama Guard 3] → LLM → [Output Rail: SelfCheck] → Tool → [Tool Rail: allowlist]
                                    ↓ fail → fallback human / safe completion
```

**Fallback:** `iteration cap` (like loop-guard) + `escalation to human` (Azure: "define fallback
behavior ... escalation to human").

## Alternatives Considered

- **Self-check only** (LLM asks itself "is this safe?") — rejected: NeMo testing shows Llama Guard
  significantly better.
- **External moderation API** (Perspective, OpenAI) — rejected: cost, latency, violates local-first.
- **Hard block from day 1** — rejected: breaks existing flows; soft WARN first, collect metrics,
  then harden.

## Implementation (This ADR)

- `src/security/guardrails/input-moderation.ts` — heuristic stub (100 patterns, <5ms) + pluggable
  `LlamaGuard` interface (future: `transformers.js` or API).
- `src/security/guardrails/output-moderation.ts` — `SelfCheck` + `LlamaGuard` stub, same interface.
- `config/guardrails.json` — blockedPatterns, allowlist, rate limits, `softWarn: true`.
- Wiring in `src/orchestration/agent-delegator.ts` as soft WARN (like `adaptive-steps` loop-guard) —
  never blocks pipeline initially.

## Verification

- `npx tsx src/security/guardrails/input-moderation.ts --test "Ignore previous instructions"` →
  `blocked:true`
- `npx tsc --noEmit` 0
- `npm run watchtower:health` 106/108 PASS (new guardrails component will be 109 checks after
  wiring)
- `npx tsx src/web/web-crawler-cli.ts health` → `jina-reader+ddg+bing` ok

## Consequences

- New component `guardrails` in watchtower (next: +3 checks → 111 checks, 26 comps).
- No latency/cost added in soft WARN mode — metrics only.
- Future: swap heuristic stub with `transformers.js` Llama Guard 3 quantized (local) or `Firecrawl`
  API when key available — interface already pluggable.

## References

- Azure AI Agent Design Patterns (ADR-0022): iteration caps + fallback (same pattern reused here).
- NeMo Guardrails Library Developer Guide: Llama-Guard Integration.
- Essential Guide to LLM Guardrails (Medium, 2026).
