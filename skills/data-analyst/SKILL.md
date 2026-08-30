---
name: data-analyst
aliases: ["data-analyst"]
description:
  Analyze datasets, generate insights, create visualizations, and perform statistical analysis. Use
  when working with data, CSV/JSON files, creating reports, or extracting insights from any
  structured data.
  
triggers:
  - analyze data
  - data analysis
  - CSV analysis
  - JSON data
  - statistics
  - visualization
  - data insights
  - generate report
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.049Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\data-analyst\SKILL.md
  version: "1.0.0"
---

# Data Analyst Skill

## Overview

Analyze structured data (CSV, JSON, SQL results) to generate insights, statistics, correlations, and
visualizations.

## Data Sources

| Source       | Capability   | Notes                        |
| ------------ | ------------ | ---------------------------- |
| CSV          | Full support | Streaming for large files    |
| JSON         | Full support | Nested object flattening     |
| TSV          | Full support | Tab-delimited                |
| SQLite       | Full support | Direct queries via Nexus     |
| Excel        | Partial      | Via document-processor first |
| API Response | Full support | JSON parsing                 |

## Analysis Types

### 1. Descriptive Statistics

```bash
# Generate summary statistics
npx tsx src/tools/data-analyst.ts describe "data.csv"

# Output: count, mean, std, min, 25%, 50%, 75%, max per column
```

### 2. Correlation Analysis

```bash
# Find correlations
npx tsx src/tools/data-analyst.ts correlate "data.json" --target revenue

# Output: correlation matrix, strongest predictors
```

### 3. Trend Analysis

```bash
# Time series analysis
npx tsx src/tools/data-analyst.ts trend "metrics.csv" --date date_column --value sales

# Output: trend direction, seasonality, growth rate
```

### 4. Segmentation

```bash
# Group by and aggregate
npx tsx src/tools/data-analyst.ts segment "transactions.csv" --by region --metric avg(amount)
```

### 5. Anomaly Detection

```bash
# Find outliers
npx tsx src/tools/data-analyst.ts anomalies "metrics.csv" --column cpu_usage
```

## Visualization Generation

```bash
# Simple charts (ASCII)
npx tsx src/tools/data-analyst.ts visualize "sales.csv" --type bar --column revenue

# Generate Vega-Lite spec
npx tsx src/tools/data-analyst.ts visualize "data.csv" --format vega --output chart.vl.json
```

## Report Generation

```bash
# Full analysis report
npx tsx src/tools/data-analyst.ts report "metrics.csv" --type comprehensive

# Sections: Summary, Statistics, Trends, Insights, Recommendations
```

## SQL Queries (via Nexus)

```bash
# Query Nexus database
npx tsx src/tools/data-analyst.ts query "SELECT * FROM metric_snapshots ORDER BY timestamp DESC LIMIT 100"

# Analyze session metrics
npx tsx src/tools/data-analyst.ts query "SELECT date(timestamp) as day, avg(quality_score) FROM sessions GROUP BY day"
```

## Response Format

```typescript
interface AnalysisResult {
  source: string;
  rowCount: number;
  columnCount: number;
  columns: ColumnInfo[];
  statistics: Record<string, ColumnStats>;
  correlations?: CorrelationMatrix;
  insights: DataInsight[];
  anomalies?: Anomaly[];
  visualizations?: Visualization[];
  summary: string;
  recommendations: string[];
}

interface ColumnStats {
  type: 'numeric' | 'categorical' | 'datetime' | 'text';
  count: number;
  unique: number;
  missing: number;
  // For numeric
  mean?: number;
  std?: number;
  min?: number;
  max?: number;
  median?: number;
  // For categorical
  topValues?: { value: string; count: number }[];
}

interface DataInsight {
  type: 'statistical' | 'trend' | 'anomaly' | 'correlation';
  description: string;
  confidence: number;
  supportingData: unknown;
}
```

## Common Patterns

### Pattern 1: Session Performance Analysis

```bash
# Analyze session quality over time
npx tsx src/tools/data-analyst.ts query "SELECT * FROM sessions WHERE timestamp > date('now', '-7 days')" --analyze quality_score

Insights:
- Quality declining on Fridays (avg -15%)
- Proactive suggestions have 23% hit rate
- Peak hours 14:00-16:00
```

### Pattern 2: Token Usage Analysis

```bash
# Analyze token efficiency
npx tsx src/tools/data-analyst.ts query "SELECT * FROM token_usage ORDER BY timestamp" --trend

Insights:
- Usage increasing 5% week-over-week
- Off-peak efficiency 40% higher
- Recommended: preemptive budget adjustment
```

### Pattern 3: File Change Analysis

```bash
# Analyze most modified files
npx tsx src/tools/data-analyst.ts query "SELECT * FROM audit_logs WHERE type LIKE '%file%'" --group-by path

Insights:
- 80% of edits in /src/components/
- config.json modified daily (consider validation)
```

## Integration Points

- **document-processor**: Feed document tables
- **observability-and-instrumentation**: Analyze metrics
- **technical-writer**: Generate data reports
- **spec-driven-development**: Validate with data

## Performance

| Rows    | Columns | Typical Time       |
| ------- | ------- | ------------------ |
| <1,000  | <20     | <2s                |
| 10,000  | <50     | 3-5s               |
| 100,000 | <100    | 10-30s (streaming) |
| >1M     | >100    | Requires sampling  |

## Error Handling

| Scenario      | Response                       |
| ------------- | ------------------------------ |
| Empty dataset | Warning with suggestions       |
| All nulls     | Column type detection failure  |
| Malformed CSV | Attempt recovery with warnings |
| Memory limit  | Automatic sampling             |
| Invalid SQL   | Query validation error         |

## Usage

Use **data-analyst** when a task matches its triggers (analyze data - data analysis - CSV analysis - JSON data - statistics - visualization - data insights - generate report).

Purpose: Analyze datasets, generate insights, create visualizations, and perform statistical analysis.

## Examples

Concrete usage drawn from this skill's own documentation:

```bash
# Generate summary statistics
npx tsx src/tools/data-analyst.ts describe "data.csv"

# Output: count, mean, std, min, 25%, 50%, 75%, max per column
```
