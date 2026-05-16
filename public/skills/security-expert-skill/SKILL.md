---
name: security-expert
description: >
  AI-powered security assistant for pre-commit validation, security audits, and secure coding.
  Trigger: "security", "vulnerability", "secrets", "auth", "jwt"
---

# Security Expert Skill

**Trigger Keywords:** security, secure, credentials, secrets, api-key, token, password, auth, jwt,
oauth, ssl, tls, https, csrf, xss, sqli, injection, vulnerability, exploit, cipher, encrypt,
decrypt, hash, signature, certificate, pem, jwt, bearer, basic-auth, cors, csrf, rate-limit,
sanitize, validate

## Overview

Security Expert is an AI-powered security assistant that provides:

- **Pre-commit validation** - Scans code for exposed secrets, vulnerabilities, and security issues
- **Interactive security reviews** - Generates detailed security audit reports
- **Real-time coding assistance** - Helps developers write secure code
- **Credential management** - Detects and helps remediate exposed secrets
- **Security best practices** - Guides implementation of secure patterns

## Activation Triggers

This skill activates when:

1. User commits code (`git commit`) - via pre-commit hook
2. User requests security review (`foundation security scan`, `foundation security audit`)
3. User asks about security topics
4. Code contains patterns matching security keywords

## Security Categories

### 1. Secrets & Credentials

- API keys, tokens, passwords in code
- Environment variables misconfiguration
- Secrets in Git history
- Hardcoded credentials
- Private keys (PEM, RSA, etc.)

### 2. Authentication & Authorization

- JWT implementation issues
- Session management
- Broken authentication
- Missing authorization checks
- Insecure password storage

### 3. Input Validation & Injection

- SQL Injection
- Cross-Site Scripting (XSS)
- Command Injection
- LDAP Injection
- XML Injection
- NoSQL Injection
- Path Traversal

### 4. API Security

- Missing authentication
- Missing rate limiting
- CORS misconfiguration
- Missing HTTPS
- Insecure direct object references
- Mass assignment

### 5. Data Protection

- Unencrypted sensitive data
- Weak encryption algorithms
- Improper key management
- Data exposure in logs
- Missing data masking

### 6. Dependencies

- Known CVEs in dependencies
- Outdated packages with vulnerabilities
- Malicious packages
- License compliance

## Workflows

### Pre-commit Security Scan

```
1. Run secret detection (gitleaks, trufflehog patterns)
2. Scan for common vulnerability patterns
3. Check dependency vulnerabilities (npm audit, safety)
4. Generate security report
5. If critical issues found:
   - Block commit with detailed report
   - Offer interactive remediation
6. If warnings only:
   - Allow commit with warning
   - Generate security report in docs/
```

### Security Audit Review

```
1. Scan entire codebase for security issues
2. Categorize by severity (Critical, High, Medium, Low)
3. Generate detailed security report
4. Provide remediation steps
5. Interactive Q&A for each finding
6. Create security-review.md in docs/
```

### Coding Assistance

When user asks about security or mentions security keywords:

1. Analyze the context
2. Provide secure implementation patterns
3. Explain vulnerabilities to avoid
4. Offer code examples with security annotations
5. Suggest security tools relevant to the tech stack

## Commands

| Command                    | Description                       |
| -------------------------- | --------------------------------- |
| `foundation security scan`         | Quick scan for critical issues    |
| `foundation security audit`        | Full security audit with report   |
| `foundation security fix`          | Auto-fix common issues            |
| `foundation security report`       | Generate security review document |
| `foundation security check <file>` | Scan specific file                |

## Output Formats

### Console Output

```
[SECURITY] Scanning...
[CRITICAL] secrets/api-keys.md:3 - API key exposed
[HIGH] auth/login.ts:45 - SQL injection vulnerability
[MEDIUM] config/database.ts:12 - Weak password hashing
[LOW] api/routes.ts:89 - Missing rate limiting

Found: 4 issues (1 critical, 1 high, 1 medium, 1 low)
Action required: Review critical issues before commit
```

### Report Format (docs/security-review.md) output path, created by agent

```markdown
# Security Review Report

**Date:** YYYY-MM-DD **Scope:** Full codebase **Severity:** Critical/High/Medium/Low

## Executive Summary

[High-level findings overview]

## Critical Issues

[Must-fix before production]

## High Issues

[Should-fix soon]

## Medium Issues

[Consider fixing]

## Low Issues

[Nice to have]

## Recommendations

[Security hardening steps]

## Remediation Status

- [ ] Issue 1 - Fixed
- [ ] Issue 2 - In progress
- [ ] Issue 3 - Accepted risk
```

## Interactive Mode

When issues are found, the skill offers:

1. **Fix Now** - Auto-apply secure patterns
2. **Explain** - Detailed explanation of the vulnerability
3. **Skip** - Accept risk with justification
4. **Template** - Generate secure code template
5. **Tools** - Suggest security tools for the tech stack

## Tech Stack Detection

Automatically detects and applies relevant security rules:

- **Node.js**: Express security, npm audit, node security
- **Python**: Bandit, safety, pip-audit
- **Go**: Gosec, govulncheck, depguard
- **TypeScript**: ESLint security plugins, TypeDoc
- **Docker**: Hadolint, trivy

## Configuration

Edit `config/security-rules.json` to customize:

- Severity thresholds
- Excluded paths (test files, examples)
- Custom vulnerability patterns
- Allowed secret patterns (for testing)

## Integration Points

- **Pre-commit hook**: Runs before each commit
- **CI/CD**: Runs in GitHub Actions, GitLab CI
- **IDE**: VSCode warnings via ESLint
- **Docs**: Auto-generates security-reports/

## Severity Levels

| Level    | Description                          | Action               |
| -------- | ------------------------------------ | -------------------- |
| Critical | Remote code execution, data breach   | Block + Report       |
| High     | Authentication bypass, data exposure | Block + Fix required |
| Medium   | Information disclosure, DoS          | Warn + Review        |
| Low      | Best practice violation              | Warn + Suggest       |

## Best Practices Reference

See `references/security-patterns.md` for:

- Secure coding patterns by language
- Authentication implementation guides
- Encryption best practices
- API security checklist
- Dependency management
