# Engineering Norms (Best Practice)

These are hand-curated engineering best-practice norms derived from project conventions and
operational experience. They supplement the learned norms in LEARNED-NORMS.md.

## ENG Norms

| ID      | Norm                                                                                                                                                                                                           | Category   | Severity | Source                                              | Date       |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | -------- | --------------------------------------------------- | ---------- |
| ENG-001 | All TypeScript scripts MUST use named parameters (`[Parameter(Mandatory)]`, `[switch]`, `[string]`) instead of positional `$args`. This ensures self-documenting interfaces and prevents parameter-order bugs. | TypeScript | error    | src/tools/auto-norm-learner.ts, src/session-scoring.ts    | 2026-06-16 |
| ENG-002 | All file paths MUST be constructed with `Join-Path` rather than string concatenation. String concatenation produces broken paths on cross-platform runs and introduces path-traversal vulnerabilities.         | security   | error    | config/orchestrator.json, src/correction-capture.ts | 2026-06-16 |

<!-- REF-OBSOLETA: src/correction-capture.ts no existe (ruta migrada o eliminada) -->

| ENG-003 | Every script MUST call a scoring/metrics event on significant actions (corrections,
session events, errors) via `session-scoring.ps1 -Action record`. Without metrics there is no
feedback loop and no quality measurement. | observability | error | src/session-scoring.ts,
config/session-autostart.config.json | 2026-06-16 | | ENG-004 | When extracting text from markdown
table cells for programmatic use, always `-replace '\|', '/'` to avoid breaking pipe-delimited table
structure. Unescaped pipes in table cells corrupt the entire markdown table. | presentation |
warning | src/tools/auto-norm-learner.ts (line 293) | 2026-06-16 | | ENG-005 | All file-read operations
MUST guard with `Test-Path` before reading. A missing file should produce a clear log message, not a
cryptic null-reference or file-not-found exception. | robustness | error | src/session-scoring.ts
(line 23), src/tools/auto-norm-learner.ts (line 51) | 2026-06-16 | | ENG-006 | When using `-match`
operator with user-derived or file-derived strings, wrap the pattern with `[regex]::Escape()` to
prevent accidental regex metacharacter interpretation. Corollary: never pipe a joined string into
`ForEach-Object`; the joined string is a single value, not an array. | correctness | error |
src/tools/auto-norm-learner.ts (line 225) | 2026-06-16 | | ENG-007 | Every pipeline step in
`session-autostart.config.json` MUST have explicit `required: true` or `required: false`. Required
steps that fail abort the pipeline; optional steps that fail produce a warning and continue. Without
this flag the pipeline behavior is undefined on failure. | reliability | error |
config/session-autostart.config.json | 2026-06-16 | | ENG-008 | Cross-file references (script paths,
config paths) MUST be validated at startup by checking file existence. A dangling reference silently
degrades functionality and produces hard-to-diagnose failures later. | integrity | error |
config/hooks-config.json, config/orchestrator.json | 2026-06-16 | | ENG-009 | Correction captures
(via `correction-capture.ps1`) MUST log every detected correction to
`.session/corrections-log.jsonl` with timestamp, type, severity, and matching input. High-severity
corrections MUST trigger `auto-norm-learner.ps1` immediately. | feedback | error |
src/correction-capture.ts | 2026-06-16 |
<!-- REF-OBSOLETA: src/correction-capture.ts no existe (ruta migrada o eliminada) -->

| ENG-010 | All generated norms in LEARNED-NORMS.md MUST have unique IDs within each prefix series
(CORR-001, CORR-002, ...). Duplicate IDs corrupt the table parser and make norm lookup ambiguous.
Use `$UsedIDs` session-level tracking to prevent intra-run collisions. | data-integrity | error |
src/tools/auto-norm-learner.ts (function Get-NextNormID) | 2026-06-16 | | ENG-011 | Any script that writes
markdown tables MUST NOT truncate content to an arbitrary character limit (e.g., 120 chars).
Truncation produces unreadable, semantically broken output. Instead, escape problematic characters
(pipes, newlines) and keep the full content. | quality | error | src/tools/auto-norm-learner.ts (line 294)
| 2026-06-16 |
