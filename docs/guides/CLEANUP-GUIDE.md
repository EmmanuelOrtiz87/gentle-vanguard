# Project Cleanup Guide

## Visión General

Este documento describe cómo limpiar el proyecto de archivos temporales, logs, cachés y otros archivos innecesarios.

**Versión**: 1.0.0
**Fecha**: 2026-04-21

---

## Tipos de Archivos a Limpiar

### 1. Archivos Temporales

**Extensiones**: `.tmp`, `.temp`, `.bak`, `.backup`

**Ubicación**: Cualquier lugar en el proyecto

**Acción**: ELIMINAR

### 2. Archivos de Log

**Extensiones**: `.log`

**Ubicación**: Cualquier lugar EXCEPTO `docs/judgment/`

**Acción**: ELIMINAR (solo en modo full)

### 3. Directorios de Caché

**Nombres**: `*cache*`, `__pycache__`, `.cache`

**Ubicación**: Cualquier lugar en el proyecto

**Acción**: ELIMINAR

### 4. Archivos de Backup

**Patrones**: `*backup*`, `*.bak`

**Ubicación**: Cualquier lugar en el proyecto

**Acción**: ELIMINAR

---

## Scripts de Limpieza

### PowerShell

**Archivo**: `tools/cleanup-project.ps1`

**Modos**:

#### Dry-Run (Seguro)
```powershell
.\tools\cleanup-project.ps1 -Mode dry-run
```
- Muestra qué se limpiaría
- NO elimina nada
- Perfecto para verificar

#### Safe (Recomendado)
```powershell
.\tools\cleanup-project.ps1 -Mode safe
```
- Elimina archivos temporales
- Elimina directorios de caché
- NO elimina logs
- Verifica integridad del proyecto

#### Full (Completo)
```powershell
.\tools\cleanup-project.ps1 -Mode full
```
- Elimina archivos temporales
- Elimina logs
- Elimina directorios de caché
- Verifica integridad del proyecto

### Bash

**Archivo**: `tools/cleanup-project.sh`

**Modos**:

#### Dry-Run (Seguro)
```bash
bash ./tools/cleanup-project.sh dry-run
```

#### Safe (Recomendado)
```bash
bash ./tools/cleanup-project.sh safe
```

#### Full (Completo)
```bash
bash ./tools/cleanup-project.sh full
```

---

## Archivos Protegidos

Los siguientes archivos/directorios NUNCA se eliminan:

### Directorios Protegidos
- `config/` - Configuraciones
- `tools/` - Scripts
- `docs/` - Documentación
- `skills/` - Skills
- `demos/` - Demos

### Archivos Protegidos
- `AGENTS.md` - Reglas del proyecto
- `README.md` - Documentación principal
- Todos los archivos en `docs/judgment/` - Reportes de juicio

### Logs Protegidos
- `docs/judgment/*.md` - Reportes de juicio
- `docs/judgment/*.json` - Packs de juicio

---

## Procedimiento de Limpieza Recomendado

### Paso 1: Verificar con Dry-Run

```powershell
# PowerShell
.\tools\cleanup-project.ps1 -Mode dry-run

# Bash
bash ./tools/cleanup-project.sh dry-run
```

**Resultado**: Ver qué se limpiaría sin eliminar nada

### Paso 2: Ejecutar Limpieza Safe

```powershell
# PowerShell
.\tools\cleanup-project.ps1 -Mode safe

# Bash
bash ./tools/cleanup-project.sh safe
```

**Resultado**: Proyecto limpio sin perder logs importantes

### Paso 3: Verificar Integridad

El script automáticamente verifica:
- ✅ Directorios requeridos presentes
- ✅ Archivos requeridos presentes
- ✅ Estructura del proyecto intacta

---

## Qué Se Limpia en Cada Modo

### Dry-Run
- ❌ No elimina nada
- ✅ Muestra qué se limpiaría
- ✅ Verifica integridad

### Safe (Recomendado)
- ✅ Archivos temporales (*.tmp, *.temp, *.bak, *.backup)
- ✅ Directorios de caché (*cache*)
- ❌ NO elimina logs
- ✅ Verifica integridad

