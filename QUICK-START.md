# Gentle-Vanguard - Guía de Uso Rápido

## 🚀 Inicio Rápido (OPTIMIZADO)

### Opción 1: Script de inicio (RECOMENDADO - 0.76s)

```batch
# Modo rápido (recomendado para uso diario)
start.bat

# Modo completo (con verificaciones adicionales)
start.bat --complete
```

**Optimizaciones:**

- ✅ 60% más rápido que dashboard-start.ts
- ✅ Limpia procesos zombie automáticamente
- ✅ No bloquea el terminal (corre en background)
- ✅ Verifica que inició correctamente
- ✅ Logs en `.runtime/dashboard.log`

### Opción 2: Comandos manuales

```bash
# Limpiar y verificar estado
npx tsx src/cli/gv.ts status

# Iniciar dashboard
npx tsx src/dashboard-start.ts

# O iniciar todo (sesión + dashboard)
npx tsx src/cli/gv.ts session start
npx tsx src/cli/gv.ts dashboard start
```

## 🎯 Comandos Principales

### CLI Unificado (gv.ts)

```bash
# Ver estado completo del stack
npx tsx src/cli/gv.ts status

# Gestionar sesión
npx tsx src/cli/gv.ts session start    # Iniciar sesión
npx tsx src/cli/gv.ts session stop     # Detener sesión
npx tsx src/cli/gv.ts session status   # Ver estado

# Controlar dashboard
npx tsx src/cli/gv.ts dashboard start   # Iniciar dashboard
npx tsx src/cli/gv.ts dashboard stop    # Detener dashboard
npx tsx src/cli/gv.ts dashboard status  # Ver estado

# Limpieza de procesos zombie
npx tsx src/cli/gv.ts cleanup

# Verificar salud del sistema
npx tsx src/cli/gv.ts health
```

### Health Check

```bash
npm run watchtower:health
```

## 📊 Acceso al Dashboard

- **Web UI**: http://localhost:5173
- **WS API**: http://localhost:8080/api/metrics

## 🛠️ Herramientas Nativas

### Gestión de Referencias PS1

```bash
# Ver qué se arreglaría (dry-run)
npx tsx src/auto-ps1-fixer.ts --dry-run

# Aplicar correcciones
npx tsx src/auto-ps1-fixer.ts

# Corregir configs
npx tsx src/auto-ps1-fixer-configs.ts --dry-run
npx tsx src/auto-ps1-fixer-configs.ts
```

### Steps Adaptativos

```bash
# Ver estado de steps
npx tsx src/adaptive-steps.ts --status

# Estimar steps para una tarea
npx tsx src/adaptive-steps.ts --estimate "complex refactoring task"

# Aplicar a un agente
npx tsx src/adaptive-steps.ts --auto "task description" --agent sdd-apply
```

## ✅ Estado Actual del Stack

- **Health Check**: 84/85 PASS (0 FAIL)
- **Dashboard**: ✅ Corriendo (PID 6520)
- **WebSocket**: ✅ Puerto 8080 activo
- **Vite**: ✅ Puerto 5173 activo

## 📝 Notas

### Sin Dependencia de PowerShell

Todas las herramientas funcionan **sin PowerShell**:

- Usan `netstat.exe` nativo de Windows
- Usan `taskkill` nativo de Windows
- APIs de Node.js para filesystem

### Session Persistence

- Timeout: 30 minutos de inactividad
- Archivo: `.session/.active-session.json`
- Si expira, simplemente reinicia con `gv.ts session start`

## 🆘 Solución de Problemas

### Dashboard no inicia

```bash
# Limpiar todo y reiniciar
npx tsx src/cli/gv.ts cleanup
npx tsx src/dashboard-start.ts
```

### Health check muestra FAILs

```bash
# Reiniciar stack completo
npx tsx src/dashboard-stop.ts
npx tsx src/cli/gv.ts cleanup
timeout /t 5
npx tsx src/dashboard-start.ts
```

### Verificar puertos ocupados

```bash
# Windows nativo (sin PowerShell)
netstat -ano | findstr :8080
netstat -ano | findstr :5173
```
