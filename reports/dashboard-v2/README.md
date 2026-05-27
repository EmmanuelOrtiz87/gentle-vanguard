# Gentle-Vanguard Dashboard v2

Real-time metrics dashboard with compact tooltip-style modal for metric information.

## Features

- 9 sections: Executive, Operations, Development, Cost, Governance, Health, Live, SLA, Performance
- Compact tooltip-style modal with metric details (what, why, how, unit, formula)
- Real-time updates every 10 seconds
- Multi-language support (EN, ES, PT)
- PDF/PNG export
- TV mode for displays

## Usage

1. Start server: node server.js
2. Open http://localhost:8080
3. Click the info icon (ℹ️) on any card to see metric details

## Files

- app.js - Main application logic
- metric-info.js - Metric definitions database
- i18n.js - Internationalization
- styles.css - Styling with compact modal
- server.js - Metrics API server
- index.html - Dashboard HTML
