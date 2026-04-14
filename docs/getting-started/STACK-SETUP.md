# 🏗️ Gentleman Foundation Stack Setup & Auto-Repair Guide

## Overview

La arquitectura de Gentleman Foundation incluye un **sistema automático de detección y reparación del stack** que se ejecuta sin intervención manual. El stack se verifica y repara cada vez que:

- Abres una terminal en una carpeta del proyecto
- Haces `git checkout` en una rama
- Ejecutas comandos del flujo de trabajo
- Ejecutas explícitamente `.\scripts\utilities\wf.ps1 verify`

## Quick Start

### Opción 1: Proyecto Nuevo

```powershell
# En workspace-foundation root
.\scripts\utilities\wf.ps1 init-stack

# O en bitbucket-dashboard root
.\scripts\utilities\wf.ps1 init-stack
```

### Opción 2: Proyecto Existente (descargado, rama nueva, etc.)

```powershell
# Verificación rápida con auto-reparación
.\scripts\utilities\wf.ps1 verify

# O verificación completa con reporte detallado
.\scripts\utilities\wf.ps1 diagnose
```

### Opción 3: Automático al Abrir Terminal (Recomendado)

El PowerShell profile ejecuta automáticamente `verify` al detectar un Gentleman Foundation project.

## Stack Components

El stack requiere estos componentes. El sistema verifica automáticamente:

### ✅ Críticos (Deben estar instalados)
- **Go** - Backend runtime
- **Git** - Version control
- **PowerShell 5.1+** - Script execution

Para bitbucket-dashboard adicional:
- **Node.js** - Frontend runtime
- **npm** - Package manager

### ⚠️ Opcionales (Se instalan automáticamente)
- **Engram CLI** - AI memory system
- **Angular CLI** - Frontend tooling (bitbucket-dashboard)
- **gh CLI** - GitHub automation

## Command Reference

### `.\scripts\utilities\wf.ps1 diagnose`
Genera un reporte completo del estado del stack.

```powershell
# Reporte detallado en consola
.\scripts\utilities\wf.ps1 diagnose

# Reporte en JSON para automatización
.\scripts\utilities\wf.ps1 diagnose -JSON > stack-status.json
```

**Salida incluye:**
- Estado de cada componente (PASS/FAIL/WARN)
- Paths resueltos de herramientas
- Configuración del workspace
- Estado del orquestador
- Recomendaciones de reparación

### `.\scripts\utilities\wf.ps1 verify`
Verificación rápida con auto-reparación. Silencioso por defecto.

```powershell
# Verificación silenciosa con auto-reparación
.\scripts\utilities\wf.ps1 verify

# Muestra detalles mientras repara
.\scripts\utilities\wf.ps1 verify -Verbose
```

**Qué hace verify:**
1. Detecta el tipo de proyecto
2. Verifica componentes críticos
3. Detecta Engram CLI, instala si falta
4. Activa herramientas de desarrollo
5. Reporta estado final

### `.\scripts\utilities\wf.ps1 health`
Chequeo de salud con activación de herramientas.

```powershell
.\scripts\utilities\wf.ps1 health
```

### `.\scripts\utilities\wf.ps1 install-engram`
Instala o verifica disponibilidad de Engram CLI.

```powershell
.\scripts\utilities\wf.ps1 install-engram
```

## Flujos de Uso

### 🆕 Iniciar Proyecto Desde Cero

```powershell
cd c:\projects
mkdir my-new-project
cd my-new-project

# Copiar template
Copy-Item -Path "c:\workspace-foundation\*" -Destination . -Recurse

# Inicializar stack
.\scripts\utilities\wf.ps1 init-stack
```

**Resultado:** Stack completamente inicializado y operacional.

### 📥 Proyecto Descargado o Nueva Rama

```powershell
# Después de git clone o git checkout
cd <project-root>

# El post-checkout hook ejecuta verify automáticamente
# Pero puedes ejecutarlo manualmente también:
.\scripts\utilities\wf.ps1 verify
```

**El hook post-checkout:**
- Se ejecuta automáticamente después de `git checkout`
- Diagnostica el estado del stack
- Repara automáticamente problemas detectados
- Inicializa ambiente si es necesario

### 🔄 Verificación Manual en Cualquier Momento

```powershell
# Reporte completo
.\scripts\utilities\wf.ps1 diagnose

# Reporte + auto-reparación
.\scripts\utilities\wf.ps1 verify

# Reporte en JSON para CI/CD
.\scripts\utilities\wf.ps1 diagnose -JSON
```

## Detección Automática

### PowerShell Profile Auto-Detection

El PowerShell profile especial (`scripts/utilities/Microsoft.PowerShell_profile.ps1`) detecta automáticamente cuando te encuentras en un Gentleman Foundation project y ejecuta:

```powershell
# Al abrir una terminal en una carpeta de proyecto:
if (es_gentleman_foundation_project) {
    .\scripts\utilities\wf.ps1 verify  # Auto-verificación silenciosa
}
```

Para activar, copia el profile:
```powershell
Copy-Item ".\scripts\utilities\Microsoft.PowerShell_profile.ps1" $PROFILE
. $PROFILE
```

