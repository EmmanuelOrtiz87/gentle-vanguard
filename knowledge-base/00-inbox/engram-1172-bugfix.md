---
created: 2026-05-26 20:20:34
tags: [engram, bugfix]
engram_id: 1172
type: bugfix
---

# Dashboard metrics fixes and enhancements

**What**: Fixed dashboard.html JavaScript bugs and added missing features (Live section, PDF/PNG export)

**Why**: Dashboard no mostraba datos ni gráficos. Había bugs en funciones bar() y line() con Math.max(...va) que fallaba con strings. Faltaba sección Live y botones de export.

**Where**:
- reports/dashboard.html - fixes de JS y nuevas secciones
- scripts/metrics/dashboard-render.ps1 - regeneración de datos

**Learned**:
- Math.max(...array) no funciona con arrays de strings, necesita parseFloat()
- JSON.stringify() en refreshCharts() rompía el chart de autores
- Las características Live y Export solo funcionaban vía metrics-server, ahora funcionan offline
- Agregar sección Live con cards para tokens, traffic light, routing, sessions, peak hour
- Botones PDF/PNG ahora funcionan con window.print() y html2canvas fallback

---
*Imported from Engram on 2026-09-06*
