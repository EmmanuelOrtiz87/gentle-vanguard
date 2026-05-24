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
2. User requests security review (`gentle-vanguard security scan`, `gentle-vanguard security audit`)
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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)