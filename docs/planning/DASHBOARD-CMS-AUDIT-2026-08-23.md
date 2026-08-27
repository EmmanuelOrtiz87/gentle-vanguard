# Dashboard + CMS - Auditoria runtime y plan de nivel producto

Fecha: 2026-08-23  
Superficies auditadas: `apps/web-dashboard/`, `src/content-operations/`, `config/`,
`docs/planning/DASHBOARD-CMS-NEXT-LEVEL.md`

## 1. Resultado ejecutivo

La base es real y diferenciada: el dashboard obtiene datos del stack, persiste snapshots en SQLite,
expone HTTP + WebSocket, mantiene fallback offline, integra tracing, alertas, estado compartido,
MCP, sesiones, tareas, skills y multi-repo. El CMS/Marketplace también tiene API, publicación
validada, reseñas y un motor de Content Operations con máquina de estados.

No está listo todavía para presentarse como producto de primer nivel sin una fase corta de
confiabilidad y coherencia. El riesgo principal no es la falta de funcionalidades, sino la distancia
entre capacidades existentes y señales visibles de confianza: cifras derivadas o sintéticas,
versiones inconsistentes, mensajes ambiguos, poca cobertura de pruebas y ausencia de un flujo
enterprise completo.

## 2. Verificación ejecutada

| Área                                       | Resultado              | Evidencia                                                                                                    |
| ------------------------------------------ | ---------------------- | ------------------------------------------------------------------------------------------------------------ |
| Build frontend                             | PASS                   | `pnpm run build` transforma 2211 módulos y genera producción                                                 |
| Tests                                      | PASS                   | 7 archivos, 52 tests                                                                                         |
| Lint                                       | PASS                   | `eslint . --max-warnings 0` sin salida de errores                                                            |
| HTTP health                                | PASS                   | `GET /api/health` devuelve 200                                                                               |
| HTTP metrics                               | PASS                   | `GET /api/metrics` devuelve 200 con payload `metrics`                                                        |
| HTTP alerts/traces/tenants/slo/marketplace | PASS                   | Todos devuelven respuesta válida; `/api/slo` actualmente sin datos                                           |
| HTTP knowledge                             | PASS                   | Búsqueda local acotada sobre `docs/`, `knowledge-base/` y `reports/`                                         |
| HTTP metrics history                       | PASS                   | `GET /api/metrics/history?limit=120` devuelve snapshots SQLite en orden temporal                             |
| Marketplace install                        | PASS                   | `POST /api/marketplace/:id/install` registra instalación local y descarga                                    |
| Marketplace uninstall                      | PASS                   | `POST /api/marketplace/:id/uninstall` desactiva sin borrar el contenido                                      |
| Historical ranges                          | PASS                   | SQLite filtra `5m`, `1h`, `24h`, `7d` y `30d`; la UI expone selector                                         |
| Marketplace versions                       | PASS WITH GAP          | Endpoints de snapshots y rollback implementados; skills antiguas no conformes son rechazadas hasta migración |
| Dependency audit                           | PASS                   | `pnpm audit --json`: 0 vulnerabilidades tras overrides de pnpm                                               |
| Catalog validation                         | PASS WITH GAP          | 175 skills detectadas: 7 válidas y 168 legacy pendientes de migración; aprobación inválida rechazada         |
| Migration queue UI                         | PASS                   | Marketplace muestra la cola, genera drafts auditables y permite aprobar skills válidas                       |
| Content Operations UI                      | PASS                   | Nueva ruta `/content-operations` consume el manifiesto, valida jobs y respeta transiciones nativas           |
| Content package preview                    | PASS                   | Detalle por job expone validación, caption, publication y estado de packaging                                |
| Bulk migration staging                     | PASS                   | 168/168 skills legacy tienen drafts separados, sin sobrescribir fuentes                                      |
| Content calendar metrics                   | PASS                   | Panel expone distribución por plataforma y fecha desde el manifiesto                                         |
| WebSocket                                  | PASS                   | Conexión, `metrics`, `bridge_status` y `state_tasks` recibidos                                               |
| Refresco vivo                              | PASS                   | Cliente queda en `WS Connected`; servidor emite cada 5 s y watcher de métricas reacciona                     |
| UI dashboard                               | PASS CON OBSERVACIONES | Renderiza y actualiza; se detectan problemas de copy, métricas y densidad                                    |
| UI Marketplace/CMS                         | PASS CON OBSERVACIONES | Catálogo y modal de publicación visibles; experiencia todavía prototípica                                    |

## 3. Hallazgos prioritarios

### P0 - Corregir antes de vender o hacer demo pública

1. **Métrica de routing mal normalizada.** RESUELTO: contrato visible 0-100 y formateo único.
2. **Distribución por modelo no confiable.** RESUELTO PARCIALMENTE: se eliminó la distribución
   sintética; la UI muestra atribución unavailable hasta contar con trazas por modelo.
