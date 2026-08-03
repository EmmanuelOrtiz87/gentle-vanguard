# Filter and Interactivity Implementation

## Dropdown Filter

```html
<div class="filter-group">
  <label for="filter-region">Region</label>
  <select id="filter-region" onchange="dashboard.applyFilters()">
    <option value="all">All Regions</option>
  </select>
</div>
```

```javascript
function populateFilter(selectId, data, field) {
  const select = document.getElementById(selectId);
  const values = [...new Set(data.map((d) => d[field]))].sort();
  values.forEach((val) => {
    const option = document.createElement('option');
    option.value = val;
    option.textContent = val;
    select.appendChild(option);
  });
}

function getFilterValue(selectId) {
  const val = document.getElementById(selectId).value;
  return val === 'all' ? null : val;
}
```

## Date Range Filter

```html
<div class="filter-group">
  <label>Date Range</label>
  <input type="date" id="filter-date-start" onchange="dashboard.applyFilters()" />
  <span>to</span>
  <input type="date" id="filter-date-end" onchange="dashboard.applyFilters()" />
</div>
```

```javascript
function filterByDateRange(data, dateField, startDate, endDate) {
  return data.filter((row) => {
    const rowDate = new Date(row[dateField]);
    if (startDate && rowDate < new Date(startDate)) return false;
    if (endDate && rowDate > new Date(endDate)) return false;
    return true;
  });
}
```

## Combined Filter Logic

```javascript
applyFilters() {
    const region = getFilterValue('filter-region');
    const category = getFilterValue('filter-category');
    const startDate = document.getElementById('filter-date-start').value;
    const endDate = document.getElementById('filter-date-end').value;

    this.filteredData = this.rawData.filter(row => {
        if (region && row.region !== region) return false;
        if (category && row.category !== category) return false;
        if (startDate && row.date < startDate) return false;
        if (endDate && row.date > endDate) return false;
        return true;
    });

    this.renderKPIs();
    this.updateCharts();
    this.renderTable();
}
```

## Sortable Table

```javascript
function renderTable(containerId, data, columns) {
  const container = document.getElementById(containerId);
  let sortCol = null;
  let sortDir = 'desc';

  function render(sortedData) {
    let html = '<table class="data-table">';
    html += '<thead><tr>';
    columns.forEach((col) => {
      const arrow = sortCol === col.field ? (sortDir === 'asc' ? ' ▲' : ' ▼') : '';
      html += `<th onclick="sortTable('${col.field}')" style="cursor:pointer">${col.label}${arrow}</th>`;
    });
    html += '</tr></thead>';
    html += '<tbody>';
    sortedData.forEach((row) => {
      html += '<tr>';
      columns.forEach((col) => {
        const value = col.format ? formatValue(row[col.field], col.format) : row[col.field];
        html += `<td>${value}</td>`;
      });
      html += '</tr>';
    });
    html += '</tbody></table>';
    container.innerHTML = html;
  }

  window.sortTable = function (field) {
    if (sortCol === field) {
      sortDir = sortDir === 'asc' ? 'desc' : 'asc';
    } else {
      sortCol = field;
      sortDir = 'desc';
    }
    const sorted = [...data].sort((a, b) => {
      const aVal = a[field], bVal = b[field];
      const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
      return sortDir === 'asc' ? cmp : -cmp;
    });
    render(sorted);
  };

  render(data);
}
```
