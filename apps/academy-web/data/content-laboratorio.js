/* Gentle-Vanguard Academy — Track "laboratorio" (8 ejercicios prácticos).
   Cada lab se ejecuta contra el stack real del repositorio gentle-vanguard.
   Formato inspirado en GENTLE_VANGUARD_MASTER/13-ACADEMY-V2/M0*-ejercicios.md:
   si no hay comando que lo verifique, no es un ejercicio. */

window.GV_CONTENT = window.GV_CONTENT || {};

window.GV_CONTENT['laboratorio'] = {
  lessons: [
    {
      id: 'lab-0-arranque-y-salud',
      title: 'Lab 0 — Arranque y salud: el stack vivo',
      minutes: 15,
      type: 'laboratorio',
      md: `## Objetivo

Dejar el stack corriendo y **probar con evidencia** que está vivo: pipeline de sesión inicializado, 97 checks de watchtower en PASS y Nexus saludable. Este lab es la puerta de todos los demás.

## Prerrequisitos

- Repositorio clonado y dependencias instaladas (\`npm install\`).
- Node.js 22+ y pnpm disponibles en el PATH.
- Estar en la raíz del repositorio (\`C:\\Workspace_local\\gentle-vanguard\` si usas la ubicación por defecto).

## Pasos

1. Arrancá el pipeline de sesión en modo no bloqueante (retorna en ~1.3 s):

\`\`\`bash
npm run session:autostart:detached
\`\`\`

2. Verificá que el pipeline dejó log. Buscá el más reciente y leé sus últimas líneas:

\`\`\`bash
ls .runtime/autostart-detached-*.log
tail -20 .runtime/autostart-detached-<timestamp>.log
\`\`\`

3. Corré el health check completo del orquestador:

\`\`\`bash
npm run watchtower:health
\`\`\`

4. Chequeá la base operacional:

\`\`\`bash
npm run db:health
\`\`\`

5. Anotá tu línea de base de consumo (la vas a usar en el Lab 3):

\`\`\`bash
npm run token:status
\`\`\`

## Resultado esperado

- El log de autostart existe y muestra los steps del pipeline (session ID, engram, security orchestrator, codegraph, token budget, watchtower autoheal, dashboard WS, pasos lazy de DB).
- Watchtower reporta **97/97 PASS** sobre 21 componentes (si el total cambió, el número canónico vive en \`docs/reference/GLOSSARY.md\`; WARN transitorios conocidos: engram reindex freshness, cloud-connectors metrics, DB locked).
- \`db:health\` responde con integridad PASS y el conteo de tablas de Nexus.
- \`token:status\` muestra usado / presupuesto (daily 5M) / porcentaje.

> Regla del set: si no hay comando que lo compruebe, no es un hecho. Guardá la salida de cada paso — es tu evidencia con fecha.

## Reto extra

Corré \`npm run watchtower:health\` dos veces seguidas y compará: ¿coincide el total? ¿Coincide el estado por componente? Clasificá cualquier diferencia (p. ej. un WARN de DB lock que desaparece) como hecho sobre variabilidad, no como "está roto".`,
    },
    {
      id: 'lab-1-navegar-codigo-sin-leer-archivos',
      title: 'Lab 1 — Navegar código sin leer archivos: graphify',
      minutes: 20,
      type: 'laboratorio',
      md: `## Objetivo

Responder preguntas de código sobre el propio repositorio **sin abrir archivos en el editor**, usando el grafo de conocimiento nativo (graphify). Es el mayor ahorro de tokens de la operación diaria: el grafo responde, el contexto no se gasta re-leyendo código.

## Prerrequisitos

- Lab 0 completado (stack vivo).
- Índice presente: verificá que exista \`graphify-out/graph.json\`. Si no existe:

\`\`\`bash
npm run graphify -- build
\`\`\`

## Pasos

1. Hacé una pregunta de código en lenguaje natural:

\`\`\`bash
npm run graphify -- query "¿quién llama al presupuesto de tokens?"
\`\`\`

2. Probá una segunda pregunta de arquitectura:

\`\`\`bash
npm run graphify -- query "¿dónde se valida la cadena hash del event sourcing?"
\`\`\`

3. De los resultados de la query, elegí un **node ID** (son rutas separadas por guiones bajos) y pedí su explicación focalizada:

\`\`\`bash
npm run graphify -- explain "<node_id>"
\`\`\`

4. Navegá ancho sin tocar fuente:

\`\`\`bash
# índice del wiki del grafo (si existe)
head -40 graphify-out/wiki/index.md
# reporte de arquitectura
head -60 graphify-out/GRAPH_REPORT.md
\`\`\`

5. Si en el camino modificaste código, refrescá el grafo:

\`\`\`bash
npm run graphify -- update .
\`\`\`

## Resultado esperado

- Cada \`query\` devuelve nodos relevantes con su ubicación — sin grep ni lectura de archivos.
- \`explain\` muestra el detalle del nodo exacto que elegiste.
- Entendiste la regla de oro: para buscar, **siempre query antes que path/explain**; \`path\` y \`affected\` son limitados (solo edges \`contains\`/\`calls\` del AST).

> GOTCHA documentado: no confundas con el paquete npm \`graphify@1.0.0\` (es un generador aleatorio de grafos, no tiene relación). El CLI correcto es \`npm run graphify -- <comando>\` local.

## Reto extra

Respondé la misma pregunta de los pasos 1–2 "a la antigua": con \`grep -rn\` y abriendo 2–3 archivos. Estimá cuántas líneas leíste y compará con la salida del grafo. Esa diferencia es tu ahorro de contexto por consulta.`,
    },
    {
      id: 'lab-2-delegar-un-code-review',
      title: 'Lab 2 — Delegar un code review',
      minutes: 20,
      type: 'laboratorio',
      md: `## Objetivo

Delegar una revisión de código al subagente adecuado y **leer el resultado**: primero ver qué agente recomienda el routing, después delegar la tarea y consumir su output.

## Prerrequisitos

- Lab 0 completado.
- Ningún cambio pendiente en tu working tree (revisá con \`git status\`) para no mezclar tu código con el review.

## Pasos

1. Pedí la recomendación de agente (sin delegar todavía):

\`\`\`bash
npx tsx src/recommend-agent.ts --task "code review del modulo secret-scanner" --topn 3
\`\`\`

2. Leé la salida: qué agente encabeza el ranking, con qué score y por qué (dominio, keywords, historial de la routing table si existe).

3. Ahora delegá la tarea completa:

\`\`\`bash
npm run delegate:run -- --task "code review del modulo src/secret-scanner.ts: hallazgos de calidad, seguridad y mantenibilidad" --topn 3
\`\`\`

4. Esperá el resultado y leelo completo. ¿Trae hallazgos concretos (archivo+línea o función)? ¿Clasifica severidad? ¿Propone siguiente paso?

5. Delegá una tarea de **otro dominio** para ver el routing cambiar:

\`\`\`bash
npm run delegate:run -- --task "audit gdpr compliance del manejo de datos del dashboard"
\`\`\`

## Resultado esperado

- El paso 1 recomienda un agente de review/quality; el paso 5 rutea a un dominio de seguridad/governance (las keywords de ciberseguridad mapean a \`gov-agent\`).
- Cada delegación devuelve un resultado legible, no solo "OK".
- El delegador aplicó el tiering del dominio (temperature por perfil de \`config/model-router.json\`).

> Nota: si un agente responde "maximum steps reached", el orquestador puede re-asignar automáticamente con +20 steps (máx 80) vía \`npx tsx src/adaptive-steps.ts --resume <agente> --task_id <id>\`.

## Reto extra

Compará los dos reviews (calidad vs. compliance): ¿qué lentes aplicó cada uno? Mapealo contra las Review Lenses (security 0.4, performance/maintainability/compliance 0.2) de la lección de verificación.`,
    },
    {
      id: 'lab-3-observar-el-consumo',
      title: 'Lab 3 — Observar el consumo de tokens',
      minutes: 20,
      type: 'laboratorio',
      md: `## Objetivo

Medir el consumo real de tokens del stack, identificar **al mayor consumidor** (orquestador vs. subagentes) y cruzar la medición con el dashboard.

## Prerrequisitos

- Lab 0 completado y algo de actividad acumulada (los labs 1–2 generan trazas).
- Ningún otro proceso del stack detenido a la fuerza.

## Pasos

1. Estado del presupuesto (usado / presupuesto / %):

\`\`\`bash
npm run token:status
\`\`\`

2. Trazabilidad por transacción y agente:

\`\`\`bash
npm run token:trace
\`\`\`

3. En la salida del trace, ubicá dos subtotales: el del **orquestador** (transacciones raíz) y el de los **subagentes** agrupados (\`parent_id\` != raíz). Anotá ambos números.

4. Levantá el dashboard completo (WS + frontend):

\`\`\`bash
npx tsx src/dashboard-start.ts
\`\`\`

5. Leé el puerto asignado y consultá la API de métricas:

\`\`\`bash
cat .runtime/dashboard-ports.json
curl http://localhost:<WS_PORT>/api/metrics
\`\`\`

(en PowerShell: \`Invoke-RestMethod http://localhost:<WS_PORT>/api/metrics\`)

6. Identificá el mayor consumidor cruzando trace + métricas: ¿un agente puntual? ¿una skill? ¿el orquestador re-leyendo contexto?

## Resultado esperado

- \`token:status\` muestra el % contra el presupuesto (daily 5M, perSession 3M en \`config/token-budget-guard.json\`).
- \`token:trace\` separa orquestador de subagentes; podés nombrar al mayor consumidor con números.
- \`/api/metrics\` responde JSON con las métricas derivadas de trazas reales — el dashboard no tiene mock data.

> Detrás: el daemon \`src/tokens/token-ingest.ts\` ingiere 4 fuentes (opencode, zcode, codex, minimax) y consolida en Nexus (\`token_usage\`, \`token_transactions\`, \`token_savings\`). Nexus es la autoridad operativa de los agregados.

## Reto extra

Repetí \`npm run token:status\` 10 minutos después (actividad de fondo incluida) y calculá el delta. Redactá 3 líneas: (1) un hecho con número, (2) una hipótesis sobre ese dato, (3) qué medirías para confirmarla. Es exactamente el formato de informe que espera el stack.`,
    },
    {
      id: 'lab-4-memoria-engram',
      title: 'Lab 4 — Memoria: guardar y recuperar en Engram',
      minutes: 20,
      type: 'laboratorio',
      md: `## Objetivo

Guardar una observación en la ==memoria persistente== (Engram), recuperarla por búsqueda semántica y **verificar que sobrevive entre sesiones** — la prueba de que el stack no arranca de cero cada vez.

## Prerrequisitos

- Lab 0 completado (Engram inicializado en el pipeline).
- Una sesión de agente con MCP engram conectado (los tools \`mem_save\`, \`mem_search\` visibles), o el CLI de engram en \`tools/\`.

## Pasos

1. Guardá una observación estructurada (el formato del stack es What/Why/Where/Learned). Pedile a tu agente:

\`\`\`text
Guardá en Engram: title "Lab 4 Academy — evidencia de memoria", type "discovery",
content: **What**: verifico persistencia de Engram desde el Lab 4.
**Why**: probar que la memoria cruza sesiones. **Where**: apps/academy-web.
**Learned**: mem_save con contenido estructurado.
\`\`\`

(Equivalente MCP: tool \`mem_save\` con esos campos.)

2. Recuperala en la misma sesión:

\`\`\`text
Buscá en Engram: "evidencia de memoria lab 4"
\`\`\`

(Equivalente MCP: \`mem_search\` con query \`"lab 4 memoria evidencia"\`.)

3. Verificá el almacenamiento físico:

\`\`\`bash
ls .engram-data/
tools/engram.exe doctor
\`\`\`

4. **La prueba de fuego:** cerrá la sesión actual, abrí una sesión nueva y repetí la búsqueda del paso 2. La observación debe aparecer con su provenance (session id de origen).

## Resultado esperado

- El paso 2 devuelve tu observación con score de match.
- \`.engram-data/\` contiene la base; \`doctor\` reporta integridad OK.
- La búsqueda en la sesión nueva encuentra el mismo registro: la memoria **persistió** entre sesiones.

> Por qué importa: sesiones que arrancan de cero repiten decisiones y gastan tokens re-explicando el proyecto. Engram convierte experiencia previa en contexto barato.

## Reto extra

Guardá una segunda observación que **contradiga** a la primera (p. ej. otro hallazgo sobre el mismo tema con conclusión distinta). Cuando el sistema lo detecte como potencial conflicto, emite un veredicto explícito (\`mem_compare\` con relación \`conflicts_with\`/\`supersedes\`/\`not_conflict\`): Engram no sobrescribe silenciosamente — los conflictos se juzgan.`,
    },
    {
      id: 'lab-5-routing-loop',
      title: 'Lab 5 — Routing loop: registrar outcomes y ver el learning',
      minutes: 25,
      type: 'laboratorio',
      md: `## Objetivo

Cerrar el ==loop de aprendizaje del routing==: correr una delegación (que registra su outcome), y ver cómo cambian los contadores de éxito en la tabla de routing — el mecanismo por el que el stack "aprende" qué agente resuelve qué.

## Prerrequisitos

- Labs 0 y 2 completados (ya viste \`recommend-agent\` y \`delegate:run\` en acción).

## Pasos

1. Mirá el estado del sistema adaptativo:

\`\`\`bash
npx tsx src/adaptive-steps.ts --status
\`\`\`

2. Anotá el baseline de recomendación para un dominio:

\`\`\`bash
npx tsx src/recommend-agent.ts --task "audit gdpr compliance" --topn 3
\`\`\`

3. Ejecutá la delegación real — \`route-and-delegate\` registra el outcome (\`recordRoutingOutcome\`) en Nexus:

\`\`\`bash
npm run delegate:run -- --task "audit gdpr compliance del dashboard: datos personales en trazas y feedback"
\`\`\`

4. Re-corré la recomendación y compará con el baseline del paso 2:

\`\`\`bash
npx tsx src/recommend-agent.ts --task "audit gdpr compliance" --topn 3
\`\`\`

5. Inspeccioná la tabla de aprendizaje:

\`\`\`bash
cat .session/routing/routing-table.json | head -50
\`\`\`

## Resultado esperado

- El paso 4 muestra el efecto del paso 3: \`success_count\` incrementado y \`success_rate\` recalculada en \`routing_rules\` (Nexus es la autoridad; \`recommend-agent\` cae a fallbacks legacy solo si Nexus no responde).
- La routing table (\`.session/routing/routing-table.json\`) refleja 17 dominios + overrides y se auto-actualiza con cada ejecución.
- Entendiste la regla de prioridad del orquestador: (1) routing table si hay historial, (2) estimación adaptativa por tarea, (3) defaults de config.

> Un solo outcome no cambia el mundo — cambia un contador. El learning es acumulativo: por eso cada delegación importa, incluso las que fallan (también se registran).

## Reto extra

Delegá la **misma tarea** tres veces e interpretá la evolución de \`success_rate\`. Después probá el mecanismo de auto-reassignment: buscá en la salida de una delegación la frase "maximum steps reached" (o simulá un agente agotado) y re-activá con \`npx tsx src/adaptive-steps.ts --resume <agente>\` — steps +20, máximo 80, contexto preservado.`,
    },
    {
      id: 'lab-6-calidad-suites-y-warning',
      title: 'Lab 6 — Calidad: correr suites y arreglar un warning',
      minutes: 25,
      type: 'laboratorio',
      md: `## Objetivo

Correr las suites de calidad del stack, **introducir un defecto a propósito**, ver cómo el guardrail lo detecta y arreglarlo — el ciclo completo detectar→corregir→verificar.

## Prerrequisitos

- Lab 0 completado.
- Working tree limpio (\`git status\` vacío) para no mezclar tu experimento con cambios reales.

## Pasos

1. Corré las suites base y anotá tiempo y resultado de cada una:

\`\`\`bash
npm run test:config       # 6 tests de configs
npm run test:workflows    # 2 tests de workflows CI
npm run typecheck
npm run lint
\`\`\`

2. Suite unit completa (si el tiempo apremia, probá primero la rápida):

\`\`\`bash
npm run test:quick
npm test
\`\`\`

3. **Introducí el defecto controlado.** En un archivo TS de prueba (p. ej. \`src/tmp-lab6.ts\`) escribí:

\`\`\`bash
const sinUso = 42;
console.log("lab6");
\`\`\`

4. Detectalo con el guardrail:

\`\`\`bash
npm run lint
\`\`\`

5. Leé el warning (variable sin usar, archivo sin efecto) y **arreglalo** (borrá \`src/tmp-lab6.ts\`):

\`\`\`bash
rm src/tmp-lab6.ts
npm run lint
\`\`\`

6. Verificá que los hooks hubieran atrapado esto antes de un commit:

\`\`\`bash
npx lefthook run pre-commit --dry-run
\`\`\`

## Resultado esperado

- Suites del paso 1 en verde (config 6/6, workflows 2/2, typecheck y lint limpios).
- El paso 4 muestra el warning señalando tu archivo temporal exacto.
- El paso 5 devuelve lint limpio; el dry-run del pre-commit lista los checks que correrían en un commit real (JSON lint, secret scanning, etc.).

> Este es el contrato del stack con sus guardrails: ellos detectan, vos corregís, y la evidencia queda en la salida del comando. Nunca uses \`--no-verify\` para esquivar el paso 4.

## Reto extra

Compará duración de \`npm run test:quick\` vs \`npm test\` y de \`npm run test:parallel -- 4\`. Después rompé a propósito un archivo JSON de configuración (agregale una coma final) y corré \`npm run test:config\` — mirá cómo la suite de configs atrapa exactamente eso (la normativa JSON prohíbe trailing commas).`,
    },
    {
      id: 'lab-7-capstone-auditoria-deuda',
      title: 'Lab 7 — Capstone: mini-auditoría de deuda técnica',
      minutes: 30,
      type: 'laboratorio',
      md: `## Objetivo

Ejecutar una ==mini-auditoría de deuda técnica== de un directorio usando el stack completo: secret scanning, análisis de código, review delegado y registro de hallazgos a prueba de manipulación. Es el capstone: combina los Labs 1–6.

## Prerrequisitos

- Labs 0 a 6 completados.
- Un directorio objetivo con código real (sugerido: \`apps/web-dashboard/server\`; válido: cualquier proyecto propio pasado como ruta).

## Pasos

1. **Barrido de seguridad** del objetivo:

\`\`\`bash
npm run scan:secrets -- --dir apps/web-dashboard/server
\`\`\`

2. **Mapa estructural** — dos queries de graphify sobre el área:

\`\`\`bash
npm run graphify -- query "websocket server: quien publica metricas"
npm run graphify -- query "database manager: migraciones y conexiones"
\`\`\`

3. **Review delegado** con foco en deuda:

\`\`\`bash
npm run delegate:run -- --task "audit tecnico de apps/web-dashboard/server: deuda tecnica, acoplamiento, manejo de errores, tests faltantes. Listar hallazgos con severidad"
\`\`\`

4. **Registrá los hallazgos en cadena hash** (uno por evento; usá el event sourcing del stack):

\`\`\`bash
npx tsx src/event-sourcing.ts -Action append -AggregateId lab7-auditoria \\
  -EventType finding.recorded -EventData '{"sev":"HIGH","title":"ejemplo hallazgo"}'
\`\`\`

5. **Verificá la cadena** de tu auditoría:

\`\`\`bash
npx tsx src/event-sourcing.ts -Action verify -AggregateId lab7-auditoria
\`\`\`

6. Cerrá con un mini-informe (10–15 líneas): 3 hallazgos con severidad, 2 quick wins, 1 acción estructural — cada uno citando el comando que lo evidenció.

## Resultado esperado

- El scanner reporta 0 secrets (exit 0) o hallazgos redactados con ubicación.
- Las queries devuelven el mapa real de llamadas del área.
- La delegación devuelve hallazgos concretos (función/archivo), no generalidades.
- \`verify\` responde cadena íntegra: tu auditoría tiene sello de tiempo y no se puede editar silenciosamente.
- El mini-informe separa hechos (con comando) de hipótesis (con métrica candidata).

> Por qué este formato: un finding en la cadena hash con severidad y evidencia es exactamente el registro que el Findings Ledger del trust-layer espera. Tu capstone produce artefactos del mismo tipo que el stack produce de sí mismo.

## Reto extra

Programá la re-auditoría: repetí este lab dentro de 30 días sobre el mismo directorio, con el mismo \`AggregateId\` (nuevos eventos se encadenan a los viejos) y compará: ¿los hallazgos HIGH siguen? ¿Los quick wins se resolvieron? Ese diff temporal es la medida honesta de si la deuda baja.`,
    },
  ],
};
