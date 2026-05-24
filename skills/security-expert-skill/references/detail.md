2. Categorize by severity (Critical, High, Medium, Low)
3. Generate detailed security report
4. Provide remediation steps
5. Interactive Q&A for each finding
6. Create security-review.md in docs/
```

### Coding Assistance

When user asks about security or mentions security keywords:

1. Analyze the context
2. Provide secure implementation patterns
3. Explain vulnerabilities to avoid
4. Offer code examples with security annotations
5. Suggest security tools relevant to the tech stack

## Commands

| Command                                 | Description                       |
| --------------------------------------- | --------------------------------- |
| `gentle-vanguard security scan`         | Quick scan for critical issues    |
| `gentle-vanguard security audit`        | Full security audit with report   |
| `gentle-vanguard security fix`          | Auto-fix common issues            |
| `gentle-vanguard security report`       | Generate security review document |
| `gentle-vanguard security check <file>` | Scan specific file                |

## Output Formats

### Console Output

```
[SECURITY] Scanning...
[CRITICAL] secrets/api-keys.md:3 - API key exposed
[HIGH] auth/login.ts:45 - SQL injection vulnerability
[MEDIUM] config/database.ts:12 - Weak password hashing
[LOW] api/routes.ts:89 - Missing rate limiting

Found: 4 issues (1 critical, 1 high, 1 medium, 1 low)
Action required: Review critical issues before commit
```

### Report Format (docs/security-review.md) output path, created by agent

```markdown
# Security Review Report

**Date:** YYYY-MM-DD **Scope:** Full codebase **Severity:** Critical/High/Medium/Low

## Executive Summary

[High-level findings overview]

## Critical Issues

[Must-fix before production]

## High Issues

[Should-fix soon]

## Medium Issues

[Consider fixing]

## Low Issues

[Nice to have]

## Recommendations

[Security hardening steps]

## Remediation Status

- [ ] Issue 1 - Fixed
- [ ] Issue 2 - In progress
- [ ] Issue 3 - Accepted risk
```

## Interactive Mode

When issues are found, the skill offers:

1. **Fix Now** - Auto-apply secure patterns
2. **Explain** - Detailed explanation of the vulnerability
3. **Skip** - Accept risk with justification
4. **Template** - Generate secure code template
5. **Tools** - Suggest security tools for the tech stack

## Tech Stack Detection

Automatically detects and applies relevant security rules:

- **Node.js**: Express security, npm audit, node security
- **Python**: Bandit, safety, pip-audit
- **Go**: Gosec, govulncheck, depguard
- **TypeScript**: ESLint security plugins, TypeDoc
- **Docker**: Hadolint, trivy

## Configuration

Edit `config/security-rules.json` to customize:

- Severity thresholds
- Excluded paths (test files, examples)
- Custom vulnerability patterns
- Allowed secret patterns (for testing)

## Integration Points

- **Pre-commit hook**: Runs before each commit
- **CI/CD**: Runs in GitHub Actions, GitLab CI
- **IDE**: VSCode warnings via ESLint
- **Docs**: Auto-generates security-reports/

## Severity Levels

| Level    | Description                          | Action               |
| -------- | ------------------------------------ | -------------------- |
| Critical | Remote code execution, data breach   | Block + Report       |
| High     | Authentication bypass, data exposure | Block + Fix required |
| Medium   | Information disclosure, DoS          | Warn + Review        |
| Low      | Best practice violation              | Warn + Suggest       |

## Best Practices Reference

See `references/security-patterns.md` for:

- Secure coding patterns by language
- Authentication implementation guides
- Encryption best practices
- API security checklist
- Dependency management