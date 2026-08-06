## CVSS 3.1 QUICK SCORING

### Formula

CVSS = f(AV, AC, PR, UI, S, C, I, A)

### Metric Quick Picks

| Metric                       | Value     | Weight | When                     |
| ---------------------------- | --------- | ------ | ------------------------ |
| **Attack Vector (AV)**       | Network   | +0.85  | Via internet             |
|                              | Local     | +0.55  | Local access needed      |
| **Attack Complexity (AC)**   | Low       | +0.77  | Repeatable               |
|                              | High      | +0.44  | Race/timing needed       |
| **Privileges Required (PR)** | None      | +0.85  | No login                 |
|                              | Low       | +0.62  | Regular user account     |
|                              | High      | +0.27  | Admin account            |
| **User Interaction (UI)**    | None      | +0.85  | No victim action         |
|                              | Required  | +0.62  | Victim must click        |
| **Scope (S)**                | Changed   | higher | Affects browser/OS/other |
|                              | Unchanged | lower  | Stays in app             |
| **Confidentiality (C)**      | High      | +0.56  | All data exposed         |
|                              | Low       | +0.22  | Limited data             |
| **Integrity (I)**            | High      | +0.56  | Can modify any data      |
| **Availability (A)**         | High      | +0.56  | Crashes service          |

### Typical Scores by Bug Class

| Bug                           | Typical CVSS | Severity |
| ----------------------------- | ------------ | -------- |
| IDOR (read PII)               | 6.5          | Medium   |
| IDOR (write/delete)           | 7.5          | High     |
| Auth bypass → admin           | 9.8          | Critical |
| Stored XSS (any user)         | 5.4–8.8      | Med–High |
| SQLi (data exfil)             | 8.6          | High     |
| SSRF (cloud metadata)         | 9.1          | Critical |
| Race condition (double spend) | 7.5          | High     |
| GraphQL auth bypass           | 8.7          | High     |
| JWT none algorithm            | 9.1          | Critical |

---

## CVSS 4.0 QUICK REFERENCE (newer programs)

CVSS 4.0 replaced CVSS 3.1 in November 2023. Some newer programs require it.

### Key Differences from CVSS 3.1

| Metric                       | CVSS 3.1                        | CVSS 4.0                            |
| ---------------------------- | ------------------------------- | ----------------------------------- |
| Attack Vector                | Network/Adjacent/Local/Physical | Same                                |
| Attack Complexity            | Low/High                        | Low/High                            |
| **NEW**: Attack Requirements | (didn't exist)                  | None/Present                        |
| Privileges Required          | None/Low/High                   | Same                                |
| User Interaction             | None/Required                   | None/Passive/Active                 |
| Scope                        | Unchanged/Changed               | REMOVED                             |
| **NEW**: Sub-Impact metrics  | (didn't exist)                  | Vulnerable/Subsequent system impact |

### CVSS 4.0 Score Examples

| Finding                      | CVSS 4.0 Score | Vector                                                          |
| ---------------------------- | -------------- | --------------------------------------------------------------- |
| Unauthenticated RCE          | 10.0           | CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H |
| IDOR read PII, auth required | 6.9            | CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N |
| Stored XSS, admin views it   | 8.2            | CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:P/VC:H/VI:H/VA:N/SC:H/SI:H/SA:N |
| SSRF → cloud metadata        | 8.7            | CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:H/SI:H/SA:N |

### Quick CVSS 4.0 Calculator

Use: https://www.first.org/cvss/calculator/4.0 Key fields: VC/VI/VA = Vulnerable System; SC/SI/SA =
Subsequent System (downstream impact) AT = None (no special condition) | Present (race/specific
config needed) UI = None | Passive (victim visits URL) | Active (victim takes explicit action)

**Practical rule**: If program uses CVSS 4.0, include the full string starting with
`CVSS:4.0/AV:...`. Programs cannot dispute a valid vector string.
