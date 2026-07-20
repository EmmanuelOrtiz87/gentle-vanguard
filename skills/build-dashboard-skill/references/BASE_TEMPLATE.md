# Base Template

Every dashboard follows this structure:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Dashboard Title</title>
    <script
      src="https://cdn.jsdelivr.net/npm/chart.js@4.5.1"
      integrity="sha384-jb8JQMbMoBUzgWatfe6COACi2ljcDdZQ2OxczGA3bGNeWe+6DChMTBJemed7ZnvJ"
      crossorigin="anonymous"
    ></script>
    <script
      src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0"
      integrity="sha384-cVMg8E3QFwTvGCDuK+ET4PD341jF3W8nO1auiXfuZNQkzbUUiBGLsIQUE+b1mxws"
      crossorigin="anonymous"
    ></script>
    <style>
      /* Dashboard styles go here */
    </style>
  </head>
  <body>
    <div class="dashboard-container">
      <header class="dashboard-header">
        <h1>Dashboard Title</h1>
        <div class="filters">
          <!-- Filter controls -->
        </div>
      </header>

      <section class="kpi-row">
        <!-- KPI cards -->
      </section>

      <section class="chart-row">
        <!-- Chart containers -->
      </section>

      <section class="table-section">
        <!-- Data table -->
      </section>

      <footer class="dashboard-footer">
        <span>Data as of: <span id="data-date"></span></span>
      </footer>
    </div>

    <script>
      // Embedded data
      const DATA = [];

      // Dashboard logic
      class Dashboard {
        constructor(data) {
          this.rawData = data;
          this.filteredData = data;
          this.charts = {};
          this.init();
        }

        init() {
          this.setupFilters();
          this.renderKPIs();
          this.renderCharts();
          this.renderTable();
        }

        applyFilters() {
          // Filter logic
          this.filteredData = this.rawData.filter((row) => {
            // Apply each active filter
            return true; // placeholder
          });
          this.renderKPIs();
          this.updateCharts();
          this.renderTable();
        }

        // ... methods for each section
      }

      const dashboard = new Dashboard(DATA);
    </script>
  </body>
</html>
```
