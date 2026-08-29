# Gentle-Vanguard Analytics

Aplicación independiente para analizar una URL o un requerimiento y producir un informe de entrega
con evidencia de Jira, Confluence y Bitbucket cuando existe una conexión válida.

## Propósito y usuarios

| Aspecto           | Definición                                                                                       |
| ----------------- | ------------------------------------------------------------------------------------------------ |
| Propósito         | Ayudar a BA, delivery y QA a transformar contexto Atlassian en un informe estructurado.          |
| Usuarios          | Analistas de negocio, líderes técnicos, delivery managers y QA.                                  |
| Clientes objetivo | Equipos que usan Atlassian y necesitan una primera lectura trazable de alcance y esfuerzo.       |
| Resultado         | Informe con estado, solución propuesta, frentes, roles, estimaciones, QA, diagramas y evidencia. |

## Capacidades actuales

- Análisis por URL o texto libre.
- Lectura de Jira, Confluence y Bitbucket mediante credenciales configuradas; búsqueda de evidencia.
- Enriquecimiento por agente/LLM, caché, fallback o heurística, con procedencia visible en el
  informe.
- Historial local de informes, filtros, apertura y borrado individual/masivo.
- Exportación a Markdown, HTML, DOCX y PDF; si no hay Chrome, PDF puede degradar a HTML con aviso.
- Servidor MCP stdio de herramientas de lectura y análisis.
- OAuth Atlassian opcional mediante variables de entorno y vault local.

No es un sistema de planificación, estimación contractual, fuente de verdad de Jira ni sustituto de
revisión humana.

## Arquitectura

La UI está en `src/`; `server/index.ts` sirve la API y el build; `server/atlassian.ts` integra
fuentes; `server/reports.ts` y `server/metrics.ts` usan SQLite WAL en `.runtime/gentle-vanguard.db`;
`server/mcp.ts` expone el transporte MCP stdio. La integración con la arquitectura actual del stack
es local-first: Engram, Obsidian, CodeGraph y Graphify aportan memoria/conocimiento/índices al
entorno de operación; Nexus es la base operativa compartida del stack. Analytics persiste además su
tabla propia `gv_analytics_reports` en el SQLite local y no debe describirse como sincronización
automática con un vault o grafo.

## Instalación y comandos

```bash
cd apps/gv-analytics
pnpm install
pnpm dev          # UI 5174 + API 4754
pnpm dev:client
pnpm dev:server
pnpm build
pnpm typecheck
pnpm lint
pnpm preview
pnpm mcp          # servidor MCP stdio
```

La API escucha en `127.0.0.1`; cambiar el puerto con `GV_ANALYTICS_PORT`. Para PDF real puede
configurarse `GV_ANALYTICS_CHROME` según el soporte de exportación existente.

## Operación independiente

Requiere Node, pnpm y dependencias instaladas. Puede funcionar sin Dashboard, CMS o Academy. Sin
Atlassian configurado puede analizar texto con las fuentes disponibles para el fallback, pero no
puede aportar evidencia remota. Las credenciales se configuran desde la UI o el flujo OAuth; el
endpoint de prueba no las persiste.

## API, MCP e import/export

La API incluye conexión/status/test, análisis, historial, métricas, templates y OAuth; el MCP ofrece
estado, análisis, lectura de issue Jira, página Confluence, PR Bitbucket y búsqueda. Los informes se
exportan, pero no existe importación de informes ni exportación de credenciales/configuración.

## Seguridad y límites

- Servidor ligado a loopback por defecto; no exponerlo directamente a Internet.
- Tokens se muestran enmascarados; OAuth guarda tokens en el vault local según la implementación.
- El acceso a Atlassian es de lectura para las herramientas MCP documentadas.
- El informe puede usar heurísticas o LLM y siempre requiere validación humana; no garantiza
  exactitud de estimaciones ni cobertura de fuentes.
- No hay multi-tenant, RBAC comercial, colaboración, SLA, alta disponibilidad ni backup gestionado.
- La base local y sus backups son responsabilidad del operador.

## Soporte y criterios de comercialización

Soporte: reproducir con la URL/requerimiento no sensible, revisar el estado de cada servicio y
ejecutar `pnpm typecheck`/`pnpm build`; nunca adjuntar tokens. No hay SLA definido.

**Apta como herramienta interna o piloto asistido.** Para comercialización enterprise faltan
onboarding administrado, gestión multi-tenant/RBAC, retención y auditoría formal, secretos
gestionados, observabilidad operativa, controles de exactitud y soporte/SLA. No se deben prometer.
