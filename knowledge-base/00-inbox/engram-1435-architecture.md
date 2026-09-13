---
created: 2026-06-18 04:55:12
tags: [engram, architecture]
engram_id: 1435
type: architecture
---

# Dashboard ultimate v2 - mejora completa

**What**: Implementación completa del Dashboard Ultimate v2 con 3 sprints de mejora: pipeline real de datos, tracing/waterfall/feedback loop, alertas/SLA/build

**Why**: Reemplazar datos mock con métricas reales, agregar telemetría tipo Langfuse (costos por modelo, latencia percentiles, feedback, SLA, alertas)

**Where**:
- apps/web-dashboard/src/types/dashboard.ts — tipos extendidos (ModelCost, LatencyMetrics, FeedbackMetric, CostInsight, SLA)
- apps/web-dashboard/server/real-data.ts — pipeline real desde .session/context-log/*/.state.json y .runtime/metrics/
- apps/web-dashboard/src/components/Dashboard.tsx — 7 filas: KPIs, Cost/Feedback/SLA/System, Active Alerts, Cost by Model, Cost Insights, Latency Percentiles, SLA & Reliability
- apps/web-dashboard/src/components/TracingDashboard.tsx — Waterfall View con spans anidados, feedback buttons, filtros
- apps/web-dashboard/src/components/LiveChart.tsx — líneas de cost y latency
- apps/web-dashboard/src/components/SessionTable.tsx — columnas Model + Cost, ordenado por status
- apps/web-dashboard/server/websocket-server.ts — endpoints POST /api/feedback, GET /api/alerts
- config/dashboard-alerts.json — 8 reglas configurables
- apps/web-dashboard/src/hooks/useAlerts.ts, useSessions.ts

**Learned**:
- Los archivos .state.json en .session/context-log/ contienen datos reales de sesiones con turns, tokens, cost, modelo
- Vite proxy configura /api y /ws para forward a backend en puerto 8080
- El build de Vite produce chunks optimizados por dependencia (react, recharts, lucide-react)
- Las alertas requieren soporte de direction (above/below) para reglas como low_sla y low_feedback_score — bug menor pendiente
- npm run build pasa correctamente con 0 errores de TypeScript

---
*Imported from Engram on 2026-09-06*
