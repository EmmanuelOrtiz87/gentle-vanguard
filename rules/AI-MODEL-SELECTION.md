# AI Model Selection Policy

**Version:** 2.0.0 **Last updated:** 2026-07-31 **Applies to:** All AI agent invocations across all
supported tools

---

## 1. Principle

Different tasks require different model capabilities. Using a large expensive model for a simple
validation is wasteful. Using a small weak model for complex architecture is risky. This policy
defines which model to use for which task, based on capability requirements and cost optimization.
In the current environment the native available model is `opencode/big-pickle` (free tier, provider
`opencode`); the tier structure below is retained for when additional models become available
(openrouter/ollama/dify/lm-studio2).

---

## 2. Model Tier Definitions

| Tier                 | Model(s)                                      | Strengths                                     | Weaknesses                        | Cost/M Tokens |
| -------------------- | --------------------------------------------- | --------------------------------------------- | --------------------------------- | ------------- |
| **T1 — Heavy**       | opencode/big-pickle                           | Deep reasoning, architecture, code generation | Single model for all tasks        | $0 (free)     |
| **T2 — Medium**      | opencode/big-pickle                           | Balanced perf/cost, good for most tasks       | Less depth on complex reasoning   | $0 (free)     |
| **T3 — Light**       | opencode/big-pickle, ollama (llama3, qwen2.5) | Fast, cheap, private (local)                  | Limited context, weaker reasoning | $0-0.5        |
| **T4 — Specialized** | Fine-tuned models                             | Domain-specific excellence                    | Narrow applicability              | Varies        |

---

## 3. Task-to-Model Mapping

| Task Category                  | Recommended Tier | Rationale                                      |
| ------------------------------ | ---------------- | ---------------------------------------------- |
| **Architecture design**        | T1 — Heavy       | Requires deep reasoning and trade-off analysis |
| **SDD spec generation**        | T1 — Heavy       | Complex multi-step specification               |
| **Complex code generation**    | T1 — Heavy       | Multi-file, cross-cutting changes              |
| **Code review (security)**     | T1 — Heavy       | Needs thoroughness, misses are costly          |
| **Code review (style)**        | T2 — Medium      | Pattern matching, less depth needed            |
| **Bug fix (simple)**           | T2 — Medium      | Localized change                               |
| **Refactoring**                | T2 — Medium      | Pattern-based transformation                   |
| **Test generation**            | T2 — Medium      | Following existing test patterns               |
| **Config validation**          | T3 — Light       | Schema validation, no creativity needed        |
| **Linting pass**               | T3 — Light       | Rule-based, deterministic                      |
| **JSON/YAML formatting**       | T3 — Light       | Mechanical transformation                      |
| **Session summarization**      | T2 — Medium      | Summarization, moderate complexity             |
| **Engram memory search**       | T3 — Light       | Simple retrieval                               |
| **Git log analysis**           | T3 — Light       | Pattern matching                               |
| **Documentation generation**   | T2 — Medium      | Following templates                            |
| **PR description**             | T2 — Medium      | Structured format                              |
| **Learning / Norm extraction** | T2 — Medium      | Pattern recognition                            |
| **Release notes**              | T2 — Medium      | Structured summarization                       |

---

## 4. Model Selection Decision Tree

```
Is the task security-critical or architecture-defining?
  ├── YES → T1 (Heavy)
  └── NO  → Does the task require deep reasoning?
              ├── YES → T2 (Medium)
              └── NO  → Is the task purely mechanical/rule-based?
                          ├── YES → T3 (Light)
                          └── NO  → T2 (Medium)
```

---

## 5. Budget Allocation

| Tier | Daily Token Budget | Daily Cost Limit | When to Use           |
| ---- | ------------------ | ---------------- | --------------------- |
| T1   | 30,000             | $0.90            | < 20% of daily tokens |
| T2   | 100,000            | $0.50            | 50% of daily tokens   |
| T3   | 200,000            | $0.00 (local)    | 30% of daily tokens   |

### Session Budget Tracking

- Track actual spend in session metrics (input_tokens, output_tokens, estimated_cost_usd)
- Alert if T1 usage exceeds 30% of total tokens in a session
- Re-route to T2 if T1 budget exhausted
- Use `token-budget-guard.ps1` for enforcement

---

## 6. Configuration per Tool

### OpenCode (`opencode.json`)

```json
{
  "orchestrator": { "model": "opencode/big-pickle" },
  "sdd-explore": { "model": "opencode/big-pickle" },
  "sdd-design": { "model": "opencode/big-pickle" },
  "sdd-apply": { "model": "opencode/big-pickle" },
  "sdd-verify": { "model": "opencode/big-pickle" }
}
```

### General Guidelines

- **Orchestrator/routing decisions**: Use the native model (cheap, fast — just needs to route)
- **Exploration/analysis**: native model for simple queries
- **Design/architecture**: native model (deep reasoning)
- **Implementation**: native model
- **Verification/testing**: native model
- **Code review**: native model (thoroughness via temperature 0.1)

---

## 7. Model Change Protocol

When changing a model assignment:

1. Document the change in `config/orchestrator.json` or `opencode.json`
2. Run `gv check` to confirm routing works
3. Monitor token consumption for 3 sessions
4. Compare quality metrics (pass rate, rework rate)
5. Roll back if quality degrades or cost exceeds 2x budget

### Custom Provider Health

- Keep `model` and `small_model` aligned when switching OpenCode models. Internal calls such as
  compaction may use the small model path.
- Validate global custom providers with `npm run model:validate-provider` before relying on them.
- For LiteLLM providers that route to Bedrock, configure the proxy with
  `litellm_settings.modify_params: true`; OpenCode fallback can keep the stack alive, but it does
  not repair the upstream proxy.
- Do not clear an unhealthy model state until a fresh request succeeds or the proxy/config change is
  verified.

---

## 8. References

| Resource                | Path                                                          |
| ----------------------- | ------------------------------------------------------------- |
| Orchestrator Config     | `config/orchestrator.json`                                    |
| Agent Config (OpenCode) | `opencode.json`                                               |
| Provider Health Runbook | `docs/operations/procedures/MODEL-PROVIDER-HEALTH-RUNBOOK.md` |
| Token Budget Guard      | `src/telemetry/token-budget-guard.ts`                         |

<!-- REF-OBSOLETA: src/telemetry/token-budget-guard.ts no existe (ruta migrada o eliminada) -->

| Performance Normatives | `rules/NORMATIVAS-PERFORMANCE.md` | | Context Engineering |
`rules/CONTEXT-ENGINEERING.md` |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_
