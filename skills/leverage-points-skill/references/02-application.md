# Applying Leverage Points

## Step 1: Identify Current Interventions

Where are you currently trying to create change?

```markdown
Current interventions:

- Increasing server count (Level 11 - buffers)
- Adjusting timeout parameters (Level 12 - parameters)
- Adding monitoring (Level 6 - information flows)
```

## Step 2: Map to Hierarchy

Plot on the hierarchy to see leverage distribution:

```
High Leverage    [3] Goals
                 [5] Rules
                 [6] Information ← Monitoring
                 [7] Reinforcing loops
Medium           [8] Balancing loops
                 [9] Delays
                 [10] Structure
Low Leverage     [11] Buffers ← Server count
                 [12] Parameters ← Timeouts
```

## Step 3: Look Higher

For each low-leverage intervention, ask: "What's the higher-leverage version?"

| Low Leverage    | Ask                           | Higher Leverage                       |
| --------------- | ----------------------------- | ------------------------------------- |
| More servers    | Why do we need more capacity? | Fix inefficient algorithm (structure) |
| Longer timeouts | Why are things slow?          | Reduce delays in pipeline             |
| More QA staff   | Why so many bugs?             | Change quality rules (Level 5)        |

## Step 4: Assess Feasibility

Higher leverage often means more resistance. Evaluate:

```markdown
Intervention: Change success metric from velocity to outcomes
Leverage: Level 3 (Goals) - Very High
Resistance: High - threatens existing measurement systems
Feasibility: Medium - needs executive buy-in
Strategy: Pilot with one team, demonstrate results, expand
```

## Step 5: Choose Highest Feasible Leverage

Select the highest-leverage intervention you can actually execute.
