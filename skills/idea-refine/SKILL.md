---
name: idea-refine
aliases: ["idea-refine"]
description:
  Refine raw ideas into sharp concepts. Divergent then convergent thinking to stress-test
  assumptions and expand options.
  
triggers:
  - idea
  - refine
  - ideate
  - concept
  - brainstorm
  - stress-test idea
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.059Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\idea-refine\SKILL.md
  version: "1.0.0"
---

# Idea Refine

Refines raw ideas into sharp, actionable concepts through structured divergent and convergent
thinking.

## Process

1. **Understand & Expand (Divergent):** Restate as "How Might We", ask 3-5 sharpening questions
   (who, success, constraints, prior attempts, why now), generate 5-8 variations (inversion,
   constraint removal, audience shift, combination, simplification, 10x, expert lens).
2. **Evaluate & Converge:** Cluster into 2-3 directions, stress-test for user
   value/feasibility/differentiation, surface hidden assumptions.
3. **Sharpen & Ship:** Produce a markdown one-pager: Problem Statement, Recommended Direction, Key
   Assumptions, MVP Scope, Not Doing, Open Questions.

## Usage

Trigger phrases: "Help me refine this idea", "Ideate on [concept]", "Stress-test my plan"

Init ideas dir: `bash scripts/idea-refine/scripts/idea-refine.sh`

## References

See `references/` in this skill directory for:

- `frameworks.md` — additional ideation frameworks
- `refinement-criteria.md` — full evaluation rubric
- `examples.md` — example ideation sessions

## Guidance

### Phase 1: Understand & Expand (Divergent)

- Restate as "How Might We" — forces clarity on the actual problem.
- Ask 3-5 sharpening questions: who specifically? what does success look like? real constraints?
  what's been tried? why now?
- Generate 5-8 variations: inversion, constraint removal, audience shift, combination,
  simplification, 10x version, expert lens.
- If inside a codebase, use Glob/Grep/Read for context.

### Phase 2: Evaluate & Converge

- Cluster resonated ideas into 2-3 distinct directions.
- Stress-test each: user value (painkiller vs vitamin), feasibility (hardest part), differentiation
  (switching cost).
- Surface hidden assumptions: what you're betting on, what could kill it, what you're ignoring.
- Be honest, not supportive. Push back on weak ideas with specificity.

### Phase 3: Sharpen & Ship

Produce a one-pager with this structure:

```md
# [Idea]

## Problem Statement

[One-line "How Might We"]

## Recommended Direction

[Chosen direction + why — 2-3 paragraphs max]

## Key Assumptions

- [ ] [Assumption] — [how to test]

## MVP Scope

[Minimum version testing core assumptions]

## Not Doing

- [Thing] — [reason]

## Open Questions

[What needs answering before building]
```

Ask user before saving to `docs/ideas/`. The "Not Doing" list is the most valuable part.

### Anti-patterns

- Don't generate 20+ shallow ideas — 5-8 considered ones
- Don't skip "who is this for"
- Don't skip surfacing assumptions
- Don't produce a plan without a "Not Doing" list
- Don't ignore the codebase
- Don't jump straight to output without phases 1-2

### Tone

Direct, thoughtful, slightly provocative. Channel "that's interesting, but what if..." — push one
step further without exhausting.

## Red Flags

- 20+ shallow variations
- "Who is this for" unanswered
- No assumptions surfaced
- Yes-machining weak ideas
- No "Not Doing" list
- Jumping straight to output without phases 1-2

## Verification

- [ ] Clear "How Might We" problem statement
- [ ] Target user and success criteria defined
- [ ] Multiple directions explored
- [ ] Hidden assumptions listed with validation strategies
- [ ] "Not Doing" list makes trade-offs explicit
- [ ] User confirmed direction before implementation
