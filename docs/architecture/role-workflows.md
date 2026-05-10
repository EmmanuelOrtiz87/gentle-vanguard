# Role-Based Workflows

## Overview

Workflows especializados por rol que operan sobre la topologa de 5 capas, usando subagentes y skills
existentes. El orquestador delega segn el rol identificado.

## Roles y Mapeo a Capas

```

  Orchestrator (Layer 5 - Coordinator)
  Identifica rol  Mapea capas  Delega a subagentes





       PM         Arquitecto    Desarrollador



       QA          DevOps      UX/UI

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

**Comunicacin**:

- Input: Requerimiento del usuario
- Output: Propuesta SDD, Jira/GitHub artifacts
- Delegacin: `task` tool con subagentes `sdd-propose`, `jira-*`

---

## Workflow: Arquitecto

**Capas principales**: Layer 5 (agentes), Layer 2 (skills), Layer 1 (memoria)

**Subagentes**: `orchestrator`, `sdd-design`, `sdd-spec`, `explore`

**Skills**: `sdd-design`, `sdd-spec`, `architecture-governance`, `project-orchestrator-skill`,
`skill-creator`

**Flujo**:

1. Recibe propuesta de PM o requerimiento arquitectnico
2. Usa `sdd-design` para crear diseo tcnico (decisións, approach)
3. Usa `sdd-spec` para escribir especificaciones (requirements, scenarios)
4. Consulta Engram (Layer 1) para decisiónes previas
5. Usa `architecture-governance` para validar estndares
6. Entrega diseo y specs validadas

**Comunicacin**:

- Input: Propuesta SDD, requerimiento tcnico
- Output: Technical design, specifications, ADRs
- Delegacin: `task` tool con `sdd-design`, `sdd-spec`, `explore`

---

## Workflow: Desarrollador (Frontend/Backend)

**Capas principales**: Layer 4 (comandos), Layer 3 (MCP), Layer 2 (skills)

**Subagentes**: `sdd-apply`, `sdd-tasks`, `general`, `explore`

**Skills (Frontend)**: `angular-spa-skill`, `react-19-skill`, `nextjs-15-skill`, `typescript-skill`,
`tailwind-4-skill`, `zustand-5-skill`

**Skills (Backend)**: `golang-api-skill`, `django-drf-skill`, `go-api`, `database-relational-skill`,
`database-nosql-skill`

**Flujo**:

1. Recibe tareas de `sdd-tasks` o diseo del Arquitecto
2. Usa `sdd-tasks` para desglose de implementacin
3. Usa `sdd-apply` para implementar cdigo siguiendo specs
4. Ejecuta comandos (Layer 4): bash, write, edit
5. Usa MCP (Layer 3) para contexto adicional si necesario
6. Ejecuta tests y linting
7. Entrega cdigo implementado

**Comunicacin**:

- Input: Task breakdown, technical design, specifications
- Output: Cdigo implementado, tests pasando
- Delegacin: `task` tool con `sdd-apply`, `sdd-tasks`, `general`

---

## Workflow: QA (Quality Assurance)

**Capas principales**: Layer 4 (comandos), Layer 2 (skills), Layer 1 (memoria)

**Subagentes**: `sdd-verify`, `general`, `explore`

**Skills**: `sdd-verify`, `testing-strategy-skill`, `pytest`, `go-testing`, `playwright`

**Flujo**:

1. Recibe cdigo implementado del Desarrollador
2. Usa `sdd-verify` para validar contra specs/design/tasks
3. Usa `testing-strategy-skill` para identificar qu probar
4. Ejecuta tests: `pytest` (Python), `go-testing` (Go)
5. Opcional: E2E con `playwright`
6. Reporta resultados y bugs encontrados
7. Guarda patrones en Engram (Layer 1)

**Comunicacin**:

- Input: Cdigo implementado, specs, tasks
- Output: Verification report, test results, bug reports
- Delegacin: `task` tool con `sdd-verify`, `general`

---

## Workflow: DevOps

**Capas principales**: Layer 4 (comandos), Layer 2 (skills), Layer 3 (MCP)

**Subagentes**: `general`, `explore`

**Skills**: `docker-devops-skill`, `workspace-automation`, `session-lifecycle`, `github-pr`,
`branch-pr`

**Flujo**:

1. Configura CI/CD basado en stack detectado
2. Usa `docker-devops-skill` para containers, deployments
3. Usa `workspace-automation` para scripts de automatización
4. Usa `github-pr` o `branch-pr` para release workflow
5. Monitorea session lifecycle con `session-lifecycle`
6. Ejecuta despliegues va comandos (Layer 4)

**Comunicacin**:

- Input: Cdigo listo para release, configuración de infraestructura
- Output: CI/CD pipelines, scripts, releases
- Delegacin: `task` tool con `general`, `explore`

---

## Workflow: UX/UI

**Capas principales**: Layer 2 (skills), Layer 4 (comandos)

**Subagentes**: `general`, `explore`

**Skills**: `angular-spa-skill`, `react-19-skill`, `tailwind-4-skill`, `zustand-5-skill`,
`nextjs-15-skill`

**Flujo**:

1. Recibe requirements del PM o diseo del Arquitecto
2. Usa `angular-spa-skill` o `react-19-skill` para componentes
3. Usa `tailwind-4-skill` para estilos
4. Usa `zustand-5-skill` para state management (React)
5. Implementa UI con `sdd-apply` o directamente
6. Valida accessibility y responsive design

**Comunicacin**:

- Input: UI requirements, wireframes, design system
- Output: Componentes UI, estilos, state management
- Delegacin: `task` tool con `general`

---

## Coordinacin del Orquestador

### Identificacin de Rol

El orquestador detecta el rol basado en:

1. Palabras clave del usuario ("disea arquitectura", "implementa", "testea")
2. Estado del proyecto (propuesta existe, specs listas, cdigo implementado)
3. Skills/disponibilidad en el workspace

### Delegacin Ordenada

```
Usuario  Orchestrator (Layer 5)
            Detecta rol necesario
            Mapea a subagente + skills
            Delega con `task` tool
            Espera resultado (input/output)
            Entrega resultado al usuario
```

### Mecanismos de Comunicacin (Sin Cambios)

- **Delegacin**: `task` tool, `delegate` tool
- **Input**: Prompt del usuario o resultado de paso anterior
- **Output**: Mensaje de retorno del subagente
- **Persistencia**: Engram (Layer 1) para state entre pasos
- **Validacin**: `sdd-verify` para control de calidad

### Optimizacin

1. **Paralelizacin**: Delegar mltiples subagentes en una sola respuesta
2. **Contexto**: Usar Engram para evitar re-exploracin
3. **Tokens**: `explore` subagent para investigacin rpida antes de delegar
4. **Reutilizacin**: Skills cargados dinmicamente segn contexto

## Compatibilidad

No afecta mecanismos existentes:

- Misma delegacin (`task`, `delegate`)
- Mismos subagentes (solo nuevos mapeos)
- Misma comunicacin input/output
- Misma persistencia (Engram)
- Mismos skills (solo nuevos triggers por rol)

Todo funcional y organizado:

- Cada rol tiene flujo documentado
- Orquestador sabe qu, cmo y cundo delegar
- Trabajo ordenado y optimizado con subagentes
- Fcil agregar nuevos roles (solo documentar mapeo)
