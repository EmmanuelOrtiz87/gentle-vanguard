# Code Example 1

From: SKILL.md

````markdown
---
name: { skill-name }
description: >
  {One-line description of what this skill does}. Trigger: {When the AI should load this skill}.
license: Apache-2.0
metadata:
  author: gentle-vanguard
  versión: '1.0'
---

## When to Use

{Bullet points of when to use this skill}

## Critical Patterns

{The most important rules - what AI MUST know}

## Code Examples

{Minimal, focused examples}

## Commands

\`\`\`bash {Common commands} \`\`\`

## Resources

<!-- Template placeholders - replace with actual paths when creating a skill -->

- **Templates**: See `assets/` for code templates, schemas, examples
- **Documentation**: See `references/` for local documentation links

---

## Naming Conventions

| Type                     | Pattern                      | Examples                                   |
| ------------------------ | ---------------------------- | ------------------------------------------ |
| Generic skill            | `{technology}`               | `pytest`, `playwright`, `typescript`       |
| Gentle-Vanguard-specific | `{name}-skill`               | `gentle-vanguard-manager`, `skill-creator` |
| Workflow skill           | `{action}-{target}`          | `github-pr`, `jira-task`                   |
| Architecture             | `{component}-governance`     | `documentation-governance`                 |
| Testing skill            | `{project}-test-{component}` | `myapp-test-sdk`                           |

---

## decisión: assets/ vs references/

| Need                    | Use                             |
| ----------------------- | ------------------------------- |
| Code templates          | `assets/`                       |
| JSON schemas            | `assets/`                       |
| Example configs         | `assets/`                       |
| Link to existing docs   | `references/`                   |
| Link to external guides | `references/` (with local path) |

**Key Rule**: `references/` should point to LOCAL files (`docs/*.md`), not web URLs.

---

## Frontmatter Fields

| Field              | Required | Description                           |
| ------------------ | -------- | ------------------------------------- |
| `name`             | Yes      | Skill identifier (lowercase, hyphens) |
| `description`      | Yes      | What + Trigger in one block           |
| `license`          | Yes      | Always `Apache-2.0`                   |
| `metadata.author`  | Yes      | `gentle-vanguard`                     |
| `metadata.versión` | Yes      | Semantic versión as string            |

---

## Content Guidelines

### DO

- Start with the most critical patterns
- Use tables for decisión trees
- Keep code examples minimal and focused
- Include Commands section with copy-paste commands

### DON'T

- Add Keywords section (agent searches frontmatter, not body)
- Duplicate content from existing docs (reference instead)
- Include lengthy explanations (link to docs)
- Add troubleshooting sections (keep focused)
- Use web URLs in references (use local paths)

---

## Checklist Before Creating

- [ ] Skill doesn't already exist (check `skills/`)
- [ ] Pattern is reusable (not one-off)
- [ ] Name follows conventions
- [ ] Frontmatter is complete (description includes trigger keywords)
- [ ] Critical patterns are clear
- [ ] Code examples are minimal
- [ ] Commands section exists
- [ ] Added to `SKILL_INDEX.md`

---

## Registration

After creating the skill, add it to `SKILL_INDEX.md`:

```

```
````
