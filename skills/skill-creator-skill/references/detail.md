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

```markdown
| **Category** | skill-name |
```

```

---

## Resources

- **Gentle-Vanguard**: See `~/.gentleman/` for global installation
- **Skill Index**: See [SKILL_INDEX.md](../SKILL_INDEX.md) for all skills
- **Documentation**: See [docs/](../../docs/) for guides
```
