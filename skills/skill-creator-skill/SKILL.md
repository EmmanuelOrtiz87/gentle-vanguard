---
name: skill-creator
description: >
  Creates new AI agent skills following the Agent Skills spec.
  Trigger: When user asks to create a new skill, add agent instructions, or document patterns for AI.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Use this skill when:
- User asks to create a new skill
- User wants to add agent instructions
- User asks to document patterns for AI
- A repeated pattern needs AI guidance

## When NOT to Create

Don't create a skill when:
- Documentation already exists (reference instead)
- Pattern is trivial or self-explanatory
- It's a one-off task

---

## Skill Structure

```
skills/{skill-name}/
├── SKILL.md              # Required - main skill file
├── assets/               # Optional - templates, schemas, examples
│   ├── template.py
│   └── schema.json
└── references/           # Optional - links to local docs
    └── docs.md           # Points to docs/developer-guide/*.mdx
```

---

## SKILL.md Template

```markdown
---
name: {skill-name}
description: >
  {One-line description of what this skill does}.
  Trigger: {When the AI should load this skill}.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

{Bullet points of when to use this skill}

## Critical Patterns

{The most important rules - what AI MUST know}

## Code Examples

{Minimal, focused examples}

## Commands

\`\`\`bash
{Common commands}
\`\`\`

## Resources

- **Templates**: See [assets/](assets/) for {description}
- **Documentation**: See [references/](references/) for local docs
```

---

## Naming Conventions

| Type | Pattern | Examples |
|------|---------|----------|
| Generic skill | `{technology}` | `pytest`, `playwright`, `typescript` |
| Foundation-specific | `{name}-skill` | `foundation-manager`, `skill-creator` |
| Workflow skill | `{action}-{target}` | `github-pr`, `jira-task` |
| Architecture | `{component}-governance` | `documentation-governance` |

---

## Decision: assets/ vs references/

| Need | Use |
|------|-----|
| Code templates | `assets/` |
| JSON schemas | `assets/` |
| Example configs | `assets/` |
| Link to existing docs | `references/` |
| Link to external guides | `references/` (with local path) |

**Key Rule**: `references/` should point to LOCAL files (`docs/*.md`), not web URLs.

---

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (lowercase, hyphens) |
| `description` | Yes | What + Trigger in one block |
| `license` | Yes | Always `Apache-2.0` |
| `metadata.author` | Yes | `gentleman-programming` |
| `metadata.version` | Yes | Semantic version as string |

---

## Content Guidelines

### DO
- Start with the most critical patterns
- Use tables for decision trees
- Keep code examples minimal and focused
- Include Commands section

### DON'T
- Add Keywords section
- Duplicate content from existing docs (reference instead)
- Include lengthy explanations (link to docs)

---

## Checklist Before Creating

- [ ] Skill doesn't already exist (check `skills/`)
- [ ] Pattern is reusable (not one-off)
- [ ] Name follows conventions
- [ ] Frontmatter is complete
- [ ] Critical patterns are clear
- [ ] Code examples are minimal
- [ ] Commands section exists
- [ ] Added to AGENTS.md

---

## Resources

- **Foundation**: See `~/.gentleman/` for global installation
- **Skill Index**: See [SKILL_INDEX.md](SKILL_INDEX.md) for all skills
- **Documentation**: See [docs/](docs/) for guides
