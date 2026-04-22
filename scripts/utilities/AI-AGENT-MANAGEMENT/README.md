# AI-AGENT-MANAGEMENT - Gestión de Agentes IA

Módulo centralizado para gestión, enrutamiento e invocación de agentes IA especializados.

**Versión**: 2.0.0  
**Última actualización**: 2026-04-22  
**Estado**: ✅ PRODUCCIÓN

---

## 📋 Descripción

Este directorio contiene scripts para:
- Enrutamiento inteligente de tareas a agentes especializados
- Invocación de procesos de juicio adversarial dual
- Sincronización de instrucciones de agentes
- Gestión de agentes en la nube
- Revisión de IA automatizada

---

## 🎯 Agentes Disponibles

### 1. **BA** - Business Analyst
**Especialización**: Requisitos, BDD, Criterios de Aceptación

**Habilidades**:
- bdd-scenarios-skill
- documentation-governance

**Entregables**:
- Escenarios BDD
- Criterios de aceptación
- Historias de usuario
- Trazabilidad de requisitos

---

### 2. **SAD** - Solution Architect
**Especialización**: Arquitectura, SDD, Decisiones Técnicas

**Habilidades**:
- architecture-governance
- api-design-skill
- database-relational-skill
- database-nosql-skill
- typescript-skill
- golang-api-skill
- sdd-lifecycle

**Entregables**:
- Documentos SDD
- Decisiones arquitectónicas
- Diseño de APIs
- Modelos de datos

---

### 3. **DEV** - Developer
**Especialización**: Implementación, Features, Refactoring

**Habilidades**:
- angular-spa-skill
- react-19-skill
- nextjs-15-skill
- tailwind-4-skill
- zustand-5-skill
- zod-4-skill
- security-skill
- technical-debt-skill
- typescript-skill

**Entregables**:
- Código implementado
- Features completadas
- Refactoring
- Tests unitarios

---

### 4. **QA** - Quality Assurance
**Especialización**: Testing, Validación, Automatización

**Habilidades**:
- testing-strategy-skill
- testing-skill
- playwright-skill
- pytest-skill

**Entregables**:
- Planes de testing
- Casos de prueba
- Automatización de tests
- Reportes de calidad

---

### 5. **OPS** - DevOps
**Especialización**: Despliegue, CI/CD, Infraestructura

**Habilidades**:
- docker-devops-skill
- kubernetes-deployment
- terraform-infrastructure
- git-workflow-skill
- release-management-skill

**Entregables**:
- Configuración CI/CD
- Scripts de despliegue
- Infraestructura como código
- Documentación de operaciones

---

### 6. **GOV** - Governance
**Especialización**: Cumplimiento, Observabilidad, Auditoría

**Habilidades**:
- observability-skill
- incident-response-plan
- security-skill
- code-review-orchestrator-skill

**Entregables**:
- Reportes de auditoría
- Planes de respuesta a incidentes
- Configuración de observabilidad
- Revisiones de seguridad

---

### 7. **DOC** - Documentation
**Especialización**: Especificaciones BDD/SDD, Guías, README

**Habilidades**:
- documentation-governance
- sdd-lifecycle
- bdd-scenarios-skill
- github-pr-skill

**Entregables**:
- Especificaciones
- Guías de usuario
- READMEs
- Documentación técnica

---

## 📁 Scripts

### `agent-router.ps1`
**Propósito**: Enrutador central de agentes

**Parámetros**:
```powershell
-Agent <string>          # Agente: BA, SAD, DEV, QA, OPS, GOV, DOC, status, list
-Task <string>           # Descripción de la tarea
-Action <string>         # Acción: run, plan, validate, status (default: run)
-Quiet                   # Modo silencioso
-AsJson                  # Salida JSON
```

**Uso**:
```powershell
# Enrutar tarea a DEV
.\agent-router.ps1 -Agent DEV -Task "implementar login"

# Listar agentes disponibles
.\agent-router.ps1 -Agent list

# Validar tarea antes de ejecutar
.\agent-router.ps1 -Agent SAD -Task "diseñar API" -Action validate

# Obtener estado
.\agent-router.ps1 -Agent status
```

