# ADR-0024: Puertos hexagonales para dependencias de infraestructura

**Estado**: Accepted **Fecha**: 2026-08-31 **Scope**: `src/ports/` — item F3.3 de
`docs/plans/STACK-EVOLUTION-PLAN-2026.md`

## Contexto

Gentle-Vanguard es local-first (ADR-0017): SQLite en `.runtime/`, colas en el propio proceso,
telemetría a archivos locales bajo `.telemetry/`. Ese modelo funciona para una instancia, pero el
plan de evolución (F3.3) exige que el escalamiento horizontal (multi-instancia, Postgres, colas
Redis) sea **configuración, no reescritura**. Hoy las decisiones de infraestructura están embebidas
en los módulos consumidores: cambiar de store o de cola implicaría tocar cada call-site.

El patrón hexagonal (ports & adapters) invierte esa dependencia: el dominio depende de interfaces
(puertos) y los adaptadores concretos se resuelven por configuración.

## Decisión

Se crea el módulo `src/ports/` con tres puertos mínimos y honestos (solo las operaciones que el
stack realmente usa), un adaptador local-first por defecto y una fábrica `resolvePorts()` que
convierte el swap en configuración de entorno:

| Puerto        | Interfaz                                      | Adaptadores                                                                         |
| ------------- | --------------------------------------------- | ----------------------------------------------------------------------------------- |
| `StoragePort` | get/set/delete/exists/list/append/count/close | `InMemoryStorage` (tests), `SqliteDiskStorage` (better-sqlite3, WAL, defecto)       |
| `QueuePort`   | enqueue/dequeue/ack/nack/depth                | `InProcessQueue` (FIFO con reserva y timeout de visibilidad); Redis/BullMQ = futuro |
| `TracingPort` | startSpan/event/recordException/flush         | `NoopTracingPort` (defecto), `OtelTracingPort` (OTLP/JSON sobre HTTP, opt-in)       |

Configuración (leída por `resolvePorts()`; fuente de env: contrato de
`src/config/config-service.ts`):

```
GV_STORAGE = memory | sqlite-disk   # defecto: sqlite-disk
GV_QUEUE   = in-process | redis     # defecto: in-process (redis = futuro)
GV_TRACING = noop | otel            # defecto: noop
```

Reglas de resolución:

- Valores desconocidos o futuros (`postgres`, `redis`) **no lanzan**: caen al default local-first
  con nota `(fallback→…)` en `ports.adapters` (coherente con ADR-0017: nunca romper el arranque
  local). El consumidor puede inspeccionar `adapters` para loggear la degradación.
- `OtelTracingPort` implementa el formato OTLP/JSON directamente sobre `http(s)` (endpoint estándar
  `OTEL_EXPORTER_OTLP_ENDPOINT`, default `localhost:4318/v1/traces`) porque no existe un SDK de
  OpenTelemetry importable en `src/` hoy — `src/monitor/tracing-instrument.ts` es un CLI que escribe
  archivos crudos. Ningún nuevo dependency; el export falla en silencio (tracing nunca rompe al
  llamador).

### Mapa de qué pasa por puertos y qué no

| Dato                                                                                  | ¿Por puerto?       | Razón                                                                                                                                                                                                                                   |
| ------------------------------------------------------------------------------------- | ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Estado de sesión pequeño, routing table, flags, cache liviana                         | Sí (`StoragePort`) | Patrón KV/documento, sin queries relacionales. Aquí es donde Postgres entra como adapter                                                                                                                                                |
| **Nexus** (métricas, trazas, eventos, alertas, feedback, tokens — 23 tablas, ADR-007) | **No**             | SQLite-native detrás del `DatabaseManager` singleton (`apps/web-dashboard/server/database/manager.ts`). Es dato operacional con esquema relacional y ciclo de vida propio; forzarlo por un puerto KV sería el anti-patrón "baling wire" |
| Tareas/jobs entre componentes                                                         | Sí (`QueuePort`)   | Semántica at-least-once con ack explícito; el contrato es el que Redis/BullMQ ya cumple                                                                                                                                                 |
| Spans de tracing                                                                      | Sí (`TracingPort`) | El contrato span/event/flush es el estándar OTLP; el adapter Noop garantiza costo cero local                                                                                                                                            |

### Demostración del swap (criterio de aceptación F3.3)

`tests/unit/ports/storage-port.test.ts` ejecuta **la misma suite de contrato** contra
`InMemoryStorage` y `SqliteDiskStorage` con aserciones idénticas (`contractSuite`). Además
`tests/unit/ports/queue-tracing-ports.test.ts` incluye un test que corre el mismo código consumidor
contra ambos adapters resueltos vía `resolvePorts()` con distinto `GV_STORAGE`.

## Camino de promoción (Postgres / Redis)

1. **Postgres**: nuevo `PostgresStorage implements StoragePort` (una tabla `port_kv`, mismas 8
   operaciones, `ON CONFLICT` ya modelado). Se activa con `GV_STORAGE=postgres` + cadena de
   conexión; cero cambios en consumidores.
2. **Redis/BullMQ**: `RedisQueue implements QueuePort` mapeando ack/nack a acknowledge/ nack de
   BullMQ; la reserva con timeout de visibilidad de `InProcessQueue` replica exactamente la
   semántica de redelivery. Se activa con `GV_QUEUE=redis`.
3. **OTel oficial**: `OtelTracingPort` se sustituye por un wrapper de
   `@opentelemetry/sdk-trace-base` detrás de la misma interfaz.
4. Nexus permanece SQLite-native hasta que la promoción multi-instancia lo exija; en ese momento se
   decide con un ADR propio (migración de esquema, backups, WAL→PITR), no como efecto colateral.

## Consecuencias

- Los consumidores nuevos de KV/colas/tracing dependen solo de `src/ports`; los módulos existentes
  NO se migran en este ADR (migración incremental posterior, como hizo ConfigService en F2.6).
- Contratos mínimos: si aparece una necesidad fuera de las ~8 operaciones de storage, se extiende el
  puerto explícitamente en lugar de filtrar SQL al consumidor.
- Costo local nulo: defaults idénticos al comportamiento previo (SQLite en `.runtime/`, cola en
  proceso, tracing noop).
- `resolvePorts()` es la única puerta de construcción; está prohibido instanciar adapters concretos
  en código de consumidor (se testea vía wiring en `queue-tracing-ports.test.ts`).

## Verificación

- `npx tsc --noEmit -p tsconfig.json` → 0 errores.
- `npx eslint src/ports --ext .ts` → 0 problemas.
- `npx tsx --test tests/unit/ports/*.test.ts` → 32/32 pass.
