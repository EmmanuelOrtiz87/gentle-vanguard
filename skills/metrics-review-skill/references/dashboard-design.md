## Dashboard Design Principles

### Effective Product Dashboards

A good dashboard answers the question "How is the product doing?" at a glance.

**Principles**:

1. **Start with the question, not the data**. What decisions does this dashboard support? Design backwards from the decision.

2. **Hierarchy of information**. The most important metric should be the most visually prominent. North Star at the top, L1 metrics next, L2 metrics available on drill-down.

3. **Context over numbers**. A number without context is meaningless. Always show: current value, comparison (previous period, target, benchmark), trend direction.

4. **Fewer metrics, more insight**. A dashboard with 50 metrics helps no one. Focus on 5-10 that matter. Put everything else in a detailed report.

5. **Consistent time periods**. Use the same time period for all metrics on a dashboard. Mixing daily and monthly metrics creates confusion.

6. **Visual status indicators**. Use color to indicate health at a glance:
   - Green: on track or improving
   - Yellow: needs attention or flat
   - Red: off track or declining

7. **Actionability**. Every metric on the dashboard should be something the team can influence. If you cannot act on it, it does not belong on the product dashboard.

### Dashboard Layout

**Top row**: North Star metric with trend line and target.
**Second row**: L1 metrics scorecard — current value, change, target, status for each key metric.
**Third row**: Key funnels or conversion metrics — visual funnel showing drop-off at each stage.
**Fourth row**: Recent experiments and launches — active A/B tests, recent feature launches with early metrics.
**Bottom / drill-down**: L2 metrics, segment breakdowns, and detailed time series for investigation.

### Dashboard Anti-Patterns

- **Vanity metrics**: Metrics that always go up but do not indicate health (total signups ever, total page views)
- **Too many metrics**: Dashboards that require scrolling to see. If it does not fit on one screen, cut metrics.
- **No comparison**: Raw numbers without context (current value with no previous period or target)
- **Stale dashboards**: Metrics that have not been updated or reviewed in months
- **Output dashboards**: Measuring team activity (tickets closed, PRs merged) instead of user and business outcomes
- **One dashboard for all audiences**: Executives, PMs, and engineers need different views. One size does not fit all.

### Alerting

Set alerts for metrics that require immediate attention:
- **Threshold alerts**: Metric drops below or rises above a critical threshold (error rate > 1%, conversion < 5%)
- **Trend alerts**: Metric shows sustained decline over multiple days/weeks
- **Anomaly alerts**: Metric deviates significantly from expected range

**Alert hygiene**:
- Every alert should be actionable. If you cannot do anything about it, do not alert on it.
- Review and tune alerts regularly. Too many false positives and people ignore all alerts.
- Define an owner for each alert. Who responds when it fires?
- Set appropriate severity levels. Not everything is P0.
