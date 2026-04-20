---
name: documentation-governance
description: Standardize and produce project documentation, technical docs, code reviews, setup guides, script comments, and markdown structure. Use when creating or updating README files, ARCHITECTURE docs, technical documents, code reviews, setup or secrets docs, script/help docs, or any markdown or comment work that must stay consistent, English-first, numbered, and easy to maintain.
---

# Documentation Governance

## Purpose

Use this skill to keep project documentation consistent, English-first, and easy to follow across repos and sessions.

## Core Rules

1. Write documentation in English.
2. Use clear section names and numbered steps for ordered flows.
3. Keep file names, headings, and script names aligned.
4. Prefer short, specific notes over long prose.
5. Call out the start point, the required order, and the files or scripts the reader should use first.
6. Keep comments in code focused on non-obvious intent, tradeoffs, or constraints.
7. Remove stale references, temporary files, and duplicate guidance.

## Workflow

1. Identify the document type.
2. Apply the matching template from `references/documentation-standards.md`.
3. Normalize language, naming, and ordering.
4. Check that script lists, file references, and paths are accurate.
5. Keep the output concise but complete enough that a new developer can act without tribal knowledge.
6. Validate links, headings, and filenames before finishing.

## When to Use the Reference File

Read `references/documentation-standards.md` when you need:

- a README structure
- an installation or setup guide
- a technical document outline
- a code review format
- a script-commenting rule set
- a cleanup checklist for stale docs

## Output Expectations

- Start with the main entry point.
- Number steps when order matters.
- Enumerate important files and scripts.
- Keep terminology stable across the repo.
- Keep docs synchronized with the code and scripts they describe.
