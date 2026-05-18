---
name: Documentation Freshness
description: Keep docs in sync when public APIs or configuration changes
---

Look for changes to public-facing APIs or configuration where documentation was not updated:

- A public function, class, or type signature was added or changed -- update README, inline docs, or JSDoc
- Configuration options were added or renamed (config files, env vars, CLI flags) -- update relevant docs
- Rules or normativas were updated without updating references in AGENTS.md or CLAUDE.md
- Skill SKILL.md files were added/removed without updating skill registry references

No changes needed if the PR does not touch public APIs or configuration, or if docs were already updated.
