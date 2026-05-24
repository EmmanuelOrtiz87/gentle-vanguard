
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

| Command                            | Description            |
| ---------------------------------- | ---------------------- |
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