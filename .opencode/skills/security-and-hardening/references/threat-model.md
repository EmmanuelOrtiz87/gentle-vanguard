# Threat Model Process

Before hardening, spend five minutes thinking like an attacker:

## 1. Map the Trust Boundaries

Where does untrusted data cross into your system? HTTP requests, form fields, file uploads, webhooks, third-party APIs, message queues, and **LLM output**. Every boundary is attack surface.

## 2. Name the Assets

What's worth stealing or breaking? Credentials, PII, payment data, admin actions, money movement.

## 3. Run STRIDE Over Each Boundary

| Threat                     | Ask                                        | Typical mitigation                             |
| -------------------------- | ------------------------------------------ | ---------------------------------------------- |
| **S**poofing               | Can someone impersonate a user/service?    | Authentication, signature verification         |
| **T**ampering              | Can data be altered in transit or at rest? | Integrity checks, parameterized queries, HTTPS |
| **R**epudiation            | Can an action be denied later?             | Audit logging of security events               |
| **I**nformation disclosure | Can data leak?                             | Encryption, field allowlists, generic errors   |
| **D**enial of service      | Can it be overwhelmed?                     | Rate limiting, input size caps, timeouts       |
| **E**levation of privilege | Can a user gain rights they shouldn't?     | Authorization checks, least privilege          |

## 4. Write Abuse Cases Next to Use Cases

For each feature, ask "how would I misuse this?" — then make that your first test.

If you can't name the trust boundaries for a feature, you're not ready to secure it. This is OWASP **A04: Insecure Design** — most breaches begin in design, not code.
