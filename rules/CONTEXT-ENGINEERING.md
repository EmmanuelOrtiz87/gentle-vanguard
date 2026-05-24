# Context Engineering Standards

**Version:** 1.3.0 **Last updated:** 2026-05-23 **Applies to:** All AI agent interactions,
CLAUDE.md, AGENTS.md, skill definitions, conversation management

---

## 1. Purpose

Context Engineering is the discipline of structuring, maintaining, and governing the information
that shapes how AI coding agents behave. This document defines standards to ensure consistent,
high-quality agent output across sessions and contributors.

Based on industry research (2026): teams practicing context engineering see 2-3x sustained ROI from
AI coding tools vs. teams that only use raw prompting.

---

## 2. Context Hierarchy

```
Level 1 — Platform Guardrails     (model provider, ~1% token budget)
Level 2 — System Instructions     (CLAUDE.md, .clinerules, ~3% token budget)
Level 3 — Repository Context      (AGENTS.md, rules/, config/, ~10% token budget)
Level 4 — Session Context         (engram, startup-summary, ~5% token budget)
Level 5 — Task Context            (current prompt, files, ~80% token budget)
```

### Optimization Rules

1. **Levels 1-4 should consume ≤ 20%** of the total context window
2. **Level 3 (repository context) MUST be machine-readable** — structured, scannable, not prose
3. **Level 4 MUST be auto-restored** via engram at session start
4. **No duplication** across levels — each fact lives in exactly one place

---

## 3. Context File Requirements

### 3.1 AGENTS.md (Tool-Agnostic Bootstrap)

- MUST exist at `docs/AGENTS.md`
- Contains: tool detection, startup sequence, routing, break glass
- MUST NOT contain project-specific code standards (those go in `rules/`)
- Max 200 lines (enforced: current ~172)
- Referenced by ALL tool-specific configs (CLAUDE.md, .clinerules, .cursorrules)

### 3.2 CLAUDE.md / .clinerules / .cursorrules (Tool-Specific)

- MUST reference `docs/AGENTS.md` as primary entry point
- MUST NOT duplicate content from AGENTS.md (use `(see docs/AGENTS.md)`)
- Contains: model selection, tool permissions, environment-specific overrides
- Max 100 lines (enforced: current ~97)

### 3.3 Rules Directory (`rules/`)

- Each rule file covers ONE domain (testing, security, performance, etc.)
- MUST have a clear version and last-updated date
- MUST reference related rules (not duplicate them)
- MUST use consistent heading structure for AI-scanability
- Max 200 lines per rule file

### 3.4 Config Directory (`config/`)

- Source of truth for ALL configurable values
- Rules reference configs; configs do NOT reference rules
- MUST be valid JSON with `version` and `description` fields

---

## 4. Conversation History Management

### 4.1 Compaction Policy

Conversation history grows append-only and MUST be managed to prevent context overflow:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `strategy` | sliding-window | Keep recent N turns complete, summarize older |
| `maxTurns` | 10 | Maximum full turns retained in context |
| `pruneToolResults` | true | Remove large tool outputs from old turns |
| `threshold` | 8000 chars | Approximate trigger for compaction activation |
| `summarize` | false | Turn on for models with summarization capability |

Config source: `opencode.json#compaction`, `config/context-efficiency.json#compactionPolicy`

### 4.2 Sliding Window Behavior

- Turns 1-N (oldest): Summarized or pruned to essential info only
- Turns N-9 to N (recent): Full fidelity
- Tool outputs > 500 chars from turns > 5: Pruned to `[result: {summary}]`
- User messages: Always retained in full
- System prompt: Always retained in full (compressed per section 3)

### 4.3 Input Token Budget Guard

Enforced via `config/context-efficiency.json#tokenAutopilot.inputGuard`:
- `softThresholdPct (70%)`: Log WARN + suggest compaction
- `hardThresholdPct (90%)`: BLOCK new tool calls, force compaction before proceeding

---

## 5. Pre-Processing Caching

### 5.1 Trigger Cache

The `pre-process-input.ps1` hook uses a SHA256-based cache to avoid re-scanning all
SKILL.md files and auto-delegation.json on every invocation:

| File | Lines Scanned Per Invocation | Cache Effect |
|------|------|------|
| SKILL.md (x132) | ~19,730 lines total | Scanned only on first call or file change |
| auto-delegation.json | ~1,805 lines | Loaded entirely only on first call or file change |

Cache location: `.session/preprocess-trigger-cache.json`
Invalidation: File timestamp changes to any SKILL.md or auto-delegation.json

### 5.2 When Cache Cannot Be Used

- First invocation in a fresh clone (no cache exists)
- After `git pull` or skill installation (timestamps change)
- If `DisableSkillFileFallback` switch is used

---

## 6. Context Budget (Updated)

| Artifact | Target | Max | Notes |
|----------|--------|-----|-------|
| AGENTS.md | 150 lines | 200 | Core bootstrap only |
| CLAUDE.md | 60 lines | 100 | Tool-specific (compressed from 220) |
| Per rule file | 120 lines | 200 | One domain per file |
| SKILL.md body | 200 tokens | 250 | Excluding frontmatter (compressed) |
| Per config JSON | 80 lines | 150 | Split into sub-configs |
| Start-up output | 8 lines | 12 | Peak block per startup |
| Conversation turns | 10 turns | 15 | Sliding window max |
| Pre-process cache | — | 50KB | JSON cache file size limit |

