# Enforcement & Governance

**Version:** 2.0.0 **Last updated:** 2026-05-30 **Status:** ACTIVE

---

## Implementation Reference

This document references the actual enforcement scripts — not process boilerplate.

## Enforcement Layers

### 1. Pre-Response Hook (Every Turn) — `scripts/utilities/pre-process-input.ps1`

Runs **before every agent response**. Three sub-layers:

| Layer | What It Checks | Rules | Script Reference |
|-------|---------------|-------|------------------|
| **Input Validation** | Secrets in plain text, destructive commands, force push patterns, excessive length | SEC-001, OPS-001, GIT-001, PERF-001 | `pre-process-input.ps1` lines 12-44 |
| **Token Tracking** | Session token accumulation, context size | NORMATIVAS-PERFORMANCE.md | `pre-process-input.ps1` lines 46-56 |
| **Pre-Compact Hook** | Triggers context compaction when >15K tokens | CONTEXT-ENGINEERING.md | `pre-process-input.ps1` lines 80-91 |
| **Response Cache** | SHA256-based cache with 30min TTL, skips redundant processing | NORMATIVAS-PERFORMANCE.md | `pre-process-input.ps1` lines 58-78 |

### 2. Adaptive Enforcement — `scripts/adaptive/auto-norm-enforcer.ps1`

Runs at session-start, session-close, or on orchestrator demand.

| Check | Auto-Fix | Description |
|-------|----------|-------------|
| Directory structure | Yes | Creates missing `docs/` subdirectories |
| Documentation standards | No | Validates English-first content |
| Learned norms validation | Yes | Applies norms from `rules/adaptive/LEARNED-NORMS.md` |

### 3. Adaptive Learning — `scripts/adaptive/auto-norm-learner.ps1`

Runs at session-close or on demand. Queries Engram memory + session artifacts
to extract recurring patterns, creates/updates norms in `rules/adaptive/LEARNED-NORMS.md`.

| Source | What It Extracts |
|--------|-----------------|
| Engram memory (`mem_search`) | Session summaries, decisions, learnings |
| Session artifacts (`.session/`, `.local/session-artifacts/`) | Discoveries, key learnings, accomplishments |

### 4. Karpathy Enforcer — `scripts/adaptive/karpathy-enforcer.ps1`

Context-aware file analysis for code quality. Runs at pre-commit or code-review triggers.

### 5. Pre-Commit Hooks — `.lefthook.yml`

| Hook | What It Validates |
|------|------------------|
| `build:mcp-server` | MCP server compiles when skills change |
| `validate-readme` | README structure compliance |

### 6. Violation Audit Trail

All input violations are logged to `.session/input-violations.jsonl` (JSONL format):

```json
{"Timestamp":"...", "Rule":"SEC-001", "Severity":"block", "Message":"...", "InputPreview":"..."}
```

## Violation Handling

| Severity | Action | Example |
|----------|--------|---------|
| **block** | Log + notify — human review required | Plain-text secrets detected |
| **warn** | Log + notify — continues with warning | Destructive command pattern |
| **info** | Log only | Input exceeds recommended length |

## Quick Reference

| What | When | Script |
|------|------|--------|
| Input validation | Every turn | `scripts/utilities/pre-process-input.ps1` |
| Norm enforcement | Session start/close | `scripts/adaptive/auto-norm-enforcer.ps1` |
| Norm learning | Session close | `scripts/adaptive/auto-norm-learner.ps1` |
| Karpathy analysis | Pre-commit / code review | `scripts/adaptive/karpathy-enforcer.ps1` |
| README validation | Pre-commit | `hooks/validate-readme-hook.ps1` |

---

_Version: 2.0.0 — 2026-05-30 — Status: ACTIVE_
