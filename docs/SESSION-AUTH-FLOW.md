# Flujo de Autenticación e Inicio de Sesión

## Visión General

El sistema de sesión y autenticación tiene dos flujos independientes pero complementarios:

1. **Session Autostart** — pipeline de inicialización del workspace
2. **Authentication** — verificación de identidad para operaciones restringidas

---

## 1. Session Autostart Pipeline

### Punto de entrada

- **Manual**: `session-manual-start.cmd` → delega a `wf.ps1 start-session`
- **AutoStart**: `session-autostart.ps1` — pipeline config-driven

### Configuración centralizada

Archivo: `config/session-autostart.config.json`

Cada paso del pipeline tiene:
```json
{
  "id": "step-name",
  "enabled": true/false,
  "script": "ruta/al/script.ps1",
  "args": "argumentos",
  "required": true/false,
  "description": "qué hace"
}
```

Si `required: true` y el paso falla → el pipeline se detiene (`exit 1`).
Si `required: false` y el paso falla → se registra warning y continúa.

### Pasos del Pipeline (11 pasos)

| # | ID | Script | Req | Descripción |
|---|-----|--------|------|-------------|
| 1 | session-manager | session-manager.ps1 | Sí | Inicializa sesión, genera ID, crea archivo `.session/`, limpia sesiones huérfanas |
| 2 | github-bypass | ensure-github-bypass.ps1 | No | Verifica políticas de bypass para el usuario |
| 3 | notifications | session-notification.ps1 | No | Notificaciones de horas pico (9-15hs Argentina GMT-3) |
| 4 | auth-session | auth-session.ps1 | No | Verifica integridad de `owner-auth.json` (deshabilitado por defecto) |
| 5 | engram-policy | engram-policy.ps1 | Sí | Verifica que Engram esté instalado y corriendo |
| 6 | token-budget | token-budget-guard.ps1 | No | Registra inicio de sesión para tracking de tokens |
| 7 | engram-optimization | optimize-engram-usage.ps1 | No | Optimiza uso de memoria Engram |
| 8 | cross-workspace-validation | cross-workspace-validator.ps1 | No | Valida consistencia entre workspaces |
| 9 | security-orchestrator | security-orchestrator.ps1 | Sí | Inicializa seguridad, verifica policy y privacy |
| 10 | skill-router | skill-router.ps1 | No | Verifica router de skills activo |
| 11 | karpathy-guidelines | karpathy-enforcer.ps1 | No | Verifica normas Karpathy |

### Session Manager (detalle)

`session-manager.ps1` soporta 5 modos:

| Modo | Descripción |
|------|------------|
| `AutoStart` | Inicio automático con limpieza de huérfanas |
| `Manual` | Inicio manual con limpieza de huérfanas |
| `Health` | Diagnóstico de sesiones activas |
| `End` | Cierre con validación pre-close y notificación |
| `Cleanup` | Solo limpieza de sesiones huérfanas |

### Limpieza de sesiones huérfanas

- Se ejecuta automáticamente al inicio (`AutoStart`, `Manual`)
- Se ejecuta manualmente con modo `Cleanup`
- Busca sesiones con `status: "active"` mayores a 24 horas
- Las marca como `status: "orphaned"` con motivo
- Archivos corruptos se mueven a `.session/archive/`

---

## 2. Flujo de Autenticación

### Archivos involucrados

| Archivo | Propósito |
|---------|----------|
| `config/owner-auth.json` | API key, preguntas de seguridad (hash SHA256), permisos |
| `config/owner-auth.json.integrity` | Hash SHA256 del archivo auth (validación de integridad) |
| `config/owner-auth.json.lock` | Lockout por intentos fallidos (3 intentos → 15 min) |
| `config/owner-auth.json.enc` | Versión encriptada con DPAPI (Windows) |
| `.workspace/config/session-auth.json` | Sesión autenticada (expira a 8h) |
| `.runtime/security-auth-audit.log` | Log de auditoría de intentos de auth |

