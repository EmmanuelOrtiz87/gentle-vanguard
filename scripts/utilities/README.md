# Scripts Utilitarios - Directorio Principal

Colección centralizada de scripts utilitarios organizados por funcionalidad para el workspace foundation.

**Versión**: 3.0.0  
**Última actualización**: 2026-04-22  
**Estado**: ✅ PRODUCCIÓN

---

## 📁 Estructura de Directorios

```
scripts/utilities/
├── README.md                          # Este archivo
├── AI-AGENT-MANAGEMENT/               # Gestión y enrutamiento de agentes IA
├── AUDIT-REPORTING/                   # Auditoría y generación de reportes
├── CONFIG/                            # Configuración y perfiles
├── DEPLOYMENT/                        # Scripts de despliegue
├── Gentleman-Skills/                  # Habilidades especializadas
├── GIT-VERSION-CONTROL/               # Control de versiones Git
├── PERFORMANCE-OPTIMIZATION/          # Optimización de rendimiento
├── SESSION-MANAGEMENT/                # Gestión de sesiones
├── SKILLS-TOOLS/                      # Herramientas de habilidades
├── TELEMETRY-METRICS/                 # Telemetría y métricas
├── UTILITIES/                         # Utilidades generales
└── WORKFLOW-ORCHESTRATION/            # Orquestación de flujos de trabajo
```

---

## 🎯 Directorios por Funcionalidad

### 1. **AI-AGENT-MANAGEMENT/** 
Gestión y enrutamiento de agentes IA especializados.

**Scripts principales:**
- `agent-router.ps1` - Enrutador central de agentes (BA, SAD, DEV, QA, OPS, GOV, DOC)
- `invoke-ai-review.ps1` - Invoca revisión de IA
- `invoke-cloud-agent.ps1` - Invoca agentes en la nube
- `invoke-judgment.ps1` - Invoca proceso de juicio dual
- `judgment-day.ps1` - Protocolo de juicio adversarial completo
- `sync-agent-instructions.ps1` - Sincroniza instrucciones de agentes

**Uso típico:**
```powershell
.\scripts\utilities\AI-AGENT-MANAGEMENT\agent-router.ps1 -Agent DEV -Task "implementar feature"
```

[Ver documentación completa](./AI-AGENT-MANAGEMENT/README.md)

---

### 2. **AUDIT-REPORTING/**
Auditoría, reportes y artefactos de sesión.

**Scripts principales:**
- `audit-script-normalization.ps1` - Normaliza scripts para auditoría
- `context-metrics-report.ps1` - Reporte de métricas de contexto
- `generate-audit-report.ps1` - Genera reporte de auditoría
- `generate-session-artifacts.ps1` - Genera artefactos de sesión
- `generate-session-audit.ps1` - Auditoría de sesión
- `generate-session-review.ps1` - Revisión de sesión

**Uso típico:**
```powershell
.\scripts\utilities\AUDIT-REPORTING\generate-audit-report.ps1
```

[Ver documentación completa](./AUDIT-REPORTING/README.md)

---

### 3. **CONFIG/**
Configuración, perfiles y archivos de configuración.

**Archivos principales:**
- `context-efficiency-config.json` - Configuración de eficiencia de contexto
- `session-autostart.config.json` - Configuración de autostart de sesión
- `Microsoft.PowerShell_profile.ps1` - Perfil de PowerShell

**Uso:** Configuración centralizada para todo el workspace.

[Ver documentación completa](./CONFIG/README.md)

---

### 4. **DEPLOYMENT/**
Scripts de despliegue, migración y configuración remota.

**Scripts principales:**
- `deploy.ps1` - Despliegue principal
- `migrate-structure.ps1` - Migración de estructura
- `setup-monitoring.ps1` - Configuración de monitoreo
- `setup-remote-agent.ps1` - Configuración de agentes remotos
- `setup-wizard.ps1` - Asistente de configuración

**Uso típico:**
```powershell
.\scripts\utilities\DEPLOYMENT\deploy.ps1
```

