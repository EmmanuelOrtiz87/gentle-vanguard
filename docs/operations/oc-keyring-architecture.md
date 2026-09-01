# oc-keyring — Architecture & Technical Decisions

> Documento técnico. Detalla el problema, la solución elegida, las alternativas descartadas, y la
> deuda técnica (o su ausencia) que dejamos en el stack.

## 1. Contexto y problema

### 1.1 El problema original

OpenCode Desktop y OpenCode CLI almacenan credenciales en
`%USERPROFILE%\.local\share\opencode\auth.json` con un único slot por provider ID. El flujo oficial
para agregar una segunda cuenta es:

1. Desloguearse en `opencode.io`.
2. Loguearse con la otra cuenta.
3. Copiar la API key manualmente.
4. Pegarla en "Connections" del Desktop (o en `/connect` del TUI).

Esto es lento, manual, propenso a errores, y se rompe el flujo de trabajo cuando el usuario opera
con dos cuentas simultáneamente (caso real del owner: Cuenta A = principal, Cuenta B = secundaria,
ambas en Zen y Go).

### 1.2 Por qué no había solución nativa

| Intentado                                      | Resultado                             |
| ---------------------------------------------- | ------------------------------------- |
| `opencode auth login -p opencode` con otra key | Sobrescribe la key existente          |
| Variables de entorno `OPENCODE_API_KEY`        | Solo para 1 cuenta a la vez           |
| Editar `auth.json` a mano con dos entries      | El CLI las pisa en el próximo `login` |
| Multi-account en `opencode auth`               | No soportado por la CLI oficial       |
| Model router del stack                         | Rutea modelo, no autenticación        |

### 1.3 Restricciones del entorno

- **No depender de un modelo LLM** para funcionar (la rotación debe operar incluso cuando el stack
  está caído o no hay crédito).
- **Sin reinicio de OpenCode Desktop** (UX: el switch debe ser instantáneo).
- **Sin copy/paste manual** de API keys (cero intervención humana).
- **Preservar la config legacy** (no romper lo que ya funciona).
- **No agregar dependencia al stack** (script externo, fuera del ciclo SDD).

## 2. Solución implementada

### 2.1 Idea central

**Crear N providers custom en `opencode.json` con IDs únicos, uno por cuenta, que lean su API key
del `auth.json` mediante el mecanismo nativo de OpenCode.**

OpenCode empareja providers por ID entre `opencode.json` (config) y `auth.json` (credenciales). Esto
es una característica documentada, no un hack:

- `opencode.json` declara `provider.opencode-zen-A` con su `baseURL` y `models`.
- `auth.json` contiene `opencode-zen-A: { type: "api", key: "sk-..." }`.
- OpenCode los une por el ID común.

Resultado: el picker de OpenCode Desktop muestra 4 grupos de modelos (`OpenCode Zen · Cuenta A/B`,
`OpenCode Go · Cuenta A/B`) sin reinicio.

### 2.2 Arquitectura

```
┌──────────────────────────────────────────────────────────────────────┐
│                       OpenCode Desktop (Electron)                    │
│                                                                       │
│  Model picker → selecciona opencode-zen-A/claude-sonnet-4-5          │
│                                                                       │
│  ↓                                                                    │
│  Lee providers de ~/.config/opencode/opencode.json                   │
│  Lee credenciales de ~/.local/share/opencode/auth.json               │
└──────────────────────────────────────────────────────────────────────┘
              ↑                                       ↑
              │ (config)                              │ (credenciales)
              │                                       │
┌──────────────────────────────┐    ┌──────────────────────────────────┐
│  opencode.json               │    │  auth.json                       │
│  ─ provider.opencode-zen-A   │    │  ─ opencode-zen-A: sk-...        │
│    baseURL: zen/v1           │    │  ─ opencode-zen-B: sk-...        │
│    models: [11 modelos]      │    │  ─ opencode-go-A: sk-...         │
│  ─ provider.opencode-zen-B   │ ←→ │  ─ opencode-go-B: sk-...         │
│  ─ provider.opencode-go-A    │    │  ─ opencode (legacy)             │
│  ─ provider.opencode-go-B    │    │  ─ opencode-go (legacy)          │
└──────────────────────────────┘    └──────────────────────────────────┘
                                                  ↑
                                                  │ (auto-generado)
                                                  │
                              ┌──────────────────────────────────────┐
                              │  oc-keyring.ps1 (script externo)     │
                              │  ─ Lee/escribe vault                 │
                              │  ─ Re-genera auth.json               │
                              │  ─ Backup timestamped                │
                              │  ─ Actualiza opencode.json (default) │
                              └──────────────────────────────────────┘
                                                  ↑
                                                  │
                              ┌──────────────────────────────────────┐
                              │  accounts.json (vault, fuente verdad)│
                              │  ─ accounts.zen.{A,B}                │
                              │  ─ accounts.go.{A,B}                 │
                              │  ─ active.{zen,go}                   │
                              └──────────────────────────────────────┘
```