### Comando principal

```powershell
# Verificar estado
.\scripts\utilities\auth-session.ps1 -ManageAuth status

# Autenticarse con API key
.\scripts\utilities\auth-session.ps1 -ApiKey "tu-api-key"

# Recuperar con preguntas de seguridad
.\scripts\utilities\auth-session.ps1 -UseSecurityQuestions

# Encriptar owner-auth.json con DPAPI
.\scripts\utilities\auth-session.ps1 -ManageAuth encrypt

# Desencriptar (requiere no estar en lockout)
.\scripts\utilities\auth-session.ps1 -ManageAuth decrypt
```

### Flujo de autenticación (secuencia)

```
1. ¿Sesión ya autenticada? → Sí: exit 0
2. ¿Lockout activo? → Sí: ACCESS DENIED (esperar N minutos)
3. ¿Integridad de owner-auth.json OK? → No: ACCESS DENIED (posible tampering)
4. ¿API key proporcionada?
   ├─ Sí → ¿Key válida?
   │   ├─ Sí → Limpiar lockout, crear session-auth.json (8h), exit 0
   │   └─ No → Registrar intento fallido, ¿3er intento? → Lockout 15min
   └─ No → ¿Preguntas de seguridad?
       ├─ Sí → ¿3/3 correctas?
       │   ├─ Sí → Limpiar lockout, mostrar API key, autenticar sesion
       │   └─ No → Registrar intento, ¿3er intento? → Lockout 15min
       └─ No → Mostrar opciones y exit 1
```

### Integridad (Hash check)

- Al iniciar: se calcula SHA256 de `owner-auth.json` y se compara contra `.integrity`
- Si el archivo fue modificado fuera del sistema → acceso bloqueado
- Comando `Initialize-Integrity` crea/recrea el archivo `.integrity`
- Se recalcula automáticamente al encriptar/desencriptar

### Encriptación DPAPI

- `secure-auth.ps1` usa Windows DPAPI (solo el usuario actual puede desencriptar)
- Flujo de producción: encriptar → borrar archivo plano → usar solo `.enc`
- Flujo de autenticación: desencriptar temporalmente → usar → re-encriptar

### Lockout (Rate limiting)

- 3 intentos fallidos (API key o preguntas) → 15 minutos de bloqueo
- Archivo `owner-auth.json.lock` persiste entre sesiones
- Se limpia automáticamente al autenticar exitosamente
- Se puede limpiar manualmente: `secure-auth.ps1 -Action unlock`

---

## 3. Cierre de Sesión

### Pasos (End-Session)

1. **Norm enforcement** (`auto-norm-enforcer.ps1 -Trigger session-close`)
2. **Norm learning** (`auto-norm-learner.ps1 -Trigger session-close`)
3. **Pre-close validation** (`pre-close-validator.ps1 -AutoResolve`)
   - Si falla → cierre bloqueado (exit 1)
4. **Guardar resumen en Engram**
5. **Actualizar sesión** → `status: "ended"`, `endTime`
6. **Notificar usuario** con opción de recovery
7. **Limpiar session-auth.json** (sesión autenticada)

---

## 4. Cambios Realizados

### Archivos creados

- `config/session-autostart.config.json` — Config centralizada del pipeline

### Archivos modificados

- `scripts/utilities/auth-session.ps1` — Reescrito con:
  - Integración DPAPI (encrypt/decrypt via secure-auth.ps1)
  - Validación de integridad SHA256
  - Rate limiting con lockout
  - Auditoría de intentos (`.runtime/security-auth-audit.log`)
  - Comando `-ManageAuth status|encrypt|decrypt`
  - Flag `-AsJson` para integración con otros scripts

- `scripts/utilities/session-autostart.ps1` — Reescrito como pipeline config-driven:
  - Lee pasos desde `config/session-autostart.config.json`
  - Ejecución dinámica según `enabled` flag
  - Diferencia entre pasos `required` y opcionales
  - Resumen al final con conteo de éxitos/fallos

- `scripts/utilities/session-manager.ps1` — Mejorado con:
  - Limpieza de sesiones huérfanas (new `Cleanup` mode)
  - Marca sesiones >24h como "orphaned"
  - Archivos corruptos → `.session/archive/`
  - Verificación de integridad auth al iniciar sesión
  - Limpieza de session-auth al cerrar sesión
  - Resolución correcta de rutas del repo

---

## 5. Lecciones Aprendidas y Patrones Defensivos

### Pattern: Resolucion robusta de repoRoot

```powershell
# PATRON CORRECTO - buscar config/ como ancla
$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) {
    $env:FOUNDATION_BASE_DIR
} else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) {
        $root = Split-Path -Parent $root
    }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}
```

**NUNCA** usar `"$PSScriptRoot\..\.."` — no resuelve `..` y falla si CWD cambia.

### Pattern: PSCustomObject property assignment

Los objetos de `ConvertFrom-Json` son PSCustomObject. Asignar propiedades nuevas con `$obj.newProp = value` puede fallar si la propiedad no existe.

```powershell
# CORRECTO - Add-Member con -Force
$obj | Add-Member -NotePropertyName 'endTime' -NotePropertyValue $value -Force

# O reconstruir como hashtable
$updated = @{
    existingProp = $obj.existingProp
    newProp = $value
}
$updated | ConvertTo-Json | Set-Content $file
```

### Pattern: Hashtable keys con guiones

```powershell
# INCORRECTO - PowerShell interpreta el guion como resta
$colors = @{ session-close = "Yellow" }

# CORRECTO - comillas siempre en claves con guiones
$colors = @{ 'session-close' = "Yellow" }
```

### Pattern: Encoding y caracteres Unicode

- **NUNCA** usar caracteres Unicode (checkmarks, emoji, acentos) en scripts PowerShell
- Siempre usar ASCII: `[OK]`, `[FAIL]`, `[PASS]` en vez de `U+2713`, `U+274C`, `U+2705`
- Archivos guardados como UTF-8 **sin BOM**

### Pattern: `$ErrorActionPreference`

Todo script PowerShell debe declarar `$ErrorActionPreference` al inicio:

```powershell
$ErrorActionPreference = 'Continue'  # o 'Stop' para criticos
```

### Pattern: Config-driven pipeline con Invoke-Expression

```powershell
# INCORRECTO - .Split(' ') rompe argumentos con espacios/comillas
$result = & $scriptPath $scriptArgs.Split(' ')

# CORRECTO - Invoke-Expression maneja argumentos complejos
$invokeCmd = "& `"$scriptPath`" $scriptArgs"
$result = Invoke-Expression $invokeCmd 2>&1
```

### Pattern: HTTP 403 esperado

```powershell
if ($errorMsg -match 'HTTP 403|403') {
    Write-Info "${repo}: skipped (requires GitHub Pro or public repo)"
} else {
    Write-Warn "${repo}: failed ($errorMsg)"
    $hasFailure = $true
}
```

### Pattern: Paths `.session` consistentes

```powershell
# INCORRECTO - path relativo, se rompe si CWD != repo root
$sessionFile = ".\.session\session-*.json"

# CORRECTO - path absoluto basado en repoRoot
$sessionDir = Join-Path $repoRoot '.session'
$sessionFile = Get-ChildItem (Join-Path $sessionDir 'session-*.json')
```

### Pattern: Karpathy enforcer - validar codebase, no el trigger string

```powershell
# INCORRECTO - validar si "session-start" contiene "think"
Test-ThinkGuideline -Content $Trigger  # siempre falla!

# CORRECTO - validar si la infraestructura del workspace existe
Test-ThinkGuideline  # verifica rules/AI-NORMATIVES.md existe
```