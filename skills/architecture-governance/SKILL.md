---
name: architecture-governance
description: Standardize architecture decisións, project structure choices, defaults, and decisión records. Use when defining or updating project architecture, layering, naming conventions, repository structure, scaffolding defaults, compatibility constraints, or architecture decisión documents.
---

# Architecture Governance

## Purpose

Use this skill to keep architecture decisións simple, explicit, technology-agnostic, and reproducible across projects.

## Core Rules

1. Prefer defaults that are safe and portable.
2. Ask the user only when a choice changes structure, compatibility, or operational cost.
3. Keep architecture decisións independent from the specific IDE, LLM, or implementation language unless a constraint requires otherwise.
4. Document the chosen shape in `docs/project-context.md` and `ARCHITECTURE.md`.
5. Record decisión rationale, impact, and fallback options.
6. Avoid embedding vendor-specific tooling or OS-specific assumptions in the architecture unless explicitly required.

## Workflow

1. Identify the project type and starting state.
2. Ask only for missing high-impact decisións.
3. Prefer project parameters and config defaults for repeatable choices.
4. Capture the architecture in a short decisión record.
5. Validate that the resulting structure matches the repo layout and scripts.

## When to Use the Reference File

Read `references/architecture-standards.md` when you need:

- a project structure outline
- a layered architecture summary
- a default decisión template
- a compatibility checklist
- a migration or refactor decisión record

## Output Expectations

- Start with the selected project shape.
- List the core layers or folders.
- State the defaults and why they are safe.
- State any user-selected exceptions.
- Keep the output technology-agnostic unless the repository requires a concrete choice.


