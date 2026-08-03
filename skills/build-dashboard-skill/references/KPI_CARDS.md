# KPI Card Pattern

```html
<div class="kpi-card">
  <div class="kpi-label">Total Revenue</div>
  <div class="kpi-value" id="kpi-revenue">$0</div>
  <div class="kpi-change positive" id="kpi-revenue-change">+0%</div>
</div>
```

```javascript
function renderKPI(elementId, value, previousValue, format = 'number') {
  const el = document.getElementById(elementId);
  const changeEl = document.getElementById(elementId + '-change');

  // Format the value
  el.textContent = formatValue(value, format);

  // Calculate and display change
  if (previousValue && previousValue !== 0) {
    const pctChange = ((value - previousValue) / previousValue) * 100;
    const sign = pctChange >= 0 ? '+' : '';
    changeEl.textContent = `${sign}${pctChange.toFixed(1)}% vs prior period`;
    changeEl.className = `kpi-change ${pctChange >= 0 ? 'positive' : 'negative'}`;
  }
}

function formatValue(value, format) {
  switch (format) {
    case 'currency':
      if (value >= 1e6) return `$${(value / 1e6).toFixed(1)}M`;
      if (value >= 1e3) return `$${(value / 1e3).toFixed(1)}K`;
      return `$${value.toFixed(0)}`;
    case 'percent':
      return `${value.toFixed(1)}%`;
    case 'number':
      if (value >= 1e6) return `${(value / 1e6).toFixed(1)}M`;
      if (value >= 1e3) return `${(value / 1e3).toFixed(1)}K`;
      return value.toLocaleString();
    default:
      return value.toString();
  }
}
```
