# SELF-HEALING-CI — Auto-Recuperación de CI/CD

**Versión:** 1.0 | **Vigente desde:** July 14, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Minimizar la intervención manual ante fallos en el pipeline CI/CD mediante clasificación automática
de fallos, reintentos inteligentes y circuit breaker que evita tormentas de reinicio.

## 2. Clasificación de Fallos

### 2.1 Flaky

- Fallo intermitente sin causa determinista (timeout de red, rate limit, recurso temporal)
- Se identifica por patrones en `config/ci-self-heal.json` sección `patterns.flaky`
- Acción: reintento automático inmediato

### 2.2 Real

- Fallo determinista en código, pruebas o configuración
- No se resuelve con reintentos; requiere intervención humana
- Acción: notificar, bloquear merge, registrar incidente

### 2.3 Infraestructura

- Fallo en recursos compartidos (disco lleno, servicio caído, credencial expirada)
- Se identifica por patrones en `config/ci-self-heal.json` sección `patterns.infra`
- Acción: reintento con backoff + alerta al equipo de infra

## 3. Reintentos por Niveles

| Nivel    | Estrategia                                | Límite | Acción al Fallar              |
| -------- | ----------------------------------------- | ------ | ----------------------------- |
| Instant  | Reintento inmediato                       | 3      | Pasa a backoff                |
| Backoff  | Exponential (5s base, 60s max, jitter 2s) | 5      | Escala a escalate             |
| Escalate | Notifica al orchestrator                  | 1      | Circuit breaker + post-mortem |

## 4. Circuit Breaker

- Estado CLOSED: operación normal, reintentos activos
- Estado OPEN: fallos > N en ventana de 5 minutos; no se ejecutan reintentos
- Estado HALF_OPEN: tras 60s en OPEN, se prueba 1 ejecución; si pasa → CLOSED, si falla → OPEN
- El estado se persiste en `.session/ci-circuit-breaker.json`

## 5. Integración con ci-self-heal.json

- `config/ci-self-heal.json` define: `patterns.flaky`, `patterns.infra`, `retryPolicy`,
  `circuitBreaker`, `notificationMatrix`
- El archivo es la fuente única de verdad; no hardcodear thresholds en scripts
- `ci-retry-engine.ps1` y `ci-rollback-engine.ps1` leen de esta configuración

## 6. Matriz de Notificaciones

| Tipo de Fallo | Canal                | Destinatario         | Tiempo Máximo |
| ------------- | -------------------- | -------------------- | ------------- |
| Flaky         | Dashboard alert      | Pipeline log         | 30 segundos   |
| Real          | GitHub Issue + Slack | Equipo de desarrollo | 2 minutos     |
| Infra         | Pager + Slack        | Equipo de infra      | 1 minuto      |
| Security      | Pager + correo       | Security lead        | 30 segundos   |

## 7. Excepciones

- Branches `feature/*` y `hotfix/*` usan solo reintento instant (sin backoff ni escalate)
- Ejecuciones manuales desde CLI con `-SkipSelfHeal` deshabilitan todo el mecanismo
