# Project Agent Rules

## Scope

- Keep implementation within the project tree.
- Keep external tools outside the project tree.
- Save architecture and session decisions in the memory layer when applicable.
- Record the initial scope, architecture, and AI model choice in `docs/project-context.md`.

## Working Style

- Follow the project structure.
- Prefer small, bounded changes.
- Validate before handing off.

## Documentation

- Write all documentation in English.
- Use clear, professional language.
- Emojis and special characters are allowed in documentation for:
  - Visual diagrams (arrows, boxes, lines)
  - Status indicators [OK], [X], [WARN]
  - Emphasis and readability
- Keep documentation concise and scannable.

## Code Standards

- Follow language-specific best practices.
- Use consistent naming conventions.
- Write self-documenting code.
- Document all public APIs.

## Review

- Use GGA hook for pre-commit review when available.
- Address AI feedback before committing.
- Follow the Definition of Done.

## Definition of Done

- [ ] Code follows style guidelines
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No secrets in code
- [ ] Validation script passes
