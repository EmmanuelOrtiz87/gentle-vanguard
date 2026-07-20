# Process Steps (Detailed)

## Step 2: Apply "Why" with Evidence Requirement

For each "why," require evidence:

```markdown
Why #1: Why did [problem] occur? Answer: [Hypothesis] Evidence: [Data, logs, metrics that support
this] Confidence: [High/Medium/Low]
```

**Evidence types:**

- Logs showing the event
- Metrics correlating with timeline
- Code showing the behavior
- Configuration proving the state
- Testimony from multiple sources

## Step 3: Branch on "What Else?"

After each "why," explicitly ask "what else could cause this?"

```markdown
Why #1: Why did API response times spike? Primary answer: Database queries were slow Evidence: DB
query times increased from 50ms to 1.5s

What else could cause this?

- [ ] Network latency (checked: normal)
- [ ] Application code changes (checked: none deployed)
- [ ] Memory pressure (checked: normal)
- [ ] External API dependencies (checked: normal)

→ Proceeding with database queries as verified cause
```

## Step 4: Apply "Why Was This Possible?" for Human Error

Never stop at "human error" or "someone made a mistake."

```
BAD chain:
Why did the outage occur? → Config was wrong
Why was config wrong? → Engineer made a typo
→ STOP (blames human)

GOOD chain:
Why did the outage occur? → Config was wrong
Why was config wrong? → Engineer made a typo
Why was a typo possible? → No validation on config changes
Why was there no validation? → Config system doesn't support schemas
Why doesn't it support schemas? → Tech debt, never prioritized
→ ROOT CAUSE: Config validation infrastructure gap
```

## Step 5: Check Stopping Criteria

Only stop when ALL are true:

| Criterion    | Question                                              |
| ------------ | ----------------------------------------------------- |
| Actionable   | Can we take concrete action on this cause?            |
| Controllable | Is this within our control to fix?                    |
| Fundamental  | Would fixing this prevent recurrence?                 |
| Evidenced    | Do we have evidence, not just speculation?            |
| Not-blame    | Is this a system issue, not just "someone messed up"? |

## Step 6: Verify with Counter-Analysis

Before finalizing, apply devil's advocate:

```markdown
Proposed root cause: [X]

Counter-analysis:

1. What evidence contradicts this conclusion?
2. What other explanation fits the evidence?
3. Would someone with a different perspective agree?
4. If we fix X, are we confident the problem won't recur?
5. Are we finding what we expected to find? (confirmation bias check)
```
