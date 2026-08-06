---
name: explore-data-skill
description: >
  Knowledge work plugin from data department.
metadata:
  source: knowledge-work-plugins
  original-name: explore-data
  department: data
---

# /explore-data - Profile and Explore a Dataset

> If you see unfamiliar placeholders or need to check which tools are connected, see
> [CONNECTORS.md](../../CONNECTORS.md).

Generate a comprehensive data profile for a table or uploaded file. Understand its shape, quality,
and patterns before diving into analysis.

## Usage

```
/explore-data <table_name or file>
```

## Workflow

### 1. Access the Data

**If a data warehouse MCP server is connected:** resolve table name, query metadata, run profiling
queries.

**If a file is provided (CSV, Excel, Parquet, JSON):** read file, infer column types.

**If neither:** ask user for a table name or file upload.

### 2. Understand Structure

Analyze table-level: row/column count, grain, primary key, last updated, date range.

Classify columns: **Identifier**, **Dimension**, **Metric**, **Temporal**, **Text**, **Boolean**,
**Structural**.

### 3. Generate Data Profile

Run profiling per column type. See [references/quality-assessment-framework.md] for rating guides.

**Numeric:** min, max, mean, median, stddev, percentiles (p1/p5/p25/p75/p95/p99), zero/negative
counts.

**String:** min/max/avg length, empty count, pattern/case/whitespace analysis.

**Date:** min/max, nulls, future dates, monthly/weekly distribution, gaps.

**Boolean:** true/false/null counts, true rate.

### 4. Identify Data Quality Issues

Flag: high null rates (>5% warn, >20% alert), unexpected cardinality, suspicious values, duplicate
natural keys, distribution skew, encoding issues. See [references/quality-assessment-framework.md].

### 5. Discover Relationships and Patterns

Foreign key candidates, hierarchies, correlations, derived/redundant columns. See
[references/pattern-discovery.md].

### 6. Suggest Interesting Dimensions and Metrics

Recommend best dimension columns (3-50 values), key metrics, time columns, natural groupings,
potential join keys.

### 7. Recommend Follow-Up Analyses

Suggest 3-5 specific analyses: trend, distribution deep-dive, data quality investigation,
correlation, cohort analysis.

## Output Format

```
## Data Profile: [table_name]

### Overview
- Rows: 2,340,891
- Columns: 23 (8 dimensions, 6 metrics, 4 dates, 5 IDs)
- Date range: 2021-03-15 to 2024-01-22

### Column Details
[summary table]

### Data Quality Issues
[flagged issues with severity]

### Recommended Explorations
[numbered list of suggested follow-up analyses]
```

## Reference Files

- [references/quality-assessment-framework.md] — completeness, consistency, accuracy, timeliness
- [references/pattern-discovery.md] — distribution, temporal patterns, segmentation, correlation
- [references/schema-documentation.md] — schema template, exploration queries, lineage
