## Dimension Details

| Dimension | Icon | Auto | Scope | What it Checks |
|-----------|------|------|-------|----------------|
| **Security** | [S] | Yes | security | Secrets, vulnerabilities, OWASP |
| **Quality** | [Q] | Yes | quality | Code smells, complexity, patterns |
| **Architecture** | [A] | No | architecture | Structure, coupling, design |
| **Testing** | [T] | No | testing | Coverage, test quality |
| **Documentation** | [D] | No | docs | README, comments, ADRs |
| **API Design** | [API] | No | api | REST compliance, validation |
| **Git Workflow** | [G] | No | git | Commits, branches, hooks |

### Security Scan Details

```
SECURITY SCAN

Pattern Detection:

  [!C] CRITICAL                    [!H] HIGH
   AWS Access Keys (AKIA...)        Generic API Keys
   GitHub Tokens (ghp_...)          Bearer Tokens
   Private Keys (PEM/RSA)           Basic Auth strings
   Stripe Keys (sk_live_...)        JWT Tokens
   SendGrid Keys (SG....)           Database URLs w/ creds

Detection Method: Regex pattern matching on staged files
Performance: < 1 second for critical patterns
```
