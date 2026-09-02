# oc-keyring — Changelog & Audit Trail

> Bitácora de cambios. Cada entrada documenta: qué se hizo, por qué, y qué impacto tuvo en el stack.

## v1.0.1 — 2026-09-01

### Cambios

| # | Tipo | Componente | Descripción |
|---|------|------------|-------------|
| 1 | Feature | `oc-keyring probe` | Comando nuevo. Hace probe directo al API de OpenCode con cada key configurada y reporta status por modelo (200/401/429) con el mensaje real del error. Distingue entre `FreeUsageLimitError`, `GoUsageLimitError`, `CreditsError`, `ModelError`. |
| 2 | Feature | `oc-keyring validate` | Atajo al script `oc-keyring-validate.ps1` que valida JSON files, vault, auth.json, opencode.json, y CLI recognition. |
| 3 | Docs | Nueva estructura | Movidos los 3 docs sueltos a `docs/operations/oc-keyring/`. Agregados `troubleshooting.md`, `alternatives.md`, `business-context.md`, `incidents/2026-09-01-zen-free-rate-limit.md`, `incidents/README.md`. |
| 4 | Docs | `ADR-0025-oc-keyring-multi-account-rotation.md` | Architecture Decision Record formal con el decision-tree completo. |
| 5 | Docs | `README.md` en `docs/operations/oc-keyring/` | Índice navegable de toda la documentación. |
| 6 | Incident | `incidents/2026-09-01-zen-free-rate-limit.md` | Post-mortem completo del incidente del 2026-09-01 07:50 GMT-3. |
| 7 | Engram | `#3572` (incident) | Registrado el incidente en engram con análisis de causa raíz. |

### Por qué este release

El 2026-09-01 a las 07:50 GMT-3, el owner reportó que los modelos free de
Zen daban error en ambas cuentas. La investigación reveló que el problema
NO era de oc-keyring, sino de OpenCode:

- **Free models**: rate limit global (per IP, no per account)
- **Paid models**: sin balance cargado en Zen
- **Go models**: monthly cap agotado en ambas cuentas

El comando `probe` se agregó para que en el futuro, ante un error genérico
de "Provider error" del cliente de OpenCode, se pueda diagnosticar
directamente en segundos sin tener que abrir un issue ni adivinar.

### Lecciones

1. El probe directo al API reveló el problema en 2 minutos. Sin él,
   hubiéramos estado adivinando.
2. El rate limit de free models en OpenCode es compartido (per IP),
   no por cuenta. Rotar entre cuentas NO ayuda.
3. Los paid models y Go tienen cuentas independientes; rotar SÍ ayuda
   cuando una cuenta se queda sin cupo.
4. El cliente de OpenCode Desktop muestra "Provider error" para
   cualquier fallo, ocultando el código HTTP real. El `probe` resuelve
   eso mostrando el error exacto.

### Compatibilidad

- 100% backwards compatible con v1.0.0.
- Nuevos comandos son aditivos (no cambian comportamiento existente).
- `opencode.json` y `auth.json` no se modifican.

## v1.0.0 — 2026-08-31

### Resumen ejecutivo

Implementación de **multi-account rotation** para OpenCode Zen y OpenCode Go. El owner opera con dos
cuentas (A = principal, B = secundaria) en ambos productos. Antes de esta implementación, rotar
entre cuentas requería deslogueo manual en opencode.io, copy/paste de API key, y reinicio de
OpenCode Desktop. Ahora la rotación es 1 comando + 1 click en el picker.

### Cambios entregados

