# Per-Phase Model Routing

Version: 2.0.0 | Framework: Assign optimal AI models per SDD phase

## Purpose

Each SDD phase has different cognitive demands. Route each phase to the model best suited for its
task type — cheaper/faster models for exploration, stronger for implementation, strict for
verification. In the current environment the native available model is
`opencode/deepseek-v4-flash-free` (free tier); temperatures vary per phase to shape behavior.

## Phase-to-Model Mapping

| Phase        | Cognitive Demand                               | Recommended Model                     | Rationale                                        |
| ------------ | ---------------------------------------------- | ------------------------------------- | ------------------------------------------------ |
| BA (Explore) | Research, analysis, requirements gathering     | `opencode/deepseek-v4-flash-free`     | Strong context understanding, good at synthesis  |
| SAD (Design) | Architecture, API contracts, sequence diagrams | `opencode/deepseek-v4-flash-free`     | Strong reasoning for design decisions            |
| DEV (Apply)  | Code generation, implementation                | `opencode/deepseek-v4-flash-free`     | Strong code generation, high max tokens          |
| QA (Verify)  | Testing, validation, edge case analysis        | `opencode/deepseek-v4-flash-free`     | Strict mode, low temperature for reproducibility |
| DOC          | Documentation, guides, markdown                | `opencode/deepseek-v4-flash-free`     | Good prose, cost-effective                       |
| OPS          | CI/CD, infrastructure, deployments             | `opencode/deepseek-v4-flash-free`     | Precision required for infra changes             |
| GOV          | Compliance, security, audit                    | `opencode/deepseek-v4-flash-free`     | Strong analytical reasoning                      |
| Session      | Session management, state tracking             | `opencode/deepseek-v4-flash-free`     | Lightweight, fast response                       |
| Premortem    | Risk analysis, stress testing                  | `opencode/deepseek-v4-flash-free`     | Systematic analysis                              |
| Finance      | Financial modeling                             | `opencode/deepseek-v4-flash-free`     | Precision required                               |
| Legal        | Compliance, regulatory                         | `opencode/deepseek-v4-flash-free`     | Strong analytical reasoning                      |
| Marketing    | Copywriting, SEO                               | `opencode/deepseek-v4-flash-free`     | Good prose, cost-effective                       |
| Sales        | Pipeline management                            | `opencode/deepseek-v4-flash-free`     | Fast, efficient                                  |
| HR           | People processes                               | `opencode/deepseek-v4-flash-free`     | Fast, efficient                                  |

## Configuration

Model routing is configured in:

1. **`config/model-router.json#agentBindings.<NAME>.model`** — per-agent model assignment (primary)
2. **`opencode.json#agent.<name>.model`** — OpenCode-specific overrides
3. **`.opencode/agents/*.md`** — subagent definitions (front-matter `model:` takes precedence)
4. **`config/model-fallback.json`** — fallback chains per agent

## Rules

### 1. Phase-Appropriate Model Selection (MUST)

All phases MUST use the native available model `opencode/deepseek-v4-flash-free` (provider
`opencode`). If additional models become available, re-apply the tier mapping:

- **BA/SAD/GOV/LEGAL**: strong reasoning tier (analytical/reasoning)
- **DEV/QA/OPS/FINANCE/PREMORTEM**: precision/code tier
- **DOC/MKT/SALES/HR/SESSION**: cost-effective tier

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

1. `opencode/deepseek-v4-flash-free` ← `ollama/qwen2.5` ← `dify/qwen-plus` (local fallbacks)
2. If all models fail → session agent logs the error and stops
3. Agent type fallback: `general` first, then `explore` (integrated types, always available)
