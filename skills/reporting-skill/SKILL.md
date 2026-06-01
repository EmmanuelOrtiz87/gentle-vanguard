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
metadata:
  source: GV-native
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

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
