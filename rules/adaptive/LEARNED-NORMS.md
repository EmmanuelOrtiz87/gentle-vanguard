# Learned Norms (Autonomous)

Auto-maintained by auto-norm-learner.ps1 — last run: 2026-06-16 16:02

## DOC Norms

| ID | Norm | Confidence | Source | Date |
|----|------|------------|--------|------|
| DOC-001 | Documentation Standards | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |

## LEARN Norms

| ID | Norm | Confidence | Source | Date |
|----|------|------------|--------|------|
| LEARN-001 | MUST produce structured, actionable output. | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-002 | Performance Standards | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-003 | Tools Configuration | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-004 | REQUIRED is    triggered unconditionally. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-005 | never committed - Single source of truth: collector. | medium | NORMATIVAS-CODE-QUALITY.md | 2026-06-16 |
| LEARN-006 | Should Be` syntax (use `Should -Be` for Pester 5. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-007 | never concatenation) - [ ] No `Invoke-Expression` on untrusted data - [ ] No sensitive data in logs or error messages - [ ] Dependencies checked for known CVEs  ### 3. | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-008 | should NOT change (configs, APIs, tests of other features) 5. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-009 | should leave the project better than it was found. | medium | CONTINUOUS-IMPROVEMENT.md | 2026-06-16 |
| LEARN-010 | 3. Review Checklist (L3+) | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-011 | MUST set `timeout-minutes`. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-012 | must maintain valid references to other scripts, configurations, and documentation. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-013 | Never log secrets with `set -x` or PowerShell's `-Verbose` on secret-manipulating steps. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-014 | MUST be valid JSON with `version` and `description` fields  ---  ## 4. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-015 | Never inline-config-values in markdown (reference `config/file. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-016 | Testing Standards | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-017 | must pass reference validation:  ```bash pwsh -NoProfile -File scripts/utilities/validate-cross-references. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-018 | Never use `--no-verify` without GOV authorization  ---  ## Security Standards  ### Mandatory Checks  1. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-019 | should leave the agent slightly better than it found it. | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-020 | MUST be auto-restored** via engram at session start 4. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-021 | PowerShell Coding Standards | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-022 | must call `scripts/utilities/token-guard. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-023 | 3. Context File Requirements | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-024 | 2. Improvement Cycles | medium | CONTINUOUS-IMPROVEMENT.md | 2026-06-16 |
| LEARN-025 | must run on all platforms - PowerShell 7. | medium | NORMATIVAS-ARCHITECTURE.md | 2026-06-16 |
| LEARN-026 | REQUIRED — always use param() block with types param(     [string]$Input,           # string params: always typed     [switch]$Verbose,         # flags: use [switch] not [bool]     [ValidateSet('a','b')]    # enums: use ValidateSet     [string]$Mode = 'a'       # defaults: in param block, not body ) ```  Rules:  - **No positional parameters without explicit `[Parameter(Position=N)]`** in public-facing scripts. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-027 | required                               / / Legal        / Compliance, regulatory                         / `openrouter/moonshot/kimi-k2. | medium | PER-PHASE-MODEL-ROUTING.md | 2026-06-16 |
| LEARN-028 | Always retained in full - System prompt: Always retained in full (compressed per section 3)  ### 4. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-029 | Code Quality Standards | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-030 | required **High**: Action required within 24 hours **Medium**: Action required within 1 week **Low**: Action required within 1 month  ---  ## Document Status  **Version**: 1. | medium | NORMATIVES.md | 2026-06-16 |
| LEARN-031 | must be validated 5. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-032 | MUST be annotated:  ```powershell # AI-generated — reviewed by <reviewer> on <date> ```  ### 5. | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-033 | never for blocking gates. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-034 | must have `[CmdletBinding()]` 2. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-035 | ALWAYS use Write-SafeHook (redacts secrets) if (Get-Command Write-SafeHook -EA SilentlyContinue) {     Write-SafeHook "message" -Color Green } else {     Write-Host "message" -ForegroundColor Green }  # Machine-readable output: ConvertTo-Json or structured objects via pipeline $result / ConvertTo-Json -Depth 5 ```  Rules:  - **No `Write-Host` of environment variables, tokens, or API keys** — ever. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-036 | required (`-Feature <name>`, alphanumeric, no spaces) - Gates between phases: each produces `gate-<phase>. | medium | NORMATIVAS-WORKFLOW.md | 2026-06-16 |
| LEARN-037 | MUST use `release-automation. | medium | NORMATIVAS-WORKFLOW.md | 2026-06-16 |
| LEARN-038 | MUST reference `docs/AGENTS. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-039 | must be verifiable 3. | medium | CONTINUOUS-IMPROVEMENT.md | 2026-06-16 |
| LEARN-040 | Change Log Format (`.local/auto-contribution-log.md`): ```markdown | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-041 | always - **Implementation**: T1 for complex, T2 for simple - **Verification/testing**: T2 for test generation, T3 for running/parsing - **Code review**: T1 for security/architecture review, T2 for style  ---  ## 7. | medium | AI-MODEL-SELECTION.md | 2026-06-16 |
| LEARN-042 | Never leave it broken             / / Workaround used more than once              / Convert it to a permanent fix in the script/config    / / Config path resolves incorrectly            / Fix path resolution in the source script              / / Step skipped because it's inconvenient      / DO NOT skip — fix the root cause instead              / / Normative exists but agent didn't follow it / Note the gap, update the normative or add enforcement /  ### 13. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-043 | 5. AI-Generated Code Rules | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-044 | NEVER commit secrets to Git. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-045 | must be reversible** — keep a change log 3. | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-046 | Should -Be $expected $value / Should -Not -BeNullOrEmpty $array / Should -Contain 'item' $string / Should -Match 'pattern'  # WRONG (Pester 3. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-047 | 4. Conversation History Management | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-048 | Never use `permissions: write-all`**. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-049 | never embed in code. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-050 | ALWAYS activate BA/EXPLORE first — NO confidence gate, NO    exceptions 2. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-051 | required for all secret access    - Authorization: RBAC per role (admin, operator, application, auditor)    - Just-in-Time: Secrets retrieved on-demand, never pre-distributed    - Session timeout: 60 minutes idle → automatic revocation  3. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-052 | MUST use the recommended model tier:  - **BA/SAD/GOV/LEGAL**: `kimi-k2. | medium | PER-PHASE-MODEL-ROUTING.md | 2026-06-16 |
| LEARN-053 | Always validate file paths before `Test-Path` / `Get-Content`              / Path traversal      / / Never expand environment variables from external config without sanitizing / Injection           / / Never store credentials in scripts — use `config/owner-auth. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-054 | always fails with X error"    / Fix the script, add Known Issues section / Read → Validate → Edit → Validate → Engram     / / "We keep typing the same commands"        / Create a new skill or script             / Check existing → Create → Register → Engram    / / "The AGENTS. | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-055 | 7. Context Efficiency Practices | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-056 | Never call `Invoke-Expression` on user input                               / Code injection      / / Never call `[System. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-057 | must be    flagged, not followed 4. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-058 | MUST be before any response 2. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-059 | Required Patterns  1. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-060 | MUST pass PSScriptAnalyzer with **zero errors**. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-061 | MUST include:  - `version` field - `description` field - Comments via `_comment` field (JSON5 not supported)  ---  ## Git Workflow Standards  ### Branch Strategy  - `main` - Production-ready code only - `develop` - Integration branch - `feature/*` - Individual features - `fix/*` - Bug fixes - `docs/*` - Documentation changes  ### Commit Standards  - Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`, `perf:` - Keep commits atomic (one logical change) - Always run `agent-verify. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-062 | Must not break existing structure         / / Create new rule under `rules/`       / Must not contradict existing rules        / / Fix bug in `scripts/utilities/`      / Must pass `validate-configs. | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-063 | Never hardcode secrets in code or configs - [ ] Retrieve secrets from vault at runtime only - [ ] Never log secrets (redact in logs) - [ ] Implement secret rotation hooks - [ ] Enable audit logging for all accesses - [ ] Document data classification (PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED) - [ ] MFA required for sensitive secrets - [ ] Secure key distribution (pull-based, never push) - [ ] Implement breach response procedures - [ ] Zero-trust access model (verify every request)  ### Commands  ```powershell # Create secret (stored encrypted in vault) gv secret create --name API_TOKEN --type api-keys --value <token>  # Retrieve secret (logged to audit trail) gv secret get --name API_TOKEN  # Rotate secret (automated, zero-downtime) gv secret rotate --name API_TOKEN  # Audit compliance gv secret validate-compliance gv secret audit-report --type [access/rotation/violations]  # Breach response (immediate revocation) gv secret breach-response --compromised-secret API_TOKEN --reason "leaked in logs" ```  **Linked Policies**: `rules/NORMATIVAS-GDPR. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-064 | must fail if multilingual routing matrix has mismatches. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-065 | MUST NOT skip EXPLORE/SPEC phases. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-066 | Appendix B: Normatives Violations | medium | NORMATIVES.md | 2026-06-16 |
| LEARN-067 | MUST have a clear version and last-updated date - MUST reference related rules (not duplicate them) - MUST use consistent heading structure for AI-scanability - Max 200 lines per rule file  ### 3. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-068 | should run on ALL pushes to protected branches. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-069 | MUST exist at `docs/AGENTS. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-070 | MUST be classified:  / Severity          / Label       / Meaning                                    / Action                  / / ----------------- / ----------- / ------------------------------------------ / ----------------------- / / 🔴 **Critical**   / `[CRIT]`    / Bug, security hole, data loss              / Block merge — MUST fix  / / 🟡 **Warning**    / `[WARN]`    / Style violation, missing docs, minor perf  / SHOULD fix before merge / / 🔵 **Suggestion** / `[SUGGEST]` / Optional improvement, alternative approach / MAY fix, no block       /  ### Critical findings that ALWAYS block merge:  - Security vulnerability (any OWASP Top 10) - Broken functionality (logic error, wrong behavior) - Data loss risk - Hardcoded secrets - PII exposure - Test suite broken  ---  ## 5. | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-071 | always use named params. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-072 | must exist in `. | medium | NORMATIVAS-OPS-DEVOPS.md | 2026-06-16 |
| LEARN-073 | 6. Configuration per Tool | medium | AI-MODEL-SELECTION.md | 2026-06-16 |
| LEARN-074 | Required Documentation  1. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-075 | Required scope                            / / ------------------------ / ----------------------------------------- / / Read code                / `contents: read` (default)                / / Create releases          / `contents: write`                         / / Comment on PRs           / `pull-requests: write`                    / / Upload packages          / `packages: write`                         / / Write checks/annotations / `checks: write`                           / / Read secrets             / No special scope — use `secrets. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-076 | Should Be $expected ```  ### Coverage Requirements  - **Critical scripts**: >80% code coverage - **Utility scripts**: >70% code coverage - **All new code**: Must have tests before merge  ### Test Tags  - `CI` - Run on every PR - `Slow` - Tests taking >1 second - `Feature` - Run daily, not on PR  ### Testing Policy Source  Canonical testing configuration: `config/testing-policy. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-077 | MUST re-process each new user message before responding. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-078 | Canonical Lightweight Workflows | medium | DELEGATION-RULES.md | 2026-06-16 |
| LEARN-079 | must declare `pnpm >=11. | medium | NORMATIVAS-SECURITY-COMPLIANCE.md | 2026-06-16 |
| LEARN-080 | always `<REDACTED>` 2. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-081 | MUST comply with enterprise-grade secrets management policies. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-082 | required  If a skill is not found locally → respond: _"Trigger detected for [skill]. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-083 | MUST have)  ```yaml name: Descriptive Name  # 1. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-084 | MUST include a UTC comment AND the local timezone (GMT-3) equivalent:  ```yaml schedule:   - cron: '30 16 * * 0' # Weekly Sunday at 13:30 GMT-3 (16:30 UTC) ```  ---  ## 6. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-085 | required for infra changes             / / GOV          / Compliance, security, audit                    / `openrouter/moonshot/kimi-k2. | medium | PER-PHASE-MODEL-ROUTING.md | 2026-06-16 |
| LEARN-086 | MUST begin with a documentation block:  ```powershell # script-name. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-087 | should consume ≤ 20%** of the total context window 2. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-088 | MUST NOT contain project-specific code standards (those go in `rules/`) - Max 200 lines (enforced: current ~172) - Referenced by ALL tool-specific configs (CLAUDE. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-089 | required for P1/P2 within 48h; blameless, action items tracked  ## Optimization Stack (Source: NORMATIVA-OPTIMIZATION-STACK. | medium | NORMATIVAS-OPS-DEVOPS.md | 2026-06-16 |
| LEARN-090 | must not be skipped; pre-commit validation is mandatory  ---  ## 7. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-091 | MUST use the first user message as input. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-092 | Required For                                 / Reviewers           / Blocks Merge / / ---------------------------- / -------------------------------------------- / ------------------- / ------------ / / **L1 — Self Review**         / Every commit                                 / Author              / No           / / **L2 — Light Review**        / `fix/*`, `docs/*`, `chore/*`                 / 1 peer              / Yes          / / **L3 — Full Review**         / `feature/*`, `refactor/*`                    / 2 peers             / Yes          / / **L4 — Security Review**     / Auth, crypto, secrets, payment               / 1 security + 1 peer / Yes          / / **L5 — Architecture Review** / Cross-cutting, new modules, breaking changes / 1 senior + 1 peer   / Yes          /  ---  ## 3. | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-093 | must have    trigger coverage in all three languages in `config/auto-delegation. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-094 | 4. Improvement Proposal Process | medium | CONTINUOUS-IMPROVEMENT.md | 2026-06-16 |
| LEARN-095 | Reference Management & Deprecation Policy | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-096 | MUST follow these rules; they are NOT optional guidelines. | medium | DELEGATION-RULES.md | 2026-06-16 |
| LEARN-097 | Always Check in AI Code  - [ ] Dependencies exist and are correct versions - [ ] Error paths are handled (not just happy path) - [ ] No mock data or test fixtures leaked to production - [ ] No synthetic examples or placeholder text - [ ] Configuration is environment-aware (not hardcoded)  ---  ## 6. | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-098 | never hardcode absolute paths ```  ---  ## 7. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-099 | must be validated (no broken links) - Use tables for structured data - All docs in English, user communication in Spanish - Max 3 heading levels deep for readability  ### SKILL. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-100 | must pass before commit: `health-check. | medium | NORMATIVAS-SECURITY-COMPLIANCE.md | 2026-06-16 |
| LEARN-101 | MUST have timeout; default 30s external, 15s internal - Circuit breaker: 3 consecutive failures → open (30s cooldown) → half-open (1 probe) → closed  ## Fallback Strategy (Source: NORMATIVAS-FALLBACK-STRATEGY. | medium | NORMATIVAS-OPS-DEVOPS.md | 2026-06-16 |
| LEARN-102 | Must not remove user-authored content     / / Add/modify `TODO:` comments          / Must be actionable                        /  ## Forbidden Self-Modifications (Requires External Approval)  / Action                                             / Reason                 / / -------------------------------------------------- / ---------------------- / / Delete or modify `CLAUDE. | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-103 | MUST include both UTC and GMT-3 mapping. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-104 | should we change? - Action items with owners  ---  ## 3. | medium | INCIDENT-RESPONSE.md | 2026-06-16 |
| LEARN-105 | Never use `$ErrorActionPreference = 'SilentlyContinue'`** at script scope. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-106 | required        / HIGH     / Block merge  / ```  ### 7. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-107 | 5. Post-Mortem Template: ```markdown | medium | INCIDENT-RESPONSE.md | 2026-06-16 |
| LEARN-108 | Always `exit 1`** (not `throw`) when a script encounters a fatal condition; hooks and CI read   exit codes. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-109 | MUST follow routing defined in `config/auto-delegation. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-110 | Always verify balanced quotes/braces/brackets before tool calls - No trailing commas; must end with `}` or `]` - `jq` for JSON manipulation in scripts; `ConvertFrom-Json` with `-Depth 10` for complex objects  ## Reporting & Metrics (Source: NORMATIVAS-REPORTING. | medium | NORMATIVAS-CODE-QUALITY.md | 2026-06-16 |
| LEARN-111 | must have frontmatter YAML 3. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-112 | Prohibido usar `!` en TypeScript (regla `no-non-null-assertion: error`). | medium | HAND-WRITTEN-NORMS.md | 2026-06-16 |
| LEARN-113 | always resolve repo root from script location $scriptDir = Split-Path -Parent $MyInvocation. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-114 | Appendix A: Normatives Checklist | medium | NORMATIVES.md | 2026-06-16 |
| LEARN-115 | MUST be structured:  ```markdown ## Review Summary  **Files reviewed**: <count> **Severity**: <critical/warning/suggestion count> **Verdict**: Approve / Changes Requested / Blocked  ### 🔴 Critical  / File          / Line / Issue / Recommendation / / ------------- / ---- / ----- / -------------- / / path/file. | medium | CODE-REVIEW-STANDARDS.md | 2026-06-16 |
| LEARN-116 | Must register in `. | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-117 | must be addressed in the same sprint. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-118 | MUST include the following controls:  1. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-119 | always interpreted in UTC. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-120 | must complete in <2s for interactive use - Use `-ProgressAction SilentlyContinue` for non-interactive - Cache results when possible (e. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-121 | MUST be machine-readable** — structured, scannable, not prose 3. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-122 | MUST either delegate or explicitly tell the user why delegation would be unsafe or wasteful for this exact case. | medium | DELEGATION-RULES.md | 2026-06-16 |
| LEARN-123 | MUST fix before proceeding) - Critical - Rollback required (security/compliance)  ---  ## References  / Resource                     / Path                                      / / ---------------------------- / ----------------------------------------- / / AI Normatives                / `rules/AI-NORMATIVES. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-124 | Work Routing Ladder | medium | DELEGATION-RULES.md | 2026-06-16 |
| LEARN-125 | required keys, script paths, root file declarations. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-126 | never string concatenation $path = Join-Path $repoRoot 'scripts\utilities\gv. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-127 | required     # 3. | medium | CI-HARDENING-STANDARDS.md | 2026-06-16 |
| LEARN-128 | MUST run:  ```powershell pwsh -File scripts/utilities/agent-verify. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-129 | Always check `$LASTEXITCODE`** after calling external executables. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-130 | required before task completion - Escalation path: agent -> escalateOnFailure -> orchestrator - Session lifecycle: autostart -> work -> verify -> persist -> close  ---  ## Tools Configuration  ### Required Tools  - **PowerShell** 7. | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-131 | MUST NOT duplicate content from AGENTS. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-132 | Git Workflow Standards | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-133 | must NOT** duplicate mapping tables — they reference the canonical config only. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-134 | MUST be managed to prevent context overflow:  / Parameter          / Value          / Description                                      / / ------------------ / -------------- / ------------------------------------------------ / / `strategy`         / sliding-window / Keep recent N turns complete, summarize older    / / `maxTurns`         / 10             / Maximum full turns retained in context           / / `pruneToolResults` / true           / Remove large tool outputs from old turns         / / `threshold`        / 8000 chars     / Approximate trigger for compaction activation    / / `summarize`        / false          / Turn on for models with summarization capability /  Config source: `opencode. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-135 | 3. Specific Incident Playbooks | medium | INCIDENT-RESPONSE.md | 2026-06-16 |
| LEARN-136 | should I fix this?" — just fix it and report what was done  Violation: leaving a known bug unfixed because the user didn't explicitly ask is a **CRITICAL** non-compliance. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-137 | required for each exclusion):  / Rule                                   / Reason                                              / / -------------------------------------- / --------------------------------------------------- / / `PSAvoidUsingWriteHost`                / Output scripts intentionally write to console       / / `PSUseDeclaredVarsMoreThanAssignments` / PowerShell scoping produces false positives         / / `PSAvoidGlobalVars`                    / Framework-level scripts need module-scope variables / / `PSReviewUnusedParameter`              / Hook and CLI parameters may be optional by design   /  Any new exclusion must be added to **both** the CI workflow and this document with justification. | medium | POWERSHELL-STANDARDS.md | 2026-06-16 |
| LEARN-138 | MUST follow:  - System context: Only task-relevant information (not full history) - Files: Only files needed for the task (max 3 unless required) - Previous turns: Summarized if referenced, never full raw text - Target: subagent prompt < 1000 tokens unless complex task  ---  ## 8. | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-139 | REQUIRED  → BA → sdd-lifecycle        └─ NO_TRIGGER_MATCH    → default agent              └─ confidence < 40 → BA clarification                    └─ unresolved → GOV review ```  ---  ## 14. | medium | AI-NORMATIVES.md | 2026-06-16 |
| LEARN-140 | always validate before committing 2. | medium | AUTO-CONTRIBUTION.md | 2026-06-16 |
| LEARN-141 | Security Standards | medium | DEVELOPMENT-STANDARDS.md | 2026-06-16 |
| LEARN-142 | 5. Pre-Processing Caching | medium | CONTEXT-ENGINEERING.md | 2026-06-16 |
| LEARN-143 | required (no orphan jobs) - `-Synthesize` for cohesive output; logs in `. | medium | NORMATIVAS-OPS-DEVOPS.md | 2026-06-16 |

## Statistics

- Total norms: 144
- New norms: 0
- Updated norms: 0
- Promoted norms: 0
- Pruned stale norms: 0
- Last trigger: session-start
