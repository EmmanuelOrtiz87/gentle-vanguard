# Bayesian Process — Worked Examples

## Step 1: Establish Your Prior

```
Question: Will this feature increase conversion?
Prior: Based on similar features, ~30% succeed significantly
       P(success) = 0.30
```

- Use base rates when available
- Be explicit about uncertainty
- Don't anchor on 50% just because you're unsure

## Step 2: Assess the Evidence

Consider:
- How likely is this evidence if hypothesis is TRUE?
- How likely is this evidence if hypothesis is FALSE?
- What's the ratio?

```
Evidence: Early A/B test shows 5% lift (p=0.08)
P(this result | feature works) = 0.60 (moderately expected)
P(this result | feature doesn't work) = 0.15 (possible but less likely)
Likelihood ratio = 0.60 / 0.15 = 4x
```

## Step 3: Update Your Belief

```
Prior odds: 0.30 / 0.70 = 0.43
Likelihood ratio: 4x
Posterior odds: 0.43 × 4 = 1.72
Posterior probability: 1.72 / (1 + 1.72) = 0.63

Updated belief: 63% confidence feature will succeed
(up from 30% prior)
```

## Step 4: Iterate

Yesterday's posterior becomes today's prior:

```
New evidence: Week 2 shows lift holding at 4.5%
Prior (from step 3): 0.63
[Repeat update process]
New posterior: 0.78
```

## Full Worked Example: Interpreting Test Results

```
Scenario: Test for rare disease (1 in 10,000 prevalence)
Test: 99% sensitive, 99% specific

Prior: P(disease) = 0.0001
If positive test:
  P(positive|disease) = 0.99
  P(positive|no disease) = 0.01
  P(positive) = 0.99 × 0.0001 + 0.01 × 0.9999 ≈ 0.0101

Posterior: P(disease|positive) = (0.99 × 0.0001) / 0.0101 ≈ 0.0098

Even with 99% accurate test, positive result only means ~1% chance of disease!
Base rate dominates when condition is rare.
```

## Debugging Application

```
Bug report: Users see error X
Prior beliefs:
  P(database issue) = 0.20
  P(network issue) = 0.30
  P(code bug) = 0.40
  P(user error) = 0.10

Evidence: Error happens only on mobile
  P(mobile-only | database) = 0.05
  P(mobile-only | network) = 0.30
  P(mobile-only | code bug) = 0.60
  P(mobile-only | user error) = 0.40

Update: Code bug becomes most likely (posterior ~0.55)
Next step: Investigate mobile-specific code paths
```

## Project Estimation

```
Prior: Based on similar projects, P(on-time) = 0.40

Evidence 1: Team is experienced with this stack
  Likelihood ratio: 1.5x → Posterior: 0.50

Evidence 2: Requirements are unclear
  Likelihood ratio: 0.6x → Posterior: 0.38

Evidence 3: Critical dependency has risk
  Likelihood ratio: 0.7x → Posterior: 0.30

Final estimate: 30% chance of on-time delivery
```
