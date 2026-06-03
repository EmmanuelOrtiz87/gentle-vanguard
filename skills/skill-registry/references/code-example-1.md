# Code Example 1

From: SKILL.md

```markdown
# Skill Registry

**Delegator use only.** Any agent that launches sub-agents reads this registry to resolve compact
rules, then injects them directly into sub-agent prompts. Sub-agents do NOT read this registry or
individual SKILL.md files.

See `docs/reference/SKILL-RESOLVER-PROTOCOL.md` for the full resolution protocol.

## User Skills

| Trigger                    | Skill        | Path                    |
| -------------------------- | ------------ | ----------------------- |
| {trigger from frontmatter} | {skill name} | {full path to SKILL.md} |
| ...                        | ...          | ...                     |

## Compact Rules

Pre-digested rules per skill. Delegators copy matching blocks into sub-agent prompts as
`## Project Standards (auto-resolved)`.

### {skill-name-1}

- Rule 1
- Rule 2
- ...

### {skill-name-2}

- Rule 1
- Rule 2
- ...

{repeat for each skill}

## Project Conventions

| File              | Path             | Notes                        |
| ----------------- | ---------------- | ---------------------------- |
| {index file}      | {path}           | Index references files below |
| {referenced file} | {extracted path} | Referenced by {index file}   |
| {standalone file} | {path}           |                              |

Read the convention files listed above for project-specific patterns and rules. All referenced paths
have been extracted no need to read index files to discover more.
```
