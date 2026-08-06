# build-dashboard-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# /build-dashboard - Build Interactive Dashboards

> If you see unfamiliar placeholders or need to check which tools are connected, see
> [CONNECTORS.md](../../CONNECTORS.md).

Build a self-contained interactive HTML dashboard with charts, filters, tables, and professional
styling. Opens directly in a browser -- no server or dependencies required.

## Usage

```
/build-dashboard <description of dashboard> [data source]
```

## Workflow

### 1. Understand Requirements
Determine purpose, audience, key metrics, dimensions, and data source.

### 2. Gather Data
From live query, pasted data, CSV, or create sample data.

### 3. Design Layout
2-4 KPI cards, 1-3 charts, optional detail table, filters in header or sidebar.

### 4. Build Dashboard
Single self-contained HTML using the [base template](references/BASE_TEMPLATE.md).

### 5. Implement Charts
Chart.js patterns: line, bar, doughnut, stacked bar, mixed — see [chart patterns](references/CHART_PATTERNS.md).

### 6. Add Interactivity
Dropdown filters, date range, sortable tables, combined filter logic — see [filters](references/FILTERS.md).

### 7. Save and Open
Save as `descriptive_name.html`, open in browser, confirm rendering.

## Reference Files

| File | Contents |
|------|----------|
| [BASE_TEMPLATE.md](references/BASE_TEMPLATE.md) | Full HTML template with embedded JS and CSS hooks |
| [KPI_CARDS.md](references/KPI_CARDS.md) | KPI card HTML/CSS/JS with number formatting |
| [CHART_PATTERNS.md](references/CHART_PATTERNS.md) | Chart.js line, bar, doughnut, and update patterns |
| [FILTERS.md](references/FILTERS.md) | Dropdown, date range, combined filter, sortable table |
| [CSS_STYLING.md](references/CSS_STYLING.md) | Complete CSS: colors, layout, cards, charts, tables, responsive |
| [PERFORMANCE.md](references/PERFORMANCE.md) | Data size guidelines, pre-aggregation, chart/DOM performance |
| [EXAMPLES.md](references/EXAMPLES.md) | Usage examples and tips |
