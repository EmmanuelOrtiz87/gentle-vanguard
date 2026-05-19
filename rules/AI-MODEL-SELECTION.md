# AI Model Selection Policy

**Version:** 1.0.0 **Last updated:** 2026-05-14 **Applies to:** All AI agent invocations across all
supported tools

---

## 1. Principle

Different tasks require different model capabilities. Using a large expensive model for a simple
validation is wasteful. Using a small weak model for complex architecture is risky. This policy
defines which model to use for which task, based on capability requirements and cost optimization.

---

## 2. Model Tier Definitions

| Tier                 | Model(s)                         | Strengths                                     | Weaknesses                        | Cost/M Tokens |
| -------------------- | -------------------------------- | --------------------------------------------- | --------------------------------- | ------------- |
| **T1 — Heavy**       | GLM-5, Claude Sonnet 4, GPT-4o   | Deep reasoning, architecture, code generation | Expensive, slower                 | $10-30        |
| **T2 — Medium**      | GLM-4, Claude Haiku, GPT-4o-mini | Balanced perf/cost, good for most tasks       | Less depth on complex reasoning   | $1-5          |
| **T3 — Light**       | Qwen 3.6B+ (local), Llama 3 8B   | Fast, cheap, private (local)                  | Limited context, weaker reasoning | $0-0.5        |
| **T4 — Specialized** | Fine-tuned models                | Domain-specific excellence                    | Narrow applicability              | Varies        |

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
  "orchestrator": { "model": "openrouter/z-ai/glm-5" },
  "sdd-explore": { "model": "openrouter/qwen/qwen-3.6-plus" },
  "sdd-design": { "model": "openrouter/z-ai/glm-5" },
  "sdd-apply": { "model": "openrouter/z-ai/glm-5" },
  "sdd-verify": { "model": "openrouter/qwen/qwen-3.6-plus" }
}
```

### General Guidelines

- **Orchestrator/routing decisions**: Use T2 (cheap, fast — just needs to route)
- **Exploration/analysis**: T3 (local) for simple queries, T2 for complex
- **Design/architecture**: T1 (heavy) always
- **Implementation**: T1 for complex, T2 for simple
- **Verification/testing**: T2 for test generation, T3 for running/parsing
- **Code review**: T1 for security/architecture review, T2 for style

---

## 7. Model Change Protocol

When changing a model assignment:

1. Document the change in `config/orchestrator.json` or `opencode.json`
2. Run `gv verify` to confirm routing works
3. Monitor token consumption for 3 sessions
4. Compare quality metrics (pass rate, rework rate)
5. Roll back if quality degrades or cost exceeds 2x budget

---

## 8. References

| Resource                | Path                                                         |
| ----------------------- | ------------------------------------------------------------ |
| Orchestrator Config     | `config/orchestrator.json`                                   |
| Agent Config (OpenCode) | `opencode.json`                                              |
| Token Budget Guard      | `scripts/utilities/TELEMETRY-METRICS/token-budget-guard.ps1` |
| Performance Normatives  | `rules/NORMATIVAS-PERFORMANCE.md`                            |
| Context Engineering     | `rules/CONTEXT-ENGINEERING.md`                               |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_
