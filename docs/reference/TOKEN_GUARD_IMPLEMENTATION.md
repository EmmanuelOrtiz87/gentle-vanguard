# Token Guard - Protección Automática contra Overflow de Tokens

## Resumen Ejecutivo

Se ha implementado un sistema completo de **Token Overflow Protection** que se ejecuta automáticamente desde el inicio de sesión. El sistema monitorea el consumo de tokens y toma acciones preventivas cuando se aproxima al límite presupuestado.

## Características Implementadas

### 1. ✅ Token Guard Automático
- **Script**: `tools/token-guard.ps1`
- **Configuración**: `tools/token-guard-config.json`
- **Estado**: `.session/token-guard-state.json`
- Se inicializa automáticamente al ejecutar `tools/session-autostart.cmd`
- Monitorea tokens en tiempo real

### 2. ✅ Pausar Dispatch por Presupuesto
- Pausa automática cuando se alcanza el 95% del presupuesto
- Función: `Pause-Dispatch`
- Registra razón de pausa en archivo de estado
- Permite reanudar con `Resume-Dispatch`

### 3. ✅ Fragmentación en Múltiples Rounds
- Presupuesto dividido en 5 rounds de 25,600 tokens cada uno
- Función: `Initialize-RoundFragmentation`
- Estrategia: round-robin
- Reinicio automático al completar rounds
- Tracking de rounds completados

### 4. ✅ Alertas Automáticas
- Alerta a 80% del presupuesto (WARNING)
- Alerta a 90% del presupuesto (WARNING)
- Alerta a 95% del presupuesto (CRITICAL)
- Pausa automática a 95%
- Notificaciones en consola con colores

## Arquitectura

### Componentes Principales

```
Token Guard System
├── tools/token-guard.ps1 (Motor principal)
├── tools/token-guard-config.json (Configuración)
├── tools/session-autostart.cmd (Integración)
├── tools/session-autostart.config.json (Config de sesión)
└── .session/token-guard-state.json (Estado en tiempo real)
```

### Flujo de Inicialización

```
session-autostart.cmd
    ↓
Optimización de Engram
    ↓
Validación cross-workspace
    ↓
Inicialización de sesión
    ↓
[NUEVO] Inicialización de Token Guard
    ├─ Cargar configuración
    ├─ Crear archivo de estado
    ├─ Inicializar monitoreo
    └─ Mostrar parámetros
    ↓
Inicialización de orquestador
```

## Configuración

### Presupuesto de Tokens

```json
{
  "tokenBudget": 128000,           // Presupuesto total
  "alertThreshold": 0.80,          // Alerta a 80%
  "pauseThreshold": 0.95,          // Pausa a 95%
  "maxRounds": 5,                  // Máximo de rounds
  "roundTokenBudget": 25600        // Tokens por round
}
```

### Umbrales de Alerta

| Umbral | Acción | Tipo |
|--------|--------|------|
| 80% | Alerta WARNING | Notificación |
| 90% | Alerta WARNING | Notificación |
| 95% | Alerta CRITICAL + PAUSA | Pausa de dispatch |

## Funciones Disponibles

### Monitoreo

```powershell
# Inicializar Token Guard
Initialize-TokenGuard -Config $config -SessionId "session-2026-04-23-15"

# Obtener estado actual
Get-TokenGuardState -StateFile ".\.session\token-guard-state.json"

# Verificar umbral
Check-TokenThreshold -CurrentTokens 102400 -BudgetTokens 128000 `
  -AlertThreshold 0.80 -PauseThreshold 0.95
```

### Control de Dispatch

```powershell
# Pausar dispatch
Pause-Dispatch -StateFile ".\.session\token-guard-state.json" `
  -Reason "Presupuesto de tokens excedido (80%)"

# Reanudar dispatch
Resume-Dispatch -StateFile ".\.session\token-guard-state.json"

# Verificar si está pausado
Is-DispatchPaused -StateFile ".\.session\token-guard-state.json"
```

### Fragmentación

```powershell
# Inicializar fragmentación
Initialize-RoundFragmentation -Config $config `
  -StateFile ".\.session\token-guard-state.json"

# Completar round
Complete-Round -StateFile ".\.session\token-guard-state.json" `
  -TokensUsedInRound 20000
```

### Reportes

```powershell
# Generar reporte
Generate-TokenReport -StateFile ".\.session\token-guard-state.json" `
  -LogPath ".\.session\token-guard.log" -Config $config
```

## Modos de Operación

### Monitor Mode (Predeterminado)
```powershell
.\tools\token-guard.ps1 -ConfigPath "tools/token-guard-config.json" `
  -SessionId "session-2026-04-23-15" -Mode "monitor"
```
- Inicializa Token Guard
- Crea archivo de estado
- Muestra parámetros de configuración

### Enforce Mode
```powershell
.\tools\token-guard.ps1 -ConfigPath "tools/token-guard-config.json" `
  -SessionId "session-2026-04-23-15" -Mode "enforce"
```
- Valida tokens actuales
- Dispara alertas si es necesario
- Pausa dispatch si se excede

### Report Mode
```powershell
.\tools\token-guard.ps1 -ConfigPath "tools/token-guard-config.json" `
  -SessionId "session-2026-04-23-15" -Mode "report"
```
- Genera reporte detallado
- Muestra consumo de tokens
- Muestra estado de fragmentación