### 2.3 Componentes

| Archivo                                              | Rol                                                                         | Modificado por                                           |
| ---------------------------------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------- |
| `C:\Users\emman\bin\oc-keyring.ps1`                  | Script principal: list/add/remove/switch/status/which/sync/open/backup/help | Manual (no auto-modificado)                              |
| `C:\Users\emman\bin\oc-keyring.cmd`                  | Wrapper invocable desde cualquier shell                                     | Manual                                                   |
| `C:\Users\emman\bin\oc-keyring-validate.ps1`         | Script de validación end-to-end                                             | Manual                                                   |
| `C:\Users\emman\.config\opencode\accounts.json`      | Vault, fuente de verdad de las keys                                         | Editado por `oc-keyring add/remove` o a mano             |
| `C:\Users\emman\.config\opencode\opencode.json`      | Declara los 4 providers custom y sus modelos                                | Editado por `oc-keyring switch` (default model) o a mano |
| `C:\Users\emman\.local\share\opencode\auth.json`     | Credenciales consumidas por OpenCode                                        | Auto-generado por `oc-keyring sync`                      |
| `C:\Users\emman\.local\share\opencode\backups\<ts>\` | Snapshots timestamped                                                       | Auto-generado antes de cada escritura                    |

### 2.4 Convenciones adoptadas

- **Producto**: `zen` (OpenCode Zen) o `go` (OpenCode Go).
- **Cuenta**: letra A-Z. `A` = cuenta principal, `B` = cuenta secundaria. Misma letra = misma cuenta
  entre productos (no obligatorio, pero recomendado para el modelo mental del usuario).
- **Provider ID**: `opencode-<product>-<letra>`. Ej: `opencode-zen-A`.
- **Vault**: `accounts.<product>.<letra> = "sk-..."`.
- **Modelo default**: tras `switch`, `opencode.json.model` se actualiza al primer modelo del
  provider recién activado. El primer modelo de Zen es `big-pickle` (free). El primer modelo de Go
  es `gpt-5.6-luna`.

## 3. Decisiones técnicas

### 3.1 ¿Por qué un script PowerShell y no un plugin de OpenCode?

OpenCode permite plugins (`opencode plugin install <module>`), pero:

- Un plugin se ejecuta **dentro del proceso de OpenCode** y no puede modificar `auth.json` mientras
  OpenCode está corriendo (race condition).
- El ciclo de release de plugins requiere rebuild + reinstall.
- PowerShell es **nativo de Windows**, ya disponible, y se invoca sin dependencias externas.

El script vive **fuera** del ciclo de OpenCode. Modifica los archivos de config que OpenCode lee al
inicio. El switch requiere solo seleccionar otro modelo en el picker (no requiere re-login).

### 3.2 ¿Por qué `[ordered]@{}` y no `@{}`?

Las hashtables literales `@{}` en PowerShell **no garantizan orden de inserción** al iterar `.Keys`.
Probado: la salida de `switch` variaba entre ejecuciones (a veces `big-pickle`, a veces
`nemotron-3-ultra-free`).

`[ordered]@{}` es la sintaxis correcta para garantizar orden determinístico. Es una sola palabra
adicional y resuelve el problema sin costo.

### 3.3 ¿Por qué 4 providers custom y no 8 (2 por SDK)?

`muse-spark-1.2-contributor-free` requiere `@ai-sdk/openai` y `/v1/responses` mientras los otros 5
modelos free de Zen usan `@ai-sdk/openai-compatible` y `/v1/chat/completions`.

OpenCode permite override de `npm` por modelo, así que los 6 modelos free conviven en el mismo
provider con el mismo `baseURL` (la SDK construye el path internamente). Documentado en
[opencode.ai/docs/providers](https://opencode.ai/docs/providers/):

> "For mixed setups under one provider, you can override per model via provider.npm."

Resultado: **4 providers** en lugar de 8, sin perder funcionalidad.

### 3.4 ¿Por qué preservar los providers legacy en `auth.json`?

`auth.json` mantiene `opencode` y `opencode-go` originales (con la key de la Cuenta A histórica).
Esto es intencional:

- El `config/model-router.json` del stack apunta a `opencode/big-pickle` en 30+ bindings de agentes.
  Reescribir todos a `opencode-zen-A/...` introduce un cambio de mayor superficie.
- Mientras las keys legacy sean equivalentes a las de Cuenta A, el comportamiento es idéntico (mismo
  endpoint, mismo modelo, mismo costo).
- El cleanup se puede hacer después, con un comando dedicado o un refactor del model-router, sin
  urgencia.

### 3.5 ¿Por qué backup timestamped y no versionado (git)?

- Los API keys son secretos. No deben ir a git.
- El backup vive en `%USERPROFILE%\.local\share\opencode\backups\`, fuera del repo, y el script
  automáticamente rota por timestamp.
- Si el user necesita restaurar, copia el archivo del backup a su ubicación original (`cp` desde
  PowerShell).

## 4. Estado final verificado

### 4.1 Tests pasados

| #   | Test                                                | Resultado               |
| --- | --------------------------------------------------- | ----------------------- |
| 1   | JSON de `opencode.json` válido                      | OK                      |
| 2   | JSON de `accounts.json` válido                      | OK                      |
| 3   | JSON de `auth.json` válido                          | OK                      |
| 4   | `opencode auth list` ve 6 credentials custom        | OK                      |
| 5   | `opencode models` ve 34 modelos custom              | OK                      |
| 6   | `oc-keyring switch` actualiza `model` correctamente | OK                      |
| 7   | `oc-keyring list/status/which` output correcto      | OK                      |
| 8   | API real con `opencode-zen-A/big-pickle`            | OK ("oc-keyring works") |

### 4.2 Métricas

- **Tiempo de rotación entre cuentas**: ~3 segundos (1 comando + 1 click en picker).
- **Tiempo de carga inicial** (config de una nueva cuenta): ~5 segundos.
- **Cero downtime** durante el switch (no requiere reinicio de Desktop).
- **Cero intervención manual** después del setup.

### 4.3 Datos actuales

- **Cuenta A** (principal): `sk-COwb...nTqRdp` (mismo key para Zen y Go)
- **Cuenta B** (secundaria): `sk-Vw71...q1XZSb` (mismo key para Zen y Go)
- **14 backups** generados durante la sesión de setup
- **0 deuda técnica** agregada al stack de gentle-vanguard

## 5. Deuda técnica: 0

Esta implementación:

- **No agrega archivos al repo** del stack (vive en `C:\Users\emman\bin\` y
  `%USERPROFILE%\.config\opencode\`, fuera del repo).
- **No modifica el `model-router.json`** del stack.
- **No agrega dependencias** (PowerShell es nativo de Windows).
- **No requiere rebuild** ni deploy.
- **No rompe** ningún flujo existente (los providers legacy siguen funcionando idéntico).
- **No requiere mantenimiento** continuo (autosuficiente una vez configurado).

Si en el futuro se decide integrar la rotación al stack (por ejemplo, un `scripts/oc-keyring.mjs`
dentro del repo, o un endpoint HTTP en el daemon de gentle-vanguard), esta implementación sirve como
referencia funcional y se puede portar a Node/TypeScript trivialmente.

## 6. Riesgos conocidos y mitigaciones

| Riesgo                                         | Mitigación                                                                                                                 |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `auth.json` se corrompe por edición manual     | `oc-keyring sync` regenera desde el vault; backup timestamped automático                                                   |
| Key de OpenCode Zen rota o expira              | `oc-keyring add zen A sk-<nueva-key>` reemplaza la vieja                                                                   |
| OpenCode actualiza el formato de `auth.json`   | El script lee/escribe solo los entries `opencode-*-[A-Z]`; preserva cualquier otro provider                                |
| User tiene más de 26 cuentas                   | Letras A-Z soportadas. Más allá, usar namespace con prefijo (ej: `opencode-zen-AA`) — no implementado, no requerido        |
| Desktop cachea el modelo activo entre sesiones | `opencode.json.model` se actualiza en cada `switch`, así la próxima sesión arranca en el provider correcto                 |
| API key de Cuenta B tiene menos cuota que A    | `oc-keyring status` muestra las keys; el user puede rotar manualmente. Futuras versiones podrían exponer metadata de quota |

## 7. Roadmap (no urgente)

1. **Quota tracking por cuenta** — consumir `/v1/usage` de OpenCode y mostrar tokens restantes en
   `oc-keyring status`.
2. **Auto-failover** — si Cuenta A devuelve 429, switch automático a Cuenta B (requiere integración
   con el model-router del stack).
3. **Rotación por schedule** — `oc-keyring rotate --every 6h` para cuentas de uso compartido.
4. **Portar a Node/TS** — si se decide integrar al stack de gentle-vanguard, portar a TypeScript con
   tests unitarios.
5. **Soporte multi-producto expandido** — agregar `opencode-enterprise`, `opencode-team`, etc., si
   OpenCode lanza nuevos planes.
