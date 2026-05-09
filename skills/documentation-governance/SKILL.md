---
name: documentation-governance
description: "Trigger: creating or updating README, ARCHITECTURE, setup guides, code reviews, script docs, or any markdown/comment work. Standardizes project documentation with English-first, numbered, easy-to-maintain structure."
---

# Documentation Governance

## Activation Contract
Load when creating or updating any project documentation: README files, ARCHITECTURE docs, setup guides, code reviews, script/help docs, secrets docs, or any markdown/comment work requiring consistent structure.

## Hard Rules
1. Write all documentation in English
2. Use numbered steps when order matters
3. Keep file names, headings, and script names aligned
4. Remove stale references, temporary files, and duplicate guidance
5. Validate links, headings, and filenames before finishing

## Decision Gates
Select document type from `references/documentation-standards.md`:
- README → use README template
- Installation/setup guide → use setup guide template
- Technical document → use technical doc template
- Code review → use code review template
- Script comments → use commenting rules

## Execution Steps
1. Identify document type
2. Apply matching template from `references/documentation-standards.md`
3. Normalize language, naming, and ordering
4. Verify script lists, file references, and paths are accurate
5. Keep output concise but complete for a new developer
6. Validate links, headings, and filenames

## Output Contract
- Start with the main entry point
- Number steps when order matters
- Enumerate important files and scripts
- Keep terminology stable across the repo
- Keep docs synchronized with code and scripts they describe

## References
- Templates & standards: [references/documentation-standards.md](references/documentation-standards.md)
