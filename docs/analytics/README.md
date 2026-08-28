# Gentle-Vanguard Analytics

Aplicacion independiente para analizar iniciativas y evidencia de la suite Atlassian usando el stack
Gentle-Vanguard.

## Objetivo

Gentle-Vanguard Analytics debe recibir una URL o pedido de Jira, Confluence o Bitbucket y producir
una lectura completa de estado actual, solucion propuesta, impacto tecnico, frentes involucrados,
roles, complejidad, estimacion, escenarios QA, evidencia enlazada, diagramas y exportables.

## Decision inicial

- La app vive en `apps/gv-analytics`, independiente del dashboard.
- Reutiliza patrones del stack: MCP, model router, agentes BA/SAD/DEV/QA/DOC, Nexus y Graphify.
- El dashboard puede observarla en el futuro, pero no es dependencia de ejecucion.
- El primer login soporta API token read-only; OAuth 2.0 queda como evolucion de producto.
- Los secretos se guardan fuera del repo en `.runtime/gv-analytics/` con cifrado local AES-GCM.

## Capacidades del primer corte

- UI independiente en React/Vite.
- API local propia en `server/index.ts`.
- Formulario de conexion Atlassian.
- Verificacion read-only de Jira, Confluence y Bitbucket.
- Analisis inicial por URL o texto.
- Reporte estructurado con frentes, roles, complejidad, estimacion, QA, diagramas y evidencia.

## Siguientes slices

1. MCP Atlassian read-only con herramientas para Jira, Confluence y Bitbucket.
2. Enriquecimiento real del analisis desde issue, paginas, repos, PRs y diffs.
3. Persistencia de conexiones, evidencia y reportes en Nexus.
4. Pipeline de agentes via `route-and-delegate` y `config/model-router.json`.
5. Exportacion PDF/DOCX.
6. OAuth 2.0 con callback local.
