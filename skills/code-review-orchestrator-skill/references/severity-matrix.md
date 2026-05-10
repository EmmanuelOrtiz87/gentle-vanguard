## Severity Levels

| Level | Icon | Action | Exit Code |
|-------|------|--------|-----------|
| CRITICAL | [!C] | Block commit | 1 |
| HIGH | [!H] | Warn + require review | 0 |
| MEDIUM | [!M] | Info + log | 0 |
| LOW | [!L] | Suggest + log | 0 |

### Detailed Descriptions

- **CRITICAL**: Security breach risk, exposed credentials, data loss vulnerability. BLOCK commit (exit code 1).
- **HIGH**: Major quality issues, SQL injection risk, missing authentication. WARN + require review.
- **MEDIUM**: Technical debt, error handling gaps, missing validation. INFO + log for review.
- **LOW**: Code style violations, missing comments, TODO/FIXME notes. Suggest + log.
