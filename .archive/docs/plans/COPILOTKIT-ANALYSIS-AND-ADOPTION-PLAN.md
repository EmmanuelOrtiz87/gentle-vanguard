# Análisis CopilotKit → Gentle-Vanguard: Patrones para Implementación Nativa

> **Fecha:** 2026-06-04 **Contexto:** Evaluación del proyecto
> [CopilotKit](https://github.com/CopilotKit/CopilotKit) (MIT, ~32k ⭐) como fuente de inspiración
> para evolucionar Gentle-Vanguard sin incorporar dependencias externas. **Decisión:** NO integrar
> CopilotKit como dependencia. SÍ adoptar sus patrones arquitectónicos como implementación nativa
> sobre MCP.

---

## 1. Resumen Ejecutivo

CopilotKit resuelve un problema claro: **dar UI conversacional y generativa a agentes de IA**. Su
stack está diseñado para LangGraph/CrewAI + React. Gentle-Vanguard tiene su propio ecosistema (MCP +
PowerShell + 18 agentes). Forzar CopilotKit requeriría un bridge frágil que se rompería con cada
release.

**El enfoque correcto:** Extraer los patrones que CopilotKit ha validado en producción (adoptados
por Google, LangChain, AWS, Microsoft) e implementarlos nativamente sobre MCP — el protocolo que GV
ya usa.

| Patrón                                    | Valor para GV                                             | Esfuerzo Est. |
| ----------------------------------------- | --------------------------------------------------------- | ------------- |
| **AG-UI Protocol** (Generative UI tier 1) | Alto — agentes pueden renderizar componentes en dashboard | 2-3 sprints   |
| **Streaming de respuestas de agente**     | Alto — feedback visual en tiempo real                     | 1 sprint      |
| **Human-in-the-Loop UI**                  | Medio — aprobaciones visuales en dashboard                | 1-2 sprints   |
| **Agent Chat Interface**                  | Medio — interacción conversacional con agentes            | 2-3 sprints   |
| **Shared State (agente ↔ UI)**            | Medio-alto — estado sincronizado entre agentes y UI       | 2 sprints     |

---

## 2. Deep Dive: Los 5 Patrones de CopilotKit que GV Debería Adoptar

### 2.1 AG-UI Protocol (Generative UI Tier 1)

**Qué hace CopilotKit:** El AG-UI Protocol es un estándar framework-agnostic que permite a agentes
backend retornar no solo texto, sino **descripciones de UI** que el frontend renderiza como
componentes nativos. Ejemplo: un agente no dice "aquí están los datos", sino que retorna
`<DataTable columns={...} rows={...} />` como parte de su respuesta.

**Cómo funciona (simplificado):**

```
Agente → response con AG-UI payload → Frontend interpreta payload → Renderiza componente React
```

**Valor para GV:**

- Hoy los agentes de GV devuelven texto plano (o JSON crudo) al CLI
- Con AG-UI sobre MCP, los agentes podrían devolver UI components renderizables en el dashboard:
  - `MetricCard` con datos dinámicos
  - `DataTable` para resultados de queries
  - `Form` para capturar input del usuario
  - `Chart` para visualizar datos

**Implementación nativa:**

```
MCP Agent Response → JSON Schema con "ui" field → Dashboard interpreta y renderiza
```

No necesitamos el protocolo de CopilotKit. Podemos definir un schema JSON propio dentro del MCP
response estándar:

```json
{
  "content": "texto del agente...",
  "ui_hints": [
    { "type": "datatable", "columns": ["Nombre", "Estado"], "rows": [...] },
    { "type": "metric", "label": "Sesiones activas", "value": 12, "color": "green" },
    { "type": "form", "fields": [...], "action": "approve_delegation" }
  ]
}
```

El dashboard ya tiene componentes (`MetricsCard`, `SessionTable`) que podrían renderizar estos
hints.

---

### 2.2 Streaming de Respuestas de Agente (SSE + WebSocket)

**Qué hace CopilotKit:** Streaming de respuestas del agente en tiempo real usando Server-Sent
Events. El usuario ve el texto del agente aparecer carácter por carácter, y los tool calls aparecen
en vivo.

**Valor para GV:**

- El dashboard ya usa WebSocket para métricas (`useWebSocket.ts`)
- Misma infraestructura puede servir respuestas de agentes en vivo
- Experiencia: usuario delega tarea a un agente → ve el razonamiento, tool calls, y resultado en
  tiempo real

**Implementación nativa:**

- Extender WebSocket server existente (`apps/web-dashboard/server/websocket-server.ts`)
- Canal `/ws/agent/:id` para streaming de respuestas de agente
- Componente `AgentMessage` en React con soporte para streaming, tool calls, y rich content

**State actual del dashboard:** ✅ WebSocket ya implementado (`useWebSocket.ts`) ✅ Servidor
WebSocket existente en `server/websocket-server.ts` ❌ Sin canal de agentes — solo métricas

---

### 2.3 Human-in-the-Loop (HITL) UI

**Qué hace CopilotKit:** Los agentes pueden pausar su ejecución y esperar input humano antes de
continuar. En la UI se muestra un modal/form con la pregunta del agente y opciones de respuesta.

**Valor para GV:**

- GV ya tiene flujos que requieren confirmación (delegación, SDD approvals)
- Hoy eso ocurre en terminal — con HITL UI ocurre en el dashboard
- Las normativas de gobernanza (7D validation) se benefician de una UI de aprobación visual

**Implementación nativa:**

```
MCP Agent → "awaiting_input" status con payload → Dashboard muestra modal
Usuario responde → Dashboard envía respuesta vía WebSocket → Agente continúa
```

**Tipos de HITL que GV podría soportar:**

| Tipo         | Ejemplo                               | UI Component  |
| ------------ | ------------------------------------- | ------------- |
| Confirmación | "¿Aprobar delegación al agente GOV?"  | ConfirmDialog |
| Selección    | "¿Qué skill usar para esta tarea?"    | SelectList    |
| Formulario   | "Ingresa los parámetros de la task"   | Form Modal    |
| Revisión     | "Revisa el output antes de continuar" | DiffViewer    |

---

### 2.4 Shared State (Agente ↔ UI)

**Qué hace CopilotKit:** Un layer de estado compartido entre los agentes y la UI. Cuando el agente
actualiza una variable, la UI se re-renderiza automáticamente. Cuando el usuario interactúa con la
UI, el agente recibe el cambio.

**Valor para GV:**

- Estado de las 18 tareas de agentes visibles en dashboard en tiempo real
- Usuario puede tomar control de una tarea desde la UI y el agente reacciona
- Sesiones de desarrollo visibles y controlables desde dashboard

**Arquitectura propuesta:**

```
┌─────────────┐     WebSocket     ┌────────────────┐
│  Dashboard   │ ◄──────────────► │  Shared State   │
│  (React)     │                   │  (Event Bus)    │
└─────────────┘                   └───────┬────────┘
                                          │ MCP
                                   ┌──────▼────────┐
                                   │   GV Agents   │
                                   │   (18 roles)  │
                                   └───────────────┘
```

GV ya tiene `.event-bus/` en el root — esto podría ser el backbone del shared state, expuesto vía
WebSocket al dashboard.

---

### 2.5 Agent Chat Interface

**Qué hace CopilotKit:** Un componente `<CopilotChat>` que da una interfaz conversacional completa:
input, historial, streaming, tool calls visibles, suggested actions.

**Valor para GV:**

- En lugar de solo CLI, los usuarios podrían interactuar con los 18 agentes desde el dashboard
- Cada agente podría tener su propia "conversación" con contexto
- El dashboard ya tiene navegación por tabs — una nueva sección "Agent Chat" sería natural

**No replicar CopilotChat. Construir agnóstico sobre MCP:**

```
Componente AgentChat:
  - Input con soporte @mentions para seleccionar agente
  - Streaming de respuestas
  - Tool calls visibles como expandibles
  - Historial por sesión
  - Sugerencias de acciones
```

---

## 3. Oportunidades Específicas para el Stack Actual de GV

### 3.1 Dashboard ↔ MCP Bridge

GV ya tiene `scripts/mcp/skill-server.ts` (MCP protocol). El puente natural es:

```
Dashboard (React) → WebSocket → MCP Skill Server → Agente GV → Respuesta MCP → Dashboard renderiza
```

**Estado actual:**

- ✅ MCP Server existe (`scripts/mcp/skill-server.ts`)
- ✅ WebSocket infra existe (`useWebSocket.ts`, `websocket-server.ts`)
- ❌ No hay bridge entre ambos — métricas y agentes están en silos

### 3.2 Generative UI desde Skills MCP

Cada skill MCP de GV (386 skills) podría opcionalmente declarar `ui_hints` en sus respuestas. Los
skills que ya devuelven JSON estructurado son candidatos naturales:

| Skill         | Output actual | Potencial UI          |
| ------------- | ------------- | --------------------- |
| SDD/explore   | Reporte texto | Tarjetas con findings |
| system-info   | JSON sistema  | Dashboard metrics     |
| model-router  | Config JSON   | Table visual          |
| security scan | Reporte texto | Alert cards + score   |

### 3.3 Engram + Dashboard

Engram (memoria persistente) almacena decisiones, bugs, patrones. Podría exponerse vía MCP al
dashboard:

- **Timeline visual** de decisiones arquitectónicas
- **Búsqueda** en memoria desde UI
- **Contexto** de sesiones anteriores visible en dashboard

---

## 4. Matriz de Decisión: Qué Implementar y Cuándo

| #   | Patrón                                         | Valor      | Esfuerzo   | Dependencias                      | Prioridad |
| --- | ---------------------------------------------- | ---------- | ---------- | --------------------------------- | --------- |
| 1   | **Streaming de agente + bridge MCP→Dashboard** | Alto       | Medio      | WebSocket existente, MCP server   | 🥇 Alta   |
| 2   | **AG-UI Hints (ui_hints en respuestas MCP)**   | Alto       | Medio-Alto | #1 completado, schema design      | 🥇 Alta   |
| 3   | **Shared State (event-bus → dashboard)**       | Medio-Alto | Alto       | Event bus existente, schema state | 🥈 Media  |
| 4   | **HITL UI (Human-in-the-Loop)**                | Medio      | Medio      | #1 completado                     | 🥈 Media  |
| 5   | **Agent Chat Interface**                       | Medio      | Alto       | #1, #3 completados                | 🥉 Baja   |
| 6   | **Engram Timeline en Dashboard**               | Medio      | Medio      | Engram API expuesta               | 🥉 Baja   |

### Análisis de Riesgos

| Riesgo                              | Probabilidad | Impacto | Mitigación                                     |
| ----------------------------------- | ------------ | ------- | ---------------------------------------------- |
| Scope creep en dashboard            | Alta         | Medio   | Limitar a #1 y #2 en primera fase              |
| Latencia en streaming vía WebSocket | Media        | Medio   | Implementar buffer + reconnect                 |
| Complejidad de ui_hints schema      | Media        | Bajo    | Schema JSON versionado, backward compatible    |
| Desalineación con roadmap existente | Baja         | Alto    | Alinear con milestone v3.x (Web UI en roadmap) |
| Deuda técnica por apresurarse       | Media        | Medio   | Fases graduales, no reescribir dashboard       |

---

## 5. Roadmap de Implementación Sugerido

### Fase 1 (Fundación) — Estimado: 2-3 sprints

- Bridge WebSocket ↔ MCP Server
- Streaming de respuestas de agente en dashboard
- Componente `AgentMessage` con soporte streaming + rich content
- Schema `ui_hints` v1 en respuestas MCP

### Fase 2 (Interactividad) — Estimado: 2-3 sprints

- Sistema de ui_hints completo (datatable, metric, form, chart)
- HITL UI (confirmación, selección)
- Renderizado de componentes nativos desde hints

### Fase 3 (Estado Compartido) — Estimado: 2 sprints

- Shared state event-bus → WebSocket → Dashboard
- Control de tareas desde dashboard
- Timeline de sesiones visibles

### Fase 4 (Chat Experience) — Estimado: 2-3 sprints

- Agent Chat Interface con @mentions
- Historial persistente vía Engram
- Suggested actions

---

## 6. Conclusión

CopilotKit **no debe integrarse como dependencia** — el desajuste arquitectónico (LangGraph/CrewAI
vs MCP/PowerShell), el churn de 1,369 releases, y el riesgo de scope drift no lo justifican.

**Pero sus patrones son oro puro.** Han validado en producción (32 empresas Fortune 500 en su site)
que:

1. La UI generativa para agentes es el futuro de la interacción AI
2. El streaming de respuestas es table-stakes hoy
3. Human-in-the-loop con UI visual mejora la adopción
4. El estado compartido agente↔UI desbloquea flujos imposibles en terminal

GV ya tiene **60% de la infraestructura** necesaria (WebSocket, MCP, React, event-bus). Completar el
bridge es cuestión de ejecución, no de investigación.

**Próximo paso:** Decidir si arrancamos Fase 1 (bridge MCP→Dashboard + streaming) como siguiente
milestone.
