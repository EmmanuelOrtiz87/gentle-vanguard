# ADR-0020: CodeGraph vs graphify — roles explícitos de grafos de código

Date: 2026-08-29 Status: Accepted

## Context

El stack mantiene dos grafos de código con trabajo solapado e interfaces distintas:

- **`.codegraph/`** (`codegraph.db`): índice incremental mantenido por hooks
  (post-commit/post-merge) y tarea programada horaria. Consumido por el MCP server `codegraph`
  (tooling MCP: `codegraph query/explain/path/affected`).
- **`graphify-out/graph.json`**: grafo nativo AST determinista (sin LLM) construido por
  `src/cli/graphify-build.ts` (4720 nodos / 9134 edges). Consumido por agentes vía
  `npm run graphify -- query "<pregunta>"` para búsquedas semánticas y navegación.

Ambos indexan el mismo código fuente con propósitos parecidos pero formatos, freshness y
consumidores distintos. Sin roles explícitos, el mantenimiento se duplica y las interfaces divergen
sin criterio.

## Decision

Se definen **roles explícitos y complementarios** (no se fusionan):

| Aspecto       | CodeGraph (`.codegraph/`)                        | graphify (`graphify-out/`)                                   |
| ------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| Rol           | Índice incremental post-hook para tooling MCP    | Grafo de análisis/query para agentes                         |
| Freshness     | Hooks (post-commit/post-merge) + tarea horaria   | `npm run graphify -- build` / `update .` (manual o pipeline) |
| Consumidor    | MCP server `codegraph` (herramientas del agente) | CLI `graphify` (query/explain) + wiki/GRAPH_REPORT           |
| Formato       | SQLite (`codegraph.db`)                          | JSON (`graphify-out/graph.json`)                             |
| Actualización | Incremental (solo diffs)                         | Full rebuild determinista                                    |
| Búsqueda      | `codegraph query` (edges contains/calls)         | `graphify query` (semántica, sin LLM)                        |

Reglas de operación:

1. **No duplicar mantenimiento**: los hooks y la tarea programada mantienen CodeGraph; el builder de
   graphify se ejecuta tras cambios estructurales (moves de archivos, refactors grandes) y en el
   pipeline de sesión cuando el grafo está ausente o stale.
2. **No fusionar**: graphify NO consume el índice de CodeGraph (formatos y propósitos distintos); la
   fusión se reevaluará solo si un consumidor demuestra necesidad de ambos en una sola query.
3. **Documentación**: AGENTS.md documenta ambos comandos con su rol (CodeGraph = tooling MCP,
   graphify = análisis/query de agentes).
4. **Freshness mínima**: el watchtower verifica ambos (codegraph freshness por hooks; graphify por
   existencia/edad de `graphify-out/graph.json`).

## Consequences

### Positive

- Cada grafo tiene un dueño claro (hooks/tarea vs builder/pipeline) y un consumidor definido.
- Sin ambigüedad sobre cuál usar: tooling MCP → CodeGraph; análisis/query de agente → graphify.
- El mantenimiento no se duplica; cada mecanismo cubre su ciclo de vida natural.

### Negative

- Dos formatos y dos CLIs que aprender (mitigado por la tabla de roles en AGENTS.md).
- La búsqueda semántica de graphify no aprovecha la frescura incremental de CodeGraph.

### Mitigation

- La tabla de roles se documenta en AGENTS.md (sección graphify) y en este ADR.
- Si un consumidor futuro necesita frescura incremental + query semántica, se evalúa un adaptador
  graphify→codegraph (no la fusión de formatos).
