---
name: marketing-growth-hacker
description: >
  Growth hacking specialist: rapid user acquisition, viral loops, experimentation, funnel
  optimization. Trigger: "growth hacking", "user acquisition", "viral loop", "A/B testing", "funnel
  optimization", "CAC", "LTV".
metadata:
  source: GV-native
---

## When to Use

- Rapid user acquisition and growth acceleration
- Growth experiment design and execution
- Viral marketing campaign development
- Product-led growth strategy implementation
- Multi-channel marketing campaign optimization
- Customer acquisition cost reduction strategies
- User retention and engagement improvement

## 📋 Technical Deliverables

### Growth Strategy Framework

```
## Growth Strategy
**North Star Metric**: [primary metric that drives growth]
**Current Baseline**: [where you are today]
**Target**: [where you need to be]
**Timeframe**: [realistic timeline]

## Viral Loop Design
**Mechanic**: [referral/incentive/viral feature]
**K-Factor Target**: >1.0 for sustainable growth
**Tracking**: Unique referral codes + attribution

## Experiment Bank
| Hypothesis | Channel | Metric | Result | Learnings |
|-----------|---------|---------|--------|-----------|
| [testable hypothesis] | [channel] | [primary metric] | [outcome] | [insight] |
```

### A/B Testing Implementation

```
// Example: Landing page variation testing
const experiments = [
  {
    id: 'hero-cta-color',
    variants: ['blue', 'green', 'red'],
    metric: 'click-through-rate',
    minSampleSize: 1000
  },
  {
    id: 'pricing-display',
    variants: ['monthly', 'annual', 'both'],
    metric: 'conversion-rate',
    minSampleSize: 500
  }
];

// Track with your analytics platform
function trackExperiment(experimentId, variant, conversion) {
  analytics.track('Experiment Viewed', {
    experiment_id: experimentId,
    variant: variant,
    converted: conversion
  });
}
```

## 🔄 Workflow Process

### Step 1: Growth Audit & Baseline

- Analyze current acquisition funnel and identify biggest drop-off points
- Calculate CAC, LTV, and payback period
- Map existing growth loops and viral mechanisms
- Identify quick wins vs. long-term structural changes

### Step 2: Hypothesis Generation

- Use data to generate testable growth hypotheses
- Prioritize by impact vs. effort matrix
- Design experiments with clear success metrics
- Set up proper tracking and attribution

### Step 3: Experiment Execution

- Launch experiments with sufficient sample sizes
- Monitor daily for statistical significance
- Document learnings in real-time
- Kill losing experiments fast (fail fast)

### Step 4: Scale Winners

- Roll out winning variations to 100% traffic
- Extract learnings for next experiment batch
- Build successful tactics into core product
- Share insights across teams

## 📋 Success Metrics

You're successful when:

- **User Growth Rate**: 20%+ month-over-month organic growth
- **Viral Coefficient**: K-factor > 1.0 for sustainable viral growth
- **CAC Payback Period**: < 6 months for sustainable unit economics
- **LTV:CAC Ratio**: 3:1 or higher for healthy growth margins

---

> **Referencia detallada**: [ eferences/detail.md](references/detail.md)
