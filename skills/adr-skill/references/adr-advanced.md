# Advanced ADR Patterns & Governance

## Combining Multiple Decisions

One PR may involve several related decisions:

```markdown
# ADR-030: Order Service Decomposition

**Status**: Accepted

## This ADR covers three decisions:
1. Extract order management from the monolith
2. Use event-driven communication between order and inventory services
3. Adopt PostgreSQL for the order service database
```

**Alternative:** Write one ADR per decision and cross-reference them.

## Architecture Review Board (ARB)

```markdown
# Architecture Review Board Charter

## Purpose
Ensure architectural consistency and quality across all products.

## Composition
- 1 Staff Engineer (permanent)
- 2 Senior Engineers (rotating, 6-month term)
- 1 Product Manager (non-voting)

## When to Escalate
- Cross-team architectural decisions
- Technology stack additions
- Major refactoring or migrations
- Decisions with significant cost implications

## Process
1. Author drafts ADR → send to ARB
2. ARB reviews within 1 week
3. ARB meeting to discuss (if needed)
4. Decision documented in ADR status
```

## Automated ADR Linting

```yaml
# .adr-lint.yml
rules:
  required-sections:
    - Status
    - Context
    - Decision
    - Consequences
    - Alternatives Considered
  status-values:
    allowed: [Proposed, Accepted, Deprecated, Superseded, Rejected]
  naming:
    pattern: '^ADR-\d{3}-[a-z0-9-]+\.md$'
  no-duplicate-numbers: true
  index-required: true
  index-path: 'docs/adr/index.md'
```

```bash
npx adr-lint docs/adr/
```

## Linking ADRs to Code

```python
# Uses Redis-backed rate limiting (see ADR-022)
from ratelimit import RateLimiter

# SQLite for local dev, PostgreSQL in production (see ADR-002)
if config.ENV == "production":
    db = PostgresDatabase(config.DATABASE_URL)
else:
    db = SQLiteDatabase(":memory:")

# Using UUID v4 instead of auto-increment IDs (see ADR-015)
order_id = uuid.uuid4()
```

## ADR Change Tracking

```markdown
# ADR-010: Authentication Architecture

## Status
Accepted (Updated 2024-03-01)

## Changelog
| Date       | Change                                                   | Author |
| ---------- | -------------------------------------------------------- | ------ |
| 2024-01-15 | Initial draft                                            | Alice  |
| 2024-01-20 | Added SSO requirement                                    | Bob    |
| 2024-02-01 | Accepted after ARB review                                | Carol  |
| 2024-03-01 | Updated token expiry from 1h to 24h based on UX feedback | Alice  |
```

## ADR Tools

### adr-tools (CLI)
```bash
brew install adr-tools
adr new Use PostgreSQL for analytics store
adr list
adr supersede 0001 0008
adr link 0001 "Amends" 0003
```

### Log4brains (modern ADR manager with UI)
```bash
npm install -g @log4brains/cli
log4brains init
log4brains adr:new
log4brains preview
log4brains build
```
