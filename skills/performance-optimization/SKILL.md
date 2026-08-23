---
name: performance-optimization
aliases: ["performance-optimization"]
description: >
  Performance Optimization
triggers:
  - performance optimization
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.074Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\performance-optimization\SKILL.md
  version: "1.0.0"
---

# Performance Optimization

## Overview

Measure, don't guess. Profile first, identify the actual bottleneck, fix it, measure again.

## When to Use

- Performance requirements exist in the spec (load time budgets, response time SLAs)
- Users or monitoring report slow behavior
- Core Web Vitals scores are below thresholds
- You suspect a change introduced a regression
- Building features that handle large datasets or high traffic

**When NOT to use:** Don't optimize before you have evidence of a problem. Premature optimization
adds complexity that costs more than the performance it gains.

## Core Web Vitals Targets

| Metric                              | Good    | Needs Improvement | Poor    |
| ----------------------------------- | ------- | ----------------- | ------- |
| **LCP** (Largest Contentful Paint)  | ≤ 2.5s  | ≤ 4.0s            | > 4.0s  |
| **INP** (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms           | > 500ms |
| **CLS** (Cumulative Layout Shift)   | ≤ 0.1   | ≤ 0.25            | > 0.25  |

## Optimization Workflow

```
1. MEASURE  → Establish baseline with real data
2. IDENTIFY → Find the actual bottleneck (not assumed)
3. FIX      → Address the specific bottleneck
4. VERIFY   → Measure again, confirm improvement
5. GUARD    → Add monitoring or tests to prevent regression
```

### Step 1: Measure

See [Measurement Reference](references/measurement.md) for synthetic/RUM approaches, Core Web Vitals
details, and the diagnostic decision tree.

### Step 2: Identify

See [Anti-Patterns Reference](references/anti-patterns.md) for bottleneck identification tables and
common patterns by symptom.

### Step 3-5: Fix, Verify, Guard

See [Anti-Patterns Reference](references/anti-patterns.md) for code examples (N+1, unbounded data,
image optimization, React re-renders, bundle splitting, caching).

## Performance Budgets

See [Budgets Reference](references/budgets.md) for recommended targets and CI enforcement.

## Common Rationalizations

| Rationalization                     | Reality                                                                               |
| ----------------------------------- | ------------------------------------------------------------------------------------- |
| "We'll optimize later"              | Performance debt compounds. Fix obvious anti-patterns now, defer micro-optimizations. |
| "It's fast on my machine"           | Your machine isn't the user's. Profile on representative hardware and networks.       |
| "This optimization is obvious"      | If you didn't measure, you don't know. Profile first.                                 |
| "Users won't notice 100ms"          | Research shows 100ms delays impact conversion rates. Users notice more than you know. |
| "The framework handles performance" | Frameworks prevent some issues but can't fix N+1 queries or oversized bundles.        |

## Red Flags

- Optimization without profiling data to justify it
- N+1 query patterns in data fetching
- List endpoints without pagination
- Images without dimensions, lazy loading, or responsive sizes
- Bundle size growing without review
- No performance monitoring in production
- `React.memo` and `useMemo` everywhere (overusing is as bad as underusing)

## Reference Files

| File                                         | Content                                                            |
| -------------------------------------------- | ------------------------------------------------------------------ |
| [Measurement](references/measurement.md)     | Synthetic & RUM approaches, diagnostic tree, Core Web Vitals table |
| [Anti-Patterns](references/anti-patterns.md) | Bottleneck tables, all code examples with BAD/GOOD patterns        |
| [Budgets](references/budgets.md)             | Budget targets, CI commands, verification checklist                |

## Examples

Concrete usage drawn from this skill's own documentation:

```
1. MEASURE  → Establish baseline with real data
2. IDENTIFY → Find the actual bottleneck (not assumed)
3. FIX      → Address the specific bottleneck
4. VERIFY   → Measure again, confirm improvement
5. GUARD    → Add monitoring or tests to prevent regression
```
