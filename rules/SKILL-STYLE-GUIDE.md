# SKILL STYLE GUIDE

**Source:** Adapted from [gentle-ai/docs/skill-style-guide.md](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/skill-style-guide.md)

A skill is a **runtime instruction contract for an LLM**, not human-facing documentation. Every `SKILL.md` MUST follow this structure.

## Required Structure

Every `SKILL.md` MUST use this order (omit only if truly irrelevant):

1. **Frontmatter** — complete metadata for skill discovery
2. **Activation Contract** — exact situations that load the skill
3. **Hard Rules** — constraints the LLM MUST NOT violate
4. **Decision Gates** — short tables or bullets for branching choices
5. **Execution Steps** — ordered operational workflow
6. **Output Contract** — required final format or artifacts
7. **References** — local files only

## Frontmatter Rules

- `description` MUST be one physical line, YAML-safe, and quoted
- Put trigger words first: `"Trigger: ... . {What the skill does}."`
- `description` SHOULD be <=160 chars and MUST be <=250 chars
- Include `name`, `description`, `trigger` (if applicable)
- Do NOT add a `Keywords` section; discovery uses frontmatter

## Body Budget

- Target **180-450 tokens** for the skill body
- Recommended maximum: **700 tokens**
- Hard maximum: **1000 tokens**. Move examples to `assets/` or `references/`

## Writing Rules

### DO

- Write imperative runtime instructions: "Load X", "Check Y", "Return Z"
- Lead with the activation trigger and hard constraints
- Use compact tables for decision gates
- Keep examples minimal and executable
- Link to local supporting files for details

### DON'T

- Explain history, motivation, or tutorial background
- Duplicate long docs inside the skill
- Add generic advice the LLM cannot execute
- Use external URLs as primary references
- Hide critical rules below examples

## Quality Gates

Before submitting a new or refactored SKILL.md:

- [ ] Frontmatter is complete, quoted, single-line, trigger-first
- [ ] Required sections exist in the expected order
- [ ] Hard rules are testable or observable
- [ ] Decision gates cover meaningful forks only
- [ ] Output contract tells the LLM exactly what to return
- [ ] References point to local files
- [ ] Body is under 1000 tokens (hard limit)
- [ ] Skill is registered in auto-delegation.json or has a clear route

## Enforcement

- New skills in `skills/` MUST pass this guide before acceptance
- Existing skills SHOULD be refactored to comply when modified
- CI SHOULD check skill body size (under 1000 tokens)
