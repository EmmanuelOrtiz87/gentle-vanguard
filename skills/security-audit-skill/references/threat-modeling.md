# Threat Modeling

## STRIDE Methodology

STRIDE categorizes threats by type:

| Threat                     | Definition                      | Example                         | Mitigation                                    |
| -------------------------- | ------------------------------- | ------------------------------- | --------------------------------------------- |
| **S**poofing               | Impersonating someone/something | Fake login page                 | Strong authentication, MFA                    |
| **T**ampering              | Modifying data in transit       | Man-in-the-middle               | Signatures, TLS, integrity checks             |
| **R**epudiation            | Denying an action was performed | "I didn't delete that data"     | Audit logs, digital signatures                |
| **I**nformation Disclosure | Exposing confidential data      | SQL injection leaking passwords | Encryption, access controls, input validation |
| **D**enial of Service      | Making system unavailable       | DDoS, resource exhaustion       | Rate limiting, load balancing, auto-scaling   |
| **E**levation of Privilege | Gaining unauthorized access     | Zero-day exploit chain          | Patch management, least privilege             |

**STRIDE per-component approach:** For each component (API gateway, database, frontend, worker
queue), ask: "Can this be spoofed? Tampered? Repudiated? Disclosed? DoSed? Escalated?"

## DREAD Framework (Risk Scoring)

| Factor               | Rating (0-10)                          |
| -------------------- | -------------------------------------- |
| **D**amage Potential | How much damage if exploited?          |
| **R**eproducibility  | How reliable is the exploit?           |
| **E**xploitability   | How easy is it to exploit?             |
| **A**ffected Users   | How many users are impacted?           |
| **D**iscoverability  | How easy is the vulnerability to find? |

**Score = (D + R + E + A + D) / 5**

DREAD is subjective but useful for prioritizing within a single organization. CVSS is preferred for
external reporting.

## Threat Modeling Process

1. **Decompose the application** — Draw data flow diagrams (DFDs) showing all components, trust
   boundaries, and data flows.
2. **Identify threats** — Use STRIDE per component. Brainstorm attack scenarios.
3. **Rank threats** — Score using DREAD or CVSS.
4. **Define mitigations** — For each threat, specify the control that addresses it.
5. **Validate** — Ensure mitigations are implemented correctly.
