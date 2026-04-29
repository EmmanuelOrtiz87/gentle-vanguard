# Role-Based Workflows

## Overview

Workflows especializados por rol que operan sobre la topología de 5 capas, usando subagentes y skills existentes. El orquestador delega según el rol identificado.

## Roles y Mapeo a Capas

```
┌─────────────────────────────────────────────────────┐
│  Orchestrator (Layer 5 - Coordinator)               │
│  Identifica rol → Mapea capas → Delega a subagentes │
└─────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │   PM    │    │ Arquitecto│   │ Desarrollador│
    └─────────┘    └─────────┘    └─────────┘
          │               │               │
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │   QA    │    │  DevOps │    │ UX/UI   │
    └─────────┘    └─────────┘    └─────────┘
```

## Workflow: Product Manager

**Capas principales**: Layer 5 (agentes), Layer 2 (skills)

**Subagentes**: `orchestrator`, `sdd-propose`, `sdd-explore`

**Skills**: `sdd-propose`, `sdd-explore`, `sdd-onboard`, `jira-epic`, `jira-task`, `issue-creation`

**Flujo**:
1. Recibe requerimiento del usuario
2. Usa `sdd-explore` para investigar viabilidad
3. Usa `sdd-propose` para crear propuesta (intent, scope, approach)
4. Opcional: crea Jira epic/task con `jira-epic` o `jira-task`
5. Opcional: crea GitHub issue con `issue-creation`
6. Entrega propuesta validada al usuario

**Comunicación**:
- Input: Requerimiento del usuario
- Output: Propuesta SDD, Jira/GitHub artifacts
- Delegación: `task` tool con subagentes `sdd-propose`, `jira-*`

---

## Workflow: Arquitecto

**Capas principales**: Layer 5 (agentes), Layer 2 (skills), Layer 1 (memoria)

**Subagentes**: `orchestrator`, `sdd-design`, `sdd-spec`, `explore`

**Skills**: `sdd-design`, `sdd-spec`, `architecture-governance`, `project-orchestrator-skill`, `skill-creator`

**Flujo**:
1. Recibe propuesta de PM o requerimiento arquitectónico
2. Usa `sdd-design` para crear diseño técnico (decisions, approach)
3. Usa `sdd-spec` para escribir especificaciones (requirements, scenarios)
4. Consulta Engram (Layer 1) para decisiones previas
5. Usa `architecture-governance` para validar estándares
6. Entrega diseño y specs validadas

**Comunicación**:
- Input: Propuesta SDD, requerimiento técnico
- Output: Technical design, specifications, ADRs
- Delegación: `task` tool con `sdd-design`, `sdd-spec`, `explore`

---

## Workflow: Desarrollador (Frontend/Backend)

**Capas principales**: Layer 4 (comandos), Layer 3 (MCP), Layer 2 (skills)

**Subagentes**: `sdd-apply`, `sdd-tasks`, `general`, `explore`

**Skills (Frontend)**: `angular-spa-skill`, `react-19-skill`, `nextjs-15-skill`, `typescript-skill`, `tailwind-4-skill`, `zustand-5-skill`

**Skills (Backend)**: `golang-api-skill`, `django-drf-skill`, `go-api`, `database-relational-skill`, `database-nosql-skill`

**Flujo**:
1. Recibe tareas de `sdd-tasks` o diseño del Arquitecto
2. Usa `sdd-tasks` para desglose de implementación
3. Usa `sdd-apply` para implementar código siguiendo specs
4. Ejecuta comandos (Layer 4): bash, write, edit
5. Usa MCP (Layer 3) para contexto adicional si necesario
6. Ejecuta tests y linting
7. Entrega código implementado

**Comunicación**:
- Input: Task breakdown, technical design, specifications
- Output: Código implementado, tests pasando
- Delegación: `task` tool con `sdd-apply`, `sdd-tasks`, `general`

---

## Workflow: QA (Quality Assurance)

**Capas principales**: Layer 4 (comandos), Layer 2 (skills), Layer 1 (memoria)

**Subagentes**: `sdd-verify`, `general`, `explore`

