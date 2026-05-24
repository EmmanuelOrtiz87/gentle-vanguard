---
name: skill-registry
description: >
  Create or update the skill registry for the current project. Scans user skills and project
  conventions, writes .atl/skill-registry.md, and saves to engram if available. Trigger: When user
  says "update skills", "skill registry", "actualizar skills", "update registry", or after
  installing/removing skills.
license: MIT
metadata:
  author: gentle-vanguard
  versión: '1.0'
---

## Purpose

You generate or update the **skill registry** a catalog of all available skills with **compact
rules** (pre-digested, 5-15 line summaries) that any delegator injects directly into sub-agent
prompts. Sub-agents do NOT read the registry or individual SKILL.md files they receive compact rules
pre-resolved in their launch prompt.

This is the gentle-vanguard of the **Skill Resolver Protocol** (see
`docs/reference/SKILL-RESOLVER-PROTOCOL.md`). The registry is built ONCE (expensive), then read
cheaply at every delegation.

## When to Run

- After installing or removing skills
- After setting up a new project
- When the user explicitly asks to update the registry
- As part of `sdd-init` (it calls this same logic)

## What to Do

### Step 1: Scan User Skills

1. Glob for `*/SKILL.md` files across ALL known skill directories. Check every path below scan ALL
   that exist, not just the first match:

   **User-level (global skills):**
   - `~/.claude/skills/` Claude Code
   - `~/.config/opencode/skills/` OpenCode
   - `~/.gemini/skills/` Gemini CLI
   - `~/.cursor/skills/` Cursor
   - `~/.copilot/skills/` VS Code Copilot
   - The parent directory of this skill file (catch-all for any tool)

   **Project-level (workspace skills):**
   - `{project-root}/.claude/skills/` Claude Code
   - `{project-root}/.gemini/skills/` Gemini CLI
   - `{project-root}/.agent/skills/` Antigravity (workspace)
   - `{project-root}/skills/` Generic

2. **SKIP `sdd-*` and `_shared`** those are SDD workflow skills, not coding/task skills
3. Also **SKIP `skill-registry`** that's this skill
4. **Deduplicate** if the same skill name appears in multiple locations, keep the project-level
   versión (more specific). If both are user-level, keep the first found.
5. For each skill found, read the **full SKILL.md** (if a SKILL.md exceeds 200 lines, focus on the
   frontmatter and Critical Patterns / Rules sections only) to extract:
   - `name` field (from frontmatter)
   - `description` field extract the trigger text (after "Trigger:" in the description)
   - **Compact rules** the actionable patterns and constraints (see Step 1b)
6. Build a table of: Trigger | Skill Name | Full Path

### Step 1b: Generate Compact Rules

For each skill found in Step 1, generate a **compact rules block** (5-15 lines max) containing ONLY:

- Actionable rules and constraints ("do X", "never Y", "prefer Z over W")
- Key patterns with one-line examples where critical
- Breaking changes or gotchas that would cause bugs if missed

**DO NOT include**: purpose/motivation, when-to-use, full code examples, installation steps, or
anything the sub-agent doesn't need to APPLY the skill.

Format per skill:

```markdown
### {skill-name}

- Rule 1
- Rule 2
- ...
```

**Example** compact rules for a React 19 skill:

```markdown
### react-19

- No useMemo/useCallback React Compiler handles memoization automatically
- use() hook for promises/context, replaces useEffect for data fetching
- Server Components by default, add 'use client' only for interactivity/hooks
- ref is a regular prop no forwardRef needed
- Actions: use useActionState for form mutations, useOptimistic for optimistic UI
- Metadata: export metadata object from page/layout, no <Head> component
```

**The compact rules are the MOST IMPORTANT output of this skill.** They are what sub-agents actually
receive. Invest time making them accurate and concise.

### Step 2: Scan Project Conventions


---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)