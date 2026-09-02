# oc-keyring — Multi-cuenta OpenCode Zen & Go

Gestor de API keys para **OpenCode Zen** y **OpenCode Go** que permite rotar entre múltiples cuentas
sin re-login manual en opencode.io y sin reiniciar OpenCode Desktop.

## Por qué existe

OpenCode Desktop guarda credenciales en `~/.local/share/opencode/auth.json` con un solo slot por
provider (`opencode`, `opencode-go`). Para cambiar de cuenta había que: desloguearse en opencode.io
→ loguearse con la otra → copiar la key → pegarla en el picker de conexiones del Desktop.

**oc-keyring** resuelve esto declarando providers custom por cuenta en `opencode.json` y manteniendo
múltiples API keys en un vault local. La rotación pasa por elegir otro modelo del picker — sin
copy/paste, sin reinicio.

## Instalación (ya quedó instalado)

| Archivo                                                     | Función                                 |
| ----------------------------------------------------------- | --------------------------------------- |
| `C:\Users\emman\bin\oc-keyring.cmd`                         | Wrapper invocable desde cualquier shell |
| `C:\Users\emman\bin\oc-keyring.ps1`                         | Script PowerShell principal             |
| `C:\Users\emman\.config\opencode\accounts.json`             | Vault de cuentas (sources of truth)     |
| `C:\Users\emman\.config\opencode\opencode.json`             | Config con 4 providers custom           |
| `C:\Users\emman\.local\share\opencode\auth.json`            | Auto-generado desde el vault            |
| `C:\Users\emman\.local\share\opencode\backups\<timestamp>\` | Backups automáticos de cada cambio      |

## Uso

### Ver cuentas configuradas

```powershell
oc-keyring list
oc-keyring status     # vault + auth.json + active
oc-keyring which      # solo la cuenta activa
```

### Agregar Cuenta B (Zen o Go)

```powershell
oc-keyring add zen B sk-Vw71cfP9uRFVwNRj3mj1t3u6dHjjSIRUXMD5ice00Z28hLBTBQKyRIaKp9q1XZSb
oc-keyring add go  B sk-Abc123ExampleKeyForOtherAccount...XYZ
```

- Letra `A-Z` (case-insensitive). Misma letra = misma cuenta entre zen y go.
- `add` valida formato mínimo (>= 20 chars).
- `add` automáticamente re-sincroniza `auth.json` y crea backup.

### Cambiar la cuenta activa (afecta el default model de `opencode.json`)

```powershell
oc-keyring switch zen B     # ahora "Cuenta B" es la activa para Zen
oc-keyring switch go  A     # vuelve a Cuenta A para Go
```

Después de `switch`, abrí OpenCode Desktop y elegí cualquier modelo del nuevo provider desde el
picker. No requiere reinicio.

### Quitar una cuenta

```powershell
oc-keyring remove zen B              # pide confirmación
oc-keyring remove zen B -Force       # sin confirmación (para scripts)
```

### Re-sincronizar auth.json desde el vault

```powershell
oc-keyring sync
```

Útil si editaste el vault a mano con `oc-keyring open`.

### Backup manual

```powershell
oc-keyring backup
```

Crea snapshot timestamped de `auth.json` + `opencode.json` + `accounts.json`.

### Editar el vault directamente

```powershell
oc-keyring open    # abre accounts.json en el editor default
```

## Estructura del vault (`accounts.json`)

```json
{
  "version": 1,
  "accounts": {
    "zen": { "A": "sk-...", "B": "sk-..." },
    "go": { "A": "sk-...", "B": "sk-..." }
  },
  "active": { "zen": "A", "go": "A" }
}
```

## Cómo se ve en OpenCode Desktop

Después de configurar, el picker de modelos muestra **4 grupos nuevos**:

| Provider ID          | Nombre en picker        | Modelos                                      |
| -------------------- | ----------------------- | -------------------------------------------- |
| `opencode-zen-A/<m>` | OpenCode Zen · Cuenta A | big-pickle, claude-sonnet-4-5, opus-4-7, ... |
| `opencode-zen-B/<m>` | OpenCode Zen · Cuenta B | (mismos)                                     |
| `opencode-go-A/<m>`  | OpenCode Go · Cuenta A  | gpt-5.6-luna, minimax-m3, kimi-k3, ...       |
| `opencode-go-B/<m>`  | OpenCode Go · Cuenta B  | (mismos)                                     |

Elegir otro = cambiar de cuenta. Instantáneo, sin copy/paste, sin reinicio.

## Modelo default

`opencode.json` tiene `"model": "opencode-zen-A/big-pickle"` por default. Cuando ejecutás
`oc-keyring switch <zen|go> <letra>`, ese campo se actualiza al primer modelo del provider recién
activado, así la próxima sesión de OpenCode arranca directo en la cuenta correcta.

## Compatibilidad

- **OpenCode CLI** (`opencode auth list`, `opencode models`) ✓
- **OpenCode Desktop** (Electron) ✓ — lee el mismo `auth.json`
- **TUI** (`/connect`, `/models`) ✓

Los providers legacy `opencode` y `opencode-go` quedan intactos en `auth.json` — no se rompe ningún
flujo anterior. Si querés limpiar, podés removerlos con la interfaz de OpenCode Desktop o editando
`auth.json` directamente.

## Seguridad

- Las keys se guardan en texto plano en `auth.json` (mismo formato que OpenCode usa nativamente). Si
  necesitás keyring del sistema operativo, OpenCode tiene un feature request abierto
  [#4318](https://github.com/anomalyco/opencode/issues/4318).
- El vault está en `~/.config/opencode/accounts.json` — fuera de los backups automáticos de
  OpenCode, accesible solo al usuario.
- Cada cambio crea un backup timestamped en `~/.local/share/opencode/backups/`.

## Troubleshooting

| Problema                                                  | Solución                                                          |
| --------------------------------------------------------- | ----------------------------------------------------------------- |
| El provider no aparece en el picker                       | Cerrar y reabrir el proyecto en OpenCode Desktop                  |
| `Confirm-Action` falla con "NonInteractive mode"          | Usar `-Force` o setear `OC_KEYRING_FORCE=1`                       |
| `auth.json` se desincronizó                               | `oc-keyring sync`                                                 |
| Olvidé qué cuenta está activa                             | `oc-keyring which` o `oc-keyring status`                          |
| Necesito un provider custom con más modelos               | Editar `opencode.json` y agregar entries a `provider.<id>.models` |
| Quiero volver al flujo original (1 sola key por provider) | Usar `opencode auth login -p opencode` directamente               |