## Archivo de Estado

El archivo `.session/token-guard-state.json` contiene:

```json
{
  "initialized": "2026-04-23 11:21:13",
  "sessionId": "session-2026-04-23-15",
  "status": "READY",
  "totalTokensUsed": 0,
  "roundsCompleted": 0,
  "currentRound": 1,
  "alertsTriggered": 0,
  "dispatchPaused": false,
  "fragmentationActive": false
}
```

## Integración con Session Autostart

El Token Guard se integra automáticamente en `tools/session-autostart.cmd`:

```batch
REM Extraer SessionId del archivo de sesión
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "..."') do set SESSION_ID=%%i

REM Inicializar Token Guard para protección de tokens
echo [INFO] Initializing Token Guard...
if exist "%TOKEN_GUARD_SCRIPT%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%TOKEN_GUARD_SCRIPT%" `
    -ConfigPath "tools/token-guard-config.json" `
    -SessionId "%SESSION_ID%" -Mode "monitor"
)
```

## Configuración de Sesión

El `tools/session-autostart.config.json` incluye la sección de Token Guard:

```json
{
  "tokenGuard": {
    "enabled": true,
    "autoStart": true,
    "configPath": "tools/token-guard-config.json",
    "tokenBudget": 128000,
    "alertThreshold": 0.80,
    "pauseThreshold": 0.95,
    "maxRounds": 5,
    "roundTokenBudget": 25600,
    "enableFragmentation": true,
    "enableAutoDispatchPause": true,
    "enableAlerts": true
  }
}
```

## Logging

### Archivo de Log
- Ubicación: `.session/token-guard.log`
- Formato: JSON
- Contiene: timestamp, tokens, acción, estado

### Ejemplo de Entrada de Log
```json
{
  "timestamp": "2026-04-23 11:21:13",
  "promptTokens": 50000,
  "completionTokens": 30000,
  "totalTokens": 80000,
  "action": "check_threshold",
  "status": "ALERT"
}
```

## Flujo de Ejecución

### Inicio de Sesión
1. ✅ Ejecutar `tools/session-autostart.cmd`
2. ✅ Optimizar Engram
3. ✅ Validar cross-workspace
4. ✅ Inicializar sesión
5. ✅ **Inicializar Token Guard** ← NUEVO
6. ✅ Inicializar orquestador

### Durante la Sesión
1. Token Guard monitorea tokens
2. Si tokens < 80% → Sin acción
3. Si 80% ≤ tokens < 95% → Alerta WARNING
4. Si tokens ≥ 95% → Alerta CRITICAL + Pausa dispatch

### Fragmentación
1. Presupuesto dividido en 5 rounds
2. Cada round: 25,600 tokens
3. Al completar round → Reiniciar contador
4. Tracking automático de rounds

## Ventajas

✅ **Automático**: Se ejecuta sin intervención manual  
✅ **Preventivo**: Alerta antes de exceder presupuesto  
✅ **Protector**: Pausa dispatch en caso crítico  
✅ **Fragmentado**: Divide trabajo en rounds manejables  
✅ **Observable**: Logging detallado y reportes  
✅ **Configurable**: Todos los parámetros ajustables  
✅ **Integrado**: Parte del flujo de sesión  

## Próximas Mejoras

- [ ] Integración con dashboard de monitoreo
- [ ] Alertas por email/Slack
- [ ] Análisis predictivo de consumo
- [ ] Auto-ajuste de presupuesto
- [ ] Reportes históricos
- [ ] Métricas de eficiencia

## Troubleshooting

### Token Guard no se inicializa
```powershell
# Verificar que el archivo de configuración existe
Test-Path "tools/token-guard-config.json"

# Verificar que el script existe
Test-Path "tools/token-guard.ps1"

# Ejecutar manualmente
.\tools\token-guard.ps1 -Mode "monitor"
```

### No se crea archivo de estado
```powershell
# Verificar permisos en .session
Get-Item ".\.session" | Select-Object FullName, Mode

# Crear directorio si no existe
New-Item -ItemType Directory -Path ".\.session" -Force
```

### Alertas no se disparan
```powershell
# Verificar configuración
Get-Content "tools/token-guard-config.json" | ConvertFrom-Json

# Verificar estado
Get-Content ".\.session\token-guard-state.json" | ConvertFrom-Json
```

## Resumen de Archivos Creados

| Archivo | Descripción |
|---------|-------------|
| `tools/token-guard.ps1` | Motor principal del Token Guard |
| `tools/token-guard-config.json` | Configuración de presupuestos y umbrales |
| `tools/session-autostart.cmd` | Integración en autostart (modificado) |
| `tools/session-autostart.config.json` | Config de sesión (modificado) |
| `.session/token-guard-state.json` | Estado en tiempo real (generado) |
| `docs/TOKEN_GUARD_IMPLEMENTATION.md` | Esta documentación |

## Conclusión

El sistema de **Token Overflow Protection** está completamente operativo y se ejecuta automáticamente desde el inicio de sesión. Proporciona protección multinivel contra overflow de tokens con alertas preventivas, pausa automática de dispatch y fragmentación en rounds manejables.