# Defaults vs Project decisións

This document explains what Gentle-Vanguard owns and what each project must decide for
itself.

## Start Here

1. Use the workspace defaults when you want a safe, repeatable starting point.
2. Use project decisións when the codebase has specific requirements that cannot be generalized.
3. Keep defaults generic so they work across technologies, IDEs, and skill levels.
4. Record project-specific choices in `docs/project-context.md`.
5. Ask the user before changing scope, architecture, secrets, or AI provider decisións.
6. Read this document before creating a new scaffolded project or changing the workspace kit.

## Workspace Defaults

These belong to `gentle-vanguard` and should remain reusable across projects:

1. Portable directory layout.
2. External tools consumed by command, not vendored in application repos.
3. Reusable Codex skills for documentation and architecture.
4. Workspace bootstrap scripts and validation scripts.
5. Local Engram runtime isolation outside the project checkout.
6. Optional AI model guidance without forcing a provider.

## Project decisións

These belong to the target project and should be recorded in `docs/project-context.md`:

1. Repository mode: scaffold or clone.
2. Project kind: `service`, `cli`, or `library`.
3. Preset, architecture, and profile.
4. AI mode, provider, model name, and endpoint, if used.
5. Credential flow, if the project needs secrets.
6. Runtime expectations and any operational constraints.

## What Can Change Safely

1. `-Kind`, `-Preset`, `-Architecture`, and `-Profile` when the project owner confirms the shape.
2. AI model fields when the project really uses AI assistance.
3. `repoUrl` when cloning an existing repository.
4. Secret handling when the project needs credentials.

## What Should Stay Stable

1. The separation between workspace tools and project code.
2. The requirement to keep runtime state outside the checkout.
3. The requirement to document decisións in English.
4. The requirement to keep reusable skills outside project repositories.

## Recommended Rule

If a choice affects more than one future project, it belongs in Gentle-Vanguard. If a
choice affects only one repository, it belongs in that project's `docs/project-context.md`.

## Quick Summary

1. Gentle-Vanguard = reusable defaults and common workflow.
2. Project context = repository-specific decisións and constraints.
3. If you are unsure, keep the default and record the question in `docs/project-context.md`.

