## Judgment Day - Dual Review Protocol

### Overview

**Judgment Day** is a pre-merge adversarial validation that complements pre-commit reviews.

### Comparison

| Aspect | Pre-commit | Judgment Day |
|--------|------------|--------------|
| **Trigger** | Pre-commit | Pre-merge |
| **Mode** | Single reviewer | Two parallel judges |
| **Purpose** | Fast block of critical issues | Deep adversarial validation |
| **Speed** | ~seconds | ~minutes |

### Workflow

```
git commit > pre-commit > Block critical issues

                    Significant work ready for merge

                    wf review --scope judgment-day

                APPROVED                     ESCALATED
                (merge)                (manual review)
```

### Commands

| Command | Description |
|---------|-------------|
| `wf review --scope judgment-day` | Run dual review protocol |
| `wf review --scope judgment-day --target <path>` | Target specific path |
| `wf review --scope judgment-day --max-iterations 3` | Custom iteration limit |

### Integration

AGENT-QA owns Judgment Day execution: `wf agent QA "judgment day on src/features/auth"`

See: `skills/multi-agent-registry/SKILL.md` - AGENT-QA section
