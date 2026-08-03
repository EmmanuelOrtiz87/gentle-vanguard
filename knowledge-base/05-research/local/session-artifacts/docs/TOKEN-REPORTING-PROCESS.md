# Token Consumption, Utility & Context Reporting Process

**Date**: 2026-04-28  
**Version**: 1.0.0  
**Status**: **COMPLETE & OPERATIONAL**

---

## Overview

Foundation includes a **comprehensive, on-demand process** to generate detailed reports about:

- **Token consumption** (total, by task, by tool)
- **Token utility** (useful vs wasted tokens)
- **Context structure** (hot/warm/cold/archive tiers)
- **Efficiency metrics** (trends, spikes, optimization opportunities)

---

## Process Components

### 1. **Token Consumption Report**

**Script**: `scripts/utilities/token-consumption-report.ps1`

**Capabilities**:

- Multiple output formats: `markdown`, `json`, `csv`
- Scope filtering: `session`, `daily`, `weekly`, `all`
- Token utility analysis (useful vs wasted)
- Context tier information
- Integrates with existing telemetry systems

**Usage**:

```powershell
# Generate markdown report (default)
.\scripts\utilities\token-consumption-report.ps1 -OutputFormat markdown -Scope weekly

# JSON format for automation
.\scripts\utilities\token-consumption-report.ps1 -OutputFormat json -Scope all -IncludeContext -IncludeUtility

# CSV export
.\scripts\utilities\token-consumption-report.ps1 -OutputFormat csv -Scope daily
```

---

## Data Sources

The process aggregates data from:

| Source                 | Path                                           | Content                          |
| ---------------------- | ---------------------------------------------- | -------------------------------- |
| **Token Guard Usage**  | `docs/sessions/metrics/token-guard-usage.csv`  | Estimated tokens per task        |
| **Telemetry Master**   | `docs/management/telemetry-master.csv`         | Session tokens, judgment results |
| **Context Efficiency** | `config/context-efficiency.json`               | Context tier definitions         |
| **Runtime Telemetry**  | `.runtime/telemetry/cloud-agent-telemetry.csv` | Input/output tokens              |

---

## Report Structure

### Markdown Report Example:

```markdown
# Token Consumption & Context Report

**Generated**: 2026-04-28 14:30:00 **Scope**: weekly **Total Records**: 17

---

## Token Usage Summary

| Metric               | Value   |
| -------------------- | ------- |
| **Total Tokens**     | 125,000 |
| **Average per Task** | 7,352   |
| **Max Single Task**  | 22,000  |
| **Tasks Executed**   | 17      |

---

## Token Usage by Task (Top 10)

| Task          | Total Tokens | Executions |
| ------------- | ------------ | ---------- |
| review        | 45,000       | 5          |
| audit         | 32,000       | 3          |
| compact-start | 18,000       | 4          |

| ...

---

## Context Tier Structure

| Tier        | Retention | Compression | Description      |
| ----------- | --------- | ----------- | ---------------- |
| **hot**     | 100%      | none        | Active session   |
| **warm**    | 90%       | light       | Recent (1 day)   |
| **cold**    | 70%       | aggressive  | Archive (7 days) |
| **archive** | 40%       | extreme     | Old sessions     |

---

## Token Utility Analysis

| Metric               | Value   |
| -------------------- | ------- |
| **Useful Tokens**    | 106,250 |
| **Wasted Tokens**    | 18,750  |
| **Efficiency Ratio** | 85%     |

**Note**: Utility estimation assumes 85% efficiency baseline. Actual may vary.

---

## Data Sources

- `docs/sessions/metrics/token-guard-usage.csv`
- `docs/management/telemetry-master.csv`
- `config/context-efficiency.json`

---

**End of Report**
```

---

## JSON Report Example

