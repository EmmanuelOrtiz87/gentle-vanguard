# bayesian-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Bayesian Reasoning

**Core Principle:** Beliefs are probabilities that should update incrementally as evidence arrives. Strong priors require strong evidence to shift.

## When to Use

- Estimating probabilities or likelihoods
- Interpreting test results or metrics
- Making decisions with incomplete information
- Evaluating competing hypotheses
- Learning from experiments or A/B tests
- Diagnosing problems with uncertain causes
- Predicting outcomes based on historical data

Decision flow: `Uncertain? → Have prior? → New evidence? → APPLY BAYESIAN UPDATE`

## Key Concepts

- **Prior P(H):** Your belief BEFORE seeing new evidence (use base rates)
- **Likelihood P(E|H):** How probable is the evidence if H is true?
- **Posterior P(H|E):** Your updated belief AFTER seeing evidence

## Bayes' Theorem

```
                P(E|H) × P(H)
P(H|E) = ─────────────────────────
                   P(E)

Intuitive: Posterior odds = Prior odds × Likelihood ratio
```

## The Process

1. **Establish Prior** — base rates, explicit uncertainty
2. **Assess Evidence** — likelihood under H vs not-H
3. **Update Belief** — multiply prior odds by likelihood ratio
4. **Iterate** — today's posterior is tomorrow's prior

→ Full worked examples in `references/process-and-examples.md`

## Common Applications

**Test Results:** Base rate dominates rare conditions (99% accurate test + 1:10k prevalence → only ~1% post-test probability).

**Debugging:** Assign prior probabilities to root causes, update with each clue.

**Project Estimation:** Start with historical base rate, update with risk factors.

→ Detailed applications in `references/process-and-examples.md`

## Mental Shortcuts

| Evidence Type     | Likelihood Ratio |
| ----------------- | ---------------- |
| Definitive proof  | 100x+            |
| Strong evidence   | 10-100x          |
| Moderate evidence | 3-10x            |
| Weak evidence     | 1.5-3x           |
| Noise             | ~1x              |

→ Calibration, checklist, and Kahneman's warning in `references/shortcuts-and-calibration.md`
