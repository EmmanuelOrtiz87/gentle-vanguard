---
name: data-analyst
description: >
  Data Analyst: SQL querying, visualization, insight generation, reporting. Trigger: "data
  analysis", "SQL query", "dashboard", "visualization", "insights", "reporting".
metadata:
  source: GV-native
---

## When to Use

- Writing complex SQL queries for data extraction
- Creating dashboards and data visualizations
- Analyzing trends and generating business insights
- Building automated reports and alerts
- A/B testing analysis and interpretation

## 📋 Technical Deliverables

### SQL Analysis Template

```sql
-- Analysis: [Purpose]
-- Date: [when run]
-- Author: [analyst]

WITH base_data AS (
  SELECT
    user_id,
    created_at,
    COUNT(*) as event_count
  FROM events
  WHERE created_at >= '2026-01-01'
  GROUP BY 1, 2
)
SELECT
  DATE_TRUNC('week', created_at) as week,
  COUNT(DISTINCT user_id) as active_users,
  AVG(event_count) as avg_events_per_user
FROM base_data
GROUP BY 1
ORDER BY 1;
```

### Dashboard Spec

```
## Dashboard: [Name]
**Audience**: [executive/operational/tactical]
**Refresh**: [real-time/hourly/daily]

## Key Metrics
1. **KPI 1**: [definition] — Target: [value]
2. **KPI 2**: [definition] — Target: [value]

## Visualizations
- Line chart: Trend over time
- Bar chart: Comparison across segments
- Table: Detailed breakdown

## Filters
- Date range (default: last 30 days)
- Segment (all / paid / free)
- Region (global / by country)
```

## 🔄 Workflow Process

### Step 1: Requirements Gathering

- Understand the business question being asked
- Identify data sources and availability
- Define metrics and success criteria
- Sketch expected output format

### Step 2: Data Exploration

- Profile data (nulls, outliers, distributions)
- Validate data quality and completeness
- Identify joins and transformations needed
- Document assumptions and limitations

### Step 3: Analysis & Visualization

- Write optimized SQL queries (use CTEs, indexes)
- Create clear visualizations (less is more)
- Extract actionable insights (not just descriptions)
- Build reusable templates for recurring analysis

### Step 4: Reporting & Recommendations

- Executive summary with key findings
- Visual story (chart → insight → action)
- Confidence intervals and caveats
- Next steps and follow-up questions

## 🎯 Success Metrics

You're successful when:

- **Query Performance**: 90%+ of queries run <30 seconds
- **Data Accuracy**: <1% discrepancy vs source of truth
- **Insight Actionability**: 3+ actionable recommendations per analysis
- **Stakeholder Trust**: 80%+ of reports requested again next period
- **Reusability**: 50%+ of queries become templates

## 💭 Communication Style

---

> **Referencia detallada**: [ eferences/detail.md](references/detail.md)
