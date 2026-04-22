# SESSION-MANAGEMENT - Gestión de Sesiones

Módulo centralizado para gestión del ciclo de vida de sesiones de trabajo.

**Versión**: 2.0.0  
**Última actualización**: 2026-04-22  
**Estado**: ✅ PRODUCCIÓN

---

## 📋 Descripción

Este directorio contiene scripts para:
- Inicio y cierre de sesiones
- Monitoreo de inactividad
- Validación de stack de sesión
- Finalización con artefactos
- Autostart automático
- Gestión centralizada de sesiones

---

## 📁 Scripts

### `start-session.ps1`
**Propósito**: Inicia una nueva sesión de trabajo

**Características**:
- Inicializa contexto de sesión
- Carga configuración
- Activa herramientas necesarias
- Genera ID de sesión único

**Parámetros**:
```powershell
-SessionName <string>    # Nombre de la sesión (opcional)
-AutoInit                # Auto-inicializar entorno
-Quiet                   # Modo silencioso
```

**Uso**:
```powershell
# Iniciar sesión estándar
.\start-session.ps1

# Iniciar con nombre específico
.\start-session.ps1 -SessionName "feature-auth"

# Iniciar con auto-inicialización
.\start-session.ps1 -AutoInit
```

---

### `end-session.ps1`
**Propósito**: Finaliza sesión con verificaciones

**Características**:
- Verifica integridad de cambios
- Genera artefactos de cierre
- Limpia recursos temporales
- Registra métricas de sesión

**Parámetros**:
```powershell
-GenerateArtifacts       # Generar artefactos de cierre
-Verify                  # Verificar antes de cerrar
-Quiet                   # Modo silencioso
```

**Uso**:
```powershell
# Finalizar sesión estándar
.\end-session.ps1

# Finalizar con artefactos
.\end-session.ps1 -GenerateArtifacts

# Finalizar con verificación
.\end-session.ps1 -Verify
```

---

### `finalize-session.ps1`
**Propósito**: Finaliza sesión con generación completa de artefactos

**Características**:
- Genera todos los artefactos de cierre
- Auditoría completa
- Reporte de sesión
- Compresión de contexto

**Parámetros**:
```powershell
-IncludeAudit            # Incluir auditoría completa
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
**Propósito**: Gestor centralizado de sesiones

**Acciones**:
- `start` - Inicia sesión
- `end` - Finaliza sesión
- `list` - Lista sesiones activas
- `status` - Estado de sesión actual
- `validate` - Valida sesión
- `cleanup` - Limpia sesiones antiguas

**Parámetros**:
```powershell
-Action <string>         # Acción a ejecutar
-SessionId <string>      # ID de sesión (opcional)
```

**Uso**:
```powershell
# Listar sesiones activas
.\session-manager.ps1 -Action list

# Obtener estado actual
.\session-manager.ps1 -Action status

# Validar sesión
.\session-manager.ps1 -Action validate

# Limpiar sesiones antiguas
.\session-manager.ps1 -Action cleanup
```

---

### `session-idle-monitor.ps1`
**Propósito**: Monitorea inactividad de sesión

**Características**:
- Detecta inactividad
- Alerta antes de timeout
- Auto-pausa de recursos
- Recuperación automática

**Parámetros**:
```powershell
-IdleThreshold <int>     # Minutos antes de considerar inactivo (default: 30)
-CheckInterval <int>     # Intervalo de verificación en segundos (default: 60)
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
**Propósito**: Valida integridad del stack de sesión

**Verifica**:
- Archivos de sesión
- Configuración
- Recursos activos
- Integridad de datos

**Parámetros**:
```powershell
-Full                    # Validación completa
-Repair                  # Reparar problemas encontrados
-Verbose                 # Salida detallada
```

**Uso**:
```powershell
# Validación rápida
.\validate-session-stack.ps1

# Validación completa con reparación
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