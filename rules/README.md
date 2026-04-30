# Custom Rules Extension

This directory is the extension layer for project-specific rules.

Purpose:

1. Allow teams to add technical and business rules without editing core skills.
2. Let orchestrator workflows load custom guidance during session/context generation.
3. Keep custom behavior versioned with the repository.

## Structure

`rules/custom/technical/`:
- Coding standards and architecture constraints.

`rules/custom/business/`:
- Domain policies, workflows, and product constraints.

`rules/custom/review/`:
- Code review checklists, severity rules, and acceptance gates.

## Rule Authoring Guidance

1. **Format is mandatory `.md`**  only Markdown files are loaded; other formats are ignored.
2. `README.md` files in each scope directory are reserved for documentation and excluded from rule loading.
3. Use one file per rule group, named with the rule ID prefix (e.g., `TECH-001-parser-validation.md`).
4. Keep files concise and explicit  short actionable statements, not long prose.
5. Follow the mandatory template defined in `docs/guides/CUSTOM-RULES.md`.
6. Avoid duplicating global security/compliance policies.

## Rule ID Convention

| Scope         | Prefix  | Example    |
|---------------|---------|------------|
| `technical/`  | `TECH-` | `TECH-001` |
| `business/`   | `BIZ-`  | `BIZ-001`  |
| `review/`     | `REV-`  | `REV-001`  |

## Runtime Integration

Rules are loaded by:

1. `scripts/utilities/custom-rules.ps1`
2. `scripts/utilities/context-pack.ps1`
3. `scripts/utilities/start-session.ps1`
4. `scripts/utilities/orchestrator-status.ps1`

## Safety Notes

1. Custom rules complement core skills.
2. Core safety/compliance policies still take precedence.
3. Use repository review workflow for rule changes.