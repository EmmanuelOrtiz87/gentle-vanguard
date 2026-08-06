---
name: clean-code-skill
description: >
  Imported from mercury-agent-skills. For clean code, code quality, refactoring.
metadata:
  source: mercury-agent-skills
  original-name: clean-code
---

# Clean Code

Write code that humans can read, understand, and change with confidence.

## Core Principles

### 1. Mean What You Say — Say What You Mean

Code is communication. Every name, structure, and abstraction should reveal intent. If you need a
comment to explain _what_ the code does, the code is failing at communication.

### 2. Small Things, Done Well

Small functions, small classes, small files. Each unit of code should have one clear responsibility
and do it well. Composability beats complexity.

### 3. The Boy Scout Rule

Leave the code cleaner than you found it. Every commit should improve the codebase incrementally —
even if it's just renaming one variable or extracting one function.

### 4. Testability == Design Quality

If code is hard to test, it has a design problem. Testable code is modular, decoupled, and honest
about its dependencies.

---

## Clean Code Scoring Rubric

Use this rubric to evaluate code quality on a scale of 1-5 for each dimension:

| Dimension          | 1 (Poor)                                    | 3 (Adequate)                                      | 5 (Excellent)                              |
| ------------------ | ------------------------------------------- | ------------------------------------------------- | ------------------------------------------ |
| **Naming**         | Single-letter vars, ambiguous abbreviations | Descriptive but occasionally redundant            | Reveals intent, consistent, searchable     |
| **Function Size**  | Monolithic 500+ line functions              | 50-100 line functions with mixed concerns         | <20 lines, one clear level of abstraction  |
| **Comments**       | Outdated or redundant comments              | Comments explain _what_ not _why_                 | Minimal comments, code is self-documenting |
| **Error Handling** | Silent catches, magic error codes           | Basic try/catch, some error types                 | Rich error types, graceful degradation     |
| **Testing**        | No tests or brittle tests                   | Tests exist but tightly coupled to implementation | Tests specify behavior, not implementation |
| **Duplication**    | Copy-paste everywhere                       | Some reuse, some DRY violations                   | DRY with well-abstracted patterns          |

Target: **4+ in every dimension** for production-grade code.

---

## Actionable Guidance

Detailed guidance for each area is in `references/`:

| Area           | File                                                         |
| -------------- | ------------------------------------------------------------ |
| Naming         | [references/naming.md](references/naming.md)                 |
| Functions      | [references/functions.md](references/functions.md)           |
| Comments       | [references/comments.md](references/comments.md)             |
| Error Handling | [references/error-handling.md](references/error-handling.md) |
| Testing        | [references/testing.md](references/testing.md)               |

### Code Smells to Hunt

| Smell                      | Symptom                                               | Fix                              |
| -------------------------- | ----------------------------------------------------- | -------------------------------- |
| **Long Method**            | >20 lines doing multiple things                       | Extract methods, compose         |
| **Switch/Types**           | Switch on type enum, then dispatch                    | Polymorphism or strategy pattern |
| **Feature Envy**           | Method uses more of another class's data than its own | Move method to the right class   |
| **Shotgun Surgery**        | One change requires edits in many files               | Consolidate related logic        |
| **Data Clumps**            | Same 3-4 fields appear together repeatedly            | Extract into a value object      |
| **Primitive Obsession**    | Using strings/ints where types belong                 | Create domain types              |
| **Inappropriate Intimacy** | Class knows too much about another's internals        | Reduce coupling, use interfaces  |

---

## Common Mistakes

1. **Over-optimizing for performance before clarity**: 99% of code doesn't need micro-optimization.
   Write clear code first, profile, then optimize the hot paths.
2. **Over-engineering**: YAGNI (You Ain't Gonna Need It). Don't add abstractions for hypothetical
   future needs.
3. **Perfect as enemy of good**: Clean code is a journey, not a destination. Incremental improvement
   beats paralysis.
4. **Ignoring the team's conventions**: Consistency within a codebase matters more than personal
   preference for a particular style.
5. **Applying rules blindly**: All rules have exceptions. Context matters.
