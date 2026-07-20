# Reporting Format

Every audit report should follow this structure:

## Executive Summary

- **Audit period:** YYYY-MM-DD to YYYY-MM-DD
- **Scope:** [brief description]
- **Overall risk rating:** Critical / High / Medium / Low
- **Key metrics:** Total findings, critical count, high count
- **Top 3 risks:** Brief one-liner for each
- **Business impact:** In plain language, what could happen

## Finding Register

| ID      | Title                  | Severity | CVSS | Status      | Owner     |
| ------- | ---------------------- | -------- | ---- | ----------- | --------- |
| AUD-001 | SQL Injection in login | Critical | 9.8  | Open        | @dev-team |
| AUD-002 | Missing CSP Header     | Medium   | 5.3  | Fixed       | @sec-team |
| AUD-003 | Hardcoded AWS Key      | High     | 7.5  | In Progress | @backend  |

## Detailed Findings

Each finding includes:

- **Title** — Clear, actionable
- **CWE ID** — Common Weakness Enumeration identifier
- **CVSS Vector** — e.g., `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`
- **Affected Asset** — URL, endpoint, file, component
- **Description** — What is the vulnerability, and why does it matter?
- **Impact** — What could an attacker do?
- **Evidence** — Steps to reproduce, screenshots, curl commands, logs
- **Remediation** — Specific fix instructions with code examples
- **References** — Links to OWASP, CVE, documentation

## Risk Heatmap

```
High Impact + High Likelihood  = CRITICAL (immediate action)
High Impact + Low Likelihood   = HIGH (plan for next sprint)
Low Impact + High Likelihood   = MEDIUM (fix during maintenance)
Low Impact + Low Likelihood    = LOW (accept or monitor)
```
