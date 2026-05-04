# Scripts Utilitarios - directorio Principal

Colección centralizada de scripts utilitarios organizados por funcionalidad para el workspace foundation.

**Versión**: 3.0.0  
**Última actualización**: 2026-04-22  
**Estado**:  PRODUCCIÓN

---

##  estructura de directorios

```
scripts/utilities/
 README.md                          # Este archivo
 AI-AGENT-MANAGEMENT/               # Gestión y enrutamiento de agentes IA
 AUDIT-REPORTING/                   # Auditoría y generación de reportes
 CONFIG/                            # Configuración y perfiles
 DEPLOYMENT/                        # Scripts de despliegue
  WORKSPACE-SKILLS/                  # Habilidades especializadas
 GIT-versión-CONTROL/               # Control de versiónes Git
 PERFORMANCE-OPTIMIZATION/          # Optimización de rendimiento
 SESSION-MANAGEMENT/                # Gestión de sesiónes
 SKILLS-TOOLS/                      # herramientas de habilidades
 TELEMETRY-METRICS/                 # Telemetría y métricas
 UTILITIES/                         # Utilidades generales
 WORKFLOW-ORCHESTRATION/            # Orquestación de flujos de trabajo
```

---

##  directorios por Funcionalidad

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

[Ver documentacin completa](./AI-AGENT-MANAGEMENT/README.md)

---

### 2. **AUDIT-REPORTING/**
Auditora, reportes y artefactos de sesin.

**Scripts principales:**
- `audit-script-normalization.ps1` - Normaliza scripts para auditora
- `context-metrics-report.ps1` - Reporte de mtricas de contexto
- `generate-audit-report.ps1` - Genera reporte de auditora
- `generate-session-artifacts.ps1` - Genera artefactos de sesin
- `generate-session-audit.ps1` - Auditora de sesin
- `generate-session-review.ps1` - revisión de sesin

**Uso tpico:**
```powershell
.\scripts\utilities\AUDIT-REPORTING\generate-audit-report.ps1
```

[Ver documentacin completa](./AUDIT-REPORTING/README.md)

---

### 3. **CONFIG/**
configuración, perfiles y archivos de configuración.

**archivos principales:**
- `context-efficiency-config.json` - configuración de eficiencia de contexto
- `session-autostart.config.json` - configuración de autostart de sesin
- `Microsoft.PowerShell_profile.ps1` - Perfil de PowerShell

**Uso:** configuración centralizada para todo el workspace.

[Ver documentacin completa](./CONFIG/README.md)

---

### 4. **DEPLOYMENT/**
Scripts de despliegue, migracin y configuración remota.

**Scripts principales:**
- `deploy.ps1` - Despliegue principal
- `migrate-structure.ps1` - Migracin de estructura
- `setup-monitoring.ps1` - configuración de monitoreo
- `setup-remote-agent.ps1` - configuración de agentes remotos
- `setup-wizard.ps1` - Asistente de configuración

**Uso tpico:**
```powershell
.\scripts\utilities\DEPLOYMENT\deploy.ps1
```

[Ver documentacin completa](./DEPLOYMENT/README.md)

---

### 5. **GIT-versión-CONTROL/**
Control de versiónes Git, ramas y pull requests.

**Scripts principales:**
- `create-gitflow-branch.ps1` - Crea rama gitflow
- `create-pull-request.ps1` - Crea pull request
- `generate-pr-artifacts.ps1` - Genera artefactos de PR

**Uso tpico:**
```powershell
.\scripts\utilities\GIT-versión-CONTROL\create-gitflow-branch.ps1 -Type feature -Name "nueva-feature"
```

[Ver documentacin completa](./GIT-versión-CONTROL/README.md)

---

### 6. **PERFORMANCE-OPTIMIZATION/**
Optimizacin de rendimiento, compactacin de memoria y Engram.

