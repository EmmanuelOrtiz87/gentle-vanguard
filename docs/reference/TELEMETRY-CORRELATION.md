# Telemetry Correlation — capa nativa de correlación OTel-compatible (F3.6)

> Unifica **traces + metrics + logs** bajo una sola cadena de correlación:
> `session_id ↔ trace_id ↔ token_transactions`, consultable en un solo lugar.

Implementado en `src/telemetry/` sin dependencias nuevas (`node:async_hooks` + `node:fs` +
`better-sqlite3` ya existente para el join con Nexus). No hay paquetes `@opentelemetry/*` en
`package.json`; en su lugar se implementa una capa nativa cuyo formato de eventos es **compatible
con el modelo mental OTLP/JSON** (trace_id/span_id hex, attribute-set en `payload`), de modo que la
promoción a un collector real no cambia los emisores (ver abajo).

## Arquitectura

```
                       ┌──────────────────────────────────────────┐
 withCorrelation(...)   │ AsyncLocalStorage<CorrelationContext>    │
   sessionId, agent,    │  { sessionId, agentName, traceId }      │
   traceId (auto)       └───────────┬──────────────────────────────┘
                                   │ enriquece automáticamente
        ┌──────────────────────────┼───────────────────────────────┐
        ▼                          ▼                               ▼
  traceEvent()              metricEvent()                   logger (bridge)
  metricEvent()             logEvent()                      src/utils/logger.ts
        └────────────┬─────────────┴───────────────────────────────┘
                     ▼  appendFileSync (1 línea por evento)
        .telemetry/correlation/correlation-YYYYMMDD.jsonl
                     ▼
        queryCorrelation({sessionId | traceId | timeRange})
             ├── JSONL (traces, metrics, logs)
             └── Nexus token_transactions (JOIN por session_id, read-only)
                     ▼
        Línea de tiempo unificada ordenada por ts
```

### Componentes

| Archivo                                    | Rol                                                                                                                                                                                                                      |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `src/telemetry/correlation.ts`             | Contexto ALS (`withCorrelation`, `getCorrelation`), generación de IDs OTLP-format (trace 32 hex / span 16 hex), emisión JSONL (`traceEvent`, `metricEvent`, `logEvent`, `emitCorrelationEvent`).                         |
| `src/telemetry/correlation-query.ts`       | `queryCorrelation({sessionId?, traceId?, from?, to?, includeTokens?, dbPath?})` → timeline unificada; `readTokenTransactions` lee Nexus `.runtime/gentle-vanguard.db` en modo read-only (best-effort).                   |
| `src/telemetry/correlation-cli.ts`         | CLI: `npx tsx src/telemetry/correlation-cli.ts --session <id> [--trace <id>] [--json] [--from] [--to] [--no-tokens]`.                                                                                                    |
| `src/utils/logger.ts`                      | Bridge no invasivo: dentro de un contexto de correlación, cada línea agrega `[session=… trace=…]` y se espeja como evento `kind:"log"` al JSONL. Fuera del contexto el logger queda 100% intacto (backwards compatible). |
| `tests/unit/telemetry-correlation.test.ts` | Propagación de contexto (anidado + async), enriquecimiento JSONL, bridge del logger, orden y filtros de la timeline.                                                                                                     |

### Cómo se construye la cadena session ↔ trace ↔ tokens

1. **session_id ↔ trace_id**: `withCorrelation({sessionId, agentName})` genera (o hereda) un
   `traceId`; todo evento emitido dentro del bloque —incluido trabajo `await`-ado y bloques anidados
   que no sobrescriban `traceId`— lleva ambos IDs. Un bloque anidado con `traceId` propio inicia una
   traza hija que **hereda el sessionId** (mismo session, nueva trace).
2. **trace_id ↔ token_transactions**: el daemon `src/tokens/token-ingest.ts` persiste transacciones
   en Nexus con `session_id` + `agent`. Como los eventos de correlación comparten `sessionId`,
   `queryCorrelation({sessionId})` une ambas fuentes: JSONL por un lado, `token_transactions` por
   otro, ordenadas por `ts` en una sola vista (kind `trace|metric|log|token`).
3. Formato del evento JSONL (una línea por evento):

```json
{
  "ts": "2026-08-31T12:00:00.000Z",
  "sessionId": "sess-1",
  "traceId": "<32hex>",
  "agent": "mavis",
  "spanId": "<16hex>",
  "kind": "trace",
  "name": "skill.run.start",
  "payload": { "skill": "nexus-database" }
}
```

## Uso

### Emitir con correlación

```ts
import { withCorrelation, traceEvent, metricEvent } from '../telemetry/correlation';

await withCorrelation({ sessionId: session.id, agentName: 'mavis' }, async () => {
  traceEvent('task.start', { task: 'audit' });
  const r = await doWork(); // logger.info(...) dentro se enriquece solo
  metricEvent('tokens.consumed', r.tokens);
});
```

### Consultar la timeline unificada

```ts
import { queryCorrelation } from '../telemetry/correlation-query';
const { entries, total, sources } = await queryCorrelation({ sessionId: 'sess-1' });
```

### CLI

```bash
npx tsx src/telemetry/correlation-cli.ts --session <id>            # tabla legible
npx tsx src/telemetry/correlation-cli.ts --trace <traceId> --json  # JSON crudo
```

(El subcomando `gv` será cableado por orquestación en `src/cli/gv.ts`.)

### Variables de entorno

- `GV_TELEMETRY_CORRELATION_DIR`: override del directorio JSONL (tests/isolation).
- `GV_CORRELATION_DEBUG=1`: loguea errores del join con Nexus (normalmente silencioso).

## Camino de promoción OTel (collector OTLP real)

Cuando se agregue un collector OTLP (p. ej. `localhost:4318/v1/traces`, como ya hace
`src/monitor/tracing-instrument.ts`), la capa no se descarta — se le agrega un exporter:

1. **Nada cambia en los emisores**: `withCorrelation`/`traceEvent`/`metricEvent` y el bridge del
   logger siguen siendo la API. El `payload` ya es un attribute-set y los IDs ya tienen el formato
   hex OTLP (trace 32, span 16).
2. `emitCorrelationEvent` pasa de (o además de) `appendFileSync` a construir spans OTLP/JSON reales:
   `kind:"trace"` → span start/end, `kind:"metric"` → datapoint, `kind:"log"` → log record con
   trace_id/span_id adjuntos (log correlation nativa de OTel).
3. `resourceSpans.resource.attributes` se puebla con `service.name=gentle-vanguard`, `session.id`,
   `agent.name` — la cadena session↔trace se vuelve consultable en Jaeger/Tempo con el mismo key.
4. La parte "queryable in one place" puede migrar de JSONL al backend del collector;
   `queryCorrelation` mantendría su firma leyendo del nuevo store, o el JSONL queda como buffer
   local-first (ADR-0017) y el collector como fan-out.
5. Si se adoptan SDKs `@opentelemetry/*`, `withCorrelation` se implementa sobre `context.active()` +
   W3C traceparent en lugar de ALS propio — de nuevo, solo cambia el interior del módulo.

## Normativa

- Telemetry nunca rompe el proceso host: errores de fs/DB se tragan (salvo
  `GV_CORRELATION_DEBUG=1`).
- Eventos fuera de contexto se descartan (sin cadena no hay valor de timeline).
- JSONL append-only, un archivo por día (`correlation-YYYYMMDD.jsonl`), líneas parciales toleradas
  por el lector.
