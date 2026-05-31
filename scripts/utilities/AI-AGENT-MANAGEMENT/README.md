# AI-AGENT-MANAGEMENT - Gestin de Agentes IA

Mdulo centralizado para gestin, enrutamiento e invocacin de agentes IA especializados.

**Versin**: 2.0.0  
**ltima actualizacin**: 2026-04-22  
**Estado**: PRODUCCIN

---

## Descripcin

Este directorio contiene scripts para:

- Enrutamiento inteligente de tareas a agentes especializados
- Invocacin de procesos de juicio adversarial dual
- Sincronizacin de instrucciones de agentes
- Gestin de agentes en la nube
- revisión de IA automatizada

---

## Agentes Disponibles

### 1. **BA** - Business Analyst

**Especializacin**: Requisitos, BDD, Criterios de aceptación

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

**Especializacin**: Arquitectura, SDD, decisiónes Tcnicas

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
- decisiónes arquitectnicas
- Diseo de APIs
- Modelos de datos

---

### 3. **DEV** - Developer

**Especializacin**: Implementacin, Features, Refactoring

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

- Cdigo implementado
- Features completadas
- Refactoring
- Tests unitarios

---

### 4. **QA** - Quality Assurance

**Especializacin**: Testing, Validacin, automatización

**Habilidades**:

- testing-strategy-skill
- testing-skill
- playwright-skill
- pytest-skill

**Entregables**:

- Planes de testing
- Casos de prueba
- automatización de tests
- Reportes de calidad

---

### 5. **OPS** - DevOps

**Especializacin**: Despliegue, CI/CD, Infraestructura

**Habilidades**:

- docker-devops-skill
- kubernetes-deployment
- terraform-infrastructure
- git-workflow-skill
- release-management-skill

**Entregables**:

- configuración CI/CD
- Scripts de despliegue
- Infraestructura como cdigo
- Documentacin de operaciónes

---

### 6. **GOV** - Governance

**Especializacin**: Cumplimiento, Observabilidad, Auditora

**Habilidades**:

- observability-skill
- incident-response-plan
- security-skill
- code-review-orchestrator-skill

**Entregables**:

- Reportes de auditora
- Planes de respuesta a incidentes
- configuración de observabilidad
- Revisiones de seguridad

---

### 7. **DOC** - Documentation

**Especializacin**: Especificaciones BDD/SDD, Guas, README

**Habilidades**:

- documentation-governance
- sdd-lifecycle
- bdd-scenarios-skill
- github-pr-skill

**Entregables**:

- Especificaciones
- Guas de usuario
- READMEs
- Documentacin tcnica

---

## Scripts

### `agent-router.ps1`

**Propsito**: Enrutador central de agentes

**Parmetros**:

```powershell
-Agent <string>          # Agente: BA, SAD, DEV, QA, OPS, GOV, DOC, status, list
-Task <string>           # Descripcin de la tarea
-Action <string>         # Accin: run, plan, validate, status (default: run)
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
.\agent-router.ps1 -Agent SAD -Task "disear API" -Action validate

# Obtener estado
.\agent-router.ps1 -Agent status
```

---

### `judgment-day.ps1`

**Propsito**: Protocolo de juicio adversarial dual completo

**Caractersticas**:

- revisión paralela (actor/critic)
- Sntesis de resultados
- Fix loop iterativo
- Escalado automtico

**Parmetros**:

```powershell
-Target <string>         # Target a revisar (default: workspace)
-Scope <string>          # Full, Quick, Focused (default: Full)
-NoPrompt                # Sin prompts interactivos
-MaxPasses <int>         # Mximo de passes (default: 3)
```

**Uso**:

```powershell
# Juicio completo del workspace
.\judgment-day.ps1

# Juicio rpido de un mdulo especfico
.\judgment-day.ps1 -Target "projects/mi-modulo" -Scope Quick -NoPrompt

# Juicio con mximo 5 passes
.\judgment-day.ps1 -MaxPasses 5
```

---

### `invoke-judgment.ps1`

**Propsito**: Invoca proceso de juicio dual (actor/critic/fix)

**Parmetros**:

```powershell
-Target <string>         # Target a revisar
-ActorRole <string>      # Rol del actor
-CriticRole <string>     # Rol del crtico
```

**Uso**:

```powershell
.\invoke-judgment.ps1 -Target "src/components" -ActorRole DEV -CriticRole QA
```

---

### `invoke-ai-review.ps1`

**Propsito**: Invoca revisión de IA automatizada

**Uso**:

```powershell
.\invoke-ai-review.ps1 -Target "src/"
```

---

### `invoke-cloud-agent.ps1`

**Propsito**: Invoca agentes en la nube

**Uso**:

```powershell
.\invoke-cloud-agent.ps1 -Agent DEV -Task "revisar cdigo"
```

---

### `sync-agent-instructions.ps1`

**Propsito**: Sincroniza instrucciones de agentes

**Uso**:

```powershell
.\sync-agent-instructions.ps1
```

---

## Flujo de Trabajo Tpico

### 1. Enrutar tarea a agente

```powershell
.\agent-router.ps1 -Agent DEV -Task "implementar autenticacin"
```

### 2. Validar antes de ejecutar

```powershell
.\agent-router.ps1 -Agent DEV -Task "implementar autenticacin" -Action validate
```

### 3. Ejecutar tarea

```powershell
.\agent-router.ps1 -Agent DEV -Task "implementar autenticacin" -Action run
```

### 4. Revisar con juicio dual

```powershell
.\judgment-day.ps1 -Target "src/auth" -Scope Quick
```

---

## Protocolo de Juicio Adversarial

El protocolo de juicio adversarial dual sigue estos pasos:

1. **revisión Paralela**: Actor y Critic revisan simultneamente
2. **Sntesis**: Resultados se sintetizan en hallazgos
3. **Fix Loop**: Se generan fixes iterativamente
4. **Escalado**: Si no hay convergencia, se escala a nivel superior

---

## Troubleshooting

### Problema: Agente no responde

```powershell
# Verificar estado
.\agent-router.ps1 -Agent status

# Sincronizar instrucciones
.\sync-agent-instructions.ps1
```

### Problema: Juicio no converge

```powershell
# Aumentar mximo de passes
.\judgment-day.ps1 -MaxPasses 5
```

---

## Documentacin Relacionada

- [skills/judgment-day/SKILL.md](../../../skills/judgment-day/SKILL.md) - Skill de juicio
  adversarial
- [docs/README.md](../docs/README.md) - Directorio principal de utilities
- [../../README.md](../../README.md) - Documentacin principal de scripts

---

## Notas

- Todos los scripts requieren PowerShell 7+
- Logging automtico en `logs/`
- Salida JSON disponible para integracin
- Modo silencioso para automatización

---

**ltima actualizacin**: 2026-04-22  
**Versin**: 2.0.0  
**Estado**: PRODUCCIN
