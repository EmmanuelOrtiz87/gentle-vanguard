# opencode.json — Estrategia de providers (2026-09-06)

## TL;DR

- `opencode-zen-A/B` y `opencode-go-A/B` ahora usan `models: {}` vacío → **auto-descubrimiento** desde el endpoint oficial (Zen: 70 modelos, Go: 35 modelos).
- `littellmott-nuevo` y `zai` → `disabled_providers` (problemas estructurales, no transitorios).
- Dify, lm-studio, tokenrouter → quedan explícitos con su catálogo curado.
- Backup previo: `~/.config/opencode/backups/opencode.json.20260906-192213.bak`.

## Por qué vacío en lugar de catálogo curado

El catálogo manual estaba stale: `qwen3-coder` para Zen no existe en el endpoint real, y los demás `claude-sonnet-4-5` / `claude-opus-4-7` / `gpt-5` / `deepseek-v4-pro` sí existen pero como modelos pagos que requieren crédito (y la cuenta A no tiene). El auto-discovery consulta `/v1/models` con la key activa y devuelve el catálogo real de la cuenta, que cambia solo.

## Por qué disable littellmott-nuevo y zai

- **littellmott-nuevo**: budget exceeded permanente, BadRequest de Bedrock, auth errors recurrentes → el gateway OTT tiene problemas estructurales.
- **zai**: insufficient balance → la cuenta no tiene fondos.

## Herramientas nativas del stack

### `oc-doctor` — health check de providers

Wrapper en `C:\Users\emman\bin\oc-doctor.cmd` que ejecuta `opencode-model-doctor.ts` contra el config real.

```bash
oc-doctor                # rápido, ~5s, solo catalog endpoint
oc-doctor --probe        # ~30s, manda chat completion a modelos sample
oc-doctor zen-A --probe  # solo un provider
oc-doctor --json         # salida JSON para CI
```

**Exit codes**: 0=OK, 1=stale config o modelos rotos, 2=auth/network error.

El doctor detecta y clasifica los problemas observados en el log:
- `OK` — el modelo respondió
- `RATE_LIMITED` — FreeUsageLimitError (cuota free diaria, **transitorio**)
- `USAGE_LIMIT` — 5-hour/weekly/monthly de Go (**transitorio** hasta el reset)
- `INSUFFICIENT_BALANCE` — CreditsError (cuenta sin saldo, **requiere recarga**)
- `INTERNAL_ERROR` — bug de config o upstream (ej. `muse-spark-*` con override npm)
- `PARAM_LEAK` — AI SDK filtra params prohibidos (ej. `kimi-k3` con `provider`/`litellm_settings`)
- `OPT_IN_REQUIRED` — modelo geo-bloqueado (ej. `deepseek-v4-flash` China)
- `AUTH_FAILED`, `NOT_FOUND`, `TIMEOUT`, `NETWORK_ERROR`

### `validate-opencode-config` — validación estructural + anti-patrones

```bash
npx tsx src/tools/validate-opencode-config.ts --config ~/.config/opencode/opencode.json
```

Detecta el **anti-patrón SDK** que rompió `muse-spark-1.2-contributor-free`:

```
WARN: provider.opencode-zen-A.models.muse-spark-1.2-contributor-free.npm = "@ai-sdk/openai"
differs from parent npm "@ai-sdk/openai-compatible". Mixing @ai-sdk/openai and
@ai-sdk/openai-compatible in the same provider causes "Internal server error"
with no useful diagnostic.
```

Si lo ves en CI, rechazar el commit.

### `oc-keyring` — rotación de cuentas (existente)

Sigue manejando `opencode-zen-A/B` y `opencode-go-A/B` automáticamente. Status:

```
zen   active = A    provider id = opencode-zen-A
go    active = A    provider id = opencode-go-A
```

## Si algo se rompe, rollback

```powershell
Copy-Item "$env:USERPROFILE\.config\opencode\backups\opencode.json.20260906-192213.bak" "$env:USERPROFILE\.config\opencode\opencode.json" -Force
Copy-Item "$env:USERPROFILE\.config\opencode\backups\auth.json.20260906-192213.bak" "$env:USERPROFILE\.local\share\opencode\auth.json" -Force
& "$env:USERPROFILE\bin\oc-keyring.cmd" sync
```

## Validación contra el log (pendiente, post-actividad)

Después de actividad real con OpenCode Desktop, revisar `~/.local/share/opencode/log/opencode.log` y confirmar:
- No más `AI_APICallError: Internal server error` para `muse-spark-1.2-contributor-free` (modelo eliminado del catálogo).
- No más `Not Found` o `Invalid input` para modelos de Zen.
- El picker muestra modelos para los 4 providers `-A/-B` (auto-descubiertos).
- `oc-keyring switch zen B` cambia la key activa y se ve reflejada en el log con el `providerID` actualizado.

## Estado del catálogo en vivo (sep-06)

| Provider | Catálogo | Modelos accesibles ahora |
|---|---|---|
| `opencode-zen-A` | 70 modelos | 1 (big-pickle con rate limit free) |
| `opencode-zen-B` | 70 modelos | 1 (idem) |
| `opencode-go-A` | 35 modelos (todos pagos) | 0 (monthly limit reached) |
| `opencode-go-B` | 35 modelos (todos pagos) | 0 (idem) |
| Dify | n/a (gateway, no `/models`) | gpt-4 (sin probar) |
| lm-studio | n/a (servidor local apagado) | 0 |
| tokenrouter | n/a (falta auth) | 0 |

Ver `docs/operations/opencode-model-compatibility.md` para la matriz completa.

## Lecciones (memoria)

- **Nunca hardcodear catálogo de modelos en opencode.json para providers auto-gestionados** (zen, go). Dejar `models: {}` y dejar que el endpoint los liste. El catálogo cambia cada 1-2 semanas.
- **Nunca mezclar `npm: "@ai-sdk/openai"` con `npm: "@ai-sdk/openai-compatible"` en el mismo provider**. El SDK openai nativo arma un payload distinto al que esperan los proxies que se hacen pasar por OpenAI-compatible. Resultado: `Internal server error` sin código útil. Ahora detectado automáticamente por `validate-opencode-config`.
- **Los límites 5-hour / weekly / monthly de OpenCode Go no son bugs**, son la política del producto.
- **El sistema dual `opencode-zen-A/B` + `opencode` (sin sufijo)** sigue siendo confuso pero la rotación con `oc-keyring` funciona. Consolidar requeriría reescribir `oc-keyring.ps1` (~30 min, fuera de scope).
- **`oc-doctor` es la fuente de verdad** sobre qué modelos funcionan. Correrlo periódicamente y antes de cualquier cambio de config para tener el ground truth.
