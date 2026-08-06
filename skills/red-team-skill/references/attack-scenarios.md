# Attack Scenarios — Reference

## Scenario 1: Credential Stuffing

**Goal:** Compromise accounts with reused passwords.

Execution:

1. Obtain breach database (simulated)
2. Run credentials against login endpoint
3. Document rate limiting behavior
4. Test account lockout triggers
5. Attempt bypass techniques

Findings:

- Rate limiting triggers at 10 attempts/minute
- No account lockout
- No breach credential detection
- Login response time reveals valid usernames

## Scenario 2: Session Hijacking

**Goal:** Access accounts without credentials.

Execution:

1. Analyze session token structure
2. Test token entropy
3. Attempt token prediction
4. Test XSS vectors for token theft
5. Check secure cookie flags

Findings:

- Session tokens use secure random
- Cookies missing HttpOnly flag ← VULNERABILITY
- No session binding to IP
- Tokens don't expire on password change

## Defense Bypass Attempts

For each defense, try to bypass it:

| Attempt                       | Result                       |
| ----------------------------- | ---------------------------- |
| Distribute across IPs         | BYPASSED — no IP correlation |
| Vary username slowly          | Works — only per-IP limit    |
| Use different user agents     | No effect                    |
| Target password reset instead | BYPASSED — no rate limit     |

**Conclusion:** Rate limiting is per-IP only, easily distributed. Password reset has no rate
limiting.