**Skills**: `sdd-verify`, `testing-strategy-skill`, `pytest`, `go-testing`, `playwright`

**Flujo**:
1. Recibe código implementado del Desarrollador
2. Usa `sdd-verify` para validar contra specs/design/tasks
3. Usa `testing-strategy-skill` para identificar qué probar
4. Ejecuta tests: `pytest` (Python), `go-testing` (Go)
5. Opcional: E2E con `playwright`
6. Reporta resultados y bugs encontrados
7. Guarda patrones en Engram (Layer 1)

**Comunicación**:
- Input: Código implementado, specs, tasks
- Output: Verification report, test results, bug reports
- Delegación: `task` tool con `sdd-verify`, `general`

---

## Workflow: DevOps

**Capas principales**: Layer 4 (comandos), Layer 2 (skills), Layer 3 (MCP)

**Subagentes**: `general`, `explore`

**Skills**: `docker-devops-skill`, `workspace-automation`, `session-lifecycle`, `github-pr`, `branch-pr`

**Flujo**:
1. Configura CI/CD basado en stack detectado
2. Usa `docker-devops-skill` para containers, deployments
3. Usa `workspace-automation` para scripts de automatización
4. Usa `github-pr` o `branch-pr` para release workflow
5. Monitorea session lifecycle con `session-lifecycle`
6. Ejecuta despliegues vía comandos (Layer 4)

**Comunicación**:
- Input: Código listo para release, configuración de infraestructura
- Output: CI/CD pipelines, scripts, releases
- Delegación: `task` tool con `general`, `explore`

---

## Workflow: UX/UI

**Capas principales**: Layer 2 (skills), Layer 4 (comandos)

**Subagentes**: `general`, `explore`

**Skills**: `angular-spa-skill`, `react-19-skill`, `tailwind-4-skill`, `zustand-5-skill`, `nextjs-15-skill`

**Flujo**:
1. Recibe requirements del PM o diseño del Arquitecto
2. Usa `angular-spa-skill` o `react-19-skill` para componentes
3. Usa `tailwind-4-skill` para estilos
4. Usa `zustand-5-skill` para state management (React)
5. Implementa UI con `sdd-apply` o directamente
6. Valida accessibility y responsive design

**Comunicación**:
- Input: UI requirements, wireframes, design system
- Output: Componentes UI, estilos, state management
- Delegación: `task` tool con `general`

---

## Coordinación del Orquestador

### Identificación de Rol
El orquestador detecta el rol basado en:
1. Palabras clave del usuario ("diseña arquitectura", "implementa", "testea")
2. Estado del proyecto (propuesta existe, specs listas, código implementado)
3. Skills/disponibilidad en el workspace

### Delegación Ordenada
```
Usuario → Orchestrator (Layer 5)
           ├─ Detecta rol necesario
           ├─ Mapea a subagente + skills
           ├─ Delega con `task` tool
           ├─ Espera resultado (input/output)
           └─ Entrega resultado al usuario
```

### Mecanismos de Comunicación (Sin Cambios)
- **Delegación**: `task` tool, `delegate` tool
- **Input**: Prompt del usuario o resultado de paso anterior
- **Output**: Mensaje de retorno del subagente
- **Persistencia**: Engram (Layer 1) para state entre pasos
- **Validación**: `sdd-verify` para control de calidad

### Optimización
1. **Paralelización**: Delegar múltiples subagentes en una sola respuesta
2. **Contexto**: Usar Engram para evitar re-exploración
3. **Tokens**: `explore` subagent para investigación rápida antes de delegar
4. **Reutilización**: Skills cargados dinámicamente según contexto

## Compatibilidad

✅ No afecta mecanismos existentes:
- Misma delegación (`task`, `delegate`)
- Mismos subagentes (solo nuevos mapeos)
- Misma comunicación input/output
- Misma persistencia (Engram)
- Mismos skills (solo nuevos triggers por rol)

✅ Todo funcional y organizado:
- Cada rol tiene flujo documentado
- Orquestador sabe qué, cómo y cuándo delegar
- Trabajo ordenado y optimizado con subagentes
- Fácil agregar nuevos roles (solo documentar mapeo)
