# SESSION-MANAGEMENT - Gestin de Sesiones

Mdulo centralizado para gestin del ciclo de vida de sesiones de trabajo.

**Versin**: 2.0.0  
**ltima actualizacin**: 2026-04-22  
**Estado**:  PRODUCCIN

---

##  Descripcin

Este directorio contiene scripts para:
- Inicio y cierre de sesiones
- Monitoreo de inactividad
- Validacin de stack de sesin
- Finalizacin con artefactos
- Autostart automtico
- Gestin centralizada de sesiones

---

##  Scripts

### `start-session.ps1`
**Propsito**: Inicia una nueva sesin de trabajo

**Caractersticas**:
- Inicializa contexto de sesin
- Carga configuracin
- Activa herramientas necesarias
- Genera ID de sesin nico

**Parmetros**:
```powershell
-SessionName <string>    # Nombre de la sesin (opcional)
-AutoInit                # Auto-inicializar entorno
-Quiet                   # Modo silencioso
```

**Uso**:
```powershell
# Iniciar sesin estndar
.\start-session.ps1

# Iniciar con nombre especfico
.\start-session.ps1 -SessionName "feature-auth"

# Iniciar con auto-inicializacin
.\start-session.ps1 -AutoInit
```

---

### `end-session.ps1`
**Propsito**: Finaliza sesin con verificaciones

**Caractersticas**:
- Verifica integridad de cambios
- Genera artefactos de cierre
- Limpia recursos temporales
- Registra mtricas de sesin

**Parmetros**:
```powershell
-GenerateArtifacts       # Generar artefactos de cierre
-Verify                  # Verificar antes de cerrar
-Quiet                   # Modo silencioso
```

**Uso**:
```powershell
# Finalizar sesin estndar
.\end-session.ps1

# Finalizar con artefactos
.\end-session.ps1 -GenerateArtifacts

# Finalizar con verificacin
.\end-session.ps1 -Verify
```

---

### `finalize-session.ps1`
**Propsito**: Finaliza sesin con generacin completa de artefactos

**Caractersticas**:
- Genera todos los artefactos de cierre
- Auditora completa
- Reporte de sesin
- Compresin de contexto

**Parmetros**:
```powershell
-IncludeAudit            # Incluir auditora completa
-CompressContext         # Comprimir contexto
-GenerateReport          # Generar reporte
```

**Uso**:
```powershell
# Finalizar con todos los artefactos
.\finalize-session.ps1 -IncludeAudit -GenerateReport
```

---

### `session-manager.ps1`
**Propsito**: Gestor centralizado de sesiones

**Acciones**:
- `start` - Inicia sesin
- `end` - Finaliza sesin
- `list` - Lista sesiones activas
- `status` - Estado de sesin actual
- `validate` - Valida sesin
- `cleanup` - Limpia sesiones antiguas

**Parmetros**:
```powershell
-Action <string>         # Accin a ejecutar
-SessionId <string>      # ID de sesin (opcional)
```

**Uso**:
```powershell
# Listar sesiones activas
.\session-manager.ps1 -Action list

# Obtener estado actual
.\session-manager.ps1 -Action status

# Validar sesin
.\session-manager.ps1 -Action validate

# Limpiar sesiones antiguas
.\session-manager.ps1 -Action cleanup
```

---

### `session-idle-monitor.ps1`
**Propsito**: Monitorea inactividad de sesin

**Caractersticas**:
- Detecta inactividad
- Alerta antes de timeout
- Auto-pausa de recursos
- Recuperacin automtica

**Parmetros**:
```powershell
-IdleThreshold <int>     # Minutos antes de considerar inactivo (default: 30)
-CheckInterval <int>     # Intervalo de verificacin en segundos (default: 60)
-AutoPause               # Auto-pausar recursos
```

**Uso**:
```powershell
# Monitorear con threshold de 30 minutos
.\session-idle-monitor.ps1

# Monitorear con threshold personalizado
.\session-idle-monitor.ps1 -IdleThreshold 60 -AutoPause
```

---

### `validate-session-stack.ps1`
**Propsito**: Valida integridad del stack de sesin

**Verifica**:
- Archivos de sesin
- Configuracin
- Recursos activos
- Integridad de datos

**Parmetros**:
```powershell
-Full                    # Validacin completa
-Repair                  # Reparar problemas encontrados
-Verbose                 # Salida detallada
```

**Uso**:
```powershell
# Validacin rpida
.\validate-session-stack.ps1

# Validacin completa con reparacin
.\validate-session-stack.ps1 
{
  "prompt_tokens": 33168,
  "prompt_unit_price": "0",
  "prompt_price_unit": "0",
  "prompt_price": "0",
  "completion_tokens": 8096,
  "completion_unit_price": "0",
  "completion_price_unit": "0",
  "completion_price": "0",
  "total_tokens": 41264,
  "total_price": "0",
  "currency": "USD",
  "latency": 49.391,
  "time_to_first_token": 3.304,
  "time_to_generate": 46.087
}