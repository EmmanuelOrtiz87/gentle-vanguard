---
name: fermi-skill
description: >
  Imported from cc-thinking-skills. fermi, estimation, order of magnitude, back of envelope,
  approximation.
metadata:
  source: cc-thinking-skills
  original-name: thinking-fermi-estimation
---

# Fermi Estimation

## Overview

Fermi estimation decomposes impossible-to-know quantities into estimable factors. Errors tend to
cancel across factors, yielding useful order-of-magnitude results.

## When to Use

- Capacity / cost / market sizing, feasibility, sanity checks, prioritization
- Use when you can't measure directly but need a number anyway

## Process

1. **Clarify** — precise question, not vague
2. **Decompose** — 3-6 independent factors (component, rate×time, population×%, analogy)
3. **Estimate each** — use ranges, geometric mean, one significant figure
4. **Combine** — multiply/add factors
5. **Sanity check** — plausible? physical? 10x change decision?
6. **State result** — point estimate, range, confidence, implication

## Decomposition Strategies

| Strategy             | Formula                    |
| -------------------- | -------------------------- |
| By component         | Total = Sum of parts       |
| Rate × time          | Total = Rate × Duration    |
| Population × %       | Target = Base × Percentage |
| Analogy × adjustment | New ≈ Similar × Ratio      |

## Key Questions

- Can I break this into smaller pieces?
- What's the upper / lower bound?
- Would being off by 10x change my decision?
- Can I cross-check via a different approach?

> Estimate first to know what answer to expect, then calculate to verify. — John Wheeler

---

_Examples, template, patterns, tips, and checklist moved to `references/`._
