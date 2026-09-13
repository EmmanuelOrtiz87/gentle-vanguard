---
created: 2026-05-22 04:06:13
tags: [engram, architecture]
engram_id: 1006
type: architecture
---

# Live telemetry pipeline for agent activity tracking

**What**: Built complete live telemetry pipeline from agent activity to dashboard/presentation in real-time
**Why**: Dashboard metrics were static (git/PR/post-hoc data) and didn't reflect live agent activity during sessions
**Where**:
- scripts/metrics/telemetry-writer.ps1 — instrumentation agent writes activity.json + events.ndjson
- scripts/metrics/telemetry.ps1 — helper wrapping POST /api/ingest with direct fallback
- scripts/metrics/collector.ps1 — Collect-TelemetryMetrics() reads activity + events
- scripts/metrics/live-feed.ps1 — daemon that runs collector every 15s, writes feed.json + daemon-health.json
- scripts/metrics/metrics-server.ps1 — /api/ingest POST endpoint, /api/live enriched with events
- scripts/metrics/dashboard-render.ps1 — "Live Activity" section with 6 metric cards + event stream table + polling JS
- gentle-vanguard-presentation.html — slide 26 "Live Activity & Telemetría del Agente" with live metrics
**Learned**:
- Live-feed must init telemetry on startup (activity.json may not exist)
- Collector needs to read events.ndjson separately, activity.json events field stays empty
- POST /api/ingest is the fast path; telemetry-writer.ps1 is the fallback
- Export PDF/PNG works via export-dashboard-pdf.ps1 (headless browser)
- Pipeline: agent → telemetry.ps1 → POST /api/ingest → activity.json+events.ndjson → collector → consolidated.json → feed.json → /api/live → dashboard+presentation

---
*Imported from Engram on 2026-09-06*
