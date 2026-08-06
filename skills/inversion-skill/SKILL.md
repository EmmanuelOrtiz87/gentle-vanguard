---
name: inversion-skill
description: >
  Imported from cc-thinking-skills. inversion, invert problem, reverse thinking, avoid failure.
metadata:
  source: cc-thinking-skills
  original-name: thinking-inversion
---

# Inversion Thinking

## Overview

Inversion thinking, championed by Charlie Munger and rooted in mathematician Carl Jacobi's principle
"Invert, always invert," approaches problems by considering their opposite. Instead of asking "How
do I succeed?", ask "How would I guarantee failure?" then avoid those paths.

**Core Principle:** "All I want to know is where I'm going to die, so I'll never go there." —
Charlie Munger

## When to Use

- Planning a new project, feature, or initiative
- Evaluating a decision before committing
- Identifying risks that optimistic thinking obscures
- Stuck on how to achieve a positive outcome
- Need to challenge assumptions in a plan
- Writing requirements or acceptance criteria

Decision flow:

```
Have a goal? → yes → Can you list ways to achieve it? → maybe → INVERT FIRST
                                                       ↘ no → Definitely invert
            ↘ no → Define goal, then invert
```

## The Process

### Step 1: Define the Goal Clearly

State what success looks like. Capture the specific outcome.

### Step 2: Invert — Ask "How Would I Fail?"

List all ways to guarantee failure or the opposite of your goal. Aim for 10+ items.

### Step 3: Categorize the Failure Modes

Group by type (security, operations, process, reliability) and severity (critical/high/medium).

### Step 4: Convert to Avoidance Checklist

Transform each failure mode into a positive requirement or mitigation.

### Step 5: Prioritize by Impact

Focus on failures that would be most damaging, most likely, or hardest to recover from.

For full examples of each step, see
[references/inversion-process.md](references/inversion-process.md).

## Application Patterns

- **Technical Design** — Invert "scalable API" → prevent no-caching, sync-everything, N+1,
  no-circuit-breakers
- **Code Review** — Invert "high-quality merge" → prevent security bugs, no tests, poor naming,
  missing error handling
- **Career/Team Building** — Invert "successful career" → prevent unreliability, no learning,
  comfort zone
- **Project Planning** — Invert "successful launch" → prevent no-user-research, no-load-testing,
  no-rollback

For detailed examples, see [references/inversion-examples.md](references/inversion-examples.md).

## Combining with Pre-Mortem

Inversion + Pre-Mortem creates powerful risk identification:

1. **Inversion**: List ways the project could fail (theoretical)
2. **Pre-Mortem**: Imagine it DID fail, explain why (narrative)
3. **Synthesize**: Combine both lists, prioritize, mitigate

## Verification Checklist

- [ ] Goal clearly defined
- [ ] Listed 10+ ways to fail/achieve opposite
- [ ] Categorized failures by type and severity
- [ ] Converted top failures to explicit requirements
- [ ] Verified plan addresses the most critical inversions
- [ ] Shared inversions with team for blind spot check

## Key Questions

- "What would guarantee failure here?"
- "What mistakes do others commonly make?"
- "What am I most likely to overlook?"
- "If this fails spectacularly, what will the postmortem say?"
- "What would I tell someone else to avoid?"
- "What would the opposite of success look like, specifically?"

## Munger's Warning

"It is remarkable how much long-term advantage people like us have gotten by trying to be
consistently not stupid, instead of trying to be very intelligent."

The power of inversion is in avoiding obvious errors that optimism blinds us to. Simple avoidance
often beats clever optimization.
