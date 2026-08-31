# Budget-Aware Routing (downgrade automático de rutas internas)

> Módulo: `src/tokens/budget-aware-routing.ts` · Config: `config/token-budget-guard.json`
> (sección `routingDowngrade`) · Decisions: `.runtime/budget-routing-decisions.jsonl` +
> eventos Nexus `budget.routing_downgrade`.

## Política

Cuando el consumo diario de tokens (Nexus, tabla `token_usage`, mismo origen que
`token:status`) supera los umbrales, las rutas **INTERNAS** de resolución de modelo
(delegación a subagentes, research/ingest) se degradan automáticamente al perfil
`cheap` — que en este entorno resuelve al modelo free-tier `opencode/mimo-v2.5-free`
(`fallback.model` de `config/model-router.json`).

**Invariante:** el modelo de la sesión interactiva/principal NUNCA se modifica. El
hook vive únicamente en `src/orchestration/agent-delegator.ts` (`runNativeAgent`,
resolución de modelo del subagente spawned) y solo reescribe el modelo interno.

## Umbrales

| Estado | Condición | Acción |
|--------|-----------|--------|
| `ok`   | uso < soft | sin cambios |
| `soft` | uso ≥ soft (100%) | rutas internas en `applyTo` → perfil `cheap` |
| `hard` | uso ≥ hard (150%) | igual que soft + WARN en log una vez por hora |

El porcentaje se calcula sobre `tokenBudget.limits.daily` (5M por defecto).

## Config

```json
"routingDowngrade": {
  "enabled": true,
  "softThresholdPct": 100,
  "hardThresholdPct": 150,
  "downgradeProfile": "cheap",
  "applyTo": ["subagent", "delegation", "research"]
}
```

- `downgradeProfile`: solo `cheap` implica cambio de modelo (→ free-tier fallback).
  `balanced`/`premium` mapean al mismo modelo nativo → sin rewrite salvo que se
  fije `downgradeModel` explícito.
- `downgradeModel` (opcional): fija el modelo destino explícitamente.
- `applyTo`: rutas afectadas. Cualquier otra ruta (p.ej. `interactive`) nunca se
  degrada.

## Desactivar / ajustar

- Desactivar: `"enabled": false` en la sección, o env `GV_BUDGET_ROUTING=0`
  (kill-switch que ignora el config).
- Ajustar sensibilidad: subir `softThresholdPct` (p.ej. 120) para degradar más tarde.
- Reversible por diseño: sin estado persistente de routing; al bajar el uso del día
  (o desactivar), la siguiente resolución vuelve al modelo original automáticamente.

## Registro de decisiones

Cada degradación automática se registra en dos sitios:

1. `.runtime/budget-routing-decisions.jsonl` — una línea JSON por decisión:
   `{ts, path, from, to, usagePct, reason}`.
2. Tabla `events` de Nexus — tipo `budget.routing_downgrade` (mismo payload).

## Uso

```bash
npx tsx src/tokens/budget-aware-routing.ts            # estado JSON
npx tsx src/tokens/budget-aware-routing.ts --demo subagent opencode/big-pickle
```

API: `getBudgetRoutingState()` y `resolveBudgetAwareModel(path, requestedModel)`
(acepta `stateOverride` para tests).
