# External Best Practices Research — 2026-08

> Curated external references that support (or informed) stack design decisions, mapped to what
> Gentle-Vanguard already implements. Purpose: theoretical backing for talks, workshops, proposals,
> and support — without claiming external validation that was not verified. Sources were reviewed on
> 2026-08-25.

## 1. SQLite as the observability backbone

**External**: "4 SQLite Tables Replaced My $200/mo AI Observability Stack" — a SQLite audit trail
logging every LLM call, routing decision and detection event replaces cloud observability SaaS
(dev.to/thestack_ai). "Show HN: A local-first memory store for LLM agents (SQLite)" praises modular
local components.

**In the stack**: Nexus (27 tables: traces, spans, tokens, routing, alerts, events, cache) plus the
OTel pipeline with Prometheus export. Same pattern, broader scope.

## 2. Local-first context indexing over maximal context

**External**: "We Cut 94% of AI Coding Tokens With a Local Code Index" — sending an index instead of
the whole repo to the model. "Using Local Coding Agents" (Raschka) documents fully local production
stacks.

**In the stack**: graphify/CodeGraph (AST graph, `query`/`explain` instead of re-reading files) and
the context-efficiency protocol in `docs/reference/`.

## 3. Token optimization: steer, then save

**External**: practitioner guidance says do not optimize prompts for fewer tokens — optimize them to
steer correctly ("A Practitioner's Guide to AI Coding Agent Quality & Token Optimization",
dev.to/webmaxru). "Token Reduction Strategies for AI Agents: 8 Techniques" (MindStudio) lists
semantic compression, capped thinking budgets, logs-to-SQLite (50–99% cuts). Elementor engineering:
model routing, prompt caching, lean tool surfaces.

**In the stack**: structural compression with lossless-only input mode, response cache (SHA256),
model router with SDD profiles (cheap/balanced/premium), token budget guard (daily 5M / per-session
3M), token-ingest consolidation into Nexus.

## 4. Skill auto-triggering via tuned descriptions

**External**: agentskills.io "Optimizing Skill Descriptions" — systematically test and tune skill
descriptions because they drive automatic triggering; Claude platform docs describe
metadata-budget-driven on-demand loading.

**In the stack**: `zcode-sync.ts --sync` filters the 12 critical skills to the 3 tools precisely
because metadata budgets degrade auto-trigger when exceeded; skill embeddings and watchtower
freshness checks keep the surface current.

## 5. Prefix/KV-cache-aware context ordering

**External**: context-optimization guidance recommends reordering stable content to the front of
context to maximize prefix/KV-cache hits, plus budget monitoring with thresholds.

**In the stack**: the slim AGENTS.md (low-context daily injection, full manual loaded on demand) is
the same principle applied to instruction delivery; the token budget guard provides threshold
monitoring. Explicit cache-order tuning of model-facing prompts is a possible future optimization —
not currently implemented; noted as a candidate, not a claim.

## 6. Empirical token-consumption research

**External**: "How Do Coding Agents Spend Your Money?" (OpenReview) — first empirical study
analyzing and predicting agent token consumption; CodeAgents (arXiv 2507.03254) — typed pseudocode
interactions for token-efficient multi-agent prompting.

**In the stack**: `token_transactions` (per message/agent) enables exactly this kind of local
empirical analysis; routing `success_rate` (migration 015) adds outcome correlation.

## Honest gaps (candidates, not implemented)

- Deliberate prompt reordering for prefix-cache hits (see §5).
- Systematic A/B testing harness for skill descriptions (§4) — embeddings freshness exists,
  description-accuracy testing does not.

## Sources

- [4 SQLite Tables Replaced My $200/mo AI Observability Stack](https://dev.to/thestack_ai/4-sqlite-tables-replaced-my-200mo-ai-observability-stack-47ap)
- [Show HN: local-first memory store for LLM agents](https://news.ycombinator.com/item?id=46262294)
- [Using Local Coding Agents — Sebastian Raschka](https://magazine.sebastianraschka.com/p/using-local-coding-agents)
- [We Cut 94% of AI Coding Tokens With a Local Code Index](https://www.youtube.com/watch?v=dRmWYHuIJxM)
- [Token Reduction Strategies for AI Agents — MindStudio](https://www.mindstudio.ai/blog/token-reduction-strategies-ai-agents-cut-costs)
- [Token Optimization Strategies — Elementor Engineers](https://medium.com/elementor-engineers/optimizing-token-usage-in-agent-based-assistants-ffd1822ece9c)
- [A Practitioner's Guide to Agent Quality & Token Optimization](https://dev.to/webmaxru/a-practitioners-guide-to-getting-more-value-out-of-ai-coding-agent-quality-token-optimization-3n7j)
- [Optimizing Skill Descriptions — agentskills.io](https://agentskills.io/skill-creation/optimizing-descriptions)
- [Agent Skills Overview — Claude Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [LLM Observability: A Developer's Guide — Dash0](https://www.dash0.com/knowledge/llm-observability-developers-guide)
- [How Do Coding Agents Spend Your Money? — OpenReview](https://openreview.net/forum?id=1bUeVB3fov)
- [CodeAgents: A Token-Efficient Framework — arXiv](https://arxiv.org/html/2507.03254v1)
