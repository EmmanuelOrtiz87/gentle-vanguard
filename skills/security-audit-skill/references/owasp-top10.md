# OWASP Top 10

## A01: Broken Access Control

- **What to check:** Missing or misconfigured access controls on API endpoints, admin panels, file
  uploads, and direct object references (IDOR).
- **Common target:** `/api/users/{id}` endpoints that don't verify the requesting user owns that
  resource.
- **Testing:** Manually modify user IDs, role parameters, or privilege tokens in requests.

## A02: Cryptographic Failures

- **What to check:** Weak TLS versions, missing HSTS headers, hardcoded keys, weak password hashing
  (MD5, SHA1), exposed secrets in source code.
- **Testing:** TLS scanner (testssl.sh), review `.env` files, check password storage algorithms.

## A03: Injection

- **What to check:** SQL, NoSQL, OS command injection, LDAP injection, and template injection
  (SSTI).
- **Testing:** Fuzz input fields with special characters (`'`, `"`, `;`, `--`, `/*`), test
  parameterized queries usage in code review.

## A04: Insecure Design

- **What to check:** Missing rate limiting, insecure password recovery flows, missing security
  controls at the design level.
- **Testing:** Review architecture diagrams, sequence flows, assess whether security was considered
  pre-implementation.

## A05: Security Misconfiguration

- **What to check:** Default credentials, unnecessary open ports, verbose error messages, missing
  security headers (CSP, X-Frame-Options), directory listing enabled.
- **Testing:** Run scanners (Nuclei, Nikto), manual header inspection with curl/burp.

## A06: Vulnerable and Outdated Components

- **What to check:** Known CVEs in dependencies, outdated libraries, unpatched frameworks.
- **Testing:** SCA tools (Trivy, Dependabot, Snyk), manual version checks against CVE databases.

## A07: Identification and Authentication Failures

- **What to check:** Weak password policies, no MFA, session fixation, credential stuffing
  vulnerability, no account lockout.
- **Testing:** Attempt brute force, check session token entropy, inspect JWT implementations.

## A08: Software and Data Integrity Failures

- **What to check:** Unsigned software updates, insecure CI/CD pipelines, untrusted data
  deserialization.
- **Testing:** Review CI/CD access controls, test deserialization of untrusted data, verify software
  signing.

## A09: Security Logging and Monitoring Failures

- **What to check:** Missing audit logs, no alerting on suspicious activity, logs that don't capture
  user identity or actions.
- **Testing:** Attempt malicious actions and verify they appear in logs. Review log retention
  policies.

## A10: Server-Side Request Forgery (SSRF)

- **What to check:** Features that fetch external URLs (webhooks, avatars, document previews)
  without allowlist validation or network restrictions.
- **Testing:** Point the application at internal services (`http://169.254.169.254/`,
  `http://localhost:9200/`).