**Scripts principales:**
- `clean-runtime.ps1` - Limpia runtime
- `compact-memory.ps1` - Compacta memoria
- `compact-start.ps1` - Inicio con compactacin
- `optimize-engram-usage.ps1` - Optimiza uso de Engram
- `optimize-performance.ps1` - Optimiza rendimiento general
- `pre-compact-hook.ps1` - Hook pre-compactacin

**Uso tpico:**
```powershell
.\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-performance.ps1
```

[Ver documentacin completa](./PERFORMANCE-OPTIMIZATION/README.md)

---

### 7. **SESSION-MANAGEMENT/**
Gestin de sesiónes, inicio, cierre y monitoreo.

**Scripts principales:**
- `start-session.ps1` - Inicia sesin
- `end-session.ps1` - Finaliza sesin
- `finalize-session.ps1` - Finaliza sesin con artefactos
- `session-manager.ps1` - Gestor de sesiónes
- `session-idle-monitor.ps1` - Monitor de inactividad
- `validate-session-stack.ps1` - Valida stack de sesin
- `session-autostart.cmd` - Autostart de sesin (Windows)
- `session-manual-start.cmd` - Inicio manual (Windows)
- `session-manual-end.cmd` - Cierre manual (Windows)

**Uso tpico:**
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\start-session.ps1
.\scripts\utilities\SESSION-MANAGEMENT\end-session.ps1
```

[Ver documentacin completa](./SESSION-MANAGEMENT/README.md)

---

### 8. **SKILLS-TOOLS/**
Instalacin y gestin de habilidades y herramientas.

**Scripts principales:**
- `create-skill.ps1` - Crea nueva habilidad
- `ensure-tools-active.ps1` - Asegura que herramientas estn activas
- `install-architecture-governance-skill.ps1` - Instala skill de gobernanza arquitectnica
- `install-documentation-governance-skill.ps1` - Instala skill de gobernanza de documentacin
- `install-engram.ps1` - Instala Engram
- `install-workspace-skills.ps1` - Instala skills del workspace
- `skills-discovery.ps1` - Descubre skills disponibles
- `update-tools.ps1` - Actualiza herramientas

**Uso tpico:**
```powershell
.\scripts\utilities\SKILLS-TOOLS\install-workspace-skills.ps1
```

[Ver documentacin completa](./SKILLS-TOOLS/README.md)

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
- `extract-engram-json.ps1` - Extrae JSON de Engram
- `generate-management-report.ps1` - Genera reporte mensual en CSV
- `generate-management-report-simple.ps1` - Versión simplificada
- `validate-report.ps1` - Valida reportes
- `validate-report-simple.ps1` - Versión simplificada

**Uso típico:**
```powershell
.\scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1
```

[Ver documentación completa](./TELEMETRY-METRICS/README.md)

---

### 9.1. **JSON-to-Document Converter**
Convierte JSON de agentes/subagentes al formato de documento correcto.

**Formats soportados:** Markdown, CSV, HTML, Text, JSON, XML, YAML

**Scripts principales:**
- `json-to-doc-converter.ps1` - Convierte JSON a 7 formatos
- `json-to-doc-converter.README.md` - Documentación completa

**Uso típico:**
```powershell
# JSON string to Markdown
$json = '{"type":"session","project":"gentleman-foundation"}'
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson $json

# JSON file to CSV
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson "logs\session.json" -OutputFormat csv

