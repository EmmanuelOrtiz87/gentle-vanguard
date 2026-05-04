---
name: security-skill
description: Use when reviewing code for security vulnerabilities, implementing authentication/authorization, handling sensitive data, or setting up security practices. Triggers: "security", "authentication", "authorization", "vulnerability", "CVE", "OWASP", "XSS", "SQL injection", "secrets", "encryption".
---

# Security Skill

## Purpose

Identify and prevent security vulnerabilities, implement secure authentication/authorization, and follow security best practices.

## Core Principles

1. **Defense in Depth** - Multiple layers of security
2. **Least Privilege** - Grant minimum necessary permissions
3. **Fail Securely** - Default to secure behavior on errors
4. **Secure by Default** - Safe defaults, opt-in for insecurity
5. **Input Validation** - Validate all external input
6. **Output Encoding** - Encode data for the context

## OWASP Top 10 (2021)

| # | Vulnerability | Prevention |
|---|---------------|------------|
| 1 | Broken Access Control | Implement proper authorization checks |
| 2 | Cryptographic Failures | Use strong encryption, hash passwords |
| 3 | Injection | Use parameterized queries, input validation |
| 4 | Insecure Design | Threat modeling, secure patterns |
| 5 | Security Misconfiguration | Harden configurations, minimal attack surface |
| 6 | Vulnerable Components | Keep dependencies updated |
| 7 | Auth Failures | Strong passwords, MFA, session management |
| 8 | Data Integrity Failures | Verify CI/CD integrity |
| 9 | Logging Failures | Log security events, monitor alerts |
| 10 | SSRF | Validate URLs, block internal requests |

## Authentication Checklist

- [ ] Use strong password hashing (bcrypt, argon2)
- [ ] Implement MFA/2FA
- [ ] Secure session management (httpOnly, secure, sameSite)
- [ ] Rate limit authentication endpoints
- [ ] Use secure token generation
- [ ] Implement account lockout policies
- [ ] Secure password reset flows

## Authorization Checklist

- [ ] Check permissions on every request
- [ ] Implement role-based access control (RBAC)
- [ ] Use policy-based authorization
- [ ] Validate ownership of resources
- [ ] Log authorization failures
- [ ] Don't expose internal IDs

## Input Validation

```typescript
// DANGEROUS - SQL Injection
const query = `SELECT * FROM users WHERE id = ${userId}`;

// SAFE - Parameterized Query
const query = `SELECT * FROM users WHERE id = $1`;
await db.query(query, [userId]);
```

```typescript
// DANGEROUS - XSS
const html = `<div>${userInput}</div>`;

// SAFE - Output Encoding
import DOMPurify from 'dompurify';
const html = DOMPurify.sanitize(userInput);
```

## Secrets Management

| Environment | Storage |
|-------------|---------|
| Development | `.env.local` (not committed) |
| Staging | Environment variables |
| Production | Vault, AWS Secrets Manager, Azure Key Vault |

```bash
# .gitignore
.env
.env.*
!.env.example

# .env.example (safe to commit)
DATABASE_URL=postgresql://user:password@host:5432/db  # Replace in production
API_KEY=your-api-key-here
```

## Security Headers

```typescript
// helmet.js for Express
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

## Secure Coding Patterns

```typescript
// File uploads
const upload = multer({
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/gif'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

// Rate limiting
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests'
});
```

## Dependency Security

```bash
# Audit dependencies
npm audit --audit-level=high

# Update dependencies
npm outdated
npm update

# Lock versións in production
npm ci  # Uses package-lock.json exactly
```

## Security Checklist for New Features

- [ ] Input validation on all entry points
- [ ] Output encoding for context
- [ ] Authentication required?
- [ ] Authorization checked?
- [ ] Sensitive data handled securely?
- [ ] Logging for security events?
- [ ] Error messages don't leak info?
- [ ] Dependencies vetted?

## Security Testing Commands

```bash
# Dependency audit
npm audit

# OWASP dependency check
npx owasp-dependency-check

# Security headers check
curl -I https://your-site.com

# Secret scanning
gitrob scan

# SAST
semgrep --config=auto .
```

## Workspace Access Control (Foundation)

Foundation implements Role-Based Access Control (RBAC) for workspace operations:

### Roles

| Role | Description | Access |
|------|-------------|--------|
| `owner` | Workspace owner | Full access to all operations |
| `developer` | Developer | Restricted to development tasks |

### Authentication

```powershell
# Check access level
.\scripts\utilities\access-control-middleware.ps1 -CheckOnly

# Authenticate with API key (8hr session)
.\scripts\utilities\auth-session.ps1 -ApiKey "fnd_local_2026_Emmanuel_"

# Authenticate via security questions (recovery)
.\scripts\utilities\auth-session.ps1 -UseSecurityQuestions
```

### Blocked Operations (developers)

- Modifying skills (`skills/*`)
- Modifying orchestrator
- Accessing workspace config (`.workspace/config/*`)
- Running skill-optimizer
- Running foundation-audit
- Managing users


