---
created: 2026-09-11 19:54:39
tags: [engram, architecture]
engram_id: 3886
type: architecture
---

# Limpieza: api-gateway y notification-hub eliminados + puntos de acción futuros

**What**: Limpieza de apps sin uso + verificación de scripts de arranque manual de command-center + registro de puntos de acción futuros.

**Why**: El usuario pidió: (1) verificar que command-center se puede iniciar manualmente desde scripts, (2) investigar y eliminar apps sin uso (api-gateway, notification-hub), (3) registrar puntos de acción futuros para el CRM.

**Where**:
- ELIMINADOS: `apps/api-gateway/` (gateway REST con auth/rate limiter — esqueleto sin usar, no referenciado, no en command-center), `apps/notification-hub/` (hub de notificaciones WebSocket — esqueleto sin usar, no referenciado, no en command-center)
- CONSERVADO: `apps/academy-landing/` (landing pública estática — útil para comercialización externa futura)
- VERIFICADO: `npm run cc:start` funciona (node --import tsx apps/command-center/start.ts), start.ts hace health check + spawn detached + open browser

**Learned**: (1) El script `npm run cc:start` funciona correctamente: start.ts verifica si el server ya está corriendo (health check), si no lo está lo spawnea detached con windowsHide, y abre el browser. (2) api-gateway y notification-hub eran esqueletos sin usar — no estaban en command-center, no eran referenciados por ninguna app, y no tenían servidores corriendo. (3) academy-landing es útil (landing pública con SEO) pero no está en command-center — se sirve con python http.server. (4) Los puntos de acción futuros del CRM están registrados en esta observación.

**PUNTOS DE ACCIÓN FUTUROS (CRM Studio)**:
- Reportes de revenue por mes/año con gráficos
- Notificaciones de seguimiento (recordatorios de contactar leads)
- Export del historial a CSV/PDF
- Integración con calendario externo (Google Calendar)
- Notificaciones push en tiempo real de leads nuevos (WebSocket en vez de polling)
- Panel "Academy Overview" consolidado en dashboard
- Export de alertas a CSV
- Checkout real (requiere procesador de pagos: Stripe/MercadoPago)
- Deploy de landing a producción con dominio propio
- Integración de leads con CRM externo
- og:image en PNG para redes sociales (convertir SVG a PNG)

---
*Imported from Engram on 2026-09-12*
