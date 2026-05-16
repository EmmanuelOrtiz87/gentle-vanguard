## 7-Dimension Code Review Protocol

Every substantial code review MUST cover all 7 dimensions.

### The 7 Dimensions

| #   | Dimension         | Icon  | Agent     | Auto? |
| --- | ----------------- | ----- | --------- | ----- |
| 1   | **Security**      | [S]   | AGENT-GOV | Yes   |
| 2   | **Quality**       | [Q]   | AGENT-DEV | Yes   |
| 3   | **Architecture**  | [A]   | AGENT-SAD | No    |
| 4   | **Testing**       | [T]   | AGENT-QA  | No    |
| 5   | **Documentation** | [D]   | AGENT-DOC | No    |
| 6   | **API Design**    | [API] | AGENT-SAD | No    |
| 7   | **Git Workflow**  | [G]   | AGENT-GOV | No    |

### Review Commands

```powershell
gv review                # Full 7-dimension review
gv review --scope quick  # Security + Quality only (~30s)
gv review --scope full   # All 7 dimensions
```

### Mandatory Coverage Rules

1. **PRE-COMMIT**: Run `gv review --scope quick` (Security + Quality)
2. **PRE-MERGE**: Run `gv review --scope full` (all 7 dimensions)
3. **JUDGMENT DAY**: Invoke for adversarial dual-review before major releases

### Severity Matrix

| Level    | Icon | Action                | Exit Code |
| -------- | ---- | --------------------- | --------- |
| CRITICAL | [!C] | BLOCK commit          | 1         |
| HIGH     | [!H] | WARN + require review | 0         |
| MEDIUM   | [!M] | INFO + log            | 0         |
| LOW      | [!L] | SUGGEST               | 0         |

See: `skills/code-review-orchestrator-skill/SKILL.md` for full implementation.

### Findings Decision Workflow

| Severity | Icon | Action             | Blocking |
| -------- | ---- | ------------------ | -------- |
| CRITICAL | [X]  | Block immediately  | YES      |
| HIGH     | [!]  | Must fix before PR | YES      |
| MEDIUM   | [-]  | User choice        | NO       |
| LOW      | [*]  | Suggestion only    | NO       |

User decision options for MEDIUM:

- A) Fix now (recommended)
- B) Create PR, fix in separate session
- C) Document as tech debt, create PR

### Findings Summary Template

```markdown
## Findings Summary

**Found:** X issues

- [x] CRITICAL: N (block if any)
- [!] HIGH: N
- [-] MEDIUM: N
- [*] LOW: N

### Critical/High Issues (MUST FIX)

1. [SEV] File:line - Description

### Medium Issues (Your Choice)

1. [SEV] File:line - Description

### Suggestions (Optional)

1. [LOW] File:line - Description

**What should we do with the findings?**

1. Fix everything now (recommended)
2. Fix CRITICAL/HIGH now, MEDIUM later
3. Create the PR and fix them later
4. Only create the PR without fixing them
5. Go back to implementation and fix more
```

### Specification Validation

- [ ] All planned features implemented
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes without notice
- [ ] CI/CD passes
- [ ] Code follows conventions

Questions: Did we meet the spec? Did we forget anything? Is the code ready for review?