# With template
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson $data -OutputFormat markdown -TemplatePath "templates\report-template.md"
```

**Integración con orquestador:**
- Auto-detecta tipo de dato (`session`, `audit`, `judgment`, `management-report`)
- Guarda en directorio correcto (`docs/`, `reports/`, `logs/`)
- Soportado por todas las herramientas (OpenCode, Cline, Claude, Copilot, etc.)

[Ver documentación completa](./json-to-doc-converter.README.md)

---

### 10. **UTILITIES/**
Utilidades generales y herramientas de propsito general.

**Scripts principales:**
- `auto-init-dev-environment.ps1` - Auto-inicializa entorno de desarrollo
- `context-pack.ps1` - Empaqueta contexto
- `day-end-closure.ps1` - Cierre de fin de da
- `detect-ide-session.ps1` - Detecta sesin IDE
- `enforce-response-mode.ps1` - Aplica modo de respuesta
- `export-backlog-csv.ps1` - Exporta backlog a CSV
- `foundation-sync.ps1` - Sincroniza foundation
- `handoff-compress.ps1` - Comprime handoff
- `help.ps1` - Ayuda
- `manage-backlog.ps1` - gestióna backlog
- `manual-recovery.ps1` - Recuperacin manual
- `mcp-monitor.ps1` - Monitor MCP
- `read-once-guard.ps1` - Guarda lectura nica
- `response-mode.ps1` - Modo de respuesta
- `rotate-artifacts.ps1` - Rota artefactos
- `run-engram.ps1` - Ejecuta Engram
- `simplify-text.ps1` - Simplifica texto
- `stack-dashboard.ps1` - Dashboard de stack
- `stack-on-demand.ps1` - Stack bajo demanda

**Uso tpico:**
```powershell
.\scripts\utilities\UTILITIES\auto-init-dev-environment.ps1
```

[Ver documentacin completa](./UTILITIES/README.md)

---

### 11. **WORKFLOW-ORCHESTRATION/**
Orquestacin de flujos de trabajo y enrutamiento de runtime.

**Scripts principales:**
- `dispatch-agent.ps1` - Despacha agente
- `event-bus.ps1` - Bus de eventos
- `orchestrator-next-steps.ps1` - Prximos pasos del orquestador
- `orchestrator-status.ps1` - Estado del orquestador
- `runtime-router.ps1` - Enrutador de runtime
- `wf-audit.ps1` - Auditora de flujo de trabajo
- `wf.ps1` - CLI principal de flujo de trabajo
- `wf.sh` - CLI de flujo de trabajo (Bash)

**Uso tpico:**
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 diagnose
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 verify
```

[Ver documentacin completa](./WORKFLOW-ORCHESTRATION/README.md)

---

##  Inicio Rpido

### Iniciar sesin
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\start-session.ps1
```

### Ejecutar diagnstico completo
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 diagnose
```

### Finalizar sesin
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\end-session.ps1
```

### Instalar herramientas
```powershell
.\scripts\utilities\SKILLS-TOOLS\install-workspace-skills.ps1
```

---

##  Requisitos

- **PowerShell**: 7.0+
- **.NET**: 6.0+
- **Git**: 2.40+
- **Engram**: (instalado automticamente si es necesario)

---

##  Seguridad

- Todos los scripts validan entrada
- Manejo robusto de errores
- Logging automtico
- Auditora completa disponible

---

##  estructura de archivos por directorio

Cada subdirectorio contiene:
- `README.md` - Documentacin especfica del directorio
- Scripts `.ps1` - Implementacin
- archivos de configuración (si aplica)

---

##  Troubleshooting

### Problema: Script no ejecuta
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problema: Permisos denegados
```powershell
# Ejecutar como administrador
Start-Process powershell -Verb RunAs
```

### Problema: Mdulos faltantes
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

---

##  Documentacin Relacionada

- [scripts/README.md](../README.md) - Documentacin principal de scripts
- [docs/getting-started/STACK-SETUP.md](../../docs/getting-started/STACK-SETUP.md) - Gua de configuración
- [skills/SKILL_INDEX.md](../../skills/SKILL_INDEX.md) - ndice de habilidades

---

##  Notas

- Todos los scripts son agnsticos de plataforma
- Compatibles con PowerShell 7+
- Logging automtico en `logs/`
- Documentacin inline completa en cada script

---

**ltima actualizacin**: 2026-04-22  
**Versin**: 3.0.0  
**Estado**:  PRODUCCIN

