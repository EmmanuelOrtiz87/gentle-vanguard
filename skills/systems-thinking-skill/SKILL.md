---
name: systems-thinking-skill
description: >
  Imported from cc-thinking-skills.
metadata:
  source: cc-thinking-skills
  original-name: thinking-systems
---

# Systems Thinking

Systems thinking views problems as part of interconnected wholes. Focuses on relationships, feedback loops, and emergent properties—behaviors that arise from interactions and can't be predicted from parts alone.

## When to Use

- Debugging issues spanning multiple services
- Understanding unexpected emergent behavior
- Designing resilient architectures
- Analyzing incidents and outages
- When fixing one thing breaks another
- Performance issues with non-obvious causes
- Organizational/process problems

## Key Concepts

### 1. Feedback Loops

**Reinforcing (Positive):** Amplify change. E.g., technical debt: deadline pressure → shortcuts → bugs → firefighting → less time for quality.

**Balancing (Negative):** Counteract change. E.g., auto-scaling: load increases → more instances → load per instance decreases.

### 2. Stocks and Flows

**Stocks** are accumulated quantities (users, tech debt, cache size). **Flows** are rates of change (registrations/day, bugs fixed/sprint). Stocks change slowly even when flows change quickly.

### 3. Delays

Time lags between cause and effect obscure relationships. Acting before feedback arrives leads to overcorrection.

### 4. Non-Linear Relationships

Small changes can have large effects. E.g., 2x traffic crossing a threshold can cause 10x latency due to queue buildup.

### 5. Emergent Properties

Behaviors arising from interactions, not components. E.g., no single service is slow but the system is slow due to cascading delays.

## Systems Debugging Process

1. **Map the System** — Draw components, connections, and flows
2. **Identify Feedback Loops** — Reinforcing or balancing? Delays? Stability?
3. **Trace Upstream** — Follow symptom backward to root cause
4. **Look for Interactions** — Circuit breakers, cascading timeouts, contention
5. **Consider Time Dynamics** — When did it start? What changed? Periodic?

See `references/systems-debugging.md` for diagrams and full explanation.

## Common System Patterns

- **Cascading Failure** — Mitigation: circuit breakers, bulkheads, graceful degradation
- **Thundering Herd** — Mitigation: jittered expiration, cache warming, coalescing
- **Queue Backup** — Mitigation: backpressure, rate limiting, bounded queues
- **Resource Contention** — Mitigation: sharding, optimistic locking, isolation

See `references/common-system-patterns.md` for diagrams.

## Leverage Points

Where small changes have large effects (Donella Meadows):

| Leverage          | Example              | Impact           |
| ----------------- | -------------------- | ---------------- |
| Parameters        | Timeout values       | Low              |
| Buffer sizes      | Queue limits         | Low-Medium       |
| Feedback loops    | Add monitoring       | Medium           |
| Information flows | Make metrics visible | Medium-High      |
| Rules             | Change retry policy  | High             |
| Goals             | Redefine SLOs        | Very High        |
| Paradigm          | Rethink architecture | Transformational |

## Key Questions

- "What feeds back into what?"
- "Where are the delays in this system?"
- "If I fix this here, what breaks over there?"
- "Where is the smallest change with the largest effect?"

## Meadows' Reminder

"We can't control systems or figure them out. But we can dance with them."

Systems resist simple fixes. Find leverage points, influence the whole.

## References

- `references/systems-debugging.md` — Full debugging process with diagrams
- `references/common-system-patterns.md` — Pattern diagrams and mitigations
- `references/causal-loop-diagram-template.md` — CLD template with legend
- `references/verification-checklist.md` — Checklist for systems analysis
