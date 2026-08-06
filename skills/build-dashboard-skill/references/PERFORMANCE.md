# Performance Considerations for Large Datasets

## Data Size Guidelines

| Data Size             | Approach                                                           |
| --------------------- | ------------------------------------------------------------------ |
| <1,000 rows           | Embed directly in HTML. Full interactivity.                        |
| 1,000 - 10,000 rows   | Embed in HTML. May need to pre-aggregate for charts.               |
| 10,000 - 100,000 rows | Pre-aggregate server-side. Embed only aggregated data.             |
| >100,000 rows         | Not suitable for client-side dashboard. Use a BI tool or paginate. |

## Pre-Aggregation Pattern

```javascript
// DON'T: embed 50,000 raw rows
const RAW_DATA = [/* 50,000 rows */];

// DO: pre-aggregate before embedding
const CHART_DATA = {
  monthly_revenue: [
    { month: '2024-01', revenue: 150000, orders: 1200 },
    // ... 12 rows instead of 50,000
  ],
  top_products: [{ product: 'Widget A', revenue: 45000 }],
  kpis: { total_revenue: 1980000, total_orders: 15600, avg_order_value: 127 },
};
```

## Chart Performance

- Limit line charts to <500 data points per series (downsample if needed)
- Limit bar charts to <50 categories
- For scatter plots, cap at 1,000 points
- Disable animations for many charts: `animation: false`
- Use `Chart.update('none')` for filter-triggered updates

## DOM Performance

- Limit data tables to 100-200 visible rows. Add pagination for more.
- Use `requestAnimationFrame` for coordinated chart updates
- Avoid rebuilding the entire DOM on filter change

```javascript
function renderTablePage(data, page, pageSize = 50) {
  const start = page * pageSize;
  const end = Math.min(start + pageSize, data.length);
  const pageData = data.slice(start, end);
  // Render only pageData
  // Show pagination controls: "Showing 1-50 of 2,340"
}
```
