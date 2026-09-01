# Cost Dashboard (F3.5 — Sostenibilidad económica del runtime)

Panel ejecutivo de costos del runtime sobre los datos históricos de tokens ya consolidados en Nexus
(`token_transactions` + `token_usage`, ~658M tokens). Sin mock data: todo deriva de trazas reales
ingeridas por `src/tokens/token-ingest.ts`.

## Acceso

- Ruta del dashboard: **`/costs`** (nav "Operate → Costs").
- API: **`GET /api/costs`** (requiere sesión viewer; auth igual que el resto del dashboard).
- El agregado se cachea en memoria del servidor por **5 minutos** (los datos son históricos, no
  real-time). La respuesta incluye `cached: true|false`.

## Cómo se calcula el costo

`costo = tokens_input/1M × precio_input + tokens_output/1M × precio_output`

- Tabla de precios de referencia: **`config/model-pricing.json`** (USD por 1M tokens). Los modelos
  free-tier/locales tienen precio 0 explícito.
- Modelos desconocidos se precio 0 y se reportan en `unpricedModels` (bandera visible en el panel).
- El matching de modelos es case-insensitive con fallback por prefijo/subcadena (ej. `GLM-5.3-Flash`
  → `glm-5.3-flash`).

## Shape de la respuesta (`data`)

```
{
  generatedAt, currency,
  totals: { costUsd, inputTokens, outputTokens, totalTokens, monthToDateCostUsd },
  perDay: [{ date, costUsd, totalTokens }],            // últimos 30 días
  perAgent: [{ key, costUsd, totalTokens, sharePct }],
  perModel: [{ key, costUsd, totalTokens, sharePct }],
  topSessions: [{ sessionId, costUsd, totalTokens, transactions, lastActivity }],  // top 5
  monthlyProjection: { from7d, from30d },               // run-rate mensual
  budget: { dailyTokens, perSessionTokens, usedTodayTokens, usedTodayPct,
            softThresholdPct, hardThresholdPct, status },  // vs config/token-budget-guard.json
  insight,                                              // p.ej. perfil "cheap" más conveniente
  unpricedModels: []
}
```

## Presupuesto

Los límites vienen de `config/token-budget-guard.json` (daily 5M, perSession 3M, soft 70%, hard
90%). El estado (`ok` / `soft` / `hard`) compara los tokens consumidos **hoy** contra el límite
diario.

## Insight de optimización

El servidor compara el costo billable real contra el costo que tendría el mismo volumen input/output
en el modelo con precio más bajo de los usados — una aproximación del ahorro de rutas el perfil
`cheap` de `config/model-router.json` en fases de bajo riesgo.

## Archivos

| Rol                        | Archivo                                                                                  |
| -------------------------- | ---------------------------------------------------------------------------------------- |
| Cómputo (puro, testeable)  | `apps/web-dashboard/server/cost-report.ts`                                               |
| Handler HTTP + caché 5 min | `apps/web-dashboard/server/handlers/costs.ts`                                            |
| Registro de ruta           | `apps/web-dashboard/server/websocket-server.ts`                                          |
| Panel (recharts, GV brand) | `apps/web-dashboard/src/components/CostPanel.tsx`                                        |
| Ruta + nav                 | `apps/web-dashboard/src/App.tsx`                                                         |
| i18n (en/es/pt-BR)         | `apps/web-dashboard/src/i18n/ui-strings.ts`                                              |
| Tests                      | `src/components/CostPanel.test.tsx`, `src/cost-report.test.ts` (en `apps/web-dashboard`) |
| Precios                    | `config/model-pricing.json`                                                              |

## Notas

- Actualizar precios: editar `config/model-pricing.json` (no requiere reinicio; se relee al expirar
  la caché).
- Los tokens del propio dashboard son locales/gratuitos; los costos reflejan el precio de referencia
  de los modelos cloud usados por las herramientas ingeridas (zcode, codex, minimax, opencode).
