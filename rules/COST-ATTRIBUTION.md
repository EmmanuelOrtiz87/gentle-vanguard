# Cost Attribution Policy

**Version:** 1.0.0 | **Date:** 2026-07-04 | **Status:** Active

## Purpose

Track, attribute, and report costs per agent, task, model, and skill. Enable ROI measurement and
cost optimization decisions.

---

## Cost Tracking Dimensions

### 1. Per-Agent Attribution

Every token consumption is tagged with:

```json
{
  "agent": "DEV-apply",
  "session_id": "session-2026-07-04",
  "task_id": "task-001",
  "model": "claude-3.5-sonnet",
  "input_tokens": 3500,
  "output_tokens": 1200,
  "cost_usd": 0.0228,
  "timestamp": "2026-07-04T10:30:00Z"
}
```

### 2. Per-Task Type Attribution

| Task Type       | Expected Cost Range | Alert Threshold |
| --------------- | ------------------- | --------------- |
| Typo/Fix        | $0.001 - $0.01      | > $0.05         |
| Feature (small) | $0.01 - $0.10       | > $0.20         |
| Feature (large) | $0.10 - $0.50       | > $1.00         |
| Refactor        | $0.05 - $0.30       | > $0.60         |
| Architecture    | $0.20 - $1.00       | > $2.00         |
| Security Review | $0.10 - $0.50       | > $1.00         |
| Documentation   | $0.02 - $0.10       | > $0.20         |

### 3. Per-Model Attribution

Track which models are used and their cost efficiency:

| Model         | Usage Count | Total Cost | Avg Cost/Task | Efficiency Score |
| ------------- | ----------- | ---------- | ------------- | ---------------- |
| GPT-4o        | {count}     | ${cost}    | ${avg}        | {score}          |
| Claude Sonnet | {count}     | ${cost}    | ${avg}        | {score}          |
| GPT-4o-mini   | {count}     | ${cost}    | ${avg}        | {score}          |
| Claude Haiku  | {count}     | ${cost}    | ${avg}        | {score}          |

### 4. Per-Skill Attribution

Track which skills consume the most resources:

| Skill        | Invocations | Total Tokens | Total Cost | ROI Score |
| ------------ | ----------- | ------------ | ---------- | --------- |
| {skill_name} | {count}     | {tokens}     | ${cost}    | {score}   |

---

## ROI Measurement

### Task ROI Formula

```
ROI = (Value of Output) / (Cost of Execution)

Where:
  Value of Output = Time saved × Developer hourly rate
  Cost of Execution = Token cost + Infrastructure cost
```

### Example Calculations

| Task                 | Time Saved | Dev Rate | Value   | Token Cost | ROI  |
| -------------------- | ---------- | -------- | ------- | ---------- | ---- |
| Bug fix (30min→2min) | 28min      | $75/hr   | $35.00  | $0.15      | 233x |
| Feature (4hr→45min)  | 3.25hr     | $75/hr   | $243.75 | $0.80      | 305x |
| Refactor (2hr→20min) | 1.67hr     | $75/hr   | $125.00 | $0.40      | 313x |

---

## Budget Allocation

### Monthly Budget by Category

| Category          | Allocation | Alert At | Hard Limit |
| ----------------- | ---------- | -------- | ---------- |
| Development (DEV) | 40%        | 35%      | 45%        |
| Analysis (BA/SAD) | 20%        | 18%      | 25%        |
| Testing (QA)      | 15%        | 13%      | 18%        |
| Operations (OPS)  | 10%        | 9%       | 12%        |
| Governance (GOV)  | 5%         | 4%       | 7%         |
| Documentation     | 5%         | 4%       | 7%         |
| Buffer            | 5%         | —        | —          |

### Cost Reduction Targets

| Quarter | Target | Strategy                   |
| ------- | ------ | -------------------------- |
| Q3 2026 | -10%   | Model routing optimization |
| Q4 2026 | -15%   | Cache hit rate improvement |
| Q1 2027 | -20%   | Context compression        |
| Q2 2027 | -25%   | Prompt optimization        |

---

## Reporting

### Real-Time Dashboard

The LLM Observability Dashboard tracks:

- Current session cost
- Per-agent token consumption
- Model distribution pie chart
- Cost trend line (24h, 7d, 30d)
- Budget utilization gauges

### Weekly Cost Report (auto-generated)

```markdown
# Weekly Cost Report — Week {number}

## Summary

- Total Cost: ${total}
- Budget Utilized: {percent}%
- Week-over-Week: {change}%

## Top Cost Drivers

1. {agent}: ${cost} ({percent}%)
2. {agent}: ${cost} ({percent}%)
3. {agent}: ${cost} ({percent}%)

## Optimization Opportunities

- {opportunity_1}
- {opportunity_2}

## Recommendations

- {recommendation_1}
```

---

## Enforcement

1. **token-budget-guard.ps1** enforces per-task limits
2. **cost-tracker.ps1** logs all token consumption
3. **dashboard** displays real-time cost metrics
4. **weekly-report.ps1** generates cost analysis
5. **watchtower** checks cost health weekly

---

## Related Files

- `scripts/utilities/telemetry/TELEMETRY-METRICS/token-budget-guard.ps1`
- `scripts/utilities/telemetry/TELEMETRY-METRICS/cost-tracker.ps1`
- `apps/web-dashboard/` (dashboard)
- `rules/TOKEN-BUDGET-POLICY.md`
- `rules/NORMATIVAS-PERFORMANCE.md`
