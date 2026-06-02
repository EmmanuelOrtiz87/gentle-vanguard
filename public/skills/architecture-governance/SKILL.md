---
name: architecture-governance
description:
  'Trigger: "architecture", "project structure", "ADR". Standardize architecture decisions, project
  structure, defaults, and decision records.'
metadata:
  source: GV-native
---

# Architecture Governance

## Activation Contract

Load this skill when defining or updating project architecture, layering, naming conventions,
repository structure, scaffolding defaults, compatibility constraints, or architecture decision
documents.

## Hard Rules

1. Prefer defaults that are safe and portable.
2. Ask the user only when a choice changes structure, compatibility, or operational cost.
3. Keep architecture decisions independent from IDE, LLM, or language unless a constraint requires
   otherwise.
4. Document the chosen shape in `docs/project-context.md` and `ARCHITECTURE.md`.
5. Record decision rationale, impact, and fallback options.
6. Avoid embedding vendor-specific or OS-specific assumptions unless explicitly required.

## Decision Gates

| Situation             | Action                                                   |
| --------------------- | -------------------------------------------------------- |
| Project type known?   | Use defaults from `references/architecture-standards.md` |
| High-impact decision? | Ask user; document in decision record                    |
| Repeatable choice?    | Use project parameters and config defaults               |
| After decisions made  | Capture in short decision record                         |

## Execution Steps

1. Identify the project type and starting state.
2. Ask only for missing high-impact decisions.
3. Prefer project parameters and config defaults for repeatable choices.
4. Capture the architecture in a short decision record.
5. Validate that the resulting structure matches the repo layout and scripts.

## Output Contract

- Start with the selected project shape.
- List the core layers or folders.
- State the defaults and why they are safe.
- State any user-selected exceptions.
- Keep the output technology-agnostic unless the repository requires a concrete choice.

## References

- `references/architecture-standards.md` — project structure outline, layered architecture summary,
  decision template, compatibility checklist, migration/refactor decision record