```json
{
  "generatedAt": "2026-04-28T14:30:00Z",
  "scope": "weekly",
  "summary": {
    "totalTokens": 125000,
    "totalRecords": 17,
    "avgPerTask": 7352
  },
  "topTasks": [
    { "task": "review", "totalTokens": 45000, "count": 5 },
    { "task": "audit", "totalTokens": 32000, "count": 3 }
  ],
  "contextTiers": {
    "hot": { "retention": "100%", "compression": "none" },
    "warm": { "retention": "90%", "compression": "light" },
    "cold": { "retention": "70%", "compression": "aggressive" },
    "archive": { "retention": "40%", "compression": "extreme" }
  },
  "utility": {
    "totalTokens": 125000,
    "usefulTokens": 106250,
    "wastedTokens": 18750,
    "efficiencyRatio": 85
  }
}
```

---

## Existing Complementary Scripts

| Script                           | Purpose                                 | Status     |
| -------------------------------- | --------------------------------------- | ---------- |
| `token-telemetry.ps1`            | Collects token data from multiple repos | Active     |
| `token-budget-guard.ps1`         | Enforces token limits, tracks usage     | Active     |
| `token-efficiency-estimator.ps1` | Estimates efficiency gains              | Active     |
| `token-telemetry-report.ps1`     | Legacy report (replaced by new process) | Legacy     |
| `consolidate-telemetry.ps1`      | Consolidates runtime/session data       | Active     |
| `token-consumption-report.ps1`   | **NEW** comprehensive report            | **Active** |

---

## Integration Points

### 1. **MCP Bridge Integration**

The token consumption report is exposed via MCP:

```
foundation_token_report -OutputFormat markdown -Scope weekly
```

### 2. **Engram Memory**

Report summaries are saved to Engram:

- Title: "Token consumption report"
- Type: telemetry
- Topic: `telemetry/token-consumption`

### 3. **CI/CD Pipeline**

Can be integrated into release pipeline:

```yaml
- name: Generate token report
  run: powershell -File scripts/utilities/token-consumption-report.ps1 -OutputFormat json -Scope all
```

---

## Validation Checklist

- **On-demand execution**: Run manually when needed
- **Multiple formats**: markdown (human), json (automation), csv (export)
- **Scope filtering**: session (2h), daily, weekly, all
- **Context tiers**: hot/warm/cold/archive structure
- **Token utility**: useful vs wasted analysis
- **Data integration**: Uses existing telemetry sources
- **MCP exposed**: Available via foundation_token_report
- **Documentation**: This file complete
- **Git tracked**: Committed and pushed to develop + main

---

## How to Use (Step-by-Step)

### Step 1: Basic Report

```powershell
cd .\foundation
.\scripts\utilities\token-consumption-report.ps1
```

Output: Markdown report printed to console.

### Step 2: Detailed JSON Report

```powershell
.\scripts\utilities\token-consumption-report.ps1 -OutputFormat json -IncludeContext -IncludeUtility -Scope all
```

Output: JSON report printed to console.

### Step 3: Export to CSV

```powershell
.\scripts\utilities\token-consumption-report.ps1 -OutputFormat csv -Scope weekly
```

Output: CSV file saved to `docs/sessions/metrics/token-consumption-YYYYMMDD-HHmmss.csv`

### Step 4: Via MCP Bridge (from any tool)

```
foundation_token_report({
  outputFormat: "markdown",
  scope: "weekly",
  includeContext: true,
  includeUtility: true
})
```

---

## Next Steps (Optional Enhancements)

| Enhancement                         | Priority | Effort |
| ----------------------------------- | -------- | ------ |
| Add token spike detection           | Medium   | 2h     |
| Add trend analysis (week-over-week) | Medium   | 3h     |
| Add cost estimation (USD)           | Low      | 1h     |
| Add visualization (charts)          | Low      | 4h     |
| Add email/Slack notifications       | Low      | 2h     |

---

**Status**: **PROCESS COMPLETE & OPERATIONAL**  
**Last Updated**: 2026-04-28  
**Memory Saved**: `telemetry/token-consumption-process`