---

## 7. Context Efficiency Practices

### 7.1 Front-Load Critical Constraints

Put the most important rules FIRST in every file:

```
Line 1-5:   Identity ("You are X")
Line 6-15:  Critical constraints (security, blocking rules)
Line 16-30: Core behavior (how to respond, format)
After 30:   Reference material, details, examples
```

### 7.2 Use Tables, Not Prose

AI agents scan tables more reliably than paragraphs:

```markdown
| Rule                  | Severity | Action       |
| --------------------- | -------- | ------------ |
| No secrets in prompts | CRITICAL | Block commit |
| Tests required        | HIGH     | Block merge  |
```

### 7.3 Eliminate Duplication

- Every fact appears in EXACTLY ONE place
- Use `(see path/to/file.md#section)` for cross-references
- Never inline-config-values in markdown (reference `config/file.json` instead)

### 7.4 Version Pinning

- Every context file has a `Last updated: YYYY-MM-DD` line
- Agent checks date at session start and reports staleness
- Files older than 90 days trigger a review prompt

### 7.5 Token Notification Reduction

- Per-turn token notifications disabled (config: `showAfterEachResponse: false`)
- Token summary shown every 5 turns (`turnInterval: 5`)
- Full report on session close only (`showOnClose: true`)
- On-demand via `token-usage-auto.ps1` manual invocation

### 7.6 Output Token Optimization

- Response profile enforces: max 200 tokens for non-code responses
- Tool outputs piped through `Select-Object -First 30` / `head -50`
- Code blocks limited to relevant lines only
- Config: `CLAUDE.md#Response-Profile`, `opencode.json#agent.orchestrator.options.maxTokens`

### 7.7 Pre-Compact Hook Compression

| Parameter | Value | Effect |
|-----------|-------|--------|
| CompressionRatio | 0.60 | 40% context reduction before compaction |
| Handoff retention | Anchored content saved to Engram | No loss of critical state |

Config: `scripts/utilities/pre-compact-hook.ps1`, `scripts/utilities/handoff-compress.ps1`

### 7.8 Behavior Prompts Optimization

- `config/behavior-prompts.json` compressed: 186 → 74 lines (−60%)
- Removed decorative fields: `vibe`, `emoji`, `communication_style`
- Prompts condensed to essential instructions only
- Applies to subagent task delegation (SDD agents)

### 7.9 Inter-Agent Communication Optimization

| Optimization | Before | After | Savings |
|-------------|--------|-------|---------|
| INTER-AGENT-COMMUNICATION.md | 167 lines | 57 lines | −66% |
| JSON schema in docs | Full verbose examples | Reference to orchestrator.json | Eliminated duplication |
| Circuit breaker doc | Full pattern + state table | Condensed to config reference | Eliminated duplication |
| Subagent delegation rule | Not defined | Send minimal context in prompt | Prevents context duplication |

Config: `rules/INTER-AGENT-COMMUNICATION.md` v1.1.0, `CLAUDE.md#Core-Rules` rule 9

### 7.10 Subagent Task Context Budget

When delegating via `task` tool, the prompt sent to subagents MUST follow:
- System context: Only task-relevant information (not full history)
- Files: Only files needed for the task (max 3 unless required)
- Previous turns: Summarized if referenced, never full raw text
- Target: subagent prompt < 1000 tokens unless complex task

---

## 8. Staleness Detection

- `Last updated` date in every context file
- Agent checks during Phase B (startup)
- Files >90 days → flag as `[STALE]`
- Stale files → read and propose update before proceeding
- Date format: `YYYY-MM-DD` (ISO 8601)

---

## 9. References

| Resource | Path |
|----------|------|
| NORMATIVES (index) | `rules/NORMATIVES.md` (120 lines) |
| NORMATIVAS-ARCHITECTURE | `rules/NORMATIVAS-ARCHITECTURE.md` |
| NORMATIVAS-CONFIG | `rules/NORMATIVAS-CONFIG.md` |
| NORMATIVAS-DEVOPS | `rules/NORMATIVAS-DEVOPS.md` |
| NORMATIVAS-DOCS | `rules/NORMATIVAS-DOCS.md` |
| NORMATIVAS-ENFORCEMENT | `rules/NORMATIVAS-ENFORCEMENT.md` |
| NORMATIVAS-GIT | `rules/NORMATIVAS-GIT.md` |
| AI Normatives | `rules/AI-NORMATIVES.md` |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| AGENTS.md | `docs/AGENTS.md` |
| Break Glass | `docs/AGENTS.md#break-glass` |
| Orchestrator Config | `config/orchestrator.json` |
| Context Efficiency | `config/context-efficiency.json` |
| Compaction Config | `opencode.json#compaction` |
| Pre-process Caching | `scripts/utilities/pre-process-input.ps1` |
| Pre-Compact Hook | `scripts/utilities/pre-compact-hook.ps1` |
| Behavior Prompts | `config/behavior-prompts.json` (74 lines) |
| Quick Commands | `docs/QUICK-COMMANDS.md` |
| Response Profile | `CLAUDE.md#Response-Profile` |

---

_Version: 1.2.0 — 2026-05-23 — Status: ACTIVE_
