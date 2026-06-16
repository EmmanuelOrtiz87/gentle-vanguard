# CODE QUALITY — Consolidated Normatives

**Source files:** CODIGO, QUALITY, ERROR-HANDLING, JSON-CONSTRUCTION, REPORTING, FEEDBACK

## Code Standards (Source: NORMATIVAS-CODIGO.md)
- Single Source of Truth: configs in JSON files, no hardcoding in scripts
- Idempotency: `Test-Path` before `New-Item`, `-ErrorAction SilentlyContinue` + explicit check
- Error handling: `try/catch` with `$Error[0].Exception`, no generic `trap`
- Logging: structured JSON via `Write-Log`, timestamps in ISO 8601
- Naming: PascalCase for PowerShell, kebab-case for files, snake_case for JSON keys

## Quality Standards (Source: NORMATIVAS-QUALITY.md)
- Testing First: every change needs tests, 80% min coverage, CI/CD enforced
- Code review: every PR requires approval; no merge with failing tests
- PSScriptAnalyzer: zero errors; custom ruleset at `.ps1xml`
- Pipeline: commit → build → test → security → deploy → monitor

## Error Handling (Source: NORMATIVAS-ERROR-HANDLING.md)
- Severity: CRITICAL(3) = block pipeline → HIGH(2) = block merge → MEDIUM(1) = warn → LOW(0) = log
- Central handler in `scripts/utilities/error-handler.ps1`
- Error categories: auth, config, dependency, execution, security, validation
- OWASP LLM06 (Excessive Agency): cascade timeout after 3 retries, escalate to orchestrator

## JSON Construction (Source: NORMATIVAS-JSON-CONSTRUCTION.md)
- Always verify balanced quotes/braces/brackets before tool calls
- No trailing commas; must end with `}` or `]`
- `jq` for JSON manipulation in scripts; `ConvertFrom-Json` with `-Depth 10` for complex objects

## Reporting & Metrics (Source: NORMATIVAS-REPORTING.md)
- LOCAL-FIRST: metrics live in `.runtime/metrics/`, never committed
- Single source of truth: collector.ps1 → `.runtime/metrics/consolidated.json`
- Dashboard HTML auto-refresh (30s); post-session metric generation
- Each snapshot: timestamp + session ID; retention: 90d for metrics

## Feedback Loop (Source: NORMATIVAS-FEEDBACK.md)
- Every action offers user rating (1-5); stored in `.session/feedback/feedback.jsonl`
- Post-session analysis: detect patterns with avg rating < 3, generate improvement proposals
- Suggest new normativas if same pattern appears 3+ times