3. **Alerta de feedback contradictoria.** RESUELTO: dirección, operador y umbral quedan explícitos.
4. **Versiones desalineadas.** RESUELTO: `/api/health` usa la versión del paquete del dashboard.
5. **CMS sin ciclo de confianza completo.** RESUELTO PARCIALMENTE: instalación, desactivación,
   snapshots, rollback, estados de revisión, reporte, cola UI y staging masivo implementados; 168
   drafts requieren revisión editorial humana.
6. **CORS y superficie write sin autenticación.** El servidor usa API HTTP/WS local con endpoints
   POST y CORS amplio. Antes de exponerlo fuera de localhost: API key o sesión firmada, RBAC,
   CSRF/origin checks, rate limits y audit log.

### P1 - Siguiente fase de producto

1. Selector de rango temporal real (`5m`, `1h`, `24h`, `7d`, `30d`) IMPLEMENTADO; queda pendiente
   rango custom y agregaciones para períodos mayores que la retención local.
2. Estados unificados de loading, stale, offline, error, retry y última actualización.
3. Reducir polling redundante: hoy hay WS, fetch cada 5 s, polling de tablas y otros intervalos
   independientes.
4. Suscripciones WS granulares, payloads diferenciales y límites de backpressure.
5. Trazabilidad completa `trace -> log -> métrica -> alerta -> acción`.
6. Métricas del propio dashboard: latencia de endpoints, tamaño de payload, duración de snapshots,
   conexiones, errores por panel y tiempo de hidratación.
7. Cobertura de hooks, servidor y E2E. Los 52 tests actuales cubren componentes puntuales, pero no
   validan los contratos más riesgosos.
8. Marketplace con búsqueda full-text, filtros, orden, paginación, detalle enriquecido, moderación
   UI, changelog, dependencias, licencia, screenshots y badges de confianza.
9. Editor Markdown con preview, validación continua, templates, diff de versiones y sandbox antes de
   publicar.
10. Construir `ContentOpsPanel` encima de `src/content-operations/engine.ts`: IMPLEMENTADO como
    panel operativo de estados, validación, filtros, calendario, métricas por plataforma, avance,
    packaging y preview; queda histórico de rendimiento por plataforma.

### P2 - Diferenciación y crecimiento

1. Demo mode read-only con dataset reproducible y botón de reset.
2. Tour guiado de cinco money-shots: agente en vivo, HITL, waterfall, auto-healing y ContentOps.
3. Forecast de tokens/costo y burn-rate de SLO.
4. Enlaces compartibles de dashboards, layouts guardados y command palette.
5. Notificaciones opt-in por webhook, Slack y correo.
6. Landing, comparativas honestas, capturas, GIFs, guiones de demo y modo público local-first.

## 4. Plan recomendado

### Fase 0 - Trust patch

Corregir normalización de porcentajes, eliminar valores sintéticos, alinear versión, reparar copy de
alertas, documentar todos los eventos WS y resolver `/api/knowledge`. Agregar tests de contrato para
estos casos. Objetivo: que cada número visible pueda explicarse y rastrearse.

### Fase 1 - Product-grade observability

Crear series históricas, selector de rango, agregación server-side, estados de datos, health de
conexión, self-telemetry y E2E de dashboard. Objetivo: que un desarrollador pueda investigar y que
un gerente pueda entender tendencia, costo, riesgo y acción.

### Fase 2 - CMS first-class

Convertir Marketplace + Content Operations en un CMS completo: discover, author, validate, review,
approve, install, execute, measure y rollback. Objetivo: demostrar el stack creando y operando
contenido con el mismo nivel de observabilidad que una sesión técnica.

### Fase 3 - Demo y comercialización

Separar `Demo mode` de `Live mode`, sembrar datos sintéticos etiquetados, preparar tour, capturas,
comparativas y casos de uso para developer, manager e institución. Objetivo: que la herramienta sea
el principal argumento visual y funcional del stack.

## 5. Criterios de aceptación de producto

- Cero números sintéticos presentados como medición real.
- Toda métrica tiene fuente, unidad, timestamp, rango y estado de frescura.
- El usuario entiende si está viendo live, cached, stale, demo o unavailable.
- Cualquier alerta explica condición, valor actual, umbral, severidad y acción sugerida.
- El dashboard soporta una investigación desde alerta hasta trace/log/evidencia.
- El CMS permite preview, validación, aprobación, instalación segura, rollback y auditoría.
- Build, lint, unit tests, E2E, accesibilidad y responsive forman parte del gate de release.
- Demo mode nunca mezcla datos sintéticos con datos reales sin etiquetarlos.

## 6. Conclusión

El plan maestro existente en `docs/planning/DASHBOARD-CMS-NEXT-LEVEL.md` sigue siendo válido y cubre
la mayor parte del recorrido. Esta auditoría agrega evidencia runtime y reordena el trabajo: primero
confianza y contratos de datos, después historia temporal y self-observability, luego CMS operativo
y finalmente demo/GTM. Con ese orden, dashboard y CMS pueden convertirse en la demostración más
convincente del stack sin depender de promesas de marketing.
