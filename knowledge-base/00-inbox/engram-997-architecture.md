---
created: 2026-05-22 01:57:06
tags: [engram, architecture]
engram_id: 997
type: architecture
---

# Metrics pipeline fully operational — board-ready

**What**: Complete metrics pipeline: collector → consolidated.json → dashboard-render → reports/dashboard.html + MANAGEMENT-REPORT-2026-05.md. Pipeline runs at session start AND session close.

**Why**: Se necesitaban datos reales para presentar al board directivo. Antes la pipeline existía (42 scripts en TELEMETRY-METRICS/) pero con cero data fluyendo — los scripts esperaban fuentes de datos que nunca se implementaron.

**Where**:
- config/session-autostart.config.json — +dashboard-render step
- scripts/utilities/session-manager.ps1 — +dashboard-render + collector en End-Session
- scripts/utilities/session-metrics-tracker.ps1 — fix: costPer1M $15→$10
- scripts/utilities/TELEMETRY-METRICS/consolidate-telemetry.ps1 — +fallback a working pipeline
- scripts/utilities/generate-board-report.ps1 — NEW

**Learned**:
1. El pipeline real y funcional está en scripts/metrics/ (collector, dashboard-render, live-feed), NO en scripts/utilities/TELEMETRY-METRICS/ que es un approach paralelo legacy
2. El costo rate estaba inconsistente: $15 en session-metrics-tracker vs $10 en collector/dashboard-render/generate-dashboard. Todas unificadas a $10
3. La pipeline no se había "encendido" nunca — los pasos autostart existían pero el dashboard-render no estaba en el pipeline
4. Los reports están listos para el board: dashboard.html (interactivo, 6 tabs, auto-refresh 30s) y MANAGEMENT-REPORT-2026-05.md (ejecutivo)
5. Costo real: $0.09 MTD, $0.14 forecast, 28.6% savings vs baseline

---
*Imported from Engram on 2026-09-06*
