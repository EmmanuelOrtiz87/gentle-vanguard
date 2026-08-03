# Domain Assessment Guide

## Step 1: Assess Cause-Effect Relationship

```
## Domain Assessment: [Problem]

Can you see clear cause-effect?

- [ ] Yes, obvious to everyone → CLEAR
- [ ] Yes, but requires expertise → COMPLICATED
- [ ] No, only visible after the fact → COMPLEX
- [ ] No, completely turbulent → CHAOTIC
- [ ] Unsure, mixed signals → DISORDER
```

## Step 2: Test Your Assessment

| Domain      | Test                                          | If yes, stay | If no, reconsider |
| ----------- | --------------------------------------------- | ------------ | ----------------- |
| Clear       | Do best practices exist and work reliably?    | Clear        | Maybe Complicated |
| Complicated | Can experts predict outcomes?                 | Complicated  | Maybe Complex     |
| Complex     | Can you run safe-to-fail experiments?         | Complex      | Maybe Chaotic     |
| Chaotic     | Is the situation too turbulent to experiment? | Chaotic      | Maybe Complex     |

## Step 3: Match Approach

```
## Approach Selection

Domain: [Assessment result]

- Decision-making style: [Best practice / Expert analysis / Experimentation / Crisis response]
- Planning depth: [Detailed / Moderate / Minimal / None]
- Methodology: [Process / Analysis / Agile / Command]
- Success measure: [Efficiency / Quality / Learning / Stability]
```

## Common Mismatches

### Treating Complex as Complicated

```
Symptom: Extensive planning, but outcomes keep surprising
Example: Detailed user research, perfect spec, but users don't engage
Why it fails: You can't analyze your way to understanding emergent behavior
Fix: Probe with experiments, sense patterns, iterate
```

### Treating Complicated as Clear

```
Symptom: "Just do it" approach to expert problems
Example: "Build it like they did at [Company]" without understanding why
Why it fails: Context matters; expertise reveals nuances
Fix: Engage experts, analyze the specific situation
```

### Treating Chaotic as Complex

```
Symptom: Running experiments during a crisis
Example: "Let's A/B test during the outage"
Why it fails: Chaos requires immediate stability, not learning
Fix: Act decisively first, learn later
```

### Treating Clear as Complicated

```
Symptom: Over-engineering simple problems
Example: Designing an architecture for "Hello World"
Why it fails: Wasted effort, delayed delivery
Fix: Apply best practice, don't over-analyze
```
