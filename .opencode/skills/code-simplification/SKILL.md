---
name: code-simplification
description:
  Simplifies code for clarity. Use when refactoring code for clarity without changing behavior. Use
  when code works but is harder to read, maintain, or extend than it should be. Use when reviewing
  code that has accumulated unnecessary complexity.
---

# Code Simplification

> Inspired by the [Claude Code Simplifier plugin](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-simplifier/agents/code-simplifier.md).
> Adapted as a model-agnostic, process-driven skill.

Simplify code by reducing complexity while preserving exact behavior. The goal is not fewer lines — it's code that is easier to read, understand, modify, and debug. Every simplification must pass a simple test: "Would a new team member understand this faster than the original?"

## When to Use

- After a feature works and tests pass, but the implementation feels heavier than needed
- During code review when readability or complexity issues are flagged
- When you encounter deeply nested logic, long functions, or unclear names
- When refactoring code written under time pressure
- When consolidating related logic scattered across files
- After merging changes that introduced duplication or inconsistency

**When NOT to use:**
- Code is already clean and readable — don't simplify for the sake of it
- You don't understand what the code does yet — comprehend before you simplify
- The code is performance-critical and the "simpler" version would be measurably slower
- You're about to rewrite the module entirely — simplifying throwaway code wastes effort

## The Five Principles

See [references/principles.md](references/principles.md) for full details and code examples.

1. **Preserve Behavior Exactly** — Change only *how* the code expresses intent, never what it does.
2. **Follow Project Conventions** — Match the codebase; don't impose external preferences.
3. **Prefer Clarity Over Cleverness** — Explicit code beats compact code when comprehension requires a mental pause.
4. **Maintain Balance** — Avoid over-simplification traps (inlining, combining logic, removing useful abstractions, optimizing for line count).
5. **Scope to What Changed** — Simplify recently modified code; avoid drive-by refactors.

## The Simplification Process

### Step 1: Understand Before Touching

Before changing anything, understand why it exists. Read context, check git blame, trace callers and edge cases. See [references/patterns.md](references/patterns.md) for the full Chesterton's Fence checklist.

### Step 2: Identify Simplification Opportunities

Scan for structural complexity, naming issues, and redundancy. See [references/patterns.md](references/patterns.md) for the full table of 15+ patterns.

### Step 3: Apply Changes Incrementally

One simplification at a time. Run tests after each change. Keep refactoring separate from feature work.

- **Rule of 500:** If touching >500 lines, use codemods or scripts instead of manual edits.

### Step 4: Verify the Result

Compare before and after. Is it genuinely easier to understand? See [references/reference.md](references/reference.md#verification-checklist) for the full checklist.

## Language-Specific Examples

- [TypeScript / JavaScript](references/code-examples.md#typescript--javascript)
- [Python](references/code-examples.md#python)
- [React / JSX](references/code-examples.md#react--jsx)

## Common Rationalizations & Red Flags

See [references/reference.md](references/reference.md) for the full rationalizations table, red flags, and verification checklist.
