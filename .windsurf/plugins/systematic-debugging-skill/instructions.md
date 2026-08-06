# systematic-debugging-skill

> Gentle-Vanguard Skill

## Description

>

## Triggers

## Instructions

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue: test failures, production bugs, unexpected behavior, performance
problems, build failures, integration issues.

**Use ESPECIALLY when:** under time pressure, "just one quick fix" seems obvious, you've already
tried multiple fixes, previous fix didn't work, you don't fully understand the issue.

**Don't skip when:** issue seems simple, you're in a hurry, manager wants it fixed NOW.

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

1. Read error messages carefully
2. Reproduce consistently
3. Check recent changes
4. Gather evidence across component boundaries
5. Trace data flow backward from symptom

→ See `references/evidence-gathering.md` for multi-component diagnostic techniques.

### Phase 2: Pattern Analysis

1. Find working examples in the same codebase
2. Compare against reference implementations
3. Identify differences between working and broken
4. Understand dependencies and assumptions

### Phase 3: Hypothesis and Testing

1. Form a single hypothesis with clear reasoning
2. Test with the smallest possible change
3. Verify before continuing — one variable at a time
4. If stuck, say "I don't understand X" and research more

### Phase 4: Implementation

1. Create a failing test case first
2. Implement a single fix addressing the root cause
3. Verify the fix and check for regressions
4. If fix doesn't work, return to Phase 1
5. **After 3 failed fixes: question the architecture**

→ See `references/advanced-patterns.md` for architectural questioning and edge cases.

## Red Flags — STOP and Follow Process

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Skip the test, I'll manually verify"
- Proposing solutions before tracing data flow
- "One more fix attempt" (when already tried 2+)
- Each fix reveals a new problem in a different place

**ALL of these mean: STOP. Return to Phase 1.**

→ See `references/common-pitfalls.md` for rationalizations and partner signals.

## Quick Reference

| Phase                 | Key Activities                                         | Success Criteria            |
| --------------------- | ------------------------------------------------------ | --------------------------- |
| **1. Root Cause**     | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY     |
| **2. Pattern**        | Find working examples, compare                         | Identify differences        |
| **3. Hypothesis**     | Form theory, test minimally                            | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify                               | Bug resolved, tests pass    |

## Supporting Techniques

- `references/evidence-gathering.md` — Multi-component diagnostic instrumentation
- `references/advanced-patterns.md` — Architecture questioning, no-root-cause handling, real-world
  impact
- `references/common-pitfalls.md` — Rationalizations table, partner redirection signals
