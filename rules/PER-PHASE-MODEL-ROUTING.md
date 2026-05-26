# Per-Phase Model Routing

Version: 1.0.0 | Framework: Assign optimal AI models per SDD phase

## Purpose

Each SDD phase has different cognitive demands. Route each phase to the model best suited for its
task type — cheaper/faster models for exploration, stronger for implementation, strict for
verification.

## Phase-to-Model Mapping

| Phase        | Cognitive Demand                               | Recommended Model               | Rationale                                        |
| ------------ | ---------------------------------------------- | ------------------------------- | ------------------------------------------------ |
| BA (Explore) | Research, analysis, requirements gathering     | `openrouter/moonshot/kimi-k2.6` | Strong context understanding, good at synthesis  |
| SAD (Design) | Architecture, API contracts, sequence diagrams | `openrouter/moonshot/kimi-k2.6` | Strong reasoning for design decisions            |
| DEV (Apply)  | Code generation, implementation                | `openrouter/z-ai/glm-5`         | Strong code generation, high max tokens          |
| QA (Verify)  | Testing, validation, edge case analysis        | `openrouter/z-ai/glm-5`         | Strict mode, low temperature for reproducibility |
| DOC          | Documentation, guides, markdown                | `openrouter/qwen/qwen-3.6-plus` | Good prose, cost-effective                       |
| OPS          | CI/CD, infrastructure, deployments             | `openrouter/z-ai/glm-5`         | Precision required for infra changes             |
| GOV          | Compliance, security, audit                    | `openrouter/moonshot/kimi-k2.6` | Strong analytical reasoning                      |
| Session      | Session management, state tracking             | `openrouter/qwen/qwen-3.6-plus` | Lightweight, fast response                       |
| Premortem    | Risk analysis, stress testing                  | `openrouter/z-ai/glm-5`         | Systematic analysis                              |
| Finance      | Financial modeling                             | `openrouter/z-ai/glm-5`         | Precision required                               |
| Legal        | Compliance, regulatory                         | `openrouter/moonshot/kimi-k2.6` | Strong analytical reasoning                      |
| Marketing    | Copywriting, SEO                               | `openrouter/qwen/qwen-3.6-plus` | Good prose, cost-effective                       |
| Sales        | Pipeline management                            | `openrouter/qwen/qwen-3.6-plus` | Fast, efficient                                  |
| HR           | People processes                               | `openrouter/qwen/qwen-3.6-plus` | Fast, efficient                                  |

## Configuration

Model routing is configured in:

1. **`config/orchestrator.json#agent.<name>.model`** — per-agent model assignment (primary)
2. **`opencode.json#agent.<name>.model`** — OpenCode-specific overrides
3. **`config/model-routing.json`** — routing rules (if exists)

## Rules

### 1. Phase-Appropriate Model Selection (MUST)

Each SDD phase MUST use the recommended model tier:

- **BA/SAD/GOV/LEGAL**: `kimi-k2.6` (analytical/reasoning)
- **DEV/QA/OPS/FINANCE/PREMORTEM**: `glm-5` (precision/code)
- **DOC/MKT/SALES/HR/SESSION**: `qwen-3.6-plus` (cost-effective)

### 2. Temperature by Phase (MUST)

| Phase      | Temperature | Rationale                |
| ---------- | ----------- | ------------------------ |
| BA/Explore | 0.7         | Creative exploration     |
| SAD/Design | 0.3         | Focused design decisions |
| DEV/Apply  | 0.15        | Precise code generation  |
| QA/Verify  | 0.1         | Strict, deterministic    |
| All others | 0.3         | Balanced                 |

### 3. Override Protocol (SHOULD)

When deviating from the recommended model:

1. Document the override reason in the task
2. Prefer a model of equal or greater capability
3. Reset to default model at phase boundary

## Fallback Strategy

If the primary model is unavailable:

1. `glm-5` ← `kimi-k2.6` ← `qwen-3.6-plus` (descending capability)
2. If all remote models fail → `ollama` local fallback (if configured)
3. If all fail → session agent logs the error and stops