### Full
- ✅ Archivos temporales
- ✅ Logs (excepto docs/judgment/)
- ✅ Directorios de caché
- ✅ Archivos de backup
- ✅ Verifica integridad

---

## Archivos Que NO Se Tocan

### Documentación
- `docs/` - Todos los archivos
- `docs/judgment/` - Especialmente protegido
- `AGENTS.md`
- `README.md`

### Configuración
- `config/` - Todos los archivos
- `config/*.json`

### Scripts
- `tools/` - Todos los scripts
- `tools/*.ps1`
- `tools/*.sh`
- `tools/*.cmd`

### Datos
- `skills/` - Todos los skills
- `demos/` - Todos los demos

---

## Verificación de Integridad

Después de limpiar, el script verifica:

### Directorios Requeridos
- [x] `config/` - Presente
- [x] `tools/` - Presente
- [x] `docs/` - Presente
- [x] `skills/` - Presente
- [x] `demos/` - Presente

### Archivos Requeridos
- [x] `AGENTS.md` - Presente
- [x] `README.md` - Presente

### Resultado
- ✅ Si todo está bien: "Project is clean and ready"
- ❌ Si hay problemas: "Project integrity issues detected"

---

## Casos de Uso

### Caso 1: Limpiar Antes de Despliegue

```powershell
# Verificar qué se limpiaría
.\tools\cleanup-project.ps1 -Mode dry-run

# Limpiar de forma segura
.\tools\cleanup-project.ps1 -Mode safe

# Verificar resultado
.\tools\cleanup-project.ps1 -Mode dry-run
```

### Caso 2: Limpiar Completamente

```powershell
# Verificar qué se limpiaría
.\tools\cleanup-project.ps1 -Mode dry-run

# Limpiar todo
.\tools\cleanup-project.ps1 -Mode full

# Verificar resultado
.\tools\cleanup-project.ps1 -Mode dry-run
```

### Caso 3: Limpiar Regularmente

```powershell
# Ejecutar limpieza segura regularmente
.\tools\cleanup-project.ps1 -Mode safe
```

---

## Troubleshooting

### Problema: "Project integrity issues detected"

**Causa**: Archivos requeridos fueron eliminados

**Solución**: 
1. Restaurar desde control de versiones
2. Verificar que no se ejecutó modo full innecesariamente

### Problema: Archivos no se eliminan

**Causa**: Permisos insuficientes

**Solución**:
1. Ejecutar como administrador
2. Verificar permisos de archivo

### Problema: Dry-run muestra archivos pero safe no los elimina

**Causa**: Archivos protegidos o permisos

**Solución**:
1. Verificar que no son archivos protegidos
2. Ejecutar con permisos elevados

---

## Mejores Prácticas

### ✅ Hacer

- [x] Ejecutar dry-run primero
- [x] Usar modo safe regularmente
- [x] Verificar integridad después
- [x] Hacer backup antes de full
- [x] Documentar cambios

### ❌ No Hacer

- [ ] Ejecutar full sin verificar
- [ ] Eliminar docs/judgment/
- [ ] Eliminar archivos de configuración
- [ ] Ejecutar sin permisos
- [ ] Ignorar errores de integridad

---

## Automatización

### Limpiar Regularmente

Agregar a tareas programadas:

**Windows (Task Scheduler)**:
```
Programa: powershell.exe
Argumentos: -NoProfile -ExecutionPolicy Bypass -File ".\tools\cleanup-project.ps1" -Mode safe
Frecuencia: Diaria (después de horas de trabajo)
```

**Linux/macOS (Cron)**:
```bash
# Ejecutar limpieza diaria a las 22:00
0 22 * * * cd /path/to/project && bash ./tools/cleanup-project.sh safe
```

---

## Conclusión

El script de limpieza proporciona:

✅ Múltiples modos de seguridad
✅ Protección de archivos importantes
✅ Verificación de integridad
✅ Logging detallado
✅ Automatización posible

**Recomendación**: Ejecutar `safe` regularmente para mantener el proyecto limpio.

---

## Referencias

- `tools/cleanup-project.ps1` - Script PowerShell
- `tools/cleanup-project.sh` - Script Bash
- `AGENTS.md` - Reglas del proyecto