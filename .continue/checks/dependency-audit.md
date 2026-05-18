---
name: Dependency Audit
description: Review new or updated dependencies for risk
---

If no dependency files (`package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`) were changed, no action is needed.

When dependencies were added or updated, look for:

- New dependency that appears unmaintained (no commits in 12 months) -- flag for review, suggest alternatives
- Dependency bumped by more than one major version (e.g., v2.x to v4.x) without PR description note -- add comment explaining jump
- Known deprecated or security-flagged package -- replace with recommended alternative
- Duplicate functionality from existing dependency -- remove and use existing one
- Dev dependencies in production section (e.g., test framework in `dependencies` vs `devDependencies`) -- move to correct section
