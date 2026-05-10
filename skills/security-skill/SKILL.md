---
name: security-skill
description:
  'Trigger: "security", "authentication", "authorization", "vulnerability", "OWASP", "XSS", "SQL
  injection", "secrets". Use when reviewing code for security vulnerabilities, implementing auth, or
  setting up security practices.'
---

# Security Skill

## Activation Contract

Load this skill when the user asks to:

- Review code for security vulnerabilities
- Implement authentication or authorization
- Handle sensitive data or secrets
- Set up security practices (headers, rate limiting, CSP)
- Audit dependencies or run security scans
- Responds to triggers: "security", "authentication", "authorization", "vulnerability", "CVE",
  "OWASP", "XSS", "SQL injection", "secrets", "encryption"

## Hard Rules

1. **MUST** use parameterized queries or prepared statements — never string concatenation for SQL
2. **MUST** hash passwords with bcrypt or argon2
3. **MUST** encode output for context (HTML escape, URL encode, etc.)
4. **MUST** validate all external input on every entry point
5. **MUST** use httpOnly, secure, sameSite cookies for sessions
6. **MUST NOT** commit secrets, API keys, or credentials to version control
7. **MUST NOT** expose internal implementation details in error messages

## Decision Gates

| Context          | Action                                                                    | Reference                     |
| ---------------- | ------------------------------------------------------------------------- | ----------------------------- |
| Authentication   | Implement MFA, strong password hashing, rate limiting, session management | `references/checklists.md`    |
| Authorization    | Check per-request, RBAC, ownership validation                             | `references/checklists.md`    |
| Input validation | Validate type, length, range, format; use parameterized queries           | `references/code-examples.md` |
| Secrets          | Environment variables or vault — never in code                            | `references/checklists.md`    |
| Security headers | CSP, HSTS, X-Frame-Options via helmet or equivalent                       | `references/code-examples.md` |
| Dependency audit | Run `npm audit`, check for known CVEs                                     | `references/checklists.md`    |

## Execution Steps

1. **Identify scope** — What code/feature needs security review?
2. **Check authentication** — Are auth mechanisms secure? Password hashing? MFA? Session config?
3. **Check authorization** — Are permissions checked on every request? RBAC in place?
4. **Check input validation** — Every external input validated? SQL injection prevented?
5. **Check output encoding** — XSS prevented? Context-appropriate encoding?
6. **Check secrets management** — No secrets in code? Proper env var or vault usage?
7. **Check security headers** — CSP, HSTS, etc. properly configured?
8. **Check dependencies** — Run `npm audit`. Any known vulnerabilities?
9. **Apply fixes** — Use reference files for patterns and examples.
10. **Verify** — Run security scans if available. Check that fixes don't block valid usage.

## Output Contract

Return a structured security report:

```
## Security Review — {target}

### Findings
| Severity | Category | Description | File:Line |
|----------|----------|-------------|-----------|
| CRITICAL | {category} | {issue} | {path} |

### Status
- ✅ PASS — all checks pass
- ⚠️ WARNING — non-critical issues found
- ❌ FAIL — critical security issues

### Summary
- {N} findings total
- {N} critical, {N} warnings
- Recommended actions: {list}
```

## References

- `references/code-examples.md` — SQL injection, XSS, CSRF, secure headers, file uploads, rate
  limiting examples
- `references/checklists.md` — OWASP Top 10, auth checklist, secrets management, dependency audit,
  security checklist for new features
