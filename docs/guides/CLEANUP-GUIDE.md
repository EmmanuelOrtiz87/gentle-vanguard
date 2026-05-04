# Project Cleanup Guide

## Visin General

Este documento describe cmo limpiar el proyecto de archivos temporales, logs, cachs y otros archivos innecesarios.

**Versin**: 1.0.0
**Fecha**: 2026-04-21

---

## Tipos de Archivos a Limpiar

### 1. Archivos Temporales

**Extensiones**: `.tmp`, `.temp`, `.bak`, `.backup`

**Ubicacin**: Cualquier lugar en el proyecto

**Accin**: ELIMINAR

### 2. Archivos de Log

**Extensiones**: `.log`

**Ubicacin**: Cualquier lugar EXCEPTO `docs/judgment/`

**Accin**: ELIMINAR (solo en modo full)

### 3. Directorios de Cach

**Nombres**: `*cache*`, `__pycache__`, `.cache`

**Ubicacin**: Cualquier lugar en el proyecto

**Accin**: ELIMINAR

### 4. Archivos de Backup

**Patrones**: `*backup*`, `*.bak`

**Ubicacin**: Cualquier lugar en el proyecto

**Accin**: ELIMINAR

---

## Scripts de Limpieza

### PowerShell

**Archivo**: `scripts/utilities/cleanup-project.ps1`

**Modos**:

#### Dry-Run (Seguro)
```powershell
.\tools\cleanup-project.ps1 -Mode dry-run
```
- Muestra qu se limpiara
- NO elimina nada
- Perfecto para verificar

#### Safe (Recomendado)
```powershell
.\tools\cleanup-project.ps1 -Mode safe
```
- Elimina archivos temporales
- Elimina directorios de cach
- NO elimina logs
- Verifica integridad del proyecto

#### Full (Completo)
```powershell
.\tools\cleanup-project.ps1 -Mode full
```
- Elimina archivos temporales
- Elimina logs
- Elimina directorios de cach
- Verifica integridad del proyecto

### Bash

**Archivo**: `scripts/utilities/cleanup-project.sh`

**Modos**:

#### Dry-Run (Seguro)
```bash
bash ./scripts/utilities/cleanup-project.sh dry-run
```

#### Safe (Recomendado)
```bash
bash ./scripts/utilities/cleanup-project.sh safe
```

#### Full (Completo)
```bash
bash ./scripts/utilities/cleanup-project.sh full
```

---

## Archivos Protegidos

Los siguientes archivos/directorios NUNCA se eliminan:

### Directorios Protegidos
- `config/` - configuraciónes
- `scripts/utilities/` - Scripts
- `docs/` - Documentacin
- `skills/` - Skills
- `demos/` - Demos

### Archivos Protegidos
- `AGENTS.md` - Reglas del proyecto
- `README.md` - Documentacin principal
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
bash ./scripts/utilities/cleanup-project.sh dry-run
```

**Resultado**: Ver qu se limpiara sin eliminar nada

### Paso 2: Ejecutar Limpieza Safe

```powershell
# PowerShell
.\tools\cleanup-project.ps1 -Mode safe

# Bash
bash ./scripts/utilities/cleanup-project.sh safe
```

**Resultado**: Proyecto limpio sin perder logs importantes

### Paso 3: Verificar Integridad

El script automticamente verifica:
-  Directorios requeridos presentes
-  Archivos requeridos presentes
-  Estructura del proyecto intacta

---

## Qu Se Limpia en Cada Modo

### Dry-Run
-  No elimina nada
-  Muestra qu se limpiara
-  Verifica integridad

### Safe (Recomendado)
-  Archivos temporales (*.tmp, *.temp, *.bak, *.backup)
-  Directorios de cach (*cache*)
-  NO elimina logs
-  Verifica integridad

### Full
-  Archivos temporales
-  Logs (excepto docs/judgment/)
-  Directorios de cach
-  Archivos de backup
-  Verifica integridad

---

## Archivos Que NO Se Tocan

### Documentacin
- `docs/` - Todos los archivos
- `docs/judgment/` - Especialmente protegido
- `AGENTS.md`
- `README.md`

### configuración
- `config/` - Todos los archivos
- `config/*.json`

### Scripts
- `scripts/utilities/` - Todos los scripts
- `scripts/utilities/*.ps1`
- `scripts/utilities/*.sh`
- `scripts/utilities/*.cmd`

### Datos
- `skills/` - Todos los skills
- `demos/` - Todos los demos

---

## Verificacin de Integridad

Despus de limpiar, el script verifica:

### Directorios Requeridos
- [x] `config/` - Presente
- [x] `scripts/utilities/` - Presente
- [x] `docs/` - Presente
- [x] `skills/` - Presente
- [x] `demos/` - Presente

### Archivos Requeridos
- [x] `AGENTS.md` - Presente
- [x] `README.md` - Presente

### Resultado
-  Si todo est bien: "Project is clean and ready"
-  Si hay problemas: "Project integrity issues detected"

---

## Casos de Uso

### Caso 1: Limpiar Antes de Despliegue

```powershell
# Verificar qu se limpiara
.\tools\cleanup-project.ps1 -Mode dry-run

# Limpiar de forma segura
.\tools\cleanup-project.ps1 -Mode safe

# Verificar resultado
.\tools\cleanup-project.ps1 -Mode dry-run
```

### Caso 2: Limpiar Completamente

```powershell
# Verificar qu se limpiara
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

**Solucin**: 
1. Restaurar desde control de versiónes
2. Verificar que no se ejecut modo full innecesariamente

### Problema: Archivos no se eliminan

**Causa**: Permisos insuficientes

**Solucin**:
1. Ejecutar como administrador
2. Verificar permisos de archivo

### Problema: Dry-run muestra archivos pero safe no los elimina

**Causa**: Archivos protegidos o permisos

**Solucin**:
1. Verificar que no son archivos protegidos
2. Ejecutar con permisos elevados

---

## Mejores Prcticas

###  Hacer

- [x] Ejecutar dry-run primero
- [x] Usar modo safe regularmente
- [x] Verificar integridad despus
- [x] Hacer backup antes de full
- [x] Documentar cambios

###  No Hacer

- [ ] Ejecutar full sin verificar
- [ ] Eliminar docs/judgment/
- [ ] Eliminar archivos de configuración
- [ ] Ejecutar sin permisos
- [ ] Ignorar errores de integridad

---

## automatización

### Limpiar Regularmente

Agregar a tareas programadas:

**Windows (Task Scheduler)**:
```
Programa: powershell.exe
Argumentos: -NoProfile -ExecutionPolicy Bypass -File ".\tools\cleanup-project.ps1" -Mode safe
Frecuencia: Diaria (despus de horas de trabajo)
```

**Linux/macOS (Cron)**:
```bash
# Ejecutar limpieza diaria a las 22:00
0 22 * * * cd /path/to/project && bash ./scripts/utilities/cleanup-project.sh safe
```

---

## Conclusin

El script de limpieza proporciona:

 Mltiples modos de seguridad
 Proteccin de archivos importantes
 Verificacin de integridad
 Logging detallado
 automatización posible

**Recomendacin**: Ejecutar `safe` regularmente para mantener el proyecto limpio.

---

## Referencias

- `scripts/utilities/cleanup-project.ps1` - Script PowerShell
- `scripts/utilities/cleanup-project.sh` - Script Bash
- `AGENTS.md` - Reglas del proyecto