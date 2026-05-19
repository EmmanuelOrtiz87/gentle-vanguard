# Context Engineering Standards

**Version:** 1.0.0 **Last updated:** 2026-05-14 **Applies to:** All AI agent interactions,
CLAUDE.md, AGENTS.md, skill definitions

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
- Max 250 lines
- Referenced by ALL tool-specific configs (CLAUDE.md, .clinerules, .cursorrules)

### 3.2 CLAUDE.md / .clinerules / .cursorrules (Tool-Specific)

- MUST reference `docs/AGENTS.md` as primary entry point
- MUST NOT duplicate content from AGENTS.md (use `(see docs/AGENTS.md)`)
- Contains: model selection, tool permissions, environment-specific overrides
- Max 100 lines each

### 3.3 Rules Directory (`rules/`)

- Each rule file covers ONE domain (testing, security, performance, etc.)
- MUST have a clear version and last-updated date
- MUST reference related rules (not duplicate them)
- MUST use consistent heading structure for AI-scanability
- Max 350 lines per rule file

### 3.4 Config Directory (`config/`)

- Source of truth for ALL configurable values
- Rules reference configs; configs do NOT reference rules
- MUST be valid JSON with `version` and `description` fields

---

## 4. Context Efficiency Practices

### 4.1 Front-Load Critical Constraints

Put the most important rules FIRST in every file:

```
Line 1-5:   Identity ("You are X")
Line 6-15:  Critical constraints (security, blocking rules)
Line 16-30: Core behavior (how to respond, format)
After 30:   Reference material, details, examples
```

### 4.2 Use Tables, Not Prose

AI agents scan tables more reliably than paragraphs:

```markdown
| Rule                  | Severity | Action       |
| --------------------- | -------- | ------------ |
| No secrets in prompts | CRITICAL | Block commit |
| Tests required        | HIGH     | Block merge  |
```

### 4.3 Eliminate Duplication

- Every fact appears in EXACTLY ONE place
- Use `(see path/to/file.md#section)` for cross-references
- Never inline-config-values in markdown (reference `config/file.json` instead)

### 4.4 Version Pinning

- Every context file has a `Last updated: YYYY-MM-DD` line
- Agent checks date at session start and reports staleness
- Files older than 90 days trigger a review prompt

---

## 5. Context Budget

| Artifact        | Target     | Max | Notes                    |
| --------------- | ---------- | --- | ------------------------ |
| AGENTS.md       | 200 lines  | 250 | Core bootstrap only      |
| CLAUDE.md       | 60 lines   | 100 | Tool-specific            |
| Per rule file   | 200 lines  | 350 | One domain per file      |
| SKILL.md body   | 400 tokens | 700 | Excluding frontmatter    |
| Per config JSON | 100 lines  | 200 | Split into sub-configs   |
| Start-up output | 10 lines   | 15  | Peak block per AGENTS.md |

---

## 6. Staleness Detection

- `Last updated` date in every context file
- Agent checks during Phase B (startup)
- Files >90 days → flag as `[STALE]`
- Stale files → read and propose update before proceeding
- Date format: `YYYY-MM-DD` (ISO 8601)

---

## 7. References

| Resource              | Path                             |
| --------------------- | -------------------------------- |
| AI Normatives         | `rules/AI-NORMATIVES.md`         |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| AGENTS.md             | `docs/AGENTS.md`                 |
| Break Glass           | `docs/AGENTS.md#break-glass`     |
| Orchestrator Config   | `config/orchestrator.json`       |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_
