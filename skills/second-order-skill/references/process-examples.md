# Process Examples

## Step 2: Ask "And Then What?"

Chain the consequences:

```
Feature flags → More flags created → Flag debt accumulates
             → Teams don't clean up → Combinatorial testing complexity
             → Bugs from flag interactions → "Turn it off" becomes risky
             → Flags become permanent → Codebase complexity explodes
```

## Step 3: 10/10/10 Framework

| Timeframe  | Question                                  | Analysis              |
| ---------- | ----------------------------------------- | --------------------- |
| 10 minutes | How will I feel right after?              | Relief—problem solved |
| 10 months  | How will this affect things in 10 months? | Flag sprawl emerging  |
| 10 years   | What's the long-term trajectory?          | Technical debt crisis |

## Step 4: Systemic Effects

Ask: "What if everyone did this?"

```
Decision: Skip code review for urgent fixes
If everyone: All urgent fixes skip review
Result: Definition of "urgent" expands → most things skip review
Outcome: Quality collapses, more urgent fixes needed
```

## Step 5: Consequence Chain Diagram

```
┌─────────────────┐
│ Decision: X     │
└────────┬────────┘
         ▼
┌─────────────────┐
│ 1st Order: A    │ ← Obvious, intended
└────────┬────────┘
         ▼
┌─────────────────┐
│ 2nd Order: B    │ ← Less obvious
└────────┬────────┘
         ▼
┌─────────────────┐
│ 3rd Order: C    │ ← Often counterintuitive
└────────┬────────┘
         ▼
┌─────────────────┐
│ Feedback Loop   │ ← May reinforce or counteract
└─────────────────┘
```