### Git Post-Checkout Hook

Se ejecuta automáticamente después de `git checkout`:

```powershell
# En .git/hooks/ (auto-configurado en bootstrap)
post-checkout -> system-diagnostics.ps1 + auto-init
```

## Escenarios de Auto-Reparación

El sistema detecta y repara automáticamente:

| Problema | Detección | Reparación |
|----------|-----------|-----------|
| Engram CLI falta | ✓ | Instala vía `go install` |
| Workspace config falta | ✓ | Crea desde template |
| Orquestador no activado | ✓ | Activa e inicializa |
| Dependencias no satisfechas | ✓ | Instala automáticamente |
| Node/npm ausentes (dashboard) | ✓ | Avisa para instalación manual |
| Go no instalado | ✓ | Avisa para instalación manual |

## Status Codes

El sistema retorna códigos de salida:

```
0 = Stack HEALTHY
1 = Stack DEGRADED (warnings, pero operacional)
2 = Stack CRITICAL (errors, no operacional)
```

## JSON Output Example

Para CI/CD y automatización:

```powershell
.\scripts\utilities\wf.ps1 diagnose -JSON | ConvertFrom-Json
```

```json
{
  "timestamp": "2026-04-11T14:30:00Z",
  "projectRoot": "C:\\Workspace_local\\bitbucket-dashboard",
  "projectType": "bitbucket-dashboard",
  "overallStatus": "HEALTHY",
  "checks": [
    {
      "name": "Go",
      "status": "PASS",
      "message": "go version go1.21.5 windows/amd64",
      "critical": true
    },
    {
      "name": "Engram CLI",
      "status": "PASS",
      "message": "C:\\Users\\emman\\go\\bin\\engram.exe",
      "critical": false
    }
  ],
  "errors": [],
  "warnings": [],
  "suggestions": []
}
```

## Procedimiento Estándar Para Desarrolladores

### Cada Vez que Abres el Proyecto

```powershell
# 1. Abre PowerShell en la carpeta del proyecto
cd C:\projects\mi-proyecto

# 2. La verificación automática se ejecuta (desde profile/hook)
# Nada que hacer, espera 2-3 segundos

# 3. Stack listo para usar
.\scripts\utilities\wf.ps1 status  # Verifica estado del proyecto
```

### Cuando Cambias de Rama

```powershell
git checkout feature/new-feature

# El post-checkout hook ejecuta:
# - system-diagnostics.ps1
# - auto-init-dev-environment.ps1

# Espera a que termine, stack está listo
.\scripts\utilities\wf.ps1 review  # Procede con trabajo
```

### Cuando Sospechas Problemas

```powershell
# Reporte completo
.\scripts\utilities\wf.ps1 diagnose

# Auto-reparar
.\scripts\utilities\wf.ps1 verify

# Re-verificar
.\scripts\utilities\wf.ps1 diagnose
```

## Troubleshooting

### "Stack is CRITICAL - Go not found"

**Solución:**
```powershell
# Instalar Go desde https://go.dev/
# Agregar a PATH
# Reiniciar PowerShell

# Verificar
.\scripts\utilities\wf.ps1 verify
```

### "Engram CLI NOT FOUND (can auto-install)"

**Solución:**
```powershell
# Auto-install
.\scripts\utilities\wf.ps1 install-engram

# O verificar e reparar todo
.\scripts\utilities\wf.ps1 verify
```

### "Orchestrator NOT ACTIVATED"

**Solución:**
```powershell
.\scripts\utilities\wf.ps1 orchestrator-status

# O usar verify para activar
.\scripts\utilities\wf.ps1 verify
```

### Hook post-checkout no se ejecuta

**Causa:** Git hooks no están configurados correctamente.

**Solución:**
```powershell
# Re-configurar hooks path
git config core.hooksPath scripts/git-hooks

# Verificar
git config core.hooksPath
# Debería mostrar: scripts/git-hooks
```

## CI/CD Integration

Para pipelines de integración continua:

```powershell
# En el paso de setup:
.\scripts\utilities\wf.ps1 diagnose -JSON | ConvertFrom-Json | Select-Object overallStatus

# Si overallStatus != "HEALTHY", fallar el pipeline
if ($status.overallStatus -ne "HEALTHY") {
    exit 1
}

# Proceder con tests/builds
```

## Best Practices

1. **Siempre ejecuta `verify` después de clonar/descargar un proyecto**
2. **El PowerShell profile hace esto automáticamente**
3. **Usa `diagnose` cuando necesites un reporte detallado**
4. **El sistema auto-repara la mayoría de problemas comunes**
5. **Componentecríticos (Go, Git, Node) requieren instalación manual**

## Ver También

- [scripts/utilities/README.md](scripts/utilities/README.md) - Comandos disponibles
- [scripts/foundation/bootstrap.ps1](scripts/foundation/bootstrap.ps1) - Inicialización completa
- [scripts/diagnostics/system-diagnostics.ps1](scripts/diagnostics/system-diagnostics.ps1) - Motor de diagnósticos
- [hooks/post-checkout.ps1](hooks/post-checkout.ps1) - Auto-verificación en checkouts
