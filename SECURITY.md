# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 2.6.x   | ✓ Active  |
| < 2.6   | ✗ No longer supported |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities privately to the platform team:

1. **Email**: Use the contact listed in the repository's CODEOWNERS file.
2. **GitHub Security Advisories**: Use the "Report a vulnerability" button in the Security tab.

### What to include

- Description of the vulnerability and potential impact
- Steps to reproduce
- Affected component(s): scripts, config, workflows, hooks
- Any suggested fix

### Response timeline

| Phase | Target |
|-------|--------|
| Initial acknowledgement | 48 hours |
| Severity assessment | 5 business days |
| Fix or mitigation | Depends on severity (CRITICAL: 7d, HIGH: 14d, MEDIUM: 30d) |
| Disclosure | Coordinated after fix is released |

## Security Controls

This project implements the following security controls:

| Control | Implementation |
|---------|----------------|
| Secret scanning | Pre-commit hook (`check-secrets` patterns) + GitHub secret scanning |
| Dependency scanning | Trivy (weekly, `.github/workflows/owasp-scan.yml`) |
| SAST (PowerShell) | PSScriptAnalyzer (`.github/workflows/ps-lint.yml`) |
| Workflow hardening | All workflows: `permissions: contents: read`, `timeout-minutes`, `concurrency` |
| Action pinning | Dependabot weekly updates (`.github/dependabot.yml`) |
| Access control | `config/access-control.json` + `config/security-policy.json` |
| Hook output safety | `scripts/hooks/hook-output-safety.ps1` (redacts secrets from hook logs) |
| RBAC | `config/owner-auth.json` (owner-only operations) |

## Hardening Checklist (for contributors)

- [ ] No secrets, tokens, or credentials in committed files
- [ ] No `Write-Host` of environment variables in hooks (use `Write-SafeHook`)
- [ ] New CI workflows must include `permissions: contents: read`, `timeout-minutes`, and `concurrency`
- [ ] PowerShell scripts must pass PSScriptAnalyzer with zero errors
- [ ] External URLs only from the allow-list in `config/security-privacy.json`
