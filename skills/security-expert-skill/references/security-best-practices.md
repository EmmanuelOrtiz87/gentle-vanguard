# Security Best Practices Guide

This document provides security guidelines for projects created with Gentle-Vanguard.

## Quick Reference

| Command              | Description                       |
| -------------------- | --------------------------------- |
| `gentle-vanguard security scan`   | Quick scan for critical issues    |
| `gentle-vanguard security audit`  | Full audit with detailed report   |
| `gentle-vanguard security report` | Generate security review document |
| `git commit`         | Runs automatic security scan      |

## Pre-commit Security

The Security Expert skill automatically runs before each commit to:

1. Scan for exposed secrets (API keys, tokens, passwords)
2. Detect common vulnerability patterns
3. Check dependencies for known vulnerabilities
4. Block commits with critical issues

## Security Categories

### Critical (Blocks Commit)

- Hardcoded credentials
- API keys in code
- SQL injection vulnerabilities
- Command injection risks
- Private keys committed

### High (Warning + Review)

- XSS vulnerabilities
- Missing authentication
- Insecure crypto usage
- CORS misconfiguration
- Missing rate limiting

### Medium (Informational)

- Weak password hashing
- Information disclosure
- Debug mode enabled
- Missing security headers

### Low (Best Practices)

- Verbose error messages
- TODO comments with security notes
- Missing input validation

## Common Issues and Fixes

### Exposed API Key

**Problem:** `const API_KEY = "sk_live_1234567890abcdef"` **Fix:** Use environment variables

```typescript
const API_KEY = process.env.API_KEY;
```

### SQL Injection

**Problem:** `query = "SELECT * FROM users WHERE id = " + userId` **Fix:** Use parameterized queries

```typescript
const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
```

### XSS Vulnerability

**Problem:** `element.innerHTML = userInput` **Fix:** Use textContent or sanitization

```typescript
element.textContent = userInput;
// Or use DOMPurify for HTML content
```

### Hardcoded Password

**Problem:** `password: "mySecretPassword123"` **Fix:** Use environment variables

```typescript
password: process.env.DB_PASSWORD;
```

## Environment Variables

Always store secrets in environment variables:

```bash
# .env (never commit)
DATABASE_URL=postgres://user:password@host:5432/db
API_KEY=your-secret-key
JWT_SECRET=your-jwt-secret

# .gitignore
.env
.env.local
.env.*.local
```

## Dependencies

### npm

```bash
npm audit          # Check for vulnerabilities
npm audit fix      # Auto-fix vulnerabilities
npm ci             # Install from lockfile
```

### Python

```bash
pip audit          # Check for vulnerabilities
safety check      # Check requirements
```

### Go

```bash
govulncheck ./...  # Check for vulnerabilities
go mod verify      # Verify dependencies
```

## Security Headers

Configure these headers in your application:

```typescript
// Helmet.js for Express
import helmet from 'helmet';
app.use(helmet());

// Content Security Policy
app.use(
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", 'https://fonts.googleapis.com'],
    },
  }),
);
```

## Rate Limiting

Protect APIs from abuse:

```typescript
import rateLimit from 'express-rate-limit';

app.use(
  '/api',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
  }),
);
```

## OWASP Top 10 (2021)

1. Broken Access Control
2. Cryptographic Failures
3. Injection
4. Insecure Design
5. Security Misconfiguration
6. Vulnerable Components
7. Authentication Failures
8. Software Integrity Failures
9. Logging & Monitoring Failures
10. SSRF

## Resources

- [OWASP Top 10](https://owasp.org/Top10/)
- [Security Code Review Guide](https://owasp.org/www-pdf-archive/OWASP_Code_Review_Guide_v2.pdf)
- [Cheat Sheet Series](https://cheatsheetseries.owasp.org/)

## Reporting Security Issues

If you find a security vulnerability:

1. Do NOT create a public issue
2. Email: security@example.com
3. Include details about the issue
4. Allow time for a fix before disclosure

