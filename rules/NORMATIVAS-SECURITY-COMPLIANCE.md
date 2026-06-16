# SECURITY & COMPLIANCE — Consolidated Normatives

**Source files:** AI-SAFETY, GDPR, SOC2, PNPM-SECURITY, CONFIG-SAFETY, SISTEMA-INTEGRIDAD, MCP-SERVER, ENFORCEMENT

## AI Safety (Source: NORMATIVAS-AI-SAFETY.md)
- OWASP LLM Top 10 mitigations: prompt injection (pre-process-input), insecure output (hallucination guards), excessive agency (escalation paths)
- NIST AI RMF: map, measure, manage, govern — enforced via security-policy.json
- Hallucination guard levels: critical/standard/minimal per agent tier

## GDPR Compliance (Source: NORMATIVAS-GDPR.md)
- Data minimization: collect only necessary data; purpose limitation; storage limitation (30d max)
- User rights: access/rectification/erasure via `privacy export-user-data` command
- Consent logging mandatory; DPIAs for any new data processing pipeline
- Breach notification within 72h

## SOC2 Compliance (Source: NORMATIVAS-SOC2.md)
- Trust criteria: CC (security), A (availability), PI (processing integrity), C (confidentiality), PR (privacy)
- CC1-CC7 controls: governance, access control, monitoring, risk assessment (quarterly)
- Audit trail: all agent actions logged with timestamp + session ID

## Dependency Security (Source: NORMATIVA-PNPM-SECURITY.md)
- pnpm only, `--ignore-scripts` always, no package-lock.json
- `engines` in package.json must declare `pnpm >=11.0.0`
- Approved commands: `pnpm install --ignore-scripts --frozen-lockfile`

## Config Safety (Source: NORMATIVAS-CONFIG-SAFETY.md)
- Tool configs: only official schema props allowed
- Project props go in `config/<tool>-project-settings.json`
- `systemPromptOptimization` centralized in `config/system-prompt-optimization.json`
- Auto-validation via `validate-tool-configs.ps1`

## System Integrity (Source: NORMATIVA-SISTEMA-INTEGRIDAD.md)
- Health check must pass before commit: `health-check.ps1 -Quiet`
- Optimization stack verified: `verify-optimization-stack.ps1`
- CodeGraph index < 7 days old; Engram backup post-session
- Zero secrets in repo (Gitleaks + Trivy), PSScriptAnalyzer zero errors

## MCP Server (Source: NORMATIVA-MCP-SERVER.md)
- `pnpm build:mcp` after any change to skill-server.ts, SKILL.md, or skill-registry.md
- All skills registered in `.atl/skill-registry.md`; backward compatibility for 1 version
- `health-check.ps1 -Component mcp` pre-merge

## Enforcement (Source: NORMATIVAS-ENFORCEMENT.md)
- Pre-response hook: input validation, token tracking, pre-compact (>15K tokens), SHA256 response cache (30min TTL)
- Auto-norm-enforcer.ps1 runs at session-start/close: directory structure, config drift, metric thresholds, cache health
- Secrets detection via regex patterns + Gitleaks; destructive commands blocked
