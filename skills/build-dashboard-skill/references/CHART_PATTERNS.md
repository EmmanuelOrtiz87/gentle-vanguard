# Chart.js Integration

## Chart Container Pattern

```html
<div class="chart-container">
  <h3 class="chart-title">Monthly Revenue Trend</h3>
  <canvas id="revenue-chart"></canvas>
</div>
```

## Line Chart

```javascript
function createLineChart(canvasId, labels, datasets) {
  const ctx = document.getElementById(canvasId).getContext('2d');
  return new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: datasets.map((ds, i) => ({
        label: ds.label,
        data: ds.data,
        borderColor: COLORS[i % COLORS.length],
        backgroundColor: COLORS[i % COLORS.length] + '20',
        borderWidth: 2,
        fill: ds.fill || false,
        tension: 0.3,
        pointRadius: 3,
        pointHoverRadius: 6,
      })),
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: { position: 'top', labels: { usePointStyle: true, padding: 20 } },
        tooltip: {
          callbacks: {
            label: function (context) {
              return `${context.dataset.label}: ${formatValue(context.parsed.y, 'currency')}`;
            },
          },
        },
      },
      scales: {
        x: { grid: { display: false } },
        y: {
          beginAtZero: true,
          ticks: { callback: function (value) { return formatValue(value, 'currency'); } },
        },
      },
    },
  });
}
```

## Bar Chart

```javascript
function createBarChart(canvasId, labels, data, options = {}) {
  const ctx = document.getElementById(canvasId).getContext('2d');
  const isHorizontal = options.horizontal || labels.length > 8;

  return new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: options.label || 'Value',
        data: data,
        backgroundColor: options.colors || COLORS.map((c) => c + 'CC'),
        borderColor: options.colors || COLORS,
        borderWidth: 1,
        borderRadius: 4,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      indexAxis: isHorizontal ? 'y' : 'x',
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: function (context) {
              return formatValue(context.parsed[isHorizontal ? 'x' : 'y'], options.format || 'number');
            },
          },
        },
      },
      scales: {
        x: {
          beginAtZero: true,
          grid: { display: isHorizontal },
          ticks: isHorizontal ? { callback: function (value) { return formatValue(value, options.format || 'number'); } } : {},
        },
        y: {
          beginAtZero: !isHorizontal,
          grid: { display: !isHorizontal },
          ticks: !isHorizontal ? { callback: function (value) { return formatValue(value, options.format || 'number'); } } : {},
        },
      },
    },
  });
}
```

## Doughnut Chart

```javascript
function createDoughnutChart(canvasId, labels, data) {
  const ctx = document.getElementById(canvasId).getContext('2d');
  return new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: labels,
      datasets: [{
        data: data,
        backgroundColor: COLORS.map((c) => c + 'CC'),
        borderColor: '#ffffff',
        borderWidth: 2,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '60%',
      plugins: {
        legend: { position: 'right', labels: { usePointStyle: true, padding: 15 } },
        tooltip: {
          callbacks: {
            label: function (context) {
              const total = context.dataset.data.reduce((a, b) => a + b, 0);
              const pct = ((context.parsed / total) * 100).toFixed(1);
              return `${context.label}: ${formatValue(context.parsed, 'number')} (${pct}%)`;
            },
          },
        },
      },
    },
  });
}
```

## Updating Charts on Filter Change

```javascript
function updateChart(chart, newLabels, newData) {
  chart.data.labels = newLabels;

  if (Array.isArray(newData[0])) {
    newData.forEach((data, i) => {
      chart.data.datasets[i].data = data;
    });
  } else {
    chart.data.datasets[0].data = newData;
  }

  chart.update('none');
}
```
