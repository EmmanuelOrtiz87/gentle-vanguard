---
name: source-driven-development
description:
  Grounds every implementation decision in official documentation. Use when you want authoritative,
  source-cited code free from outdated patterns. Use when building with any framework or library
  where correctness matters.
---

# Source-Driven Development

Every framework-specific code decision must be backed by official documentation. Training data goes stale, APIs get deprecated, best practices evolve. Verify, cite, and let the user see your sources.

## When to Use

- Framework-specific code, boilerplate, starter code, or patterns that will be copied
- User asks for documented, verified, or "correct" implementation
- Forms, routing, data fetching, state management, auth — any framework-recommended approach
- Reviewing or improving framework-specific code
- **Anytime** you're about to write framework code from memory

**Skip**: pure logic (loops, conditionals, data structures), typos, file moves, or when the user explicitly says "just do it quickly."

## Process

```
DETECT → FETCH → IMPLEMENT → CITE
```

**1. Detect** — Read the project's dependency file for exact versions. If missing, ask.

**2. Fetch** — Fetch the *relevant* docs page (not the homepage). Priority: official docs → official blog/changelog → web standards (MDN) → browser compat.

**3. Implement** — Follow API signatures from the docs. Use new patterns, avoid deprecated ones. Surface doc-vs-codebase conflicts explicitly.

**4. Cite** — Full URLs with deep links and anchors. Quote relevant passages. If unverifiable, say so.

## Reference Files

- [Full Process Detail](references/process.md) — Step-by-step examples for all 4 phases
- [Common Rationalizations](references/rationalizations.md) — Why confidence is not evidence
- [Red Flags](references/red-flags.md) — Signs you're going off track
- [Verification Checklist](references/verification.md) — Post-implementation quality check
