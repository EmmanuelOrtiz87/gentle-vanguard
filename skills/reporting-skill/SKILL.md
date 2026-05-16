---
name: reporting-skill
description: >
  Comprehensive reporting skill for generating management reports, session metrics, cost analysis,
  performance dashboards, and technical documentation on demand. Trigger: "informe", "report",
  "reporte", "mtricas", "metrics", "dashboard", "gerencia", "costos", "tokens", "consumo",
  "performance", "analytics", "sesiónes", "telemetry", "estadsticas", "resumen"
license: Apache-2.0
metadata:
  author: workspace-local
  versión: '1.0'
---

# Reporting Skill

## Purpose

Generate comprehensive reports for management, technical analysis, and decisión-making. Reports can
be requested on-demand and are structured for executive presentation.

## Trigger Keywords

| Category    | Keywords                                     |
| ----------- | -------------------------------------------- |
| Reports     | "informe", "report", "reporte", "resumen"    |
| Metrics     | "mtricas", "metrics", "estadsticas", "stats" |
| Analytics   | "analytics", "anlisis", "dashboard"          |
| Costs       | "costos", "costs", "gastos", "consumo"       |
| Performance | "performance", "rendimiento", "eficiencia"   |
| Sessions    | "sesiónes", "sessions", "tokens"             |
| Gerencia    | "gerencia", "ejecutivo", "management"        |

## Data Sources

| Source      | Path                               | Description        |
| ----------- | ---------------------------------- | ------------------ |
| Sessions    | `.session/session-*.json`          | Session metadata   |
| Telemetry   | `.telemetry/initialization-*.json` | Tracing data       |
| Token Guard | `.session/token-*.json`            | Token monitoring   |
| Metrics CSV | `docs/sessions/metrics/`           | Aggregated metrics |

## Report Types

### 1. Session Report (`informe sesiónes`)

```powershell
.\scripts\utilities\session-metrics-collector.ps1 -Period 7days
```

**Output**: `docs/sessions/metrics/session-metrics.csv`

| Column             | Description               |
| ------------------ | ------------------------- |
| session_id         | Unique session identifier |
| status             | active/completed          |
| start_time         | ISO 8601 timestamp        |
| end_time           | ISO 8601 timestamp        |
| duration_seconds   | Session duration          |
| input_tokens       | Tokens in prompt          |
| output_tokens      | Tokens in response        |
| total_tokens       | Total consumed            |
| estimated_cost_usd | Cost in USD               |
| tool_calls         | Tool invocations          |
| files_read         | Files accessed            |
| files_edited       | Files modified            |

### 2. Cost Report (`informe costos`)

```powershell
.\scripts\utilities\token-telemetry.ps1 -CostPer1MTokens 15
```

| Metric            | Calculation               |
| ----------------- | ------------------------- |
| Total Tokens      | Sum of all session tokens |
| Cost per 1M       | $15 (modelo actual)       |
| Daily Average     | Total / days              |
| Monthly Projected | Daily \* 30               |

### 3. Performance Report (`informe performance`)

```powershell
.\scripts\utilities\aggregate-metrics.ps1 -Period weekly
```

| Metric             | Description         |
| ------------------ | ------------------- |
| Sessions           | Total session count |
| Active Users       | Unique developers   |
| Lines Added        | Code generated      |
| Lines Removed      | Code deleted        |
| Files Created      | New files           |
| Files Modified     | Changed files       |
| AI Assistance Rate | Sessions with AI %  |

### 4. Executive Summary (`resumen ejecutivo`)

```powershell
.\scripts\utilities\generate-executive-summary.ps1
```

## Report Formats

### Markdown (default)

```
#  Report Title

**Period**:Date range
**Generated**: ISO timestamp

---

##  Executive Summary
| Metric | Value | Trend |
|--------|-------|-------|
| Sessions | N |  |
| Tokens | N |  |
| Cost | $N |  |

##  Detailed Analysis
...

##  Recommendations
...
```

### JSON (with `-AsJson`)

```powershell
.\scripts\utilities\session-metrics-collector.ps1 -Period 7days -AsJson
```

## Usage Examples

### Generate session report for last 3 days

```powershell
.\scripts\utilities\session-metrics-collector.ps1 -Period 7days
```

### Generate cost analysis

```powershell
.\scripts\utilities\token-telemetry.ps1 -AsJson
```

### Generate executive summary

```powershell
# Uses aggregate-metrics.ps1
.\scripts\utilities\aggregate-metrics.ps1 -Period daily
```

### On-demand via orchestrator

```
User: "generame un informe de las sesiónes de ayer"
 Auto-detects: REPORT + Sessions
 Delegates to: session-metrics-collector.ps1
 Output: markdown report
```

### On-demand WITHOUT context

```
User: "quiero un informe" (vago)
 Clarification menu:
   "Qu tipo de informe necesitas?"
   - sesiónes (resumen de actividad)
   - Costos (anlisis de gastos)
   - Rendimiento (mtricas de performance)
   - Ejecutivo (para gerencia)
   - Completo (integral)
 Genera segn seleccin
```

## Metrics Schema

### session-metrics.csv

```csv
session_id,status,start_time,end_time,duration_seconds,mode,project,correlation_id,root_span_id,input_tokens,output_tokens,total_tokens,estimated_cost_usd,context_chars,tool_calls,files_read,files_edited,files_created
```

### telemetry-master.csv (business telemetry)

```csv
Timestamp,User_ID,Session_ID,Task_Scope,Tokens_Estimated,Judgment_Result,Review_Issues,Duration_Min,Efficiency_Score
```

## CLI Commands

| Command               | Description            |
| --------------------- | ---------------------- |
| `gentle-vanguard report today`     | Report for today       |
| `gentle-vanguard report yesterday` | Report for yesterday   |
| `gentle-vanguard report 7days`     | Report for last 7 days |
| `gentle-vanguard metrics`          | Show metrics summary   |
| `gentle-vanguard costs`            | Show cost analysis     |

## Integration Points

- **Auto-delegation**: Keywords mapped in `config/auto-delegation.json`
- **Session workflow**: Calls metrics collector on session end
- **Token Guard**: Records token usage to CSV
- **Orchestrator**: Delegates to reporting skill on demand

## What NOT to Do

- Don't generate reports without data sources verified
- Don't report estimated metrics as actual
- Don't skip the limitations section in reports
- Don't use hardcoded costs without noting them

## Best Practices

1. Always verify data sources exist before reporting
2. Include "limitations" section when data is missing
3. Use ISO 8601 timestamps
4. Add trend indicators ()
5. Structure for executive readability
6. Save reports to `reports/` directory

## Output Locations

| Report Type | Default Path                                |
| ----------- | ------------------------------------------- |
| Session     | `docs/sessions/metrics/session-metrics.csv` |
| Cost        | `docs/sessions/metrics/token-cost.csv`      |
| Executive   | `reports/informe-*.md`                      |
| Telemetry   | `docs/management/telemetry-master.csv`      |

---

_Skill versión: 1.0_  
_Last updated: 2026-04-26_

