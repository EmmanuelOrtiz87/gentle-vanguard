---
created: 2026-09-03 10:15:16
tags: [engram, architecture]
engram_id: 3645
type: architecture
---

# OWASP coverage elevated to 80% with output-encoding module

**What**: Elevated OWASP Agentic AI Top 10 coverage from 75% to 80% (6 full / 4 partial / 0 none) by adding a new `src/security/output-encoding.ts` module that provides context-aware output encoding/sanitization for unsafe downstream contexts (SQL, shell, HTML, htmlAttr, url, json). LLM05:2025 (Improper Output Handling) elevated from `partial` to `full` in `src/security/owasp/owasp-agentic-top10.ts`.

**Why**: Strict OWASP mode requires >= 80% coverage to pass. At 75% (5 full / 5 partial) strict mode failed, causing the watchtower to report a WARN and the governance facade to return `review` verdict for strict checks. The gap was "No explicit output encoding/sanitization for SQL/shell/HTML injection contexts."

**Where**: `src/security/output-encoding.ts` (new), `src/security/owasp/owasp-agentic-top10.ts` (LLM05 → full), `tests/unit/output-encoding.test.ts` (new, 8 tests), `tests/unit/owasp-agentic-top10.test.ts` (updated 75→80), `tests/unit/agent-governance-integration.test.ts` (updated strict OWASP now passes → allow).

**Learned**:
- The `edit` tool can report success but NOT persist to disk (cache artifact). Always verify edits with `read` after applying, especially when a subsequent `tsc`/test run shows the old content.
- `output-encoding.ts` is fail-closed, deterministic, no LLM. SQL escaping doubles single quotes (`''`), shell wraps in single quotes, HTML/attr entity-encodes, URL-encodes, JSON-escapes.
- Watchtower now reports `owasp coverage: PASS - coverage=80% (strict threshold 80%)`, PASS: 122 | WARN: 2 | FAIL: 0.
- Also fixed preexisting typecheck error in `src/orchestration/task-wrapper.ts`: duplicate `smartTask` export (re-export on line 32 conflicted with function declaration on line 78). Removed the redundant re-export, keeping only `getDelegatorStatus`.

---
*Imported from Engram on 2026-09-06*
