---
created: 2026-05-29 04:43:46
tags: [engram, architecture]
engram_id: 1211
type: architecture
---

# Skill Factory runtime

**What**: Implemented Skill Factory runtime at scripts/utilities/SKILL-FACTORY/skill-factory.ps1. Creates scaffolding for new skills: SKILL.md with YAML frontmatter, references/detail.md, optional registration in auto-delegation.json and skill-registry.md, and automatic MCP server rebuild. Tested with rust-backend-skill (DEV agent, 4 triggers).

**Why**: Automates the repetitive process of creating new skills, ensuring consistent structure, frontmatter, and registration across the stack.

**Where**: scripts/utilities/SKILL-FACTORY/skill-factory.ps1, skills/rust-backend-skill/

**Learned**:
- MCP server auto-rebuild on skill creation ensures immediate discoverability
- Manual registry append needed when skill exists but wasn't registered initially
- PowerShell here-strings require closing not on the same line as content

---
*Imported from Engram on 2026-09-06*
