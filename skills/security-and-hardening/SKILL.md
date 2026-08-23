---
name: security-and-hardening
aliases: ["security-and-hardening"]
description: >
  Security and Hardening
triggers:
  - security and hardening
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.087Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\security-and-hardening\SKILL.md
  version: "1.0.0"
---

# Security and Hardening

## Overview

Treat every external input as hostile, every secret as sacred, every auth check as mandatory.
Security is a constraint on every line touching user data, auth, or external systems.

## Process: Threat Model First

1. **Map trust boundaries** — where does untrusted data cross into your system?
2. **Name the assets** — what's worth stealing or breaking?
3. **Run STRIDE** — see [references/threat-model.md](references/threat-model.md).
4. **Write abuse cases** next to use cases.

## The Three-Tier Boundary System

**Always Do:** Validate all external input; parameterize all DB queries; encode output (XSS
prevention); use HTTPS; hash passwords (bcrypt/scrypt/argon2); set security headers (CSP, HSTS,
X-Frame-Options, X-Content-Type-Options); use httpOnly+secure+sameSite cookies; run native package
audit before every release.

**Ask First (human approval):** New auth flows; storing PII/payment data; new external integrations;
changing CORS; file upload handlers; modifying rate limiting; granting elevated roles.

**Never Do:** Commit secrets to VCS; log sensitive data; trust client-side validation as a security
boundary; disable security headers for convenience; use `eval()`/`innerHTML` with user data; store
sessions in client-accessible storage; expose stack traces to users.

## Reference Links

| Topic                                              | Reference                                                            |
| -------------------------------------------------- | -------------------------------------------------------------------- |
| OWASP Top 10 prevention patterns                   | [references/owasp-patterns.md](references/owasp-patterns.md)         |
| Input validation (Zod schemas, file upload safety) | [references/input-validation.md](references/input-validation.md)     |
| Dependency audit triage & supply-chain hygiene     | [references/dependency-audit.md](references/dependency-audit.md)     |
| Rate limiting code examples                        | [references/rate-limiting.md](references/rate-limiting.md)           |
| Secrets management (.env, gitignore, rotation)     | [references/secrets-management.md](references/secrets-management.md) |
| LLM security (OWASP LLM Top 10)                    | [references/llm-security.md](references/llm-security.md)             |
| Full security checklist                            | [references/security-checklist.md](references/security-checklist.md) |
| Threat model reference table                       | [references/threat-model.md](references/threat-model.md)             |

## Red Flags

User input to DB/shell/DOM directly; secrets in source code; endpoints without auth; missing CORS or
wildcard origins; no rate limiting on auth endpoints; exposed stack traces; unmitigated critical
deps; SSRF (user-supplied URLs); LLM output fed into query/DOM/shell; secrets/PII in LLM context.

## Verification

- [ ] Native audit has no unmitigated critical/high findings
- [ ] No secrets in source code or git history
- [ ] All user input validated at system boundaries
- [ ] Auth on every protected endpoint
- [ ] Security headers present
- [ ] Error responses don't expose internals
- [ ] Rate limiting on auth endpoints
- [ ] No SSRF (server-side URL fetches allowlisted)
- [ ] LLM output validated and encoded before use

## Usage

Use **security-and-hardening** when a task matches its triggers (security and hardening).

Purpose: Security and Hardening

## Examples

**Input:** a task matching `security-and-hardening` triggers.
**Action:** apply the workflow described above.
**Expected result:** Security and Hardening
