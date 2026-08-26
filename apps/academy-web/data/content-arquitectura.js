/* Gentle-Vanguard Academy — Track "arquitectura" (10 lecciones, ES).
   Formato: window.GV_CONTENT["<track>"] = { lessons: [...] }. Markdown subset soportado por app.js. */
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT['arquitectura'] = {
  lessons: [
    {
      id: 'mapa-alto-nivel-capas',
      title: 'Mapa de alto nivel: las capas del stack',
      minutes: 9,
      type: 'curso',
      md: `## La vista de 30.000 pies

Antes de estudiar componentes individuales necesitas el mapa. Gentle-Vanguard se organiza en **seis planos funcionales** que cubren todo el ciclo de operar con agentes de IA:

| Capa | Rol | Piezas clave |
| --- | --- | --- |
| CLI / orquestación | Coordinar la sesión y las tareas | \`src/\` (pipeline, adaptive steps, delegación) |
| Datos | Persistencia operacional | ==Nexus== (SQLite WAL en \`.runtime/gentle-vanguard.db\`) |
| Memoria | Estado entre sesiones | ==Engram== (\`.engram-data/\` + MCP) |
| Grafo de código | Índice del repositorio | ==graphify / CodeGraph== (\`graphify-out/\`, \`.codegraph/\`) |
| Observabilidad | Ver lo que pasa en vivo | ==Dashboard== (WS + Vite), tracing, watchtower |
| Seguridad | Límites y evidencia | Secret scanner, RBAC v1, promotion gates, audit |

## La topología de 5 capas

Dentro de esa vista funcional, el diseño interno sigue una ==topología de 5 capas== formalizada en \`docs/architecture/layer-topology.md\`, pensada para ser agnóstica a agente, SO, herramienta y lenguaje:

1. **Memoria** — estado persistente (Engram, sesiones, observations con tipos y topic keys).
2. **Skills** — conocimiento de dominio declarativo en markdown con triggers; cualquier agente puede interpretarlas.
3. **MCP** — protocolo estándar de integración de herramientas/recursos/prompts.
4. **Comandos/Herramientas** — operaciones ejecutables: bash, archivos, web, delegación.
5. **Agentes** — los que orquestan usando las capas inferiores.

### Los principios que la sostienen

- **Interfaz sobre implementación**: cada capa define QUÉ hace, no CÓMO.
- **Componentes pluggables**: puedes cambiar Engram por otra memoria o sumar un MCP server sin tocar agentes.
- **Sin dependencias cruzadas**: cada capa solo depende de la inmediatamente inferior.
- **Agnóstico total**: sin paths de SO, nombres de agente ni lenguajes quemados en la topología central.

## Cómo fluye una sesión

El flujo real conecta todas las capas:

1. El ==autostart== arranca el pipeline (sesión, memoria, grafo, presupuesto, salud, dashboard).
2. El developer (o el orquestador) formula una tarea; el contexto se sirve del grafo y la memoria, no de lecturas a ciegas.
3. Las delegaciones generan subagentes con steps adaptativos; cada mensaje queda como transacción de tokens.
4. El dashboard refleja métricas y alertas en push cada 5s; Nexus consolida todo.
5. Al cerrar, aprendizajes y resúmenes vuelven a Engram: el ciclo se retroalimenta.

## Dónde vive cada cosa

| Directorio | Contenido |
| --- | --- |
| \`.runtime/\` | Nexus, backups, logs, puertos del dashboard |
| \`.session/\` | Checkpoints, snapshots, event store, sagas, audit, routing |
| \`.engram-data/\` | Memoria persistente |
| \`.telemetry/\` | Spans y trazas JSONL |
| \`graphify-out/\` | Grafo de código, reporte y wiki |

Esta separación no es cosmética: todo lo que es ==estado operacional== vive fuera de \`src/\`, así el código es versionable y el estado es respaldable por separado.

## En el stack

- Entrada de arquitectura: \`docs/architecture/ARCHITECTURE.md\` apunta al documento canónico \`docs/reference/ARCHITECTURE.md\`.
- Topología de capas: \`docs/architecture/layer-topology.md\`.
- Estructura de proyecto: \`docs/architecture/PROJECT-STRUCTURE.md\`.
- Vista generada del código real: \`graphify-out/GRAPH_REPORT.md\` y el wiki en \`graphify-out/wiki/index.md\`.

\`\`\`bash
npm run session:autostart:detached   # verás las capas despertando en el log
npm run graphify -- status           # estado del índice de código
\`\`\`

## Puntos clave

- Seis planos funcionales (CLI, datos, memoria, grafo, observabilidad, seguridad) y una ==topología interna de 5 capas== agnóstica.
- La regla de oro del diseño: interfaz sobre implementación, capas pluggables.
- Ninguna capa asume vendor, SO ni lenguaje: por eso el stack sobrevive a cambios de herramienta.
- El mapa mental correcto: la sesión es el hilo que cose todas las capas.`,
    },
    {
      id: 'nexus-base-de-datos-operacional',
      title: 'Nexus — la base de datos operacional',
      minutes: 10,
      type: 'curso',
      md: `## Qué es

==Nexus== es la base de datos operacional del stack: un SQLite en modo WAL con foreign keys ON, ubicado en \`.runtime/gentle-vanguard.db\`. Es el sistema nervioso central donde converge toda la información operacional: métricas, sesiones, trazas, eventos, alertas, feedback, caché de respuestas, resultados de contratos SDD, uso de skills, uso de tokens, reglas de ruteo y session scoring.

## Por qué existe

Sin Nexus, cada script escribiría su propio archivo de estado disperso, y auditar o consultar historia sería imposible. La decisión fue: **un store local, inspeccionable y respaldable** en vez de archivos sueltos o un SaaS. Todo con auto-init, auto-prune y auto-backup.

## Arquitectura interna

- **Singleton \`DatabaseManager\`** en \`apps/web-dashboard/server/database/manager.ts\`, importable desde cualquier script del stack.
- **Repositorios por dominio** encapsulan el acceso (no hay SQL regado por la codebase).
- ==27 tablas y 15 migraciones== numeradas (dato canónico del glosario); las migraciones son automáticas e idempótentes.

### Migraciones fundacionales

| Migración | Aporta |
| --- | --- |
| 001 — Core operacional | \`metric_snapshots\`, \`sessions\`, \`traces\`, \`events\`, \`alerts\`, \`feedback\` |
| 002 — Stack tables | \`response_cache\`, \`contract_results\`, \`skill_usage\`, \`token_usage\`, \`routing_rules\` |
| 003 — Session scoring | \`session_scoring\` (calidad por sesión: delegaciones, correcciones, hits proactivos) |

Migraciones posteriores amplían el esquema (por ejemplo, la 015 añade columnas de éxito al learning loop de routing). Cada tabla de dominio lleva \`tenant_id\` (ver la lección de tenancy).

## Ciclo de vida

\`\`\`bash
npm run db:init      # init + migraciones (idempotente)
npm run db:health    # integridad, WAL, tablas, filas
npm run db:backup    # backup online seguro a .runtime/backups/
npm run db:restore   # restaurar el último backup
npm run db:optimize  # WAL checkpoint + REINDEX + VACUUM
npm run db:prune     # events >30d, cache >7d, token_usage >90d
\`\`\`

### Integración con el pipeline y la watchtower

Tres steps lazy en \`config/session-autostart.config.json\` mantienen a Nexus sano sin bloquear el arranque: \`db-init\`, \`db-health-check\` y \`db-prune\`. El componente \`gentle-vanguard-db\` de la watchtower verifica en cada ciclo: existencia y tamaño del archivo, tamaño del WAL (> 5MB dispara WARN y checkpoint), integrity check y conteo de tablas/filas.

### Quién lee y quién escribe

| Componente | Relación |
| --- | --- |
| Dashboard | Lee métricas, sesiones, trazas, alertas, feedback |
| Session scoring | Escribe/lee scores de calidad |
| Adaptive router | Persiste \`routing_rules\` con hit/success counts |
| Response cache | Cacha respuestas SHA256 con TTL |
| Token budget | Almacena \`token_usage\` por sesión |
| Watchtower | Monitorea integridad, tamaño, WAL |

## En el stack

- Normativa: \`rules/NEXUS-NORMATIVA.md\` (identidad, ciclo de vida, guardrails, retención).
- Skill de gestión autónoma: \`skills/nexus-database/SKILL.md\` (se activa con triggers como nexus, db, database).
- Verificación rápida: \`npm run db:init && npm run db:health\`.

> Disciplina operacional: Nexus es la **autoridad de agregados** (tokens consolidados, scoring, routing), mientras los rollouts JSONL de las herramientas son la autoridad de uso bruto. Nunca mezclar esas jerarquías al razonar sobre cifras.

## Puntos clave

- SQLite WAL local con ==27 tablas / 15 migraciones==, singleton DatabaseManager y repos por dominio.
- Lifecycle completo de comandos \`db:*\` con retención automática (30d eventos, 7d caché, 90d tokens).
- La watchtower lo vigila en cada ciclo; el pipeline lo inicializa en cada sesión, sin bloquear.
- Un solo lugar para todos los datos operacionales: auditable, respaldable, local.`,
    },
    {
      id: 'engram-memoria-semantica',
      title: 'Engram — memoria semántica persistente',
      minutes: 9,
      type: 'curso',
      md: `## El problema de la amnesia

Cada sesión nueva parte de cero: el agente olvidó las decisiones de arquitectura de ayer, el bug que ya corregiste, el patrón que prefieres. Re-explicarlo todo cuesta tokens y tiempo, y encima se repiten errores. ==Engram== ataca exactamente eso: memoria **entre** sesiones.

## Qué guarda

Engram organiza el conocimiento en **observations** con tipo, procedencia (provenance) y sesión de origen:

| Tipo | Uso |
| --- | --- |
| bugfix | Qué se rompió, por qué, cómo se arregló |
| decision / architecture | Decisiones y trade-offs |
| discovery | Hallazgos y gotchas |
| pattern | Convenciones establecidas |
| config | Cambios de configuración |
| preference | Cómo quiere trabajar el usuario |

Además persiste ==session summaries== estructurados (goal, instructions, discoveries, accomplished, next steps) que la sesión siguiente usa como handoff.

## Las herramientas MCP

Engram se opera como servidor MCP (configurado en \`.zcode/config.json\`; datos en \`.engram-data/\`):

- \`mem_save\` — guardar observation (formato What/Why/Where/Learned).
- \`mem_search\` — búsqueda semántica/FTS por palabras clave.
- \`mem_context\` — contexto reciente de sesiones previas.
- \`mem_get_observation\` — contenido completo por ID.
- \`mem_update\` / \`mem_pin\` — actualizar o fijar observaciones.
- \`mem_doctor\` — diagnóstico operativo read-only.
- \`mem_timeline\` — línea de tiempo de observaciones.
- \`mem_suggest_topic_key\` — propone topic keys estables para upserts.
- \`mem_save_prompt\` — persiste el prompt del usuario con su intención (contexto de objetivos).
- \`mem_pin\` / \`mem_unpin\` — fija observaciones clave al inicio del contexto (estado local, no sincronizado).

## Veredictos y conflictos

Lo que distingue a Engram de una bitácora: cuando una memoria nueva choca con una vieja, ==no se sobreescribe en silencio==. El sistema emite un **judgment required** con candidatos, y se resuelve con un veredicto explícito:

| Relación | Significado |
| --- | --- |
| related | Simplemente relacionadas |
| compatible | Cohabitan sin problema |
| scoped | Válidas en scopes distintos |
| conflicts_with | Contradicción real |
| supersedes | La nueva reemplaza a la vieja |
| not_conflict | Evaluadas: no hay conflicto |

Los veredictos se persisten (\`mem_judge\` para resolver pendientes, \`mem_compare\` para registrar uno ya juzgado), formando un grafo de relaciones entre memorias. Las session summaries cierran el ciclo: \`mem_session_summary\` al final, \`mem_context\` al empezar.

### Topic keys para decisiones vivas

Las decisiones que evolucionan (arquitectura, políticas) usan ==topic_key==: upsert sobre la observación más reciente del mismo tema en vez de acumular versiones huérfanas.

## En el stack

\`\`\`bash
npm run session:autostart:detached   # el pipeline valida la integridad de engram al inicio
\`\`\`

La watchtower lo verifica (integridad de la DB, log de reindex, pipeline RAG). El protocolo de fases SDD lo usa en cada paso: recuperación paralela con \`mem_search\`, persistencia obligatoria con \`mem_save\` y topic_key para upserts.

> Práctica recomendada: guarda la decisión y su **por qué**, no solo el qué. Dentro de seis meses el por qué es lo único que no podrás reconstruir del código.

## Puntos clave

- Engram = memoria persistente con ==observations tipadas, provenance y session summaries==.
- Conflictos → veredictos explícitos (related, compatible, scoped, conflicts_with, supersedes), nunca overwrite silencioso.
- Se opera vía MCP (\`mem_*\`), se integra al pipeline de sesión y a las fases SDD.
- El costo de guardar es mínimo; el de re-aprender cada sesión, enorme.`,
    },
    {
      id: 'codegraph-graphify-indice',
      title: 'CodeGraph y graphify — el índice de código',
      minutes: 9,
      type: 'curso',
      md: `## Dos índices complementarios

La pregunta más frecuente con un agente es "¿dónde vive X y cómo funciona?". La respuesta clásica —releer archivos— quema ventana de contexto. El stack la responde con dos índices complementarios:

- ==graphify==: el grafo nativo construido por AST. Nodos archivo/función/clase/método, edges \`contains\` y \`calls\`, comunidades por label propagation. Lo construye \`src/cli/graphify-build.ts\`.
- ==CodeGraph==: el índice consultado por las herramientas, expuesto como servidor MCP con herramientas de consulta enriquecidas.

El principio de graphify: **determinista, sin LLM, sin red**. Los mismos archivos producen siempre el mismo grafo, en segundos.

## El ahorro real

Cada consulta al grafo sustituye lecturas completas de archivos. En operación diaria es ==el mayor ahorro de tokens== del stack: en vez de inyectar 2.000 líneas, inyectas el snippet exacto del símbolo relevante con su firma y sus relaciones.

## Comandos

\`\`\`bash
npm run graphify -- build    # primera vez (o si falta graphify-out/graph.json)
npm run graphify -- query "cómo funciona el budget guard de tokens"
npm run graphify -- explain <node_id>     # detalle de un nodo exacto
npm run graphify -- update .  # tras modificar código
npm run graphify -- status
\`\`\`

Reglas de uso del manual:

- Para preguntas de código, **siempre** \`query\` antes que \`path\`/\`explain\` para búsquedas.
- Los IDs de nodo usan paths underscore-separated; usa \`query\` para encontrarlos.
- \`path\` y \`affected\` son limitados: solo edges \`contains\`/\`calls\`; rutas cross-file raras sin extracción semántica de pago.
- Archivos sucios tras hooks/updates son normales: no es razón para saltarse graphify.
- Navegación amplia: \`graphify-out/wiki/index.md\`; revisión de arquitectura: \`graphify-out/GRAPH_REPORT.md\`.

## Las herramientas MCP de CodeGraph

| Herramienta | Para qué |
| --- | --- |
| \`codegraph_context\` | Contexto completo de una tarea/símbolo (search + related + código) |
| \`codegraph_explore\` | Código fuente de varios símbolos agrupado por archivo |
| \`codegraph_search\` | Búsqueda rápida de nombres |
| \`codegraph_node\` | Detalle de un símbolo |
| \`codegraph_callers\` / \`codegraph_callees\` | Quién llama a quién |
| \`codegraph_impact\` | Radio de impacto de un cambio |
| \`codegraph_files\` | Estructura de archivos del proyecto |

## Limitaciones honestas

- El ==labeling== de comunidades usa el free tier de Gemini: 20 requests/día. Un 429 obliga a esperar reset diario o configurar API key paga; el labeler real no se simula.
- Visualización de grafos grandes: fijar el límite de nodos antes de \`cluster-only\`/\`label\` (variable de entorno de viz, default 5000 nodos).
- Gotcha de ecosistema: NO instalar el paquete npm \`graphify@1.0.0\` — es un generador de grafos aleatorios sin relación. El CLI es \`npm run graphify --\` local.

## En el stack

- Datos: \`graphify-out/\` (graph.json, GRAPH_REPORT.md, wiki opcional).
- Freshness: hooks PostToolUse ejecutan \`graphify update\` tras ediciones; la sync de CodeGraph mantiene \`.codegraph/\` al día.
- CI: la watchtower verifica existencia del índice, conteo de nodos y edad.

## Puntos clave

- graphify = ==AST determinista== (build/query/explain); CodeGraph = MCP con callers/callees/impact.
- Consultar el índice antes que leer archivos es el hábito de mayor retorno en tokens.
- Limitaciones documentadas: edges sin semántica de pago, labeling con quota diaria.
- Tras editar código: \`npm run graphify -- update .\` para no consultar un grafo viejo.`,
    },
    {
      id: 'watchtower-salud-autohealing',
      title: 'Watchtower — salud y auto-healing',
      minutes: 8,
      type: 'curso',
      md: `## El guardián

==Watchtower== (\`src/core/maintenance-watchtower.ts\`) es el orquestador central de health checks, auto-healing y monitoreo continuo. Unifica en un solo punto checks que antes vivían dispersos en scripts separados (health-check, stack-health-check, watchdog). Su misión: **detectar drift y degradación antes de que se conviertan en una sesión fallida**.

## Los números

:::stats 97~checks PASS | 21~componentes vigilados | 6~modos de operación:::

- ==97 checks== distribuidos en ==21 componentes==.
- ==6 modos== de operación (ver tabla).
- Expectativa en verde: \`npm run watchtower:health\` → **97/97 PASS, 0 WARN, 0 FAIL, 0 SKIP**.

## Qué verifica (componentes representativos)

| Componente | Checks |
| --- | --- |
| dashboard-ws | API 200 OK, PID del watchdog vivo, PID del WS vivo |
| codegraph | Índice existe, conteo de nodos, edad |
| ml-embeddings | ml-index, archivos de embeddings, skill-embeddings |
| engram | Integridad de DB, log de reindex, pipeline RAG |
| mcp | Config files, bridge health y status |
| session | Directorio de sesión, manifest, config del pipeline |
| hooks | git hooks pre-commit, post-commit, post-merge |
| configs | Esquemas JSON (5 configs), validador |
| tool-configs | clinerules, cursorrules, continue config |
| security / governance | Estructura de auth, policies, directorio de reglas |
| secret-scanner | Módulo, CLI, config y tests del scanner |
| cli-guard | Patrón roto de import.meta.url (ver abajo) |
| gentle-vanguard-db | Nexus: archivo, WAL, integridad, tamaño |

## Los 6 modos

| Modo | Qué hace |
| --- | --- |
| health | 97 checks, 21 componentes |
| rebuild | health + rebuild de índices ML/RAG |
| autoheal | health + restart de procesos caídos |
| report | Exporta JSON (\`-OutputFile status.json\`) |
| continuous | Loop cada N segundos (\`-Interval 30\`) |
| all | health + autoheal + rebuild |

\`\`\`bash
npm run watchtower:health                        # verificación puntual
npx tsx src/core/maintenance-watchtower.ts -Action continuous -Interval 30
\`\`\`

## Auto-healing e integraciones

El modo \`autoheal\` corre ==lazy y en silencio al inicio de cada sesión== (step del pipeline, no bloquea). Detecta procesos caídos y los restaura. Cuando un componente sale FAIL o WARN, la watchtower puede trazar la **cadena causal** del proceso/puerto con el wrapper de ==witr== ("Why Is This Running?"), que además redacta secrets del entorno antes de reportar.

### CLI Guard: un check anti-regresión

Uno de los checks más interesantes detecta el patrón roto de entrada de CLI donde la comparación de \`import.meta.url\` contra la ruta de \`argv[1]\` no normaliza rutas de Windows y el \`main()\` nunca se ejecuta. \`src/auto-url-fix.ts\` lo corrige automáticamente; la watchtower garantiza que no regrese.

### Trazar la causa de un fallo

Cuando un componente sale WARN/FAIL, el wrapper de witr permite bajar al detalle sin salir del stack:

\`\`\`bash
npx tsx src/web/witr-cli.ts process <pid>   # cadena causal de un proceso
npx tsx src/web/witr-cli.ts port <port>     # quién ocupa un puerto y por qué
\`\`\`

Y para dejar evidencia, el modo report exporta el estado completo a JSON (\`-Action report -OutputFile status.json\`), insumo de los reportes fechados del repositorio.

## En el stack

- Fuente: \`src/core/maintenance-watchtower.ts\` (migrado de PS1 a TS; los \`npm run\` apuntan solo a la versión TS).
- La sonda del dashboard usa el endpoint público \`/api/health\` (7 componentes de infraestructura v4.0).
- Los resultados alimentan reportes y el estado canónico del repo.

> Hábito sano: trata cualquier WARN como señal, no como ruido. La watchtower existe para que el stack se cure solo, pero solo si se le hace caso cuando avisa.

## Puntos clave

- 97 checks / 21 componentes / 6 modos, con ==autoheal lazy== en cada sesión.
- Cobertura total: dashboard, grafo, memoria, MCP, sesión, hooks, configs, seguridad, Nexus.
- witr añade trazabilidad causal de procesos/puertos a los hallazgos.
- CLI Guard ejemplifica la filosofía: cada bug estructural se convierte en check permanente.`,
    },
    {
      id: 'pipeline-de-sesion',
      title: 'El pipeline de sesión: autostart y adaptive steps',
      minutes: 9,
      type: 'curso',
      md: `## El arranque

Toda sesión arranca con \`npm run session:autostart:detached\` (o la variante bloqueante \`npx tsx src/session-autostart.ts\`). Es ==obligatorio, idempotente y no pide permiso==: inicializa session ID, integridad de Engram, security orchestrator, sync de CodeGraph, token budget, session scoring, Karpathy guidelines, perfiles adaptativos, watchtower auto-heal y el dashboard WS — con los steps perezosos en background.

### Dos sabores

- **Bloqueante**: corre el pipeline completo y devuelve.
- ==Detached==: fire-and-forget que retorna en ~1.3s; el pipeline sigue en background con log por corrida en \`.runtime/autostart-detached-<timestamp>.log\` (poda automática a 7 días). Es el indicado para CI, git hooks y shells de agentes que no deben colgarse.

## Anatomía del orquestador

El orquestador (\`src/core/session-autostart.ts\`) ejecuta una secuencia determinista de steps: \~29 steps principales más \~77 ==lazy steps== que no bloquean. Decisiones de diseño verificables en el código:

- \`onStepFailure: continue\` — un step que falla no tumba la sesión; queda registrado.
- ==MAX_LAZY_CONCURRENCY = 2== — los lazy steps se lanzan en lotes de 2 para no saturar la CPU ni lanzar 56 procesos a la vez (bajarlo de 5 a 2 eliminó picos).
- **Log de auditoría de lazy steps** en \`session-autostart-lazy.log\`, con deduplicación: si el daemon de un step ya vive, no se relanza.
- Lock robusto que valida que el dueño del lock es un proceso node real: los \`conhost.exe\` huérfanos no pueden trabar el pipeline.

### Steps v4.0 notables

| Step | Script | Propósito |
| --- | --- | --- |
| tracing-init | \`src/tracing-instrument.ts\` | Spans en \`.telemetry/\`, export OTLP |
| checkpoint-auto-create | \`src/checkpoint-manager.ts\` | Checkpoint de sesión |
| audit-pipeline-init | \`src/infrastructure/audit-pipeline.ts\` | Audit logs diarios JSONL |
| event-sourcing-init | \`src/event-sourcing.ts\` | Event store |
| cloud-connectors-init | \`src/hybrid-executor.ts\` | Healthcheck de conectores (opt-in) |
| token-ingest-init | \`src/tokens/token-ingest.ts\` | Daemon de tokens en modo watch |
| post-session-learning | \`src/post-autostart-summary.ts\` | Cierre y aprendizaje |

## Adaptive steps

La otra mitad del pipeline de sesión es el presupuesto de autonomía. Cada agente tiene steps base (\`opencode.json\`), pero el sistema ==auto-escala== por complejidad de la tarea:

1. Señales del texto (\`refactor\` +12, \`explore\` +8, \`test\` +6, \`config\` +4, \`complex\` +10...).
2. Heurística de cantidad de archivos.
3. Historial de ejecuciones en la routing table (\`.session/routing/routing-table.json\`, 17 dominios + 10 overrides, success rate por agente).

\`\`\`bash
npx tsx src/adaptive-steps.ts --estimate "migrate 20 ps1 files"
npx tsx src/adaptive-steps.ts --auto "deep refactor" --agent sdd-apply
npx tsx src/adaptive-steps.ts --resume sdd-apply --task_id ses_xxx
npx tsx src/adaptive-steps.ts --status
\`\`\`

### Auto-reassignment

Cuando un subagente reporta "maximum steps reached", el orquestador detecta el evento, re-asigna con ==+20 steps (máximo 80)== y preserva el contexto para continuar desde donde quedó. La sesión no se pierde por agotamiento de presupuesto.

## En el stack

- Config de steps: \`config/session-autostart.config.json\` (fuente de verdad de qué corre y qué es lazy).
- Comandos de verificación: \`npx tsx src/adaptive-steps.ts --status\` y \`npm run watchtower:health\` (componente session).

## Puntos clave

- Autostart ==detached = CI-friendly==: ~1.3s de espera, pipeline en background, logs con retención.
- \~29 steps + \~77 lazy con concurrencia limitada y tolerancia a fallos por step.
- Adaptive steps + auto-reassignment = agentes que no mueren a mitad de tarea.
- La config del pipeline es declarativa y versionada: la sesión es reproducible.`,
    },
    {
      id: 'dashboard-observabilidad',
      title: 'Dashboard — observabilidad en tiempo real',
      minutes: 9,
      type: 'curso',
      md: `## Qué es

El dashboard es la ==UI de observabilidad LLM== del stack: una SPA React/TypeScript/Vite en \`apps/web-dashboard/\` que muestra tokens, trazas, alertas, routing y salud **en tiempo real y sin mock data** — todo deriva de trazas reales persistidas.

## Arquitectura

- **WS server** (\`server/websocket-server.ts\`): lee datos reales de \`.session/context-log/*/.state.json\` vía el pipeline \`server/real-data.ts\`, computa métricas y hace ==push cada 5s== por WebSocket. Expone REST: \`/api/metrics\`, \`/api/traces\`, \`/api/alerts\`, \`/api/feedback\`, \`/api/health\`.
- **Frontend** (Vite): 7 secciones —Executive, Operations, Development, Cost & ROI, Governance, Health, Live— con charts, waterfall de trazas y feedback thumbs up/down por span. i18n en ==en/pt-BR/es== (14 métricas × 3 idiomas).
- **Alertas**: 8 reglas en \`config/dashboard-alerts.json\`, evaluadas en el ciclo de broadcast.

## Puertos dinámicos y watchdog

- \`Get-FreePort()\` en \`src/dashboard-common.ts\` escanea +100 puertos y elige el primero libre; la elección se persiste en \`.runtime/dashboard-ports.json\` (clave para stop/restart limpios).
- El ==watchdog== (\`src/dashboard-ws-autostart.ts\`) monitorea el proceso cada 5s; si muere, lo reinicia hasta 10 veces. Su PID vive en \`.runtime/dashboard-ws-watchdog.pid\`.
- \`src/dashboard-stop.ts\` mata ==primero el watchdog== y después el WS — al revés habría restart loops.

\`\`\`bash
npx tsx src/dashboard-start.ts         # WS watchdog + Vite + Chrome
npx tsx src/dashboard-ws-autostart.ts  # solo WS (modo pipeline)
npx tsx src/dashboard-stop.ts          # parada limpia
cd apps/web-dashboard && npm run build # verificación: exit 0 sin errores TS
\`\`\`

## Resiliencia

El frontend no depende del WS para vivir: \`hooks/useMetrics.ts\` mantiene ==HTTP polling siempre activo==, así los datos cargan aunque el WS server esté caído temporalmente. El pipeline integra el arranque como step lazy \`dashboard-ws-start\` que no bloquea la sesión.

## Tenancy y caché LRU

La lectura de datos es ==tenant-aware== y está cacheada:

- \`server/cache/tenant-lru-cache.ts\` implementa una **LRU cache por tenant** (TTL 3s, menor que el intervalo de push de 5s) que absorbe las ráfagas de requests REST entre pushes — verificado en \`server/real-data.ts\`.
- La ==source provenance== clasifica el origen de cada dato: \`database\` (tenant-scoped, explícito) o \`filesystem\` (debe declarar \`system-wide\` o \`deployment-tenant\`; datos de filesystem sin tenant explícito se ==rechazan==). Implementado en \`server/dashboard-source-provenance.ts\`.

## Health API

\`/api/health\` reporta ==7 componentes== de la infraestructura v4.0: websocket, mcp, adaptive, cloud, tracing, checkpoints, audit — cada uno con status ok/unknown/degraded y métricas propias. Es la sonda que usa la watchtower para el componente dashboard-ws.

## Cuándo algo no carga

El triage documentado, en orden:

1. Verifica el WS server: consulta \`/api/health\` en el puerto asignado (está en \`.runtime/dashboard-ports.json\`).
2. Si no responde, reinicia limpio: \`dashboard-stop.ts\` y luego \`dashboard-start.ts\`.
3. Si los gráficos no renderizan, revisa la consola del navegador y la integridad de los datos.
4. Ante problemas de rendimiento, limpia la caché del Service Worker.

El frontend tolera la caída temporal del WS gracias al polling, así que "medio roto" casi siempre significa "WS caído, datos vía HTTP".

## En el stack

| Archivo | Rol |
| --- | --- |
| \`server/real-data.ts\` | Pipeline de datos (state.json → métricas) |
| \`server/websocket-server.ts\` | WS + HTTP + health |
| \`components/TracingDashboard.tsx\` | Waterfall de trazas + feedback |
| \`hooks/useMetrics.ts\` | Polling resiliente + WS |
| \`src/dashboard-start.ts\` / \`-stop.ts\` | Lifecycle completo |

## Puntos clave

- ==Sin mock data==: si el dashboard muestra un número, es medido.
- Push WS cada 5s + polling HTTP de respaldo + watchdog con 10 reintentos = resiliencia por capas.
- Puertos dinámicos persistidos y parada ordenada (watchdog primero).
- Tenancy real: LRU por tenant y provenance database/filesystem validada en el servidor.`,
    },
    {
      id: 'event-sourcing-saga-audit',
      title: 'Event sourcing, saga y audit hash-chain',
      minutes: 9,
      type: 'curso',
      md: `## Trazabilidad inmutable

Cuando un agente autónomo modifica tu repo, la pregunta incómoda es: **¿quién hizo qué y puedo demostrarlo?** El stack responde con tres piezas complementarias de la infraestructura v4.0: event sourcing con cadena de hashes, sagas para procesos largos, y un pipeline de auditoría diario.

## Event sourcing con hash-chain

\`src/event-sourcing.ts\` implementa un event store append-only en \`.session/event-store/\`. Cada evento guarda \`prevHash\` y \`hash\` (==SHA-256== del contenido + hash previo), formando una cadena a prueba de manipulación:

\`\`\`bash
npx tsx src/event-sourcing.ts -Action append -AggregateId <id> -EventType <type> -EventData '{}'
npx tsx src/event-sourcing.ts -Action verify -AggregateId <id>
npx tsx src/event-sourcing.ts -Action project -AggregateId <id>
\`\`\`

La acción \`verify\` valida la integridad de la cadena y detecta manipulación explícitamente (\`tamper-mismatch\` / \`broken\`). Cambiar un byte de un evento histórico rompe todos los hashes posteriores: la alteración no puede pasar desapercibida. El patrón fue absorbido de awesome-llm como trust-gated audit trail, con tests en \`tests/unit/event-sourcing-hashchain.test.ts\`.

### Operaciones del event store

- \`append\` — añadir evento a un agregado.
- \`project\` — reconstruir estado desde los eventos.
- \`snapshot\` — congelar estado para no reproyectar todo.
- \`prune\` — política de retención.

## Saga orchestration

Una ==saga== coordina un proceso multi-paso con compensación: si el paso 4 falla, se ejecutan las compensaciones inversas de los pasos 1-3. \`src/saga-orchestrator.ts\` opera sobre \`.session/sagas/\`:

\`\`\`bash
# create → register-step → complete/compensate → list
\`\`\`

Es el mecanismo natural para flujos con efecto lateral real (deploys, migraciones, transformaciones multi-repo) donde "retry todo" no es aceptable. Hoy es de activación ==manual== dentro del pipeline de sesión.

## Audit pipeline

\`src/infrastructure/audit-pipeline.ts\` mantiene logs de auditoría JSONL ==diarios== en \`.session/audit/logs/\`:

| Acción | Qué hace |
| --- | --- |
| log | Registra un evento de auditoría |
| status | Estado del pipeline |
| query | Busca en los logs |
| archive | Archiva logs antiguos |
| prune | Aplica retención |

Se inicializa como step lazy (\`audit-pipeline-init\`) en cada sesión y limpia su log al cierre.

## El conjunto, en contexto

Estas tres piezas no viven solas:

- El ==tracing== (\`.telemetry/\` JSONL + export OTLP) aporta la dimensión temporal de "qué pasó".
- Los ==checkpoints/snapshots== (\`.session/checkpoints/\`, \`.session/snapshots/\`) aportan "a qué estado volver": \`src/checkpoint-manager.ts\` ofrece create/list/diff/verify/prune, \`src/snapshot-manager.ts\` snapshot/list/prune, y \`src/rollback-orchestrator.ts\` restaura desde checkpoint con validación dry-run antes de tocar nada.
- El audit hash-chain aporta "qué se decidió y que no fue alterado".
- La watchtower y el dashboard consumen estos estados para salud y visibilidad.

## En el stack

\`\`\`bash
npm run watchtower:health   # componentes audit y checkpoints entre los verificados
\`\`\`

- Event store: \`src/event-sourcing.ts\` → \`.session/event-store/\`.
- Saga: \`src/saga-orchestrator.ts\` → \`.session/sagas/\`.
- Audit: \`src/infrastructure/audit-pipeline.ts\` → \`.session/audit/logs/\`.

> Caso de uso canónico: delegaste una tarea multi-paso a subagentes. La saga registra cada paso, el event store la cadena de decisiones, y el audit log deja evidencia diaria. Si algo sale mal, tienes rollback (checkpoints) y explicación (eventos), no solo un diff confuso.

## Puntos clave

- Eventos con ==prevHash + hash SHA-256==: \`verify\` detecta cualquier manipulación.
- Sagas con compensación para procesos largos; audit JSONL diario con retención.
- Todo local, en \`.session/\`, sin servicio externo.
- La tríada tracing + checkpoints + hash-chain convierte "confía en mí" en "verifícalo".`,
    },
    {
      id: 'tenancy-aislamiento-datos',
      title: 'Tenancy y aislamiento de datos',
      minutes: 8,
      type: 'curso',
      md: `## Qué es un tenant

Un ==tenant== es una frontera lógica de datos dentro de un mismo deployment. Aunque operes solo, el modelo de tenancy importa: es lo que permite pasar de "todo mezclado" a "local-multi-tenant" sin rediseño, y lo que da garantías reales de aislamiento cuando compartes el deployment.

### Por qué importa aunque trabajes solo

Tres razones prácticas: primero, el scoping temprano evita la migración dolorosa cuando aparece un segundo contexto (por ejemplo, separar datos de dos clientes en servicios); segundo, obliga a que cada dato tenga procedencia explícita, lo que mejora la auditoría incluso con un solo tenant; y tercero, las consultas tenant-scoped en SQL se prueban igual que el código — un bug de aislamiento se detecta en test, no en producción.

## Tenancy en Nexus

:::diagram tenancy:::

Todas las tablas de dominio llevan \`tenant_id\`. La regla crítica: **el scoping es en SQL**, no filtrado en memoria:

- Las lecturas filtran por tenant en el WHERE.
- Las escrituras estampan el tenant de la sesión.

El tenant local por defecto es ==gentle-vanguard==, controlado por la variable \`GENTLE_TENANT_ID\`. Nada de datos de dominio existe "sin tenant".

## Source provenance del dashboard

El dashboard no acepta datos de origen ambiguo. Cada fuente se clasifica (\`apps/web-dashboard/server/dashboard-source-provenance.ts\`):

| Procedencia | Regla |
| --- | --- |
| database | Tenant-scoped, explícito en la consulta |
| filesystem | Debe declarar system-wide o deployment-tenant |

Un dato de filesystem "propiedad del tenant" ==sin tenantId explícito se rechaza==. Esta validación en el servidor evita el leak más común en sistemas multi-tenant: datos de archivo que nadie reclama y todos leen.

## RBAC v1

El modelo de roles del dashboard (\`apps/web-dashboard/server/{auth,rbac}.ts\`):

| Rol | Puede |
| --- | --- |
| viewer | Leer (\`viewer.read\`) |
| operator | Leer + mutar (\`operator.write\`) |
| admin | Todo + \`/api/admin/*\` |

Detalles de la implementación:

- Sesiones ==opacas, respaldadas en SQLite==, protegidas con CSRF double-submit.
- El primer principal que arranca se convierte en ==admin== (bootstrap).
- El bypass de localhost solo se permite habilitado explícitamente y con host y remote address en loopback; nunca es identidad productiva.
- La membresía de tenant es la frontera de autorización donde aplica tenant-scoping.

## Los límites honestos (ADR-0017)

- La autenticación es ==deployment-scoped==: sesiones, principales, membresías, roles y secrets viven en el deployment local.
- ==No reclama OIDC/LDAP/SSO==: son federación futura opt-in.
- El perfil \`local-multi-tenant\` (varios tenants en un deployment local) es opt-in; \`server-promotion\` y \`saas-federated\` requieren inputs externos y gates de promoción antes de llamarse empresariales.

### Promotion gates

Para deployment externo, los gates bloqueantes (operador-owned): digests de imagen fijados, firma Cosign, evidencia CNI/NetworkPolicy, evidencia de sandbox para MCP (\`src/ci/deployment-prerequisites.ts\`). En modo local los mismos checks son informativos (exit 0); con \`--promotion\` son bloqueantes. Los inputs faltantes ==nunca se fabrican==.

## En el stack

\`\`\`bash
npm run db:health    # el conteo de tablas/filas refleja el esquema tenant-aware
\`\`\`

- Glosario: entradas Tenant, Source provenance, RBAC v1, Promotion gates en \`docs/reference/GLOSSARY.md\`.
- ADR: \`docs/adr/ADR-0017-local-first-operating-model.md\` (perfiles y reglas de autenticación).
- Dashboard admin: \`docs/security/DASHBOARD-ADMIN-STATUS.md\`.

## Puntos clave

- \`tenant_id\` en todas las tablas de dominio, scoping ==en SQL==, default \`gentle-vanguard\`.
- Provenance database/filesystem validada en el servidor: sin tenant explícito, el dato se rechaza.
- RBAC v1 con sesiones opacas, CSRF double-submit y bootstrap admin del primer principal.
- Multi-tenant local es opt-in; enterprise identity es frontera explícita, no promesa implícita.`,
    },
    {
      id: 'tokens-pipeline-tracking',
      title: 'Tokens: el pipeline de tracking real',
      minutes: 9,
      type: 'curso',
      md: `## Medición agnóstica

El presupuesto de tokens del stack no se estima ni se simula: se ==lee del disco lo que cada herramienta ya persistió==. El daemon \`src/tokens/token-ingest.ts\` ingiere las fuentes y consolida todo en Nexus, sin depender de plugins de opencode/claude/cursor.

## Las 4 fuentes

| Herramienta | De dónde se lee |
| --- | --- |
| opencode | SQLite \`~/.local/share/opencode/opencode.db\` (tablas session y message) |
| zcode | Rollouts JSONL bajo \`~/.zcode/\` |
| codex | Sesiones bajo \`~/.codex/sessions/\` |
| minimax | \`~/.minimax/v2/sqlite/runtime-state.sqlite\`, tabla \`local_runtime_token_usage\` |

El registry \`detectSources()\` es extensible (históricamente opencode/codex/claude/cursor), así que sumar una herramienta nueva es registrar una fuente, no reescribir el pipeline.

## Las tres tablas de Nexus

- ==token_usage== — por sesión (agregado).
- ==token_transactions== — por mensaje: input/output/reasoning/cache, cost, model, y el agente responsable (orquestador como parent ROOT vs subagentes con parent distinto).
- ==token_savings== — ahorros: cache reads + compresión del stack (prompt/output/structural).

## La jerarquía de autoridades

Punto clave para no confundirse con las cifras:

1. Los ==rollouts JSONL de cada herramienta== son la autoridad de **uso bruto** cuando la herramienta los produce (zcode, codex).
2. ==Nexus== es la autoridad de **agregados y transacciones ingeridas** (\`token_usage\`, \`token_transactions\`, \`token_savings\`).
3. \`src/tokens/token-usage-reader.ts\` es el lector único: Nexus primero, luego el reporte live (\`reports/stack-live-observability-latest.json\`) y fallbacks explícitos.
4. Snapshots heredados (\`.session/token-usage.json\`, \`.session/session-current.json\`) existen para consumidores legacy: ==no reemplazan== ninguna autoridad.

## Comandos y ciclo de vida

\`\`\`bash
npm run token:ingest   # una pasada
npm run token:trace    # trazabilidad: transacciones por agente y ahorros
npm run token:status   # presupuesto real: usado / presupuesto / %
\`\`\`

El lazy step \`token-ingest-init\` arranca el daemon en modo \`--watch 30\` con la sesión y captura en vivo hasta el cierre.

## Presupuestos

Fuente única: \`config/token-budget-guard.json\` — ==daily 5M, perSession 3M==, alineado con \`model-router.json\`. El budget guard vigila contra esos valores; el exceso se alerta (reglas del dashboard) antes que sea una sorpresa de facturación.

## Trazabilidad disponible

- **Por transacción**: qué mensaje, qué modelo, qué costo, qué agente.
- **Por sesión**: agregados en \`token_usage\`.
- **Por agente**: orquestador vs subagentes, agrupados e individuales — clave para descubrir qué subagente quema el presupuesto.
- **Ahorros**: cache reads y compresión — la contrapartida que justifica las optimizaciones del stack.

## En el stack

- Daemon: \`src/tokens/token-ingest.ts\`; lectores: \`token-usage-reader.ts\`, \`token-metrics-store.ts\` (el close report lee tokens REALES de Nexus y sus derivados).
- Verificación: \`npm run token:status\` tras una sesión con trabajo real.
- La watchtower monitorea el componente de presupuesto; el dashboard grafica uso vs presupuesto en las secciones Executive y Cost & ROI.

> Disciplina de lectura: si alguien cita una cifra de tokens, pregúnta de qué autoridad viene (rollout bruto, agregado Nexus o snapshot legacy). El stack está diseñado para que esa pregunta tenga respuesta única.

## Puntos clave

- Ingesta agnóstica de ==4 fuentes reales== (opencode, zcode, codex, minimax) consolidadas en Nexus.
- Tres tablas: usage (sesión), transactions (mensaje+agente), savings (cache+compresión).
- Jerarquía clara: rollouts = uso bruto; Nexus = agregados; snapshots legacy = compatibilidad.
- Presupuestos centralizados (5M/3M) con vigilancia y alertas — el costo deja de ser invisible.`,
    },
  ],
};
