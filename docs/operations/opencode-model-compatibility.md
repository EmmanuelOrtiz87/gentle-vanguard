# opencode — Matriz de compatibilidad de modelos (2026-09-06)

Matriz viva basada en el catálogo real (`GET /v1/models`) del endpoint, contrastada con los errores
observados en `~/.local/share/opencode/log/opencode.log`.

## Cómo regenerar esta matriz

```bash
# Catálogo + auth (rápido, ~5s)
oc-doctor

# Catálogo + probe por modelo (lento, ~30s)
oc-doctor --probe

# Solo un provider
oc-doctor go-A --probe
```

## OpenCode Zen (`https://opencode.ai/zen/v1`) — 70 modelos

| Modelo                                                                             | Estado cuenta A (sep-06)     | Notas                                                                                                                       |
| ---------------------------------------------------------------------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `big-pickle`                                                                       | ⚠️ RATE_LIMITED (free quota) | Free, transitorio. Reset diario. **Default actual**.                                                                        |
| `deepseek-v4-flash-free`                                                           | ❌ HTTP 400                  | **Roto** (no devuelve error claro, posiblemente ya retirado).                                                               |
| `muse-spark-1.2-contributor-free`                                                  | ❌ INTERNAL_ERROR            | **Bug de SDK**: el modelo se sirve con un payload distinto al esperado. Ver `opencode-provider-strategy.md` (npm override). |
| `muse-spark-1.3-contributor-free`                                                  | ❌ INTERNAL_ERROR            | **Mismo bug que 1.2** (toda la línea `muse-spark-*` está rota).                                                             |
| `mimo-v2.5-free`                                                                   | ⚠️ RATE_LIMITED (free quota) | Free, transitorio.                                                                                                          |
| `ling-3.0-flash-fin-free`                                                          | ❔ Sin probar                | Free, no probado en el log.                                                                                                 |
| `nemotron-3-ultra-free`                                                            | ✅ OK (probado zen-B)        | Free, sin errores.                                                                                                          |
| `nemotron-3.5-lightning-free`                                                      | ❔ Sin probar                | Free.                                                                                                                       |
| `claude-fable-5`, `-5-1`                                                           | ❌ INSUFFICIENT_BALANCE      | Paid, requiere créditos.                                                                                                    |
| `claude-opus-5`, `-4-8`, `-4-7`, `-4-6`, `-4-5`                                    | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `claude-sonnet-5`, `-4-6`, `-4-5`, `-4`                                            | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `claude-haiku-4-5`                                                                 | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `gemini-3.6-flash`, `-3.8-flash`, `-3.7-flash`, `-3.5-flash-lite`, `-3.5-flash`    | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `gemini-3.1-pro`, `-3-flash`                                                       | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `gpt-6-astra`, `-5.6-sol`, `-5.6-terra`                                            | ❌ INSUFFICIENT_BALANCE      | Paid, nuevos.                                                                                                               |
| `gpt-5.6-luna`, `-5.5`, `-5.5-pro`                                                 | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `gpt-5.4`, `-5.4-pro`, `-5.4-mini`, `-5.4-nano`                                    | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `gpt-5.3-codex-spark`, `-5.3-codex`                                                | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `gpt-5.2`, `-5.2-codex`, `-5.1`, `-5.1-codex-max`, `-5.1-codex`, `-5.1-codex-mini` | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `gpt-5`, `-5-codex`, `-5-nano`                                                     | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `grok-build-0.1`, `-4.6`, `-4.5`                                                   | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `muse-spark-1.3`, `-1.2`                                                           | ❔ Sin probar (paid)         | Paid.                                                                                                                       |
| `deepseek-v4-pro`                                                                  | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `deepseek-v4-flash`                                                                | ❔ Sin probar (paid)         | Paid.                                                                                                                       |
| `deepseek-v4-flash-vision-exp`                                                     | ❔ Sin probar (paid)         | Paid.                                                                                                                       |
| `glm-5.3-flash`, `-5.3`, `-5.2`, `-5.1`, `-5`                                      | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `minimax-m3`, `-m2.7`, `-m2.5`                                                     | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `kimi-k3`, `-k2.7-code`, `-k2.6`, `-k2.5`                                          | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |
| `qwen3.6-plus`, `-3.5-plus`                                                        | ❌ INSUFFICIENT_BALANCE      | Paid.                                                                                                                       |

**Tasa de utilidad inmediata (cuenta A): 5 free modelos** (big-pickle, mimo-v2.5-free,
ling-3.0-flash-fin-free, nemotron-3-ultra-free, nemotron-3.5-lightning-free), de los cuales:

- 2 están rate-limited en este momento
- 2 son `muse-spark-*` con bug de SDK

## OpenCode Go (`https://opencode.ai/zen/go/v1`) — 35 modelos

⚠️ **Todos los modelos Go son pagos.** No hay free tier. La cuenta tiene
`Monthly usage limit reached` (reset en 19-28 días).

| Modelo              | Estado cuenta A (sep-06)       | Notas                                                                                                                                                                                                                |
| ------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TODOS               | ❌ USAGE_LIMIT (monthly)       | Esperar al reset. Rotar con `oc-keyring switch go B` para probar cuenta B.                                                                                                                                           |
| `kimi-k3`           | ⚠️ PARAM_LEAK (adicional)      | **Bug SDK**: además del usage limit, el AI SDK filtra `provider` y `litellm_settings` que Go rechaza. No se puede usar desde Go. **Workaround**: usar el mismo modelo desde `tokenrouter` (id `moonshotai/kimi-k3`). |
| `deepseek-v4-flash` | ⚠️ OPT_IN_REQUIRED (adicional) | Geo-bloqueado a China. Opt-in manual en `https://opencode.ai/workspace/wrk_01KP8TETMRRZ9WGQ0J7YZ9NVGK/go`.                                                                                                           |

## OpenCode Go (`https://opencode.ai/zen/go/v1`) — 35 modelos (cuenta B)

| Modelo         | Estado (sep-06)          | Notas               |
| -------------- | ------------------------ | ------------------- |
| `gpt-5.6-luna` | ❌ USAGE_LIMIT (monthly) | Igual que cuenta A. |

## Resumen ejecutivo

- ✅ **4/4 providers `opencode-{zen,go}-{A,B}` están healthy** (auth + catálogo).
- ✅ **Auto-discovery funciona** — el catálogo de cada cuenta es accesible.
- ⚠️ **Tasa de uso real en este momento: muy baja** (big-pickle con rate limit, muse-spark con bug,
  todo Go con usage limit).
- 🛠️ **Próximos pasos para aumentar disponibilidad**:
  1. Cargar saldo en la cuenta OpenCode para usar modelos paid.
  2. Rotar a `opencode-zen-B` para probar si tiene saldo free distinto.
  3. Resolver el bug de `muse-spark-*` (opcional, son free tier pero rotos por SDK).
  4. Opt-in manual para `deepseek-v4-flash` si se quiere usar desde Go.
- 🔄 **Rotación entre cuentas** funciona via `oc-keyring switch zen B` / `oc-keyring switch go B`.
- 📋 **El log mantiene el ground truth** de qué modelos generaron errores y por qué. `oc-doctor`
  automatiza la consulta del estado real.

## Decisión recomendada

**Default model: `opencode-zen-A/big-pickle`** (ya configurado). Es el único free model que
consistentemente funciona y la cuota free se resetea diariamente. Para tareas pesadas, rotar a
`opencode-zen-B` (puede tener crédito) o cargar saldo en Go.
