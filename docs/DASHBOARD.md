# Dashboard Ultimate v2.0 - Complete Documentation

## Overview

The Gentle-Vanguard Dashboard Ultimate v2.0 is an enterprise-grade live metrics dashboard with 9 sections, real-time updates, comprehensive analytics, and WCAG 2.1 AA accessibility compliance.

---

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Sections](#sections)
5. [Accessibility](#accessibility)
6. [Security](#security)
7. [Analytics](#analytics)
8. [Troubleshooting](#troubleshooting)

---

## Features

### Core Features

- **9 Interactive Sections**: Executive, Operations, Development, Cost & ROI, Governance, Health, Live, SLA, Performance
- **Real-time Updates**: Auto-refresh every 30s (charts) and 10s (live data)
- **TV Mode**: Auto-rotation every 30s for monitoring displays
- **Export**: PDF and PNG export per section
- **Offline Support**: Service Worker caching for offline access
- **Responsive Design**: Optimized for desktop, tablet, and mobile

### Enterprise Features

- **WCAG 2.1 AA Accessibility**: Full keyboard navigation, screen reader support, ARIA labels
- **Data Encryption**: AES-256 encryption for sensitive metrics
- **Health Monitoring**: Automated health checks and alerts
- **CI/CD Integration**: GitHub Actions pipeline for automated testing
- **Analytics**: Usage tracking and performance metrics
- **Testing**: Automated validation with 100% pass rate

---

## Architecture

### Data Flow

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   SOURCES       │────▶│   COLLECTOR      │────▶│   STORE         │
│                 │     │                  │     │                 │
│ • session/*.json│     │ collector.ps1    │     │ .runtime/metrics│
│ • logs/*.json   │     │   -Scope full    │     │                 │
│ • .token-state  │     │                  │     │ • consolidated  │
│ • git log       │     │ Extract→Transform│     │ • sessions      │
│ • gh pr list    │     │ →Consolidate     │     │ • token         │
│                 │     │                  │     │ • git           │
└─────────────────┘     └──────────────────┘     │ • pr            │
                                                   │ • cost          │
                                                   │ • live          │
                                                   │ • performance   │
                                                   └─────────────────┘
                                                            │
                                                            ▼
                                                   ┌─────────────────┐
                                                   │   RENDERER      │
                                                   │                 │
                                                   │ • dashboard-    │
                                                   │   render.ps1    │
                                                   │                 │
                                                   │ Generates HTML  │
                                                   │ with 9 sections │
                                                   └─────────────────┘
                                                            │
                                                            ▼
                                                   ┌─────────────────┐
                                                   │   OUTPUT        │
                                                   │                 │
                                                   │ reports/        │
                                                   │ dashboard.html  │
                                                   │ (38.8 KB)       │
                                                   └─────────────────┘
```

### Components

| Component | File | Purpose |
|-----------|------|---------|
| Collector | `scripts/metrics/collector.ps1` | Aggregates metrics from all sources |
| Log Analyzer | `scripts/metrics/log-analyzer.ps1` | Analyzes session logs for productivity |
| Dashboard Render | `scripts/metrics/dashboard-render.ps1` | Generates HTML dashboard |
| Health Check | `scripts/metrics/dashboard-health-check.ps1` | Monitors dashboard health |
| Validator | `scripts/tests/dashboard-validator.ps1` | Validates dashboard integrity |
| Service Worker | `reports/sw.js` | Caching and offline support |
| Analytics | `reports/analytics.js` | Usage tracking |

---

## Quick Start

### Generate Dashboard

```powershell
# 1. Collect all metrics
.\scripts\metrics\collector.ps1 -Scope full

# 2. Analyze logs for performance metrics
.\scripts\metrics\log-analyzer.ps1 -DaysBack 30 -SaveToMetrics

# 3. Generate dashboard
.\scripts\metrics\dashboard-render.ps1 -Open
```

### Validate Dashboard

```powershell
# Run automated tests
.\scripts\tests\dashboard-validator.ps1

# Expected output:
# [OK] Dashboard Exists - 38.8 KB
# [OK] JSON Valid - 10 files
# [OK] Structure - All 7 checks
# Summary: 3/3 passed
```

### Monitor Health

```powershell
# Single check
.\scripts\metrics\dashboard-health-check.ps1

# Continuous monitoring (daemon mode)
.\scripts\metrics\dashboard-health-check.ps1 -Daemon -CheckInterval 300
```

---

## Sections

### 1. Executive Overview
KPIs principales con sparklines y tendencias.
- Traffic Light status
- Token usage and budget
- Cost metrics
- Session statistics

### 2. Operations
Session management and usage metrics.
- Active sessions
- Session history
- Duration statistics

### 3. Development
Git and PR activity tracking.
- Commit statistics
- Author contributions
- PR lifecycle metrics

### 4. Cost & ROI
Financial metrics and projections.
- Actual costs
- Forecasts
- Savings analysis

### 5. Governance
Compliance and benchmark tracking.
- Routing accuracy
- Benchmark results

### 6. Health
System health monitoring.
- Latest session
- Active sessions
- Performance metrics

### 7. Live
Real-time event stream.
- Live tokens
- Traffic light
- Routing status
- Event log

### 8. SLA
Service Level Agreement compliance.
- Uptime metrics
- Incident tracking
- SLO compliance table

### 9. Performance
Productivity analytics.
- Sessions analyzed
- Peak activity hours
- Velocity trends
- Activity heatmap

---

## Accessibility

### WCAG 2.1 AA Compliance

The dashboard meets WCAG 2.1 AA standards:

- **Keyboard Navigation**: Full tab navigation, skip links
- **Screen Reader Support**: ARIA labels, semantic HTML
- **Visual**: Contrast ratio 4.5:1, focus indicators
- **Motion**: Respects `prefers-reduced-motion`
- **Color**: Respects `prefers-contrast` and `prefers-color-scheme`

### ARIA Labels

All interactive elements have appropriate ARIA labels:

```html
<button aria-label="Seccion Executive" aria-pressed="true">Executive</button>
<div role="region" aria-label="Traffic Light Status">...</div>
<nav aria-label="Navegacion principal">...</nav>
```

### Keyboard Shortcuts

- `Tab`: Navigate between sections
- `Enter`: Activate buttons
- `Space`: Toggle switches

---

## Security

### Data Encryption

Encrypt sensitive metrics:

```powershell
# Encrypt file
.\scripts\utils\encrypt-data.ps1 -Action encrypt -FilePath ".runtime\metrics\sensitive.json"

# Decrypt file
.\scripts\utils\encrypt-data.ps1 -Action decrypt -FilePath ".runtime\metrics\sensitive.json"
```

### Security Features

- AES-256 encryption
- Automatic key generation
- Secure key storage
- No secrets in git (pre-commit hooks)

---

## Analytics

### Usage Tracking

The dashboard tracks:

- Page views per section
- User interactions (clicks)
- JavaScript errors
- Performance metrics (load time, render time)
- Session duration

### Data Collection

Analytics data is:
- Stored in localStorage
- Sent via Beacon API on page unload
- Aggregated for reporting

### Privacy

- No PII collected
- Anonymous usage data
- Local-first storage

---

## Troubleshooting

### Dashboard Not Loading

1. Check if files exist:
   ```powershell
   Test-Path "reports/dashboard.html"
   ```

2. Validate JSON files:
   ```powershell
   .\scripts\tests\dashboard-validator.ps1
   ```

3. Regenerate dashboard:
   ```powershell
   .\scripts\metrics\dashboard-render.ps1
   ```

### Charts Not Rendering

1. Check browser console for JavaScript errors
2. Verify canvas elements exist
3. Ensure data files are not corrupted

### Performance Issues

1. Clear Service Worker cache
2. Reduce auto-refresh interval
3. Check for memory leaks in browser DevTools

### Accessibility Issues

1. Use browser DevTools Accessibility panel
2. Test with keyboard navigation only
3. Verify ARIA labels with screen reader

---

## CI/CD Integration

### GitHub Actions

The dashboard includes automated CI/CD:

```yaml
# .github/workflows/dashboard-ci.yml
- Validates dashboard on every PR
- Runs security scans
- Checks compliance
- Auto-deploys on merge to main
```

### Pre-commit Hooks

Prevents committing metrics files:

```powershell
# .git/hooks/pre-commit
if ($files -match "\.runtime/metrics") {
    Write-Host "ERROR: Metrics files should not be committed"
    exit 1
}
```

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| First Contentful Paint | < 1.5s | ✅ |
| Time to Interactive | < 3s | ✅ |
| Largest Contentful Paint | < 2.5s | ✅ |
| Cumulative Layout Shift | < 0.1 | ✅ |

---

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting)
2. Review [NORMATIVAS-REPORTING.md](../rules/NORMATIVAS-REPORTING.md)
3. Review [NORMATIVAS-QUALITY.md](../rules/NORMATIVAS-QUALITY.md)
4. Run validator: `.\scripts\tests\dashboard-validator.ps1`

---

_Version: 2.0.0 | Last Updated: 2026-05-26_
