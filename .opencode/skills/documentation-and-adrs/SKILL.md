---
name: documentation-and-adrs
description:
  Record architectural decisions and documentation. Use when shipping features, changing APIs, or
  recording context for future engineers.
triggers:
  - document
  - adr
  - decision record
  - architecture decision
  - documentation
---

# Documentation and ADRs

## Overview

Document decisions, not just code. The most valuable documentation captures the _why_ — the context,
constraints, and trade-offs that led to a decision. Code shows _what_ was built; documentation
explains _why it was built this way_ and _what alternatives were considered_.

## When to Use

- Making a significant architectural decision
- Choosing between competing approaches
- Adding or changing a public API
- Shipping a feature that changes user-facing behavior
- Onboarding new team members (or agents) to the project
- When you find yourself explaining the same thing repeatedly

**When NOT to use:** Don't document obvious code. Don't add comments that restate what the code
already says. Don't write docs for throwaway prototypes.

## Architecture Decision Records (ADRs)

ADRs capture the reasoning behind significant technical decisions.

### When to Write an ADR

- Choosing a framework, library, or major dependency
- Designing a data model or database schema
- Selecting an authentication strategy
- Deciding on an API architecture (REST vs. GraphQL vs. tRPC)
- Choosing between build tools, hosting platforms, or infrastructure
- Any decision that would be expensive to reverse

See [ADR Template & Lifecycle](references/adr-template.md) for the full template and lifecycle.

## Reference Files

- [ADR Template & Lifecycle](references/adr-template.md) — Template, status lifecycle, and
  guidelines
- [Inline Documentation](references/inline-docs.md) — Comments, gotchas, and what to avoid
- [API Documentation](references/api-docs.md) — TypeScript JSDoc and OpenAPI patterns
- [README & Changelog](references/readme-changelog.md) — README structure, changelog format, and
  agent docs

## Common Rationalizations

| Rationalization                            | Reality                                                                                               |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| "The code is self-documenting"             | Code shows what. It doesn't show why, what alternatives were rejected, or what constraints apply.     |
| "We'll write docs when the API stabilizes" | APIs stabilize faster when you document them. The doc is the first test of the design.                |
| "Nobody reads docs"                        | Agents do. Future engineers do. Your 3-months-later self does.                                        |
| "ADRs are overhead"                        | A 10-minute ADR prevents a 2-hour debate about the same decision six months later.                    |
| "Comments get outdated"                    | Comments on _why_ are stable. Comments on _what_ get outdated — that's why you only write the former. |

## Red Flags

- Architectural decisions with no written rationale
- Public APIs with no documentation or types
- README that doesn't explain how to run the project
- Commented-out code instead of deletion
- TODO comments that have been there for weeks
- No ADRs in a project with significant architectural choices
- Documentation that restates the code instead of explaining intent

## Verification

- [ ] ADRs exist for all significant architectural decisions
- [ ] README covers quick start, commands, and architecture overview
- [ ] API functions have parameter and return type documentation
- [ ] Known gotchas are documented inline where they matter
- [ ] No commented-out code remains
- [ ] Rules files (CLAUDE.md etc.) are current and accurate
