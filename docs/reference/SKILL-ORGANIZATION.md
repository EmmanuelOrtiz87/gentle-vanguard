# Skill Organization Policy

## Security Skills (Intentional Separation)

Foundation has two security skills by design - they serve different agents:

| Skill | Agent | Purpose | Scope |
|--------|-------|---------|--------|
| `security-skill` | AGENT-DEV | Basic security patterns | Inline with code |
| `security-expert-skill` | AGENT-GOV | Deep security audits | Full audit |

### Why Separate?

- **DEV needs quick security checks** during implementation
- **GOV needs comprehensive audits** before release
- Different depth, different output formats

## Skill Naming Conventions

| Pattern | Example | Purpose |
|---------|---------|---------|
| `<name>-skill` | `security-skill` | Skills with triggers |
| `<name>-<subtype>-skill` | `security-expert-skill` | Specialized variants |

## Duplicate Detection

Skills are considered duplicates if:
1. Same trigger keywords
2. Same output format
3. Different name only

Skills are NOT duplicates if:
1. Different target agent (DEV vs GOV vs QA)
2. Different depth (basic vs expert)
3. Different phase (inline vs audit)

## Example: Security Skills

```
security-skill          → DEV agent → inline checks
security-expert-skill   → GOV agent → full audits
```

## Example: Testing Skills

```
testing-skill           → DEV agent → unit tests
playwright-skill       → QA agent → E2E tests
pytest-skill           → QA agent → Python tests
```
