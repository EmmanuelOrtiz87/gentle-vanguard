# Issue Tracker Template

This template is used by the Code Review Orchestrator to track issues found during code reviews.

## Usage

Issues are automatically added to this file when running:

```bash
gv review --track
```

## Format

```markdown
## [YYYY-MM-DD] Review Session

### Issues

| ID  | Severity | Category | Title             | File           | Status |
| --- | -------- | -------- | ----------------- | -------------- | ------ |
| 1   | CRITICAL | Security | API Key Exposed   | src/config.ts  | OPEN   |
| 2   | HIGH     | Quality  | Empty Catch Block | src/handler.ts | FIXED  |

### Action Items

- [ ] [CRITICAL] Fix API key exposure - src/config.ts:15
- [x] [HIGH] Add error handling - src/handler.ts:42

---
```

## Issue Lifecycle

1. **OPEN** - Issue identified, needs attention
2. **IN_PROGRESS** - Fix being implemented
3. **REVIEW** - Fix submitted, awaiting review
4. **FIXED** - Issue resolved
5. **ACCEPTED** - Risk accepted with justification
6. **DUPLICATE** - Already addressed elsewhere

## Categories

- **Security** - Secrets, vulnerabilities, compliance
- **Quality** - Code smells, complexity, patterns
- **Architecture** - Structure, coupling, design
- **Testing** - Coverage, patterns, maintenance
- **Documentation** - Completeness, accuracy, clarity
- **API Design** - Contracts, versióning, errors
- **Git Workflow** - Commits, branches, history

## Severity Levels

| Level    | Color | Description                     | SLA         |
| -------- | ----- | ------------------------------- | ----------- |
| CRITICAL | [!C]  | Security breach, data loss risk | Immediate   |
| HIGH     | [!H]  | Major quality/deployment issue  | 24 hours    |
| MEDIUM   | [!M]  | Technical debt, maintainability | 1 week      |
| LOW      | [!L]  | Best practice, polish           | Next sprint |

## Quick Reference

```bash
# Quick status update
gv review --update-issue 1 --status FIXED

# Export issues
gv review --export-csv

# Generate report
gv review --report
```

