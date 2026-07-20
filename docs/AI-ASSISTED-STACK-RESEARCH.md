# AI-Assisted Software Engineering Stack: Research Report

> Compiled: 2026-07-14 | Scope: Production-grade AI-assisted dev framework Sources: Vercel
> Eval-Driven Dev, Microsoft Azure Agent Patterns, Anthropic Cookbook, BCMS SDD Guide 2026,
> Codebridge Multi-Agent Orchestration 2026, evaldriven.org, DuckDuckGo search synthesis,
> Gentle-Vanguard source analysis

---

## Table of Contents

1. [Top 10 Recommendations for Improving an AI-Assisted Dev Stack](#1-top-10-recommendations)
2. [5 Common Anti-Patterns to Avoid](#2-5-common-anti-patterns)
3. [3 Emerging Trends Worth Adopting Early](#3-3-emerging-trends)
4. [Specific Configuration Recommendations for Gentle-Vanguard](#4-gentle-vanguard-recommendations)

---

## 1. Top 10 Recommendations for Improving an AI-Assisted Dev Stack

### 1.1 Adopt Spec-Driven Development (SDD) with EARS Notation

**What**: Move from free-form prompting to structured, version-controlled specifications as the
primary artifact. Code becomes a generated output from specs, not the source of truth.

**Why**: SDD directly solves the "vibe coding" failure mode where AI agents produce plausible code
that drifts from intent as projects scale. With EARS (Easy Approach to Requirements Syntax), specs
become AI-parseable while remaining human-reviewable. Early adopters report 3-10x higher first-pass
success rates on non-trivial tasks (GitHub, AWS, 2026).

**How**:

- Store specs in `specs/` directory alongside code, version-controlled
- Use EARS five patterns for all acceptance criteria:
  `The [system] shall [action] [when/while/where/if] [condition]`
- Implement a 4-phase SDD cycle: Specify -> Plan -> Tasks -> Implement, each with human checkpoint
- Always edit the spec FIRST when requirements change, then regenerate code

**For Gentle-Vanguard**: You already have `config/sdd-framework-mapping.json` with sophisticated
phase-to-agent mapping. Strengthen it by adding EARS-based acceptance criteria templates and making
`check-sdd-gate.ps1` enforced (currently `enforced: false` in quality-gates.json).

### 1.2 Implement Eval-Driven Development (EDD) with Tiered Evaluation Suites

**What**: Replace binary pass/fail testing for AI components with threshold-based evaluations across
three tiers: unit (code), integration (AI-assisted), and LLM-as-judge (subjective).

**Why**: Traditional TDD doesn't work for probabilistic AI systems. Outputs vary across runs,
models, and prompts. EDD defines success thresholds _before_ writing tests — "what score is good
enough?" Vercel reports this as foundational for v0's quality pipeline.

**How**:

- **Tier 1 (Smoke/Unit)**: Fast, cheap evals on every commit. Deterministic checks — regex, schema
  validation, keyword matching.
- **Tier 2 (Integration)**: On merge to develop. Uses a cheaper model (e.g., GPT-4o-mini) with
  temperature=0 and retry budget=3.
- **Tier 3 (E2E/LLM-as-Judge)**: Nightly and pre-release. Golden dataset with rubric-based scoring
  across dimensions (correctness, safety, format, latency, robustness).
- Tier by cost: smoke evals run on every push; full suite runs nightly.

**For Gentle-Vanguard**: Your `testing-policy.json` already defines this three-tier pyramid and even
has the right `retry_budget`, `judge_model`, and `acceptance_bands`. The missing piece is a unified
eval runner that wires `eval-gates.json` thresholds into CI and blocks pipelines when scores drop
below `minScore: 0.7-0.9`.

### 1.3 Multi-Agent Orchestration with Platform-Native Subagents + MCP/A2A

**What**: Use platform-native subagent orchestration for internal flows (simpler, lower latency,
built-in governance) and standardize external agent communication via MCP (Model Context Protocol)
for tools and A2A (Agent-to-Agent) for cross-platform messaging.

**Why**: Microsoft's Azure Architecture Center and the 2026 Codebridge guide converge on the same
pattern: avoid the complexity of full multi-agent mesh for internal flows. Platform-native
orchestration (like opencode's subagent mechanism) keeps coordination overhead low. MCP provides
enterprise-grade security/auth for tool access. A2A enables capability discovery via published
"agent cards."

**Patterns to implement**: | Pattern | Use Case | Coordination |
|---------|----------|-------------| | **Sequential** | Document generation pipeline | Agent A ->
Agent B -> Agent C | | **Concurrent** | Parallel compliance checks | Fan-out -> gather results | |
**Handoff** | Escalation (BA -> SAD -> DEV -> QA) | One agent delegates to another | | **Magentic**
| Self-organizing swarm | Agents discover and negotiate tasks |

**For Gentle-Vanguard**: Your model-router.json already has a sophisticated per-agent binding
(BA/SAD/DEV/QA/OPS/GOV/DOC/SESSION). Add explicit orchestration topology: define which patterns
(sequential, concurrent, handoff, magentic) apply to which SDD phases, and publish "agent cards" for
each subagent in a registry.

### 1.4 Persistent Memory with Conflict Resolution and Topic Key Upserts

**What**: Move beyond flat memory storage to a structured memory system with: (a) topic-key-based
upserts for evolving decisions, (b) automatic conflict detection with semantic judgment, (c) pinning
for critical context, (d) review lifecycle management.

**Why**: Engram's LOCOMO benchmark (80% recall) shows that structured memory with conflict
resolution dramatically outperforms flat key-value stores. The `topic_key` mechanism (from engram)
lets evolving topics like architecture decisions consolidate into a single observation that gets
updated, rather than creating hundreds of stale records.

**Best practices**:

- Use `topic_key` for all architectural decisions, policies, and conventions
- Call `mem_save` proactively after every significant decision, not just at session end
- Always check `judgment_required` in mem_save responses — resolve conflicts immediately
- Pin critical architectural decisions so they appear at top of memory context
- Set `scope: "project"` for code decisions, `scope: "personal"` for workflow preferences
- Run `mem_review` weekly to review observations past their decay interval

**For Gentle-Vanguard**: Your engram-policy.ps1 enforces engram at session start. Add a post-task
hook that auto-saves the completion summary with `topic_key: "session/<date>/<focus>"` and implement
a weekly `mem_review` to prune stale context.

### 1.5 Self-Healing CI/CD with Failure Classification and Tiered Retry

**What**: Build an AI-aware CI/CD pipeline that classifies failures (transient vs. permanent vs.
security), retries with exponential backoff + jitter, and auto-rollbacks with safe-branch
protection.

**Why**: The 2026 Microsoft pattern for self-healing CI/CD uses a three-phase loop: Observe (webhook
on failure) -> Analyze (classify error) -> Act (retry, rollback, or alert). This is especially
important for AI-assisted pipelines where flakiness comes from both infrastructure AND model
non-determinism.

**Components**:

- **Failure classifier**: regex-based pattern matching into transient/permanent/security buckets
- **Retry engine**: max 3 retries, 5s base delay, 2s jitter, exponential backoff
- **Auto-rollback**: automatic revert to last known good commit on permanent failure, safe-branch
  protection (main/master/develop require approval)
- **Alert routing**: transient -> warning, permanent -> error, security -> critical (with
  dashboard + audit channel notifications)

**For Gentle-Vanguard**: Your `ci-self-heal.json` already has an excellent retry/rollback/alerting
config with proper transient/security/permanent pattern classification. The gap is that this config
isn't wired into CI — it's just a config document. Implement `scripts/ci/ci-self-heal.ps1` that
reads this config, wraps your CI commands, and applies retry/rollback logic at runtime.

### 1.6 Per-Tool/Per-Agent Model Routing with Automatic Fallback

**What**: Bind specific models and temperatures to each agent/role, with automatic fallback when
quota is exhausted or model fails.

**Why**: Different tasks need different models — BA requires high-temperature reasoning (kimi-k2.6,
0.7), DEV requires low-temperature precision (glm-5, 0.15), QA requires critical hallucination
guards (0.1). Routing by agent role reduces cost by ~40% vs. using the same model for everything,
and fallback ensures pipeline resilience when premium models hit rate limits.

**Best practice pattern**:

```
BA: kimi-k2.6 @ 0.7 (exploration)
SAD: kimi-k2.6 @ 0.3 (architecture)
DEV: glm-5 @ 0.15 (code generation)
QA: glm-5 @ 0.1 (verification)
Fallback: opencode/big-pickle (free tier, auto-notify)
```

**For Gentle-Vanguard**: Your `model-router.json` is already state-of-the-art here — per-agent
bindings with temperature, rationale, and even big-pickle fallback with quota notifications. One
improvement: add circuit breaker metrics (5 failures -> OPEN state, 2 successes -> HALF_OPEN ->
CLOSED) and expose via dashboard `/api/health` component.

### 1.7 Distributed Tracing with Span-Based Observability for AI Agents

**What**: Instrument every AI agent call with OpenTelemetry-compatible spans: parent span
(session/request) -> child spans (subagent calls, tool invocations, LLM calls). Export to OTLP
collector or local JSONL.

**Why**: AI agent pipelines are inherently complex and non-deterministic. Without tracing, it's
impossible to debug why an agent took the wrong path, which sub-call consumed the most tokens, or
where latency spikes originate. The LangChain observability pattern uses 3 core constructs: traces
(sessions), spans (individual operations), and evaluations (quality scores on spans).

**Key metrics to capture**:

- Token cost per agent call (input + output + cached)
- Latency: p50/p95/p99 across all agent calls
- Error rate: structured (parse errors, tool failures) vs. unstructured (hallucination, drift)
- Subagent cascade depth: how many levels of delegation occurred
- Hallucination guard triggers: how often did safety checks fire?

**For Gentle-Vanguard**: You have `tracing-instrument.ts` with start/end/error actions, spans stored
in `.telemetry/spans/` and `.telemetry/traces/` as JSONL, OTLP export to `localhost:4318`. The gap
is dashboard visualization — implement a "Trace View" waterfall panel in `apps/web-dashboard` that
reads traces and renders them by parentSpanId.

### 1.8 LLM-as-Judge with Rubric-Based Evaluation and Human Sampling

**What**: Use a strong model (claude-sonnet-4, gemini-2.5-pro, etc.) to evaluate outputs against
structured rubrics, with 5% human review sampling for calibration.

**Why**: Vercel's eval-driven development philosophy and evaldriven.org's manifesto converge:
AI-generated outputs need evaluation beyond code tests. LLM-as-judge scales to subjective dimensions
(clarity, coherence, safety) that automated code checks can't assess. The rubric is the key —
without structured criteria, LLM-as-judge falls to model bias.

**Rubric template**:

```json
{
  "dimension": "correctness",
  "criteria": "Output matches spec acceptance criteria",
  "weights": {
    "exact_match": 1.0,
    "semantic_equivalence": 0.8,
    "minor_deviation": 0.5,
    "incorrect": 0.0
  }
}
```

**For Gentle-Vanguard**: Your `testing-policy.json` defines the right dimensions (correctness,
safety, format_compliance, latency_p95, robustness) and even has `human_review_sample_pct: 5`. The
missing implementation is the actual eval runner (`tests/e2e/llm-judge-runner.ts`) and the golden
dataset (`tests/e2e/golden-dataset.json`).

### 1.9 Multi-Tool Configuration Parity and Portable Profiles

**What**: Maintain synchronized configurations across OpenCode, Cline, Cursor, Windsurf, and Claude
Code, with a shared config schema and tool-specific adapters.

**Why**: Teams don't all use the same AI coding tool. Each tool has different config locations and
capabilities — OpenCode uses `opencode.json`, Cursor uses `.cursorrules`, Cline uses `.clinerules`,
Windsurf uses `.windsurf/rules.json`, Claude Code uses `CLAUDE.md`. Without a sync mechanism,
configs drift, and developers get inconsistent behavior across tools.

**Pattern**: Shared repo-level file (`.ai-config/tool-shared.json`) with tool-specific adapters that
transform it to each tool's format. Validate all configs with `validate-tool-configs.ps1` in
pre-commit.

**For Gentle-Vanguard**: You already have per-tool config files in `config/tool-*.json` and a
`validate-tool-configs.ps1` script. The missing piece is: (1) a shared schema that all tool configs
derive from, (2) a CI check that ensures all tool configs are in sync, (3) a generation script that
updates each tool config from the shared schema.

### 1.10 AI-Specific Security Governance with Prompt Injection Prevention and Policy-as-Code

**What**: Implement security controls specifically for AI agent pipelines: prompt injection
detection at network level, least-privilege scope for agent tool access, secrets scanning with
AI-aware patterns, and policy-as-code for agent behavior.

**Why**: AI agents introduce new attack surfaces — prompt injection (OWASP Top 10 for LLMs #1), tool
misuse (agents can execute commands/access data that humans wouldn't), and data exfiltration via
model outputs. Microsoft's 2026 guidance recommends: (1) network-level prompt injection protection
via Global Secure Access, (2) least-privilege MCP tool authorization, (3) published agent cards with
explicit capability declarations.

**Controls to implement**:

- **Pre-commit**: Secretlint + TruffleHog on staged files
- **CI**: Gitleaks + Trivy vulnerability scanning
- **Pre-push**: npm audit with moderate+ severity blocking
- **Runtime**: Hallucination guard (critical for QA agent), circuit breaker for tool calls
- **Governance**: RBAC policy for which agents can access which tools/data
- **Audit**: Full audit trail of all agent actions and tool invocations

**For Gentle-Vanguard**: You have most of these: `secretlint`, `trufflehog`, `hallucinationGuard`
per agent, `rbac-policy.json`, `security-orchestrator.ts`. The gaps: (1) prompt injection detection
isn't wired into the pre-process-input pipeline, (2) there's no policy-as-code check that runs
before agent delegation, (3) the audit pipeline doesn't capture tool invocation payloads.

---

## 2. 5 Common Anti-Patterns to Avoid

### 2.1 The "Vibe Coding" Trap (Specs After Code)

**Anti-pattern**: Jumping straight to prompting without writing specs, treating AI output as a first
draft, and iterating via "debugging the output."

**Why it fails**: Without a spec as the source of truth, every regeneration starts from scratch. The
AI has no fixed target to aim at. Context degrades across iterations because each message adds to
the prompt but doesn't refine the goal. Drift accumulates silently — the code works differently by
the 10th prompt than the 1st, and no one knows which version was correct.

**Fix**: Always write the spec first (SDD phase 1). Store it in `specs/` in the repo. When
requirements change, edit the spec before regenerating code. Treat code as a build artifact from the
spec, not the other way around.

**Gentle-Vanguard status**: You have the SDD mapping but your AGENTS.md doesn't enforce spec-first
workflow. Make `spec-first` an explicit session rule.

### 2.2 Single-Model-for-All (No Agent Role Differentiation)

**Anti-pattern**: Using the same model with the same temperature for all tasks — BA exploration, DEV
coding, QA verification.

**Why it fails**: A model optimized for code generation (low temp, high precision) is terrible at
creative exploration (needs high temp, broad context). The same model doing both verification and
implementation creates confirmation bias — it "sees" its own mistakes as correct. You also pay
premium-tier prices for trivial tasks.

**Fix**: Route by role. BA/SAD -> high-temperature reasoning models (Kimi, Claude Sonnet). DEV/QA ->
low-temperature precision models (GLM-5, GPT-4o). OPS/GOV -> critical-precision models. Use a
fallback chain for resilience.

**Gentle-Vanguard status**: Already done correctly in `model-router.json`. Don't regress on this
when adding new agents.

### 2.3 Flat Memory with No Conflict Resolution (Memory Sprawl)

**Anti-pattern**: Saving every observation to memory without topic-key deduplication or conflict
resolution, resulting in thousands of unlinked observations that the AI can't effectively search.

**Why it fails**: The agent's memory recall degrades linearly with clutter. Without topic_key
upserts, a single architecture decision spawns 10-30 separate observations over a project. Without
conflict resolution, the agent gets contradictory context (e.g., "we use JWT" vs. "we switched to
OAuth") with no way to know which is current.

**Fix**: Use `topic_key` for all evolving topics. Designate one observation per topic as "source of
truth." Always check `judgment_required` on `mem_save` and resolve conflicts immediately with
`mem_judge`. Pin critical decisions. Run `mem_review` bi-weekly.

**Gentle-Vanguard status**: Enforcing engram at session start is good. But there's no `topic_key`
convention, no `mem_review` schedule, and no guidance for resolution. Document these in AGENTS.md.

### 2.4 All-Evals-on-Every-Commit (Cost Explosion)

**Anti-pattern**: Running the full evaluation suite (including LLM-as-judge with expensive models)
on every git commit.

**Why it fails**: LLM-as-judge evaluations cost $0.50-$2.00 per call. A full eval suite with 50
scenarios at $1/scenario = $50 per commit. At 10 commits/day, that's $500/day. The team disables
evals because they're too slow, or the CI bill becomes unsustainable.

**Fix**: Tier by cost and frequency: | Tier | Example Cost | Frequency | Model |
|------|-------------|-----------|-------| | Smoke (code checks) | ~$0 | Every commit | None
(deterministic) | | Unit (AI-assisted) | ~$0.01 | Every PR | gpt-4o-mini | | Integration | ~$0.10 |
Merge to develop | Claude Haiku | | E2E (LLM-as-Judge) | ~$1.00 | Nightly & pre-release | Claude
Sonnet 4 |

**Gentle-Vanguard status**: `testing-policy.json` defines the right tiered pyramid but doesn't
specify cost budgets per tier. Add `max_daily_cost` fields.

### 2.5 Orphaned Tool Configs (Multi-Tool Drift)

**Anti-pattern**: Maintaining OpenCode, Cursor, Cline, Windsurf, and Claude Code configs
independently, each diverging over time.

**Why it fails**: A project with 5 tools has 5+ configs to update when changing model preferences,
adding hooks, or updating rules. Teams using different tools get inconsistent AI behavior. Config
drift leads to subtle failures (e.g., OpenCode loads the right agent but Cursor falls back to
defaults).

**Fix**: One shared schema + tool-specific generators. A `config/tool-profiles/shared-schema.json`
as the source of truth, with `scripts/generate-tool-configs.ps1` that regenerates each tool's
config. Validate all tool configs in CI with `config-sync-check`.

**Gentle-Vanguard status**: You have per-tool configs (`tool-opencode.json`,
`tool-claude-code.json`, etc.) and a validator. But there's no shared schema or generation script.
Build `config/tool-profiles/shared-schema.json` and a generator.

---

## 3. 3 Emerging Trends Worth Adopting Early

### 3.1 Agent-to-Agent (A2A) Protocol for Cross-Platform Agent Mesh

**What**: The Linux Foundation's A2A protocol (2025-2026) defines a standard for agents to discover
each other's capabilities (via "agent cards"), negotiate tasks, and exchange artifacts. It's the
HTTP of agent communication.

**Why adopt now**: Early adopters get first-mover advantage on interoperability. A2A will become the
standard for cross-platform agent communication (similar to how MCP became the standard for tool
access). Adopting now means your agents can talk to agents from other platforms (e.g., a Cursor
agent delegating to a Claude Code subagent).

**How to start**: Define "agent cards" for each of your agents in `config/agent-cards/`. Each card
declares: identity, capabilities, input/output schemas, rate limits, security requirements. Use
A2A's task/artifact model for long-running operations. Publish cards in a registry.

**For Gentle-Vanguard**: Add `config/agent-cards/` with cards for BA, SAD, DEV, QA, OPS, GOV, DOC,
SESSION. Each card should include the model binding, max context, supported patterns (handoff,
sequential, concurrent), and security scope (tools it can access, data it can read/write).

### 3.2 Spec-as-Code with AI-Native DSLs (EARS, Gherkin, OpenAPI)

**What**: Moving from natural-language specs to machine-parseable specification DSLs that AI agents
can read, validate, AND generate. EARS for requirements, Gherkin for acceptance criteria, OpenAPI
for API contracts, AsyncAPI for event-driven contracts.

**Why adopt now**: The 2026 SDD tooling ecosystem (GitHub Spec Kit, AWS Kiro, OpenSpec, BMAD) all
converge on structured specs. Tools like GitHub Spec Kit can automatically generate implementation
tasks from specs. This isn't "future" — it's shipping now. Teams using EARS notation report 3x
higher first-pass success from AI agents (BCMS SDD Guide 2026).

**How to start**:

1. Write all requirements using EARS five patterns (universal, state-driven, event-driven, optional,
   unwanted)
2. Convert any existing ACs to Gherkin: `Given [context] When [action] Then [outcome]`
3. Use OpenAPI 3.1 spec-first for all API endpoints
4. Store specs in `specs/` alongside code
5. Run `spec-validator` in pre-commit to ensure spec format compliance

**For Gentle-Vanguard**: Your SDD mapping is impressive (cynefin, socratic, first-principles, etc.).
Add EARS templates and Gherkin scenarios to the spec output. Create
`specs/templates/ears-template.md` and `specs/templates/gherkin-template.feature`.

### 3.3 Hallucination-Aware CI/CD with Predictive Safety Gates

**What**: CI/CD that proactively scans AI-generated code for hallucination patterns — APIs that
don't exist, libraries with wrong import paths, configurations that reference nonexistent services,
tests that test the wrong thing.

**Why adopt now**: As AI agents write more production code, hallucination is the #1 quality risk.
The 2026 OWASP LLM Top 10 lists "Sensitive Information Disclosure" and "Insecure Output Handling" as
critical vulnerabilities specific to AI-generated code. Predictive safety gates catch these before
they reach review.

**Patterns to detect**:

- **Non-existent API calls**: Compare function calls against known SDK documentation
- **Import path drift**: Validated against known package registries (npm, PyPI, NuGet)
- **Mock/test hallucinations**: Tests that import source functions that match against non-existent
  signatures
- **Config ghosts**: References to services/endpoints that don't exist in the infrastructure
- **Version hallucinations**: Package versions that don't exist or don't have the claimed API

**How to start**:

1. Build a local package index of all dependencies (from lockfile + package registries)
2. Add a pre-commit hook that scans changed files for hallucination patterns
3. In CI, run a "hallucination audit" that flags suspicious patterns as PR comments
4. Integrate with your existing `hallucinationGuard` configuration per agent

**For Gentle-Vanguard**: You already have `hallucinationGuard` levels per agent in
`model-router.json` (critical/medium/low). Extend this with an automated scanner
(`src/hallucination-scanner.ts`) that checks AI-generated code against your dependency index.

---

## 4. Gentle-Vanguard Specific Recommendations

Based on thorough analysis of your existing codebase, here are the highest-impact changes ordered by
effort/impact:

### Priority Matrix

| #   | Recommendation                                 | Effort | Impact   | Current State                                    |
| --- | ---------------------------------------------- | ------ | -------- | ------------------------------------------------ |
| 1   | Wire eval-gates.json into CI pipeline          | Medium | Critical | Config exists but not wired                      |
| 2   | Add shared tool config schema + generator      | Medium | High     | Per-tool configs exist but no sync               |
| 3   | Enforce spec-first workflow in AGENTS.md       | Low    | High     | SDD mapping exists but not enforced              |
| 4   | Implement trace waterfall in dashboard         | High   | Medium   | Tracing infra exists, visualization missing      |
| 5   | Add topic_key convention for engram            | Low    | High     | Engram used but no topic_key discipline          |
| 6   | Build hallucination scanner for generated code | High   | Critical | hallucinationGuard config exists, no runtime     |
| 7   | Implement self-heal CI wrapper script          | Medium | High     | ci-self-heal.json config exists, no runner       |
| 8   | Add prompt injection detection to pre-process  | Medium | Critical | pre-process-input.ps1 exists, no injection check |
| 9   | Create golden dataset for eval-driven tests    | Medium | Medium   | testing-policy.json references it, doesn't exist |
| 10  | Publish agent cards in config/agent-cards/     | Low    | Medium   | No agent cards exist                             |

### Detailed Config Changes

#### config/eval-gates.json — URGENT

This is the single highest-impact change. Your eval thresholds are defined but never enforced. Wire
them:

```json
{
  "version": "1.1",
  "enforcement": {
    "mechanism": "scripts/ci/enforce-eval-gates.ps1",
    "ciStep": "pre-merge",
    "blockOnFail": true,
    "notifyChannels": ["dashboard", "audit", "pr-comment"]
  }
}
```

Create `scripts/ci/enforce-eval-gates.ps1` that reads thresholds from this config, runs the eval
suite, and fails CI if scores are below `minScore`.

#### config/ci-self-heal.json — HIGH IMPACT

Your retry/rollback config is excellent but not wired. Create `scripts/ci/ci-self-heal-wrapper.ps1`:

```powershell
param([string]$CommandToRun)
$config = Get-Content 'config/ci-self-heal.json' | ConvertFrom-Json
# Parse output for transient/permanent/security patterns
# Apply retry logic with exponential backoff + jitter
# On permanent failure after maxRetries: auto-rollback on safe branches
# Alert dashboard via WS_PORT endpoint
```

#### config/agent-cards/ — MEDIUM IMPACT

Create per-agent cards following the A2A pattern. Example for DEV:

```json
{
  "agent": "DEV",
  "model": "glm-5",
  "temperature": 0.15,
  "hallucinationGuard": "high",
  "patterns": ["sequential", "handoff"],
  "canDelegateTo": ["QA"],
  "toolAccess": ["read_fs", "write_fs", "execute_command"],
  "maxContextTokens": 32000,
  "dataScope": "current_sprint",
  "auditLevel": "all_calls"
}
```

#### AGENTS.md — CRITICAL POLICY

Add to the existing file:

```markdown
## mandatory rules before generating code

1. **spec-first**: No code generation without a spec checked into `specs/`. The spec must include:
   - EARS acceptance criteria
   - Gherkin scenarios for edge cases
   - Architecture constraints (from config/architecture-rules.json)
2. **eval-gates**: Every PR must pass eval-gates with scores above thresholds in
   config/eval-gates.json
3. **engram-topic-key**: Every mem_save must use a topic_key following convention:
   `<domain>/<scope>/<name>`
4. **conflict-resolution**: Always check judgment_required after mem_save and resolve with mem_judge
```

#### .github/workflows/ — CI ENHANCEMENTS

Add to the existing CI workflow:

```yaml
# Eval gates step
- name: Eval Quality Gates
  run: pwsh scripts/ci/enforce-eval-gates.ps1
  env:
    MIN_SCORE: ${{ secrets.EVAL_MIN_SCORE || '0.7' }}
  if: github.event_name == 'pull_request'

# Self-healing wrapper around critical CI step
- name: TypeScript Check (with self-heal)
  run: pwsh scripts/ci/ci-self-heal-wrapper.ps1 -CommandToRun "pnpm typecheck"
  continue-on-error: ${{ env.CI_SELF_HEAL == 'true' }}

# Hallucination scan
- name: Hallucination Audit
  run: npx tsx src/hallucination-scanner.ts --diff-only
  continue-on-error: true
```

### Session Pipeline Enhancements

Your `config/session-autostart.config.json` has 30+ steps. Add these:

```json
{
  "id": "memory-review",
  "enabled": true,
  "script": "scripts/utilities/memory-review.ps1",
  "args": "--auto-prune --threshold-days 30",
  "lazy": true,
  "description": "Auto-prune stale memory observations past decay threshold"
},
{
  "id": "golden-dataset-verify",
  "enabled": false,
  "script": "src/eval-runner.ts",
  "args": "--suite smoke",
  "lazy": true,
  "description": "Run smoke eval tier against golden dataset on session start"
}
```

### Key Metrics Dashboard Additions

To your dashboard, add these AI-specific metrics tracks:

- **Hallucination Rate**: Percentage of code generations with detected hallucination patterns
- **First-Pass Success Rate**: Percentage of agent outputs that pass eval gates on first attempt
- **Spec Adherence Score**: How closely generated code matches spec acceptance criteria
- **Agent Cascade Depth**: Average depth of subagent delegation chains
- **Memory Hit Rate**: Percentage of mem_search calls that return relevant results

---

## Appendix: Quick Reference

### Recommended Config File Checklist

| File                                      | Purpose                         | Status            |
| ----------------------------------------- | ------------------------------- | ----------------- |
| `config/eval-gates.json`                  | Eval threshold enforcement      | Exists, not wired |
| `config/ci-self-heal.json`                | Self-healing retry/rollback     | Exists, not wired |
| `config/agent-cards/*.json`               | A2A agent capabilities          | Missing           |
| `config/tool-profiles/shared-schema.json` | Multi-tool config sync          | Missing           |
| `config/hallucination-patterns.json`      | Known hallucination patterns    | Missing           |
| `config/memory-topic-keys.json`           | engram topic_key conventions    | Missing           |
| `specs/templates/ears-template.md`        | EARS requirement templates      | Missing           |
| `tests/e2e/golden-dataset.json`           | Eval golden dataset             | Missing           |
| `scripts/ci/enforce-eval-gates.ps1`       | Eval gate CI enforcer           | Missing           |
| `scripts/ci/ci-self-heal-wrapper.ps1`     | Self-heal CI wrapper            | Missing           |
| `src/hallucination-scanner.ts`            | Runtime hallucination detection | Missing           |

### Recommended Script Orderings

**Pre-commit (order matters)**:

1. spec-format-check (validate spec structure)
2. json-lint (fast syntax check)
3. env-validate (check required vars)
4. secretlint (security fast-path)
5. tool-config-sync (validate tool configs)
6. hallucination-scan (check new code)
7. pre-commit-opencode-validation (compliance)

**CI (order matters)**:

1. Smoke evals (fast, deterministic)
2. Lint + TypeScript typecheck
3. Unit tests + coverage
4. Eval quality gates (block if below threshold)
5. Integration tests (with self-heal wrapper)
6. Security scan (gitleaks + trivy)
7. Build verification
8. LLM-as-Judge evals (nightly only)

---

_End of Report_
