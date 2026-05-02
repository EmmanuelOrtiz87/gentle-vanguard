# Token Guard - Proteccin Automtica contra Overflow de Tokens

## Resumen Ejecutivo

Se ha implementado un sistema completo de **Token Overflow Protection** que se ejecuta automticamente desde el inicio de sesin. El sistema monitorea el consumo de tokens y toma acciones preventivas cuando se aproxima al lmite presupuestado.

## Caractersticas Implementadas

### 1.  Token Guard Automtico
- **Script**: `tools/token-guard.ps1`
- **configuración**: `tools/token-guard-config.json`
- **Estado**: `.session/token-guard-state.json`
- Se inicializa automticamente al ejecutar `tools/session-autostart.cmd`
- Monitorea tokens en tiempo real

### 2.  Pausar Dispatch por Presupuesto
- Pausa automtica cuando se alcanza el 95% del presupuesto
- Funcin: `Pause-Dispatch`
- Registra razn de pausa en archivo de estado
- Permite reanudar con `Resume-Dispatch`

### 3.  Fragmentacin en Mltiples Rounds
- Presupuesto dividido en 5 rounds de 25,600 tokens cada uno
- Funcin: `Initialize-RoundFragmentation`
- Estrategia: round-robin
- Reinicio automtico al completar rounds
- Tracking de rounds completados

### 4.  Alertas Automticas
- Alerta a 80% del presupuesto (WARNING)
- Alerta a 90% del presupuesto (WARNING)
- Alerta a 95% del presupuesto (CRITICAL)
- Pausa automtica a 95%
- Notificaciones en consola con colores

## Arquitectura

### Componentes Principales

```
Token Guard System
 tools/token-guard.ps1 (Motor principal)
 tools/token-guard-config.json (configuración)
 tools/session-autostart.cmd (Integracin)
 tools/session-autostart.config.json (Config de sesin)
 .session/token-guard-state.json (Estado en tiempo real)
```

### Flujo de Inicializacin

```
session-autostart.cmd
    
Optimizacin de Engram
    
Validacin cross-workspace
    
Inicializacin de sesin
    
[NUEVO] Inicializacin de Token Guard
     Cargar configuración
     Crear archivo de estado
     Inicializar monitoreo
     Mostrar parmetros
    
Inicializacin de orquestador
```

## configuración

### Presupuesto de Tokens

```json
{
  "tokenBudget": 128000,           // Presupuesto total
  "alertThreshold": 0.80,          // Alerta a 80%
  "pauseThreshold": 0.95,          // Pausa a 95%
  "maxRounds": 5,                  // Mximo de rounds
  "roundTokenBudget": 25600        // Tokens por round
}
```

### Umbrales de Alerta

| Umbral | Accin | Tipo |
|--------|--------|------|
| 80% | Alerta WARNING | Notificacin |
| 90% | Alerta WARNING | Notificacin |
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

# Verificar si est pausado
Is-DispatchPaused -StateFile ".\.session\token-guard-state.json"
```

### Fragmentacin

```powershell
# Inicializar fragmentacin
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

## Modos de Operacin

### Monitor Mode (Predeterminado)
```powershell
.\tools\token-guard.ps1 -ConfigPath "tools/token-guard-config.json" `
  -SessionId "session-2026-04-23-15" -Mode "monitor"
```
- Inicializa Token Guard
- Crea archivo de estado
- Muestra parmetros de configuración

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
- Muestra estado de fragmentacin

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

## Integracin con Session Autostart

El Token Guard se integra automticamente en `tools/session-autostart.cmd`:

```batch
REM Extraer SessionId del archivo de sesin
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "..."') do set SESSION_ID=%%i

REM Inicializar Token Guard para proteccin de tokens
echo [INFO] Initializing Token Guard...
if exist "%TOKEN_GUARD_SCRIPT%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%TOKEN_GUARD_SCRIPT%" `
    -ConfigPath "tools/token-guard-config.json" `
    -SessionId "%SESSION_ID%" -Mode "monitor"
)
```

## configuración de Sesin

El `tools/session-autostart.config.json` incluye la seccin de Token Guard:

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
- Ubicacin: `.session/token-guard.log`
- Formato: JSON
- Contiene: timestamp, tokens, accin, estado

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

## Flujo de Ejecucin

### Inicio de Sesin
1.  Ejecutar `tools/session-autostart.cmd`
2.  Optimizar Engram
3.  Validar cross-workspace
4.  Inicializar sesin
5.  **Inicializar Token Guard**  NUEVO
6.  Inicializar orquestador

### Durante la Sesin
1. Token Guard monitorea tokens
2. Si tokens < 80%  Sin accin
3. Si 80%  tokens < 95%  Alerta WARNING
4. Si tokens  95%  Alerta CRITICAL + Pausa dispatch

### Fragmentacin
1. Presupuesto dividido en 5 rounds
2. Cada round: 25,600 tokens
3. Al completar round  Reiniciar contador
4. Tracking automtico de rounds

## Ventajas

 **Automtico**: Se ejecuta sin intervencin manual  
 **Preventivo**: Alerta antes de exceder presupuesto  
 **Protector**: Pausa dispatch en caso crtico  
 **Fragmentado**: Divide trabajo en rounds manejables  
 **Observable**: Logging detallado y reportes  
 **Configurable**: Todos los parmetros ajustables  
 **Integrado**: Parte del flujo de sesin  

## Prximas Mejoras

- [ ] Integracin con dashboard de monitoreo
- [ ] Alertas por email/Slack
- [ ] Anlisis predictivo de consumo
- [ ] Auto-ajuste de presupuesto
- [ ] Reportes histricos
- [ ] Mtricas de eficiencia

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

| Archivo | Descripcin |
|---------|-------------|
| `tools/token-guard.ps1` | Motor principal del Token Guard |
| `tools/token-guard-config.json` | configuración de presupuestos y umbrales |
| `tools/session-autostart.cmd` | Integracin en autostart (modificado) |
| `tools/session-autostart.config.json` | Config de sesin (modificado) |
| `.session/token-guard-state.json` | Estado en tiempo real (generado) |
| `docs/TOKEN_GUARD_IMPLEMENTATION.md` | Esta documentacin |

## Conclusin

El sistema de **Token Overflow Protection** est completamente operativo y se ejecuta automticamente desde el inicio de sesin. Proporciona proteccin multinivel contra overflow de tokens con alertas preventivas, pausa automtica de dispatch y fragmentacin en rounds manejables.