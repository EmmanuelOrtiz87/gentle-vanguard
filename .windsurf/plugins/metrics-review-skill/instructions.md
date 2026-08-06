# metrics-review-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Metrics Review

> If you see unfamiliar placeholders or need to check which tools are connected, see
> [CONNECTORS.md](../../CONNECTORS.md).

Review and analyze product metrics, identify trends, and surface actionable insights.

## Usage

```
/metrics-review $ARGUMENTS
```

## Workflow

### 1. Gather Metrics Data

If **product analytics** is connected, pull key metrics. Otherwise, ask the user to provide data.

Ask: time period, metrics focus, targets/goals, known events (launches, outages, campaigns).

### 2. Organize the Metrics

Structure hierarchically: North Star → L1 health indicators (acquisition, activation, engagement, retention, revenue, satisfaction) → L2 diagnostic metrics. See [Product Metrics Hierarchy](references/product-metrics-hierarchy.md).

### 3. Analyze Trends

For each metric: current value, trend, vs target, rate of change, anomalies. Identify correlations across metrics and segments.

### 4. Generate the Review

**Summary**: 2-3 sentences on overall health, notable changes, key callout.

**Metric Scorecard**: Table with Metric, Current, Previous, Change, Target, Status.

**Trend Analysis**: What happened, why, sustained vs one-time.

**Bright Spots**: Metrics beating targets, positive trends, strong segments.

**Areas of Concern**: Missing targets, negative trends, visibility gaps.

**Recommended Actions**: Investigations, experiments, investments, alerts.

**Context and Caveats**: Data quality issues, comparability events, missing metrics.

### 5. Follow Up

Ask about deeper investigation, offer dashboard spec, experiment proposals, recurring review template.

## Output Format

Use tables for the scorecard. Use clear status indicators. Keep the summary tight — the reader should get the essential story in 30 seconds.

## Tips

- Start with the "so what" — lead with the most important finding
- Always show comparisons (vs previous period, vs target, vs benchmark)
- Correlation is not causation — acknowledge uncertainty
- Segment analysis reveals what aggregates mask
- Small fluctuations are noise — focus on meaningful changes
- Reviews should drive decisions — recommend actions, not just report misses

## Reference Material

- [Product Metrics Hierarchy](references/product-metrics-hierarchy.md) — North Star, L1/L2 definitions
- [Common Product Metrics](references/common-product-metrics.md) — DAU/WAU/MAU, Retention, Conversion, Activation
- [Goal Setting Frameworks](references/goal-setting-frameworks.md) — OKRs, targets
- [Review Cadences](references/review-cadences.md) — weekly, monthly, quarterly
- [Dashboard Design](references/dashboard-design.md) — layout, principles, anti-patterns, alerting