---

### `judgment-day.ps1`
**Propósito**: Protocolo de juicio adversarial dual completo

**Características**:
- Revisión paralela (actor/critic)
- Síntesis de resultados
- Fix loop iterativo
- Escalado automático

**Parámetros**:
```powershell
-Target <string>         # Target a revisar (default: workspace)
-Scope <string>          # Full, Quick, Focused (default: Full)
-NoPrompt                # Sin prompts interactivos
-MaxPasses <int>         # Máximo de passes (default: 3)
```

**Uso**:
```powershell
# Juicio completo del workspace
.\judgment-day.ps1

# Juicio rápido de un módulo específico
.\judgment-day.ps1 -Target "projects/mi-modulo" -Scope Quick -NoPrompt

# Juicio con máximo 5 passes
.\judgment-day.ps1 -MaxPasses 5
```

---

### `invoke-judgment.ps1`
**Propósito**: Invoca proceso de juicio dual (actor/critic/fix)

**Parámetros**:
```powershell
-Target <string>         # Target a revisar
-ActorRole <string>      # Rol del actor
-CriticRole <string>     # Rol del crítico
```

**Uso**:
```powershell
.\invoke-judgment.ps1 -Target "src/components" -ActorRole DEV -CriticRole QA
```

---

### `invoke-ai-review.ps1`
**Propósito**: Invoca revisión de IA automatizada

**Uso**:
```powershell
.\invoke-ai-review.ps1 -Target "src/"
```

---

### `invoke-cloud-agent.ps1`
**Propósito**: Invoca agentes en la nube

**Uso**:
```powershell
.\invoke-cloud-agent.ps1 -Agent DEV -Task "revisar código"
```

---

### `sync-agent-instructions.ps1`
**Propósito**: Sincroniza instrucciones de agentes

**Uso**:
```powershell
.\sync-agent-instructions.ps1
```

---

## 🔄 Flujo de Trabajo Típico

### 1. Enrutar tarea a agente
```powershell
.\agent-router.ps1 -Agent DEV -Task "implementar autenticación"
```

### 2. Validar antes de ejecutar
```powershell
.\agent-router.ps1 -Agent DEV -Task "implementar autenticación" -Action validate
```

### 3. Ejecutar tarea
```powershell
.\agent-router.ps1 -Agent DEV -Task "implementar autenticación" -Action run
```

### 4. Revisar con juicio dual
```powershell
.\judgment-day.ps1 -Target "src/auth" -Scope Quick
```

---

## 📊 Protocolo de Juicio Adversarial

El protocolo de juicio adversarial dual sigue estos pasos:

1. **Revisión Paralela**: Actor y Critic revisan simultáneamente
2. **Síntesis**: Resultados se sintetizan en hallazgos
3. **Fix Loop**: Se generan fixes iterativamente
4. **Escalado**: Si no hay convergencia, se escala a nivel superior

---

## 🆘 Troubleshooting

### Problema: Agente no responde
```powershell
# Verificar estado
.\agent-router.ps1 -Agent status

# Sincronizar instrucciones
.\sync-agent-instructions.ps1
```

### Problema: Juicio no converge
```powershell
# Aumentar máximo de passes
.\judgment-day.ps1 -MaxPasses 5
```

---

## 📚 Documentación Relacionada

- [skills/judgment-day/SKILL.md](../../../skills/judgment-day/SKILL.md) - Skill de juicio adversarial
- [../README.md](../README.md) - Directorio principal de utilities
- [../../README.md](../../README.md) - Documentación principal de scripts

---

## 📝 Notas

- Todos los scripts requieren PowerShell 7+
- Logging automático en `logs/`
- Salida JSON disponible para integración
- Modo silencioso para automatización

---

**Última actualización**: 2026-04-22  
**Versión**: 2.0.0  
**Estado**: ✅ PRODUCCIÓN