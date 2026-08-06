# Dashboard Slide Design

## Executive Dashboard Layout

```
┌──────────────────────────────────────────────────┐
│ HEADER: Key Metric + Trend (Large, Center)       │
│ [KPI: $1.2M ARR]  [↑ 40% YoY]                   │
├──────────┬──────────┬──────────┬─────────────────┤
│ KPI 1    │ KPI 2    │ KPI 3    │ KPI 4           │
│ Revenue  │ Users    │ Retention│ NPS             │
│ $X       │ X,XXX    │ XX%      │ XX              │
│ ↑ X%     │ ↑ X%     │ ↓ X%     │ → X pts         │
├──────────┴──────────┴──────────┴─────────────────┤
│ Main Chart Area (largest real estate)            │
│ [Line chart showing trend over time]             │
├──────────────────────────────────────────────────┤
│ Supporting Detail / Breakdown                    │
│ [Secondary chart or table]                        │
└──────────────────────────────────────────────────┘
```

## KPI Presentation Patterns

### Single KPI (Hero Metric)

`[Large Number]` →
$1,200,000 `[Label]` → Annual Recurring Revenue `[Trend]` → ↑ 40% YoY
`[Sparkline]` → Mini line chart `[Context]` → "On track to hit $2M
by Q4"

### Multiple KPIs (Dashboard Style)

| Metric       | Value  | Trend  | vs Target  | Sparkline |
| ------------ | ------ | ------ | ---------- | --------- |
| ARR          | $1.2M  | ↑ 40%  | ✓ On track | [mini ln] |
| Active Users | 45,000 | ↑ 22%  | ✓ Ahead    | [mini ln] |
| Churn Rate   | 3.2%   | ↓ 0.5% | ⚠ Watch    | [mini ln] |
| NPS          | 62     | ↑ 5pts | ✓ Good     | [mini ln] |

### Waterfall KPI

`[Starting Point]` → `[Change 1]` → `[Change 2]` → `[Change 3]` = `[Result]`
