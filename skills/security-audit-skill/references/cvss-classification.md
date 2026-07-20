# CVSS v3.1 Classification

## Score Ranges

| Severity | Score Range |
| -------- | ----------- |
| None     | 0.0         |
| Low      | 0.1 - 3.9   |
| Medium   | 4.0 - 6.9   |
| High     | 7.0 - 8.9   |
| Critical | 9.0 - 10.0  |

## CVSS Vector Breakdown

Example: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`

| Component                | Value | Meaning                                       |
| ------------------------ | ----- | --------------------------------------------- |
| AV (Attack Vector)       | N     | Network (remotely exploitable)                |
| AC (Attack Complexity)   | L     | Low (no special conditions)                   |
| PR (Privileges Required) | N     | None (no auth needed)                         |
| UI (User Interaction)    | N     | None (no user action needed)                  |
| S (Scope)                | U     | Unchanged (vuln doesn't cross trust boundary) |
| C (Confidentiality)      | H     | High (all data exposed)                       |
| I (Integrity)            | H     | High (all data can be modified)               |
| A (Availability)         | H     | High (system fully unavailable)               |

## Priority Interpretation

- **Critical:** Remote, no auth, full compromise → fix within 24h
- **High:** Needs auth but leads to data breach → fix within 1 week
- **Medium:** Requires interaction or special conditions → fix within 1 month
- **Low:** Hard to exploit, limited impact → fix within next release
