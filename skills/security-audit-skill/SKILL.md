---
name: security-audit-skill
description: >
  Imported from mercury-agent-skills. Use when working with "security audit", "vulnerability
  assessment", "OWASP", "security review". Triggers: "security audit", "vulnerability assessment",
  "OWASP", "security review".
metadata:
  source: mercury-agent-skills
  original-name: security-audit
---

# Security Audit Skill

A systematic approach to evaluating the security posture of applications, systems, and
infrastructure.

---

## Core Principles

1. **Defense in Depth** — Layered protections; failure in one layer caught by another.
2. **Least Privilege** — Minimum permissions necessary; verify boundaries are enforced.
3. **Assume Breach** — Design as if an attacker already has a foothold.
4. **Repeatability** — Same methodology → same conclusions across auditors.
5. **Evidence-Based Findings** — Every finding backed by reproducible evidence.
6. **Continuous Improvement** — Find bugs AND improve the process.

---

## Audit Lifecycle

1. **Scope Definition** — Boundaries, rules of engagement, testing window
2. **Reconnaissance** — Passive/active recon, code review, dependency analysis
3. **Testing** — Automated SAST/DAST + manual business logic testing
4. **Reporting** — Executive summary, finding register, detailed findings
5. **Remediation** — Track, assign severity, re-test, close

> Full methodology → `references/audit-methodology.md`

---

## OWASP Top 10

Detailed checklists and testing guidance → `references/owasp-top10.md`

---

## Tooling

| Category | Tools | Reference |
|----------|-------|-----------|
| SAST     | Semgrep, SonarQube, CodeQL, Brakeman | `references/tooling.md` |
| DAST     | OWASP ZAP, Burp Suite Pro, Acunetix | `references/tooling.md` |
| SCA      | Trivy, Snyk, Dependabot, OWASP Dependency-Check | `references/tooling.md` |
| Container| Grype, Kube-bench, Trivy | `references/tooling.md` |

---

## Threat Modeling

| Framework | Use | Reference |
|-----------|-----|-----------|
| STRIDE    | Categorize threats per component | `references/threat-modeling.md` |
| DREAD     | Risk scoring (internal prioritization) | `references/threat-modeling.md` |

---

## Reporting

- **Executive summary** — risk rating, key metrics, top risks
- **Finding register** — ID, title, severity, CVSS, status, owner
- **Detailed findings** — CWE, CVSS vector, evidence, remediation

> Full template → `references/reporting-format.md`

---

## CVSS v3.1 Quick Reference

| Severity | Score Range |
|----------|-------------|
| Critical | 9.0 – 10.0 |
| High     | 7.0 – 8.9 |
| Medium   | 4.0 – 6.9 |
| Low      | 0.1 – 3.9 |
| None     | 0.0 |

> Full classification → `references/cvss-classification.md`

---

## Common Mistakes

12 common pitfalls → `references/common-mistakes.md`
