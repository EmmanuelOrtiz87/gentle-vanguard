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
- Start substantial work with `scripts/start-session.ps1`.
- Keep `docs/sessions/` and `docs/tasks/` aligned with the real scope of work.

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

## Orchestrator

- The Project Orchestrator is responsible for analysis, design, architecture, and testing guidance.
- Use `.\scripts\orchestrator-next-steps.ps1` to ask the orchestrator for the next development
  actions.

## Review

- Use native review hooks for pre-commit when available.
- Address AI feedback before committing.
- Follow the Definition of Done.

## Audit

AI-assisted development activity is automatically tracked in the `.audit/` directory:

- Sessions: Development session records
- Code Reviews: PR/MR review records
- Metrics: Velocity, effectiveness, and cost analytics
- Reports: Weekly summaries for stakeholders

See `.audit/README.md` for details.

## Definition of Done

- [ ] Code follows style guidelines
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No secrets in code
- [ ] Validation script passes
