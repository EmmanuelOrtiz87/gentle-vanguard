# Checklists — Security Skill

## OWASP Top 10 (2021)

| #   | Vulnerability             | Prevention                                    |
| --- | ------------------------- | --------------------------------------------- |
| 1   | Broken Access Control     | Implement proper authorization checks         |
| 2   | Cryptographic Failures    | Use strong encryption, hash passwords         |
| 3   | Injection                 | Use parameterized queries, input validation   |
| 4   | Insecure Design           | Threat modeling, secure patterns              |
| 5   | Security Misconfiguration | Harden configurations, minimal attack surface |
| 6   | Vulnerable Components     | Keep dependencies updated                     |
| 7   | Auth Failures             | Strong passwords, MFA, session management     |
| 8   | Data Integrity Failures   | Verify CI/CD integrity                        |
| 9   | Logging Failures          | Log security events, monitor alerts           |
| 10  | SSRF                      | Validate URLs, block internal requests        |

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

## Secrets Management

| Environment | Storage                                     |
| ----------- | ------------------------------------------- |
| Development | `.env.local` (not committed)                |
| Staging     | Environment variables                       |
| Production  | Vault, AWS Secrets Manager, Azure Key Vault |

```bash
# .gitignore
.env
.env.*
!.env.example

# .env.example (safe to commit — placeholder values, never use real secrets)
DATABASE_URL=postgresql://app:PLACEHOLDER@localhost:5432/app_db
API_KEY=sk-placeholder-key-not-real
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

## Blocked Operations (Gentle-Vanguard workspace, developer role)

- Modifying skills (`skills/*`)
- Modifying orchestrator
- Accessing workspace config (`.workspace/config/*`)
- Running skill-optimizer
- Running gentle-vanguard-audit
- Managing users
