---
name: doubt-driven-development
description:
  Fresh-context adversarial review for non-trivial decisions. Use when correctness matters,
  working in unfamiliar code, or stakes are high (production, security, irreversible ops).
---

# Doubt-Driven Development

## Overview

Long sessions accumulate context that turns assumptions into "facts." Doubt-driven development materializes a fresh-context reviewer — biased to **disprove**, not approve — before any non-trivial output stands.

This is not `/review`. `/review` is a verdict on a finished artifact. This is an in-flight posture: course-correction while it's still cheap.

## When to Use

A decision is **non-trivial** when at least one is true:

- Introduces or modifies branching logic
- Crosses a module or service boundary
- Asserts a property the type system cannot verify (thread safety, idempotence, ordering, invariants)
- Correctness depends on context the future reader cannot see
- Blast radius is irreversible (production deploy, data migration, public API change)

**When NOT to use:** mechanical ops (renaming, formatting), following clear unambiguous instructions, reading/summarizing existing code, one-line changes, pure tooling, or when the user asked for speed.

## Loading Constraints

This skill is designed for the **main-session orchestrator** only. **Do NOT add to a persona's `skills:` frontmatter** — a persona invoking another persona is an orchestration anti-pattern.

If inside a subagent where nesting is prevented: surface to the user that doubt-driven cannot run nested and let the main session handle it. As last resort, use the self-questioning fallback documented in [references/process-detail.md](references/process-detail.md), but flag results as degraded.

## Quick Start

```
Doubt cycle:
- [ ] Step 1: CLAIM — wrote the claim + why-it-matters
- [ ] Step 2: EXTRACT — isolated artifact + contract, stripped reasoning
- [ ] Step 3: DOUBT — invoked fresh-context reviewer with adversarial prompt
- [ ] Step 4: RECONCILE — classified every finding against the artifact text
- [ ] Step 5: STOP — met stop condition (trivial findings, 3 cycles, or user override)
```

## Steps Overview

**1. CLAIM** — Name the decision in 2–3 lines. If you can't write it compactly, surface the vibe before scrutinizing.

**2. EXTRACT** — Give the reviewer artifact + contract only, never the reasoning. Must fit in one read; decompose if too large.

**3. DOUBT** — Invoke a fresh-context reviewer with an adversarial prompt. Pass ARTIFACT + CONTRACT only — **never the CLAIM**. See full adversarial prompt and detail in [references/process-detail.md](references/process-detail.md).

**Cross-model escalation** (interactive only): after single-model review, always ask the user if they want a second opinion (Gemini CLI, Codex CLI, manual, or skip). Verify the tool exists, works, and confirm the exact invocation before running. Never interpolate artifacts into shell arguments — use a temp file and stdin. See [references/cross-model-escalation.md](references/cross-model-escalation.md).

**4. RECONCILE** — Classify each finding by precedence: contract misread → valid+actionable → valid trade-off → noise. The reviewer can be wrong; re-read the artifact, don't rubber-stamp.

**5. STOP** — Stop when findings are trivial, after 3 cycles (escalate, don't grind), or on user override. If 3 cycles are insufficient, the artifact is too big — return to Step 2 and decompose.

## Rationalizations and Red Flags

See [references/rationalizations-and-red-flags.md](references/rationalizations-and-red-flags.md) for the full table of common rationalizations and the red flags checklist.

## Verification Checklist

See [references/verification-and-interactions.md](references/verification-and-interactions.md) for the post-application verification checklist and interaction with other skills (code-review, source-driven-dev, TDD, debugging).
