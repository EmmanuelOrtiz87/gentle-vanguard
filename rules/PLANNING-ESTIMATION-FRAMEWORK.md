# Planning & Estimation Framework

**Version:** 1.0.0 | **Date:** 2026-07-04 | **Status:** Active

## Purpose

Provide a standardized framework for estimating AI-assisted development tasks, tracking velocity,
and predicting delivery timelines with high accuracy.

---

## Task Complexity Scoring

### Score Definition (1-5)

| Score | Name     | Description                        | Files Changed | Time Range | Token Estimate |
| ----- | -------- | ---------------------------------- | ------------- | ---------- | -------------- |
| 1     | Trivial  | Typo, rename, config change        | 1             | 1-5 min    | 500-2,000      |
| 2     | Simple   | Bug fix, small feature             | 1-3           | 5-30 min   | 2,000-8,000    |
| 3     | Medium   | Multi-file feature, refactor       | 3-10          | 30min-2hr  | 8,000-25,000   |
| 4     | Complex  | Architecture, major feature        | 10-25         | 2-8hr      | 25,000-60,000  |
| 5     | Critical | Security, data migration, breaking | 25+           | 8-24hr     | 60,000-100,000 |

### Complexity Factors

Multiply base score by these factors:

| Factor               | Multiplier | Condition                         |
| -------------------- | ---------- | --------------------------------- |
| External dependency  | ×1.3       | Requires API, library, or service |
| Security impact      | ×1.5       | Handles auth, PII, or secrets     |
| Breaking change      | ×1.4       | Changes public API or interface   |
| Cross-platform       | ×1.2       | Must work on Windows/Linux/Mac    |
| Performance critical | ×1.3       | Latency or throughput sensitive   |
| No tests exist       | ×1.2       | Must create test infrastructure   |
| Legacy code          | ×1.3       | Modifying old/untested code       |

---

## Estimation Formula

```
Estimated Time = Base Time × Complexity Score × Σ(Factor Multipliers)

Where:
  Base Time = 15 minutes (baseline for Score 1)
  Complexity Score = 1-5
  Factor Multipliers = Product of applicable factors
```

### Example

```
Task: Add OAuth2 authentication to API endpoint
Base Score: 3 (multi-file feature)
Factors: Security (×1.5), External dependency (×1.3)

Estimated Time = 15min × 3 × 1.5 × 1.3 = 87.75 min ≈ 1.5 hours
Token Estimate = 15,000 tokens
Cost Estimate = $0.15
```

---

## PR Size Classification

| Size | Title Limit | Files Changed | Lines Changed | Review Time | Merge Window |
| ---- | ----------- | ------------- | ------------- | ----------- | ------------ |
| XS   | < 10 chars  | 1-2           | < 50          | 5 min       | Same day     |
| S    | < 50 chars  | 3-5           | 50-200        | 15 min      | Same day     |
| M    | < 100 chars | 6-15          | 200-500       | 30 min      | 1-2 days     |
| L    | < 200 chars | 16-30         | 500-1000      | 1 hr        | 2-3 days     |
| XL   | Any         | 30+           | 1000+         | 2+ hr       | 3-5 days     |

### PR Size Rules

1. **XL PRs MUST be split** — No PR should exceed 1000 lines
2. **L PRs need 2+ reviewers** — At least two approvals required
3. **M PRs need 1 reviewer** — One approval required
4. **S/XS PRs** — Can be self-merged after CI passes

---

## Velocity Tracking

### Metrics to Track

| Metric                | Definition                        | Target    |
| --------------------- | --------------------------------- | --------- |
| Story Points / Sprint | Total complexity points completed | 20-30     |
| Tasks / Week          | Number of tasks completed         | 8-12      |
| Avg Time / Task       | Actual time / Estimated time      | 0.8 - 1.2 |
| First-Pass Rate       | PRs merged without changes        | > 70%     |
| Rework Rate           | Tasks requiring revision          | < 15%     |
| Cycle Time            | Time from start to merge          | < 2 days  |

### Velocity Calculation

```
Velocity = Total Story Points Completed / Number of Sprints

Where:
  Story Point = Task Complexity Score (1-5)
  Sprint = 1 week (or defined period)
```

---

## Estimation Process

### Step 1: Classify Task Type

| Type           | Description                       | Base Multiplier |
| -------------- | --------------------------------- | --------------- |
| Feature        | New functionality                 | 1.0             |
| Bugfix         | Fix existing behavior             | 0.7             |
| Refactor       | Improve without changing behavior | 0.8             |
| Documentation  | Docs, comments, README            | 0.3             |
| Test           | Add or improve tests              | 0.5             |
| Security       | Security fix or audit             | 1.2             |
| Performance    | Optimization                      | 0.9             |
| Infrastructure | CI/CD, tooling, config            | 0.6             |

### Step 2: Assess Complexity

Apply the scoring table (1-5) and factor multipliers.

### Step 3: Estimate Tokens

```
Token Estimate = Base Tokens × Complexity Score × Factor Multiplier

Where:
  Base Tokens = 2,000 (for Score 1)
```

### Step 4: Estimate Cost

```
Cost Estimate = Token Estimate × Model Price per Token

Example (Claude 3.5 Sonnet):
  Cost = 15,000 × $0.000015 = $0.225
```

### Step 5: Generate PR Estimate

```json
{
  "task": "Add OAuth2 to /api/users",
  "type": "feature",
  "complexity": 3,
  "factors": ["security", "external-dep"],
  "estimated_time": "1.5 hours",
  "estimated_tokens": 15000,
  "estimated_cost": "$0.225",
  "pr_size": "M",
  "reviewers_required": 1,
  "suggested_model": "claude-3.5-sonnet"
}
```

---

## Burndown & Forecasting

### Daily Burndown

```
Remaining = Total Points - Completed Points

Where:
  Total Points = Sum of all task scores in sprint
  Completed Points = Sum of scores for merged PRs
```

### Forecast Formula

```
Estimated Completion = Remaining Points / Average Velocity

Example:
  Remaining: 15 points
  Average Velocity: 5 points/day
  Forecast: 3 days
```

---

## Integration with SDD

The estimation framework integrates with the SDD lifecycle:

| SDD Phase | Estimation Activity               |
| --------- | --------------------------------- |
| EXPLORE   | Initial complexity assessment     |
| SPEC      | Detailed estimation with factors  |
| DESIGN    | Architecture impact assessment    |
| TASKS     | Per-task breakdown and estimation |
| APPLY     | Track actual vs estimated         |
| VERIFY    | Validate estimates accuracy       |

---

## Enforcement

1. **PR template** requires complexity score and time estimate
2. **planning-estimator.ps1** generates estimates automatically
3. **Dashboard** tracks velocity and burndown
4. **Weekly report** compares estimated vs actual
5. **Retrospective** adjusts multipliers based on accuracy

---

## Related Files

- `scripts/utilities/planning/planning-estimator.ps1`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `rules/SDD-STRICT-TDD.md`
- `rules/DELEGATION-RULES.md`
- `apps/web-dashboard/` (velocity charts)
