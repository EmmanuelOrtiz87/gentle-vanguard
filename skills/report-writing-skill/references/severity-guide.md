## SEVERITY DECISION GUIDE

### Critical (P1)

- Full account takeover of any user without interaction
- Remote code execution
- SQLi with ability to dump/modify entire DB
- Auth bypass to admin panel
- SSRF to cloud metadata → IAM credentials exfil

### High (P2)

- Mass PII exposure (email, phone, SSN, payment data)
- Privilege escalation from user to admin
- SSRF reaching internal services (data returned)
- Stored XSS executing for all users of sensitive feature
- Payment bypass / financial loss without limit

### Medium (P3)

- IDOR on specific user's non-critical data
- XSS on low-sensitivity page requiring victim interaction
- CSRF on important but non-critical action
- Rate limit bypass on OTP (with effort demonstrated)

### Low (P4)

- Information disclosure (non-sensitive, no PII)
- Clickjacking on sensitive action WITH working PoC
- CORS on limited data

---

## SEVERITY SELF-ASSESSMENT

Each YES raises severity:

1. Exposes PII / health / financial data of other users? → +1 severity
2. Allows account takeover or privilege escalation? → +2 severity
3. Requires ZERO user interaction from victim? → +1 severity
4. Affects ALL users (not specific condition)? → +1 severity
5. Remotely exploitable with no internal network access? → baseline for High+
