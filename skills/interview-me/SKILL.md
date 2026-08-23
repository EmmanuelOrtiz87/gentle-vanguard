---
name: interview-me
aliases: ["interview-me"]
description:
  Extract what the user actually wants. One-question-at-a-time interviewing with hypothesis
  attached.
  
triggers:
  - interview
  - clarify
  - extract requirements
  - interview me
  - grill me
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.061Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\interview-me\SKILL.md
  version: "1.0.0"
---

# Interview Me

## Overview

What people ask for and what they actually want differ. They ask for "a dashboard" because that's
the convention, not because it solves their problem. The cheapest moment to find this gap is before
any plan, spec, or code exists — once you start building, switching costs lock the misfit in.

This skill is the prequel to `idea-refine` and `spec-driven-development`: asking one question at a
time, with your guess attached, until you can predict what the user will say before they say it.

## When to Use

Apply when the ask is missing **who** / **why** / **success** / **constraint**, or when it's
conventional ("build me X") and you can't unpack it without guessing. Also when the user explicitly
invokes "interview me", "grill me", "are we sure?", or "stress-test my thinking."

**Do not use** for unambiguous asks, mechanical operations, info requests, or when the user wants
speed over verification. Verify ≥95% confidence via the stop condition.

## Loading Constraints

Requires a live, responsive user. Do not invoke in CI, scheduled runs, `/loop`, or autonomous loops.
Flag underspecified asks as blockers instead.

## The Process

### Step 1: Hypothesize

Write the user's desired outcome in **one sentence** + a 0–100% confidence number. Below ~70%,
append a reason (what's missing).

### Step 2: Ask one at a time, each with a guess

Format: `Q: <question>` / `GUESS: <hypothesis>`. Wait for a reaction. The guess commits you to
something you can be wrong about.

### Step 3: Listen for "want vs. should want"

Probe sophistication-signaling answers ("scalable", "clean architecture") with: _"If you didn't have
to justify this to anyone, what would you actually want?"_

### Step 4: Restate

Structure: **Outcome** / **User** / **Why now** / **Success** / **Constraint** / **Out of scope** —
"Out of scope" is non-negotiable.

### Step 5: Confirm explicit yes

"Whatever you think," "sounds good," "sure, let's go" are not yes. Loop until explicit yes.

### The 95% Stop Condition

Done when you can predict the user's reaction to the next three questions. If you can't, keep
asking. If several rounds still can't predict, flag it.

## Output

A confirmed statement of intent (Step 4 restate + Step 5 yes). Specs and plans are downstream.
Optionally persist to `docs/intent/[topic].md` on user confirmation.

## Interaction with Other Skills

- **`idea-refine`**: downstream — variations against confirmed intent
- **`spec-driven-development`**: downstream — intent to spec
- **`planning-and-task-breakdown`**: two hops downstream
- **`doubt-driven-development`**: post-decision artifact review
- **`source-driven-development`**: orthogonal

## References

- [Process Guide](references/process-guide.md) — Full rationale and common mistakes
- [Example](references/example.md) — Before/after walkthrough
- [Reference Tables](references/reference-tables.md) — Rationalizations, red flags, verification

## Examples

**Input:** a task matching `interview-me` triggers.
**Action:** apply the workflow described above.
**Expected result:** Extract what the user actually wants.