[Ver documentación completa](./DEPLOYMENT/README.md)

---

### 5. **GIT-VERSION-CONTROL/**
Control de versiones Git, ramas y pull requests.

**Scripts principales:**
- `create-gitflow-branch.ps1` - Crea rama gitflow
- `create-pull-request.ps1` - Crea pull request
- `generate-pr-artifacts.ps1` - Genera artefactos de PR

**Uso típico:**
```powershell
.\scripts\utilities\GIT-VERSION-CONTROL\create-gitflow-branch.ps1 -Type feature -Name "nueva-feature"
```

[Ver documentación completa](./GIT-VERSION-CONTROL/README.md)

---

### 6. **PERFORMANCE-OPTIMIZATION/**
Optimización de rendimiento, compactación de memoria y Engram.

**Scripts principales:**
- `clean-runtime.ps1` - Limpia runtime
- `compact-memory.ps1` - Compacta memoria
- `compact-start.ps1` - Inicio con compactación
- `optimize-engram-usage.ps1` - Optimiza uso de Engram
- `optimize-performance.ps1` - Optimiza rendimiento general
- `pre-compact-hook.ps1` - Hook pre-compactación

**Uso típico:**
```powershell
.\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-performance.ps1
```

[Ver documentación completa](./PERFORMANCE-OPTIMIZATION/README.md)

---

### 7. **SESSION-MANAGEMENT/**
Gestión de sesiones, inicio, cierre y monitoreo.

**Scripts principales:**
- `start-session.ps1` - Inicia sesión
- `end-session.ps1` - Finaliza sesión
- `finalize-session.ps1` - Finaliza sesión con artefactos
- `session-manager.ps1` - Gestor de sesiones
- `session-idle-monitor.ps1` - Monitor de inactividad
- `validate-session-stack.ps1` - Valida stack de sesión
- `session-autostart.cmd` - Autostart de sesión (Windows)
- `session-manual-start.cmd` - Inicio manual (Windows)
- `session-manual-end.cmd` - Cierre manual (Windows)

