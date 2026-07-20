# Spec Template

```markdown
# Spec: [Project/Feature Name]

## Objective

[What we're building and why. User stories or acceptance criteria.]

## Tech Stack

[Framework, language, key dependencies with versions]

## Commands

[Build, test, lint, dev — full commands]

## Project Structure

[Directory layout with descriptions]

## Code Style

[Example snippet + key conventions]

## Testing Strategy

[Framework, test locations, coverage requirements, test levels]

## Boundaries

- Always: [...]
- Ask first: [...]
- Never: [...]

## Success Criteria

[How we'll know this is done — specific, testable conditions]

## Open Questions

[Anything unresolved that needs human input]
```

## Success Criteria Reframing

When receiving vague requirements, translate them into concrete conditions:

```
REQUIREMENT: "Make the dashboard faster"

REFRAIMED SUCCESS CRITERIA:
- Dashboard LCP < 2.5s on 4G connection
- Initial data load completes in < 500ms
- No layout shift during load (CLS < 0.1)
→ Are these the right targets?
```