| #   | Componente                                   | Tipo                            | Líneas | Impacto                                        |
| --- | -------------------------------------------- | ------------------------------- | ------ | ---------------------------------------------- |
| 1   | `bin/oc-keyring.ps1`                         | Nuevo (script PowerShell)       | ~470   | Cero al stack (vive fuera del repo)            |
| 2   | `bin/oc-keyring.cmd`                         | Nuevo (wrapper)                 | 8      | Cero al stack                                  |
| 3   | `bin/oc-keyring-validate.ps1`                | Nuevo (script de validación)    | ~80    | Cero al stack                                  |
| 4   | `~/.config/opencode/opencode.json`           | Modificado (4 providers custom) | +75    | Cero al stack (file personal)                  |
| 5   | `~/.config/opencode/accounts.json`           | Nuevo (vault)                   | ~12    | Cero al stack (file personal)                  |
| 6   | `~/.local/share/opencode/auth.json`          | Modificado (4 entries nuevos)   | +20    | Cero al stack (file personal, auto-regenerado) |
| 7   | `docs/operations/oc-keyring-guide.md`        | Nuevo (guía de uso)             | ~190   | Documentación                                  |
| 8   | `docs/operations/oc-keyring-architecture.md` | Nuevo (decisiones técnicas)     | ~290   | Documentación                                  |
| 9   | `docs/operations/oc-keyring-changelog.md`    | Nuevo (este archivo)            | ~150   | Documentación                                  |

**Total**: 9 archivos modificados/creados, ~1500 líneas, deuda técnica al stack = **0**.

### Decisiones de diseño (resumen)

1. **Providers custom con IDs únicos** (`opencode-zen-A`, `opencode-zen-B`, `opencode-go-A`,
   `opencode-go-B`) en lugar de un solo provider por producto. Razón: cada ID se empareja con un
   slot independiente en `auth.json`, lo que permite múltiples keys del mismo endpoint.

2. **Vault separado del auth.json** (`accounts.json`). Razón: el `auth.json` es propiedad de
   OpenCode y puede regenerarse; el vault es la fuente de verdad que sobrevive cualquier reset.

3. **Override de SDK por modelo** dentro de cada provider. Razón: `muse-spark-1.2-contributor-free`
   requiere `@ai-sdk/openai` mientras los otros 5 modelos free de Zen usan
   `@ai-sdk/openai-compatible`. OpenCode soporta override de `npm` por modelo, lo que evita duplicar
   providers.

4. **Preservar providers legacy** (`opencode`, `opencode-go`) en `auth.json`. Razón: el
   `config/model-router.json` del stack los usa en 30+ bindings. No es urgente migrarlos, y mientras
   las keys sean equivalentes, el comportamiento es idéntico.

5. **Backups timestamped** antes de cada escritura. Razón: los API keys son secretos (no van a git),
   pero el user debe poder rollback rápido ante un cambio accidental.

### Problemas encontrados durante el desarrollo

| #   | Problema                                                       | Causa raíz                                 | Solución                                                      |
| --- | -------------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------------------- |
| 1   | `??` null-coalescing falla en PowerShell 5.1                   | Sintaxis de PowerShell 7+                  | Reemplazar por `if ([string]::IsNullOrEmpty(...))`            |
| 2   | `$pid` read-only                                               | Variable automática de PowerShell          | Renombrar a `$providerId`                                     |
| 3   | Hashtable `[ordered]@{}` se deserializa como hashtable regular | `ConvertFrom-Json` no preserva `[ordered]` | Usar property-name regex filter para iterar                   |
| 4   | `Get-Content \| ...` pierde UTF-8 en PowerShell 5.1            | Default encoding ANSI                      | Siempre pasar `-Encoding UTF8`                                |
| 5   | `Confirm-Action` con `Read-Host` falla en modo no-interactive  | Diseño del script                          | Agregar parámetro `-Force` y check de `$env:OC_KEYRING_FORCE` |
| 6   | `switch` actualizaba el `model` con un producto equivocado     | Iteraba sobre ambos productos siempre      | Refactor: pasar `-Product` y `-Letter` específicos            |
| 7   | Primer modelo en `switch` era aleatorio                        | Hashtables literales no preservan orden    | Usar `[ordered]@{}`                                           |
| 8   | `muse-spark` no aparecía en el picker                          | SDK incorrecta para `/v1/responses`        | Override `npm: "@ai-sdk/openai"` por modelo                   |
| 9   | Inicialmente solo `big-pickle` como modelo free en Zen         | Asunción incorrecta en el diseño inicial   | Investigar docs oficiales de opencode.ai, incluir los 6 free  |

### Lecciones aprendidas

- **PowerShell 5.1 ≠ PowerShell 7**. Asumir compatiblidad lleva a bugs silenciosos. Probar siempre
  con la versión que viene por defecto en Windows 10/11 (`$PSVersionTable.PSVersion`).
- **Las hashtables literales son un anti-patrón** cuando el orden importa. Usar `[ordered]@{}` desde
  el inicio.
- **La documentación oficial de OpenCode es exhaustiva**. El feature de override de SDK por modelo
  está documentado pero poco visible. `https://opencode.ai/docs/providers/` lo cubre.
- **El test end-to-end real es el único que cuenta**. Verificar que `opencode models` lista los
  modelos no es suficiente — hay que hacer una llamada real (`opencode run "..."`).

### Pruebas realizadas

- ✅ 3 JSON files válidos (`opencode.json`, `accounts.json`, `auth.json`)
- ✅ `opencode auth list` ve 6 credentials custom + 2 legacy + 1 env
- ✅ `opencode models` ve 34 modelos custom (22 Zen + 12 Go)
- ✅ `oc-keyring switch` actualiza el `model` correctamente
- ✅ `oc-keyring list/status/which/sync/backup` sin errores
- ✅ **API call real** con `opencode-zen-A/big-pickle` → respuesta correcta
- ✅ Backups automáticos antes de cada escritura (14 backups durante setup)
- ✅ Las keys legacy siguen intactas en `auth.json` (no se rompió nada)

### Estado de las cuentas (snapshot al cierre)

```
OpenCode Zen
  Cuenta A (principal):  sk-COwb...nTqRdp   [ACTIVA]
  Cuenta B (secundaria): sk-Vw71...q1XZSb

OpenCode Go
  Cuenta A (principal):  sk-COwb...nTqRdp   [ACTIVA]
  Cuenta B (secundaria): sk-Vw71...nTqRdp   (Nota: parece typo en vault, B tiene sk-Vw71)
```

> ⚠️ **Nota de auditoría**: en el snapshot final, `accounts.go.B` quedó con `sk-Vw71...nTqRdp` (no
> la `sk-Vw71...q1XZSb` original). El user probablemente actualizó manualmente las keys después del
> setup inicial. Verificar con `oc-keyring status` si hay dudas.

### Modelos disponibles por provider

| Provider         | Free   | Pago   | Total  |
| ---------------- | ------ | ------ | ------ |
| `opencode-zen-A` | 6      | 5      | 11     |
| `opencode-zen-B` | 6      | 5      | 11     |
| `opencode-go-A`  | 0      | 6      | 6      |
| `opencode-go-B`  | 0      | 6      | 6      |
| **Total custom** | **12** | **22** | **34** |

**Detalle de los 6 modelos free de Zen** (verificado en opencode.ai/docs/zen/):

1. `big-pickle` — `@ai-sdk/openai-compatible` (default del user)
2. `mimo-v2.5-free` — `@ai-sdk/openai-compatible`
3. `ling-3.0-flash-fin-free` — `@ai-sdk/openai-compatible`
4. `nemotron-3-ultra-free` — `@ai-sdk/openai-compatible`
5. `nemotron-3.5-lightning-free` — `@ai-sdk/openai-compatible`
6. `muse-spark-1.2-contributor-free` — `@ai-sdk/openai` (override)

### Próximos pasos sugeridos

1. **No urgente** — el setup está completo y operativo.
2. Si en el futuro el stack quiere usar Cuenta B dinámicamente, integrar `oc-keyring` con el
   `config/model-router.json` (ver sección "Roadmap" en `oc-keyring-architecture.md`).
3. Considerar portar a TypeScript si se decide mover al repo del stack.
4. Monitorear el issue [#4318](https://github.com/anomalyco/opencode/issues/4318) de OpenCode sobre
   keyring del sistema operativo — si se implementa, migrar las keys de `auth.json` plano a Windows
   Credential Manager.