**Uso típico:**
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\start-session.ps1
.\scripts\utilities\SESSION-MANAGEMENT\end-session.ps1
```

[Ver documentación completa](./SESSION-MANAGEMENT/README.md)

---

### 8. **SKILLS-TOOLS/**
Instalación y gestión de habilidades y herramientas.

**Scripts principales:**
- `create-skill.ps1` - Crea nueva habilidad
- `ensure-tools-active.ps1` - Asegura que herramientas estén activas
- `install-architecture-governance-skill.ps1` - Instala skill de gobernanza arquitectónica
- `install-documentation-governance-skill.ps1` - Instala skill de gobernanza de documentación
- `install-engram.ps1` - Instala Engram
- `install-workspace-skills.ps1` - Instala skills del workspace
- `skills-discovery.ps1` - Descubre skills disponibles
- `update-tools.ps1` - Actualiza herramientas

**Uso típico:**
```powershell
.\scripts\utilities\SKILLS-TOOLS\install-workspace-skills.ps1
```

[Ver documentación completa](./SKILLS-TOOLS/README.md)

---

### 9. **TELEMETRY-METRICS/**
Telemetría, métricas y presupuesto de tokens.

**Scripts principales:**
- `agent-usage-metrics.ps1` - Métricas de uso de agentes
- `aggregate-metrics.ps1` - Agrega métricas
- `consolidate-telemetry.ps1` - Consolida telemetría
- `token-budget-guard.ps1` - Guarda presupuesto de tokens
- `token-efficiency-estimator.ps1` - Estima eficiencia de tokens
- `token-telemetry-report.ps1` - Reporte de telemetría de tokens
- `token-telemetry.ps1` - Telemetría de tokens

**Uso típico:**
```powershell
.\scripts\utilities\TELEMETRY-METRICS\token-telemetry.ps1
```

[Ver documentación completa](./TELEMETRY-METRICS/README.md)

---

### 10. **UTILITIES/**
Utilidades generales y herramientas de propósito general.

**Scripts principales:**
- `auto-init-dev-environment.ps1` - Auto-inicializa entorno de desarrollo
- `context-pack.ps1` - Empaqueta contexto
- `day-end-closure.ps1` - Cierre de fin de día
- `detect-ide-session.ps1` - Detecta sesión IDE
- `enforce-response-mode.ps1` - Aplica modo de respuesta
- `export-backlog-csv.ps1` - Exporta backlog a CSV
- `foundation-sync.ps1` - Sincroniza foundation
- `handoff-compress.ps1` - Comprime handoff
- `help.ps1` - Ayuda
- `manage-backlog.ps1` - Gestiona backlog
- `manual-recovery.ps1` - Recuperación manual
- `mcp-monitor.ps1` - Monitor MCP
- `read-once-guard.ps1` - Guarda lectura única
- `response-mode.ps1` - Modo de respuesta
- `rotate-artifacts.ps1` - Rota artefactos
- `run-engram.ps1` - Ejecuta Engram
- `run-gentle-ai.ps1` - Ejecuta Gentle AI
- `run-gga.ps1` - Ejecuta GGA
- `simplify-text.ps1` - Simplifica texto
- `stack-dashboard.ps1` - Dashboard de stack
- `stack-on-demand.ps1` - Stack bajo demanda

**Uso típico:**
```powershell
.\scripts\utilities\UTILITIES\auto-init-dev-environment.ps1
```

[Ver documentación completa](./UTILITIES/README.md)

---

### 11. **WORKFLOW-ORCHESTRATION/**
Orquestación de flujos de trabajo y enrutamiento de runtime.

**Scripts principales:**
- `dispatch-agent.ps1` - Despacha agente
- `event-bus.ps1` - Bus de eventos
- `orchestrator-next-steps.ps1` - Próximos pasos del orquestador
- `orchestrator-status.ps1` - Estado del orquestador
- `runtime-router.ps1` - Enrutador de runtime
- `wf-audit.ps1` - Auditoría de flujo de trabajo
- `wf.ps1` - CLI principal de flujo de trabajo
- `wf.sh` - CLI de flujo de trabajo (Bash)

**Uso típico:**
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 diagnose
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 verify
```

[Ver documentación completa](./WORKFLOW-ORCHESTRATION/README.md)

---

## 🚀 Inicio Rápido

### Iniciar sesión
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\start-session.ps1
```

### Ejecutar diagnóstico completo
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 diagnose
```

### Finalizar sesión
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\end-session.ps1
```

### Instalar herramientas
```powershell
.\scripts\utilities\SKILLS-TOOLS\install-workspace-skills.ps1
```

---

## 📋 Requisitos

- **PowerShell**: 7.0+
- **.NET**: 6.0+
- **Git**: 2.40+
- **Engram**: (instalado automáticamente si es necesario)

---

## 🔐 Seguridad

- Todos los scripts validan entrada
- Manejo robusto de errores
- Logging automático
- Auditoría completa disponible

---

## 📊 Estructura de Archivos por Directorio

Cada subdirectorio contiene:
- `README.md` - Documentación específica del directorio
- Scripts `.ps1` - Implementación
- Archivos de configuración (si aplica)

---

## 🆘 Troubleshooting

### Problema: Script no ejecuta
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problema: Permisos denegados
```powershell
# Ejecutar como administrador
Start-Process powershell -Verb RunAs
```

### Problema: Módulos faltantes
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

---

## 📚 Documentación Relacionada

- [scripts/README.md](../README.md) - Documentación principal de scripts
- [docs/getting-started/STACK-SETUP.md](../../docs/getting-started/STACK-SETUP.md) - Guía de configuración
- [skills/SKILL_INDEX.md](../../skills/SKILL_INDEX.md) - Índice de habilidades

---

## 📝 Notas

- Todos los scripts son agnósticos de plataforma
- Compatibles con PowerShell 7+
- Logging automático en `logs/`
- Documentación inline completa en cada script

---

**Última actualización**: 2026-04-22  
**Versión**: 3.0.0  
**Estado**: ✅ PRODUCCIÓN