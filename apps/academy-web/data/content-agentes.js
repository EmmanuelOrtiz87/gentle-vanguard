/* Gentle-Vanguard Academy — Track "agentes" (10 lecciones).
 * Contenido educativo basado en cifras reales del stack (AGENTS.md, docs/reference/, config/).
 * Sin dependencias: define window.GV_CONTENT["agentes"].
 */
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT['agentes'] = {
  lessons: [
    {
      id: 'los-21-subagentes',
      title: 'Los 21 subagentes del stack: quién hace qué',
      minutes: 10,
      type: 'curso',
      md: `## Por qué dividir un agente en veintiuno

Un orquestador monolítico que "sabe de todo" paga dos precios: carga skills que no usa en cada turno y arrastra contexto acumulado. La arquitectura de subagentes del stack ataca ambos: ==21 subagentes especializados== viven en \`.opencode/agents/\`, cada uno con contexto acotado y skills propias. La arquitectura de referencia documentó el resultado: ~60% de ahorro frente al orquestador monolítico (~20K vs ~50K tokens por sesión).

## El mapa por dominios

**Ciclo SDD (Spec-Driven Development)** — el corazón del desarrollo:

| Agente | Rol | Steps base |
| --- | --- | --- |
| \`sdd-explore\` | Explorar/analizar el problema (fase BA) | 38 |
| \`sdd-design\` | Diseñar la solución (fase SAD) | 30 |
| \`sdd-apply\` | Implementar código (fase DEV) | ==52== |
| \`sdd-verify\` | Verificar y validar (fase QA) | 36 |

\`sdd-apply\` tiene el presupuesto de pasos más alto porque escribir código es la tarea más larga; su presupuesto de tokens es 2000-6000.

**Operaciones y ciclo de vida**: \`ops-agent\` (deploys, 30 steps), \`maintenance-agent\` (mantenimiento, 30), \`session-agent\` (estado de sesión, 25), \`gitflow-agent\` (branch/PR/merge/hooks/conflictos — el stack registra siete códigos GITFLOW-\* que despachan todos a este agente).

**Gobernanza y riesgo**: \`gov-agent\` (auditoría, seguridad, compliance — 38 steps), \`legal-agent\` (cumplimiento normativo), \`premortem-agent\` (análisis de riesgos antes de que ocurran), \`self-diag-agent\` (auto-diagnóstico del propio stack, 38 steps).

**Negocio**: \`finance-agent\`, \`mkt-agent\`, \`sales-agent\`, \`hr-agent\` — los agentes de dominio de negocio, con tiering premium/balanced según criticidad.

**Analítica y conocimiento**: \`bus-tele-agent\` (telemetría de negocio), \`sia-agent\` (refinamiento iterativo, 35 steps), \`knowledge-agent\` (base de conocimiento), \`doc-agent\` (documentación, 34 steps).

**El coordinador**: \`orchestrator\` — construye el grafo de ejecución, parte el trabajo en lanes, delega en paralelo, fusiona resultados. Es deliberadamente **slim** (~24 steps, presupuesto de 2000-4500 tokens): su trabajo es decidir, no ejecutar.

## Contratos, no conversaciones

Cada lane debe devolver un **output contract** estructurado: \`lane_id\`, \`status\` (success/failed/blocked/partial), \`files_touched\`, \`findings_or_changes\` (máximo 8 bullets), \`validation_result\`, \`next_action\`, más campos opcionales como \`confidence_score\` (0-100) y \`token_estimate\`. Fusionar JSON compacto cuesta una fracción de re-leer prosa narrativa.

## Políticas de ejecución en paralelo

- Máximo de lanes según riesgo: ==low 4 / medium 3 / high 2==.
- Timeout por lane: 8 minutos; retry: 1 para fallos transitorios.
- Stop duro ante hallazgos críticos de seguridad.
- Ninguna lane pushea a remoto: solo el coordinador aprueba la publicación final.

Los 21 archivos se sincronizan a las herramientas externas con \`npx tsx src/zcode-sync.ts --sync\` (copia a \`~/.zcode/agents/\`), y el mapeo completo de códigos de agente (29 códigos como BA, SAD, DEV, QA, GITFLOW-PR... que despachan a estos 21) vive en \`config/subagent-mapping.json\`.

> La regla de oro del diseño: minimizar contexto por subagente usando **task packets** acotados (1.5k-2.5k caracteres: objetivo, archivos, símbolos, checks de aceptación). El historial completo de chat nunca viaja al subagente.

## En el stack

\`\`\`bash
npx tsx src/adaptive-steps.ts --status              # steps configurados por agente
npx tsx src/recommend-agent.ts --task "code review" --topn 3
cat config/subagent-mapping.json                    # mapeo código → subagente
\`\`\`

## Puntos clave

- 21 subagentes en 6 grupos funcionales (SDD, ops, gobernanza, negocio, analítica, orquestación) con presupuesto de steps/tokens propio.
- \`sdd-apply\` es el más dotado (52 steps); el orquestador es deliberadamente slim.
- Output contracts JSON + packets de 1.5-2.5k caracteres = merge barato y contexto acotado (~60% de ahorro vs monolítico).
- Paralelismo limitado por riesgo (4/3/2 lanes) y stop duro en seguridad.
- Los 21 se sincronizan multi-tool con \`zcode-sync.ts --sync\`.`,
    },
    {
      id: 'delegacion-route-and-delegate',
      title: 'Delegación: cómo una tarea llega al agente correcto',
      minutes: 9,
      type: 'curso',
      md: `## El problema del "¿quién debería hacer esto?"

En un stack con 21 subagentes, la primera decisión no es *cómo* ejecutar sino **a quién** enviarle la tarea. Mandar "auditar cumplimiento GDPR" al agente de marketing no es solo ineficiente: produce un resultado confiadamente mediocre. La pieza central del stack es \`src/route-and-delegate.ts\` — el **route-and-delegate** que recomienda el agente nativo adecuado y delega con el tiering de modelo aplicado.

## El flujo, paso a paso

1. **Recepción**: la tarea entra como texto libre (\`--task "build a revenue forecast"\`).
2. **Recomendación**: internamente usa \`recommend-agent.ts\`, que combina un STATIC_MAP de dominios, keywords negocio-primero y —si existe— la routing table aprendida (ver lección 5).
3. **Tiering**: antes de delegar, inyecta \`AGENT_TEMPERATURE\` según el dominio del tier (\`config/model-router.json\`): finance/legal/gov reciben temperatura 0.1; marketing/sales 0.25; gitflow/ops/session 0.15.
4. **Delegación**: lanza el subagente recomendado con el contexto provisto, de forma cross-platform (\`npx.cmd\` en Windows, \`shellQuote\` en Unix — el detalle que evita que un comando funcione en un OS y reviente en el otro).
5. **Reporte**: el resultado de validación se persiste (\`reports/delegation-validation-report.md\`).

## El paquete de tarea: qué viaja y qué no

La arquitectura de subagentes fija el presupuesto del paquete en ==1.5k-2.5k caracteres==, con cuatro contenido obligatorios:

- **Objetivo**: una frase de qué hay que lograr.
- **Archivos**: la lista de archivos a tocar (no su contenido).
- **Símbolos requeridos**: las funciones/clases involucradas.
- **Checks de aceptación**: cómo saber que está done.

Lo que **nunca** viaja: el historial completo de la conversación. El estado entre batches se transfiere con artefactos \`context-pack\`, no con transcripciones. Y el subagente devuelve su output contract JSON (máx. 8 bullets de hallazgos) — el coordinador fusiona estructuras, no ensayos.

## El mismo patrón, versión cloud (opt-in)

Para promoción externa existe la variante de conectores cloud (\`src/hybrid-executor.ts\`, \`src/agent-delegator.ts\`): routing por costo/latencia/carga con fallback automático y **circuit breaker** — 5 fallos consecutivos abren el circuito (OPEN), 2 éxitos lo pasan a HALF_OPEN y de ahí a CLOSED. Es opt-in: el modelo local-first no lo requiere.

## Cuándo delegar y cuándo hacer directo

Delega cuando: la tarea es de un dominio claro con agente especializado, quieres paralelizar lanes independientes, o el orquestador ya acumula contexto (el subagente nace limpio). Hazlo directo cuando: la tarea es puramente mecánica ("corre este comando", el Skill Resolver Protocol exime esas de inyección de skills), es una microdecisión que cuesta más enmarcar que resolver, o depende de contexto conversacional íntimo que no cabe en un packet de 2.5k caracteres.

> La delegación tiene costo fijo: preparar el packet, lanzar el subagente, fusionar el resultado. Si el trabajo cabe en 2-3 pasos directos, el overhead no se paga.

## En el stack

\`\`\`bash
npm run delegate:run -- --task "audit gdpr compliance"
npm run delegate:run -- --task "build a revenue forecast" --context "..." --topn 3
npx tsx src/recommend-agent.ts --task "code review" --topn 3   # solo recomendar, sin delegar
\`\`\`

## Puntos clave

- \`route-and-delegate\` = recomendar agente (STATIC_MAP + keywords + routing table) + delegar con temperatura del tier del dominio.
- El packet viaja liviano (1.5-2.5k caracteres: objetivo, archivos, símbolos, aceptación); el historial jamás.
- Output contract JSON de vuelta: merge estructurado, no narrativa.
- Cross-platform desde el diseño (\`npx.cmd\` vs \`shellQuote\`).
- Delegar tiene costo fijo: tareas de 2-3 pasos van directo.`,
    },
    {
      id: 'adaptive-steps',
      title: 'Adaptive steps: escalado de complejidad y re-asignación automática',
      minutes: 8,
      type: 'curso',
      md: `## El problema: el agente que se queda sin pasos a mitad de tarea

Un "step" es una unidad de acción de un agente (una llamada a herramienta, un razonamiento, un ciclo). La configuración original daba a los subagentes ==6 steps== fijos. El síntoma era recurrente: en tareas complejas, el agente reportaba \`maximum steps reached\` y la tarea quedaba a mitad de camino — ni fallada ni terminada. Aumentar los steps para todos era tirar tokens en tareas simples.

La solución: **adaptive steps** (\`src/adaptive-steps.ts\`), un sistema que auto-escala el presupuesto de pasos según la tarea real.

## Las cuatro señales de estimación

1. **Tipo de agente** — capacidad base del rol (\`sdd-apply\` parte de 52; \`session-agent\` de 25).
2. **Señales de texto** — palabras que anticipan carga:

| Señal en la tarea | Steps extra |
| --- | --- |
| files, refactor, migrate, implement, feature, module | +12 |
| complex, large, big, deep, nested, integrate | +10 |
| explore, investigate, research, audit, analyze, parallel | +8 |
| test, verify, validate, typecheck, lint | +6 |
| config, doc, readme, guide, schema | +4 |

3. **Cantidad de archivos** — heurística de tamaño del problema.
4. **Historial de ejecuciones** — learning data acumulado en \`.session/routing/routing-table.json\`.

## La prioridad de asignación

Cuando el orquestador delega, resuelve los steps en este orden:

\`\`\`text
1. routing-table.json   (si hay historial del dominio)
2. adaptive-steps --auto (estimación por señal de la tarea)
3. opencode.json defaults (fallback estático)
\`\`\`

El historial manda sobre la heurística, y la heurística manda sobre el default: el sistema aprende de lo que ya corrió.

## Auto-reasignación: el mecanismo estrella

Cuando un agente reporta ==maximum steps reached==, el orquestador no abandona la tarea:

1. **Detecta** el evento en la respuesta del agente.
2. **Re-asigna** automáticamente con \`adaptive-steps.ts --resume\`.
3. **Incrementa** el presupuesto en ==+20 steps, con tope de 80==.
4. **Preserva** el contexto y continúa desde donde quedó.

La combinación de detección + reanudación convierte un tipo de fallo frecuente en un detalle operativo: la tarea sigue, el presupuesto se ajusta, nadie rehace trabajo.

## Los números del sistema

La configuración vigente por agente: orquestador 24, \`sdd-explore\` 38, \`sdd-design\` 30, \`sdd-apply\` ==52==, \`sdd-verify\` 36, \`doc-agent\` 34, \`ops-agent\` 30, \`gov-agent\` 38, \`session-agent\` 25, \`premortem-agent\` 30, \`maintenance-agent\` 30, \`self-diag-agent\` 38, \`sia-agent\` 35. El presupuesto de tokens acompaña (p. ej. orquestador 2000-4500 tokens, \`sdd-apply\` 2000-6000 en el budget guard).

## En el stack

\`\`\`bash
npx tsx src/adaptive-steps.ts --estimate "fix broken ps1 refs in 20 files"
npx tsx src/adaptive-steps.ts --auto "complex refactoring task" --agent sdd-apply
npx tsx src/adaptive-steps.ts --resume sdd-apply --task_id ses_xxx
npx tsx src/adaptive-steps.ts --status
\`\`\`

## Puntos clave

- Steps fijos (6) mataban tareas complejas; steps uniformemente altos queman tokens.
- Estimación por 4 señales: agente, texto de la tarea, archivos, historial — con esta prioridad: historial > heurística > default.
- \`maximum steps reached\` se maneja solo: re-asignación +20 (tope 80) preservando contexto.
- \`sdd-apply\` (52) y \`sdd-explore\`/\`gov-agent\`/\`self-diag-agent\` (38) son los mejor dotados; \`session-agent\` (25) el más austero.
- \`--status\` para auditar la configuración, \`--estimate\` para probar hipótesis de carga antes de delegar.`,
    },
    {
      id: 'routing-learning-loop',
      title: 'El routing learning loop: outcomes reales en Nexus (migración 015)',
      minutes: 9,
      type: 'curso',
      md: `## Recomendar por reglas está bien; recomendar por resultados es mejor

Un router basado solo en keywords y árboles de decisión tiene techo: no sabe que el agente A resolvió 12 de 13 tareas de un dominio y el agente B solo 3 de 10. El **routing learning loop** cierra ese ciclo: cada delegación registra su **outcome** (éxito/fallo) en Nexus, y las recomendaciones futuras priorizan los agentes con mejores resultados medidos.

## El dato: la tabla routing_rules

:::diagram routing-loop:::

Nexus persiste las reglas de ruteo en \`routing_rules\` con columnas de telemetría de outcomes:

| Columna | Significado |
| --- | --- |
| \`tenant_id\` | Aislamiento multi-inquilino (default: gentle-vanguard) |
| \`pattern\` / \`target\` | Patrón de tarea → agente destino |
| \`hit_count\` | Veces que la regla se usó |
| \`success_count\` | Usos que terminaron en éxito |
| \`success_rate\` | ==success_count \* 100.0 / hit_count== |

## La migración 015: \`015_routing_outcome_metrics\`

La migración hace dos cosas concretas en la base:

1. **Backfill del success rate** para las filas existentes:

\`\`\`sql
UPDATE routing_rules
SET success_rate = CASE WHEN hit_count > 0
  THEN success_count * 100.0 / hit_count ELSE 0 END;
\`\`\`

2. **Índice de consulta por desempeño**:

\`\`\`sql
CREATE INDEX idx_routing_rules_tenant_success
  ON routing_rules(tenant_id, enabled, success_rate DESC, hit_count DESC);
\`\`\`

Ese índice expresa la política en su propio orden de columnas: ==por tenant, solo habilitadas, primero por success_rate, desempate por hit_count==. Un agente con 100% en 2 usos no supera a uno con 92% en 200 — el volumen de evidencia desempata.

La migración además es **defensiva**: antes de aplicar, verifica con \`pragma_table_info\` si \`success_count\`/\`success_rate\` ya existen como columnas y las agrega con \`ALTER TABLE\` solo si faltan — idempotente en bases parcialmente migradas.

## Cómo se registran los outcomes

El repositorio (\`SkillRepo\`) registra el resultado de cada uso con un UPDATE que incrementa y recalcula en una sola operación:

\`\`\`sql
success_rate = (success_count + ?) * 100.0 / (hit_count + 1)
\`\`\`

El increment ocurre transaccionalmente con el hit: no hay ventana donde el rate quede desincronizado de sus contadores.

## Cómo consume recommend-agent

\`src/recommend-agent.ts\` lee la routing table aprendida (\`.session/routing/routing-table.json\`, actualizada desde los outcomes) antes que su STATIC_MAP. Cada \`domainEntry\` guarda: \`bestAgent\`, \`alternatives\` (con \`successRate\` por agente), \`avgSuccessRate\`, \`confidence\`, \`totalAttempts\` y \`lastRouted\`. Con \`--topn 3\` ves los tres candidatos rankeados — y por qué.

> El detalle honesto: en un stack recién instalado la tabla está fría (\`totalAttempts: 0\`, confianza base 0.7) y el STATIC_MAP hace el trabajo. El loop de aprendizaje no reemplaza el cold-start: lo mejora con el uso.

## Por qué por tenant

El éxito de un agente no es universal: el "code review" de un tenant de fintech (con compliance pesado) puede preferir \`gov-agent\` mientras uno de marketing prefiere \`sdd-verify\`. Scope por tenant = cada inquilino aprende su propia distribución sin contaminar la del vecino.

## En el stack

\`\`\`bash
npm run db:init    # aplica migraciones pendientes (incl. 015 si falta)
npm run db:health  # verificación de tablas/índices
npx tsx src/recommend-agent.ts --task "security audit" --topn 3
\`\`\`

## Puntos clave

- \`routing_rules\` guarda hit_count, success_count y success_rate por tenant: el outcome es un dato de primera clase.
- Migración 015 = backfill del rate + índice \`(tenant_id, enabled, success_rate DESC, hit_count DESC)\`: la política de prioridad vive en el índice.
- El registro recalcula el rate transaccionalmente con cada uso.
- recommend-agent prioriza la tabla aprendida sobre el STATIC_MAP; el cold-start usa el mapa.
- Scope por tenant: cada inquilino aprende su propio mejor agente.`,
    },
    {
      id: 'auto-delegacion-ml',
      title: 'Auto-delegación: routing table aprendible y scoring de confianza',
      minutes: 10,
      type: 'curso',
      md: `## De keywords a aprendizaje: la escalera de la delegación automática

La auto-delegación del stack es un sistema de enrutamiento de tareas a subagentes que sube por tres peldaños de inteligencia: reglas → heurística estructurada → aprendizaje por outcomes. La implementación de referencia (\`docs/reference/AUTO-DELEGATION-IMPLEMENTATION.md\`) documenta el recorrido completo.

## Peldaño 1: extracción de keywords

El motor extrae palabras clave de la descripción de la tarea y las mapea a agentes — ==más de 200 keywords== para los 29 códigos de agente en \`config/auto-delegation.json\`:

- **BA**: requirement, user story, bdd, gherkin, acceptance, specification
- **DEV**: implement, code, develop, feature, refactor, bug fix
- **QA**: test, testing, validation, e2e, unit test, playwright, pytest
- **OPS**: deploy, ci/cd, docker, kubernetes, infrastructure, terraform

## Peldaño 2: árbol de decisión de 4 niveles

Sobre las keywords, el árbol añade contexto:

1. **Nivel 1** — agente primario por dominio.
2. **Nivel 2** — agente secundario si la coincidencia supera 60%.
3. **Nivel 3** — ajustes por riesgo (riesgo alto ⇒ incluir QA).
4. **Nivel 4** — dependencias (deploy/release ⇒ incluir OPS).

## Peldaño 3: scoring de confianza

La puntuación final combina coincidencias con ajustes dinámicos: base de 15 por coincidencia (tope 100), ==+10== multi-agente, ==+15== agente único claro, ==+5== objetivo claro, ==-15== si el ruteo es ambiguo (más de 3 agentes empatados). Niveles: High ≥80, Medium ≥60, Low ≥40, Very Low <40. Si la puntuación no supera el **umbral de confianza (default 60%)**, el sistema no delega a ciegas: marca \`LowConfidence\` y pide decisión manual — el ejemplo canónico es la tarea "Fix the thing" (score 25).

El control es **opt-in**: disabled por defecto, con \`confidenceThreshold\` configurable (recomendado 50 para desarrollo permisivo, 75 para producción conservadora).

## La routing table aprendible: 17 dominios

Sobre esa base, \`.session/routing/routing-table.json\` mantiene el aprendizaje: ==17 dominios pre-configurados== (requirements, architecture, implementation, testing, docs, ops, security...) más ==10 overrides de alta prioridad== (security audit, code review, bug fix...). Cada entrada registra \`bestAgent\`, alternativas con success rate, confianza y total de intentos, y se actualiza con cada ejecución. El STATIC_MAP de \`recommend-agent.ts\` aporta el cold-start por dominio — del code-review (\`sdd-verify\` primero) al finance (\`finance-agent\`), pasando por los 8 dominios de negocio.

\`\`\`text
Prioridad de resolución en cada delegación:
1. routing-table.json (historial aprendido)
2. adaptive-steps --auto (estimación heurística)
3. opencode.json defaults (fallback)
\`\`\`

## Métricas del router

\`Get-RoutingMetrics\` expone: total de ruteos, ruteos exitosos, ruteos de baja confianza, score promedio y distribución por agente. Las métricas de delegación se persisten con topic_key \`metrics/subagent-delegation\`, y las mejoradas añaden: **delegación accuracy** (qué tan seguido se eligió el subagente correcto), **fallback rate** (cuánto se usó el agente general), **calibración de confianza** (correlación score vs éxito real).

> La ruta de madurez documentada ("Mejoras Futuras") es explícita: ML a partir de decisiones históricas, feedback loop con correcciones del usuario, umbrales dinámicos. El sistema actual aprende outcomes reales en Nexus (lección anterior) — el "ML" de hoy es estadística de éxito por agente, y está cableada.

## En el stack

\`\`\`bash
npx tsx src/recommend-agent.ts --task "audit gdpr compliance" --topn 3
npx tsx src/adaptive-steps.ts --status
npm run delegate:run -- --task "code review" --topn 3
\`\`\`

## Puntos clave

- Tres capas: keywords (200+) → árbol de decisión (4 niveles) → aprendizaje por outcomes (routing table 17 dominios + 10 overrides).
- Confianza con ajustes simétricos (+15 claro, -15 ambiguo); bajo el umbral 60% manda a decisión manual, no adivina.
- Opt-in por defecto: disabled; umbral 50 dev / 75 prod.
- La routing table se auto-actualiza con cada ejecución y alimenta \`recommend-agent\`.
- "Fix the thing" (score 25) es el test mental honesto: si tu tarea no supera al árbol, descríbela mejor.`,
    },
    {
      id: 'mcp-model-context-protocol',
      title: 'MCP: Model Context Protocol y los servers locales del stack',
      minutes: 8,
      type: 'curso',
      md: `## El problema que resuelve MCP

Un agente de código necesita capacidades fuera del modelo: buscar en una base de conocimiento, leer archivos, consultar un grafo de código. Históricamente cada herramienta de agente definía sus propias integraciones — escribir un conector para ZCode no servía para Codex ni para Claude. **Model Context Protocol (MCP)** estandariza eso: un protocolo abierto por el que un **server** expone herramientas (**tools**) que cualquier **client** compatible puede invocar. Las herramientas aparecen con el prefijo del server (p. ej. \`mcp__codegraph__codegraph_query\`), el modelo decide cuándo usarlas y el protocola transporta la llamada.

La analogía útil: MCP es a las capacidades del agente lo que LSP fue a los editores — un contrato común que rompe el lock-in de integraciones propietarias.

## Los servers locales del stack

La configuración de ZCode (\`.zcode/config.json\`, sección \`mcp.servers\`) registra los servers MCP locales del stack:

| Server | Qué expone |
| --- | --- |
| ==codegraph== | Consultas al grafo de conocimiento del código (context/\`query\`/\`node\`) — la vía estructurada de responder preguntas de código |
| ==engram== | Memoria persistente: búsqueda de observaciones, contexto de sesiones previas |
| ==filesystem== | Operaciones de archivos y directorios dentro de los allow-list |
| ==memory== | Knowledge graph de entidades y relaciones |
| ==chrome-devtools== | Control de navegador para pruebas de frontend |

El punto clave del modelo **local-first** del stack: estos servers corren en la máquina, contra datos locales (el grafo AST, la memoria, los archivos) — sin round-trips a servicios externos para consultar lo que ya tienes en disco.

## Operación y salud

MCP es infraestructura, y la watchtower lo verifica en cada ciclo como componente propio: ==3 archivos de config, bridge health y bridge status==. Un server MCP que no conecta se traduce en herramientas que no aparecen; el síntoma visible para el usuario es "el agente no encuentra la herramienta X", y el diagnóstico pasa por el health del componente MCP antes que por el modelo.

Reglas operativas que evitan confusiones comunes:

1. Los cambios de config MCP **requieren nueva sesión** en la herramienta — no hay hot-reload.
2. El nombre completo de la herramienta incluye el server: si no aparece \`mcp__<server>__<tool>\`, el server no cargó.
3. Un server puede estar configurado pero deshabilitado o fallido: config presente ≠ server operativo (por eso el health check existe).

> Patrón de diseño que se repite: exponer como herramienta MCP la **consulta** a un artefacto local pre-computado (el grafo), no un acceso crudo a los archivos. El server hace el trabajo barato (buscar en el índice) y el modelo recibe solo el resultado relevante — la misma economía de tokens del índice local, ahora disponible para cualquier cliente MCP.

## En el stack

\`\`\`bash
npm run watchtower:health   # el ciclo incluye el componente MCP (configs + bridge)
cat .zcode/config.json      # servers registrados: codegraph, engram, chrome-devtools, filesystem, memory
\`\`\`

## Puntos clave

- MCP estandariza cómo un server expone herramientas a cualquier cliente: escribir una vez, usar en todas las herramientas compatibles.
- El stack corre 5 servers locales (codegraph, engram, filesystem, memory, chrome-devtools) sobre datos propios de la máquina.
- Los cambios de config exigen nueva sesión; herramienta ausente = server que no cargó.
- La watchtower verifica el componente MCP (3 configs + bridge health/status) en cada ciclo.
- El patrón ganador: exponer consultas a índices locales pre-computados, no acceso crudo a archivos.`,
    },
    {
      id: 'skills-auto-trigger',
      title: 'Skills: auto-trigger, presupuesto de metadata y las 12 críticas',
      minutes: 9,
      type: 'curso',
      md: `## Qué es una skill

Una **skill** es un paquete de instrucciones especializadas que se inyecta en el agente cuando la tarea la necesita: un \`SKILL.md\` con frontmatter (\`name\`, \`description\`) más archivos de soporte (plantillas, ejemplos). No es código que corre: es conocimiento de procedimiento que el modelo carga bajo demanda. El stack tiene ==~120 skills== disponibles entre \`.opencode/skills/\` (nivel 1) y \`skills/\` (stack).

## El auto-trigger: la description es el contrato

Las skills se activan **automáticamente** cuando la descripción de la tarea coincide con la \`description\` del frontmatter. Eso convierte a la description en la pieza más importante del diseño: una description vaga hace que la skill nunca se dispare; una inflada la dispara fuera de lugar. La práctica externa de 2026 (agentskills.io, "Optimizing Skill Descriptions") es explícita: ==las descriptions dirigen el triggering automático y deben probarse y ajustarse sistemáticamente==. El stack añade un límite material: la description debe caber en ==1024 caracteres== para compatibilidad con ZCode/Codex.

## El presupuesto de metadata: por qué NO copiar todas

Aquí está la lección contraintuitiva del stack. ZCode asigna un **presupuesto fijo de metadata compartida** — un excerpt de ==250 caracteres por skill== — para decidir el auto-trigger. Si registras 120 skills, el presupuesto se agota y ==el auto-trigger de TODAS se degrada==. La decisión documentada en \`src/zcode-sync.ts\`:

> NO copiar todas (~120). Se sincronizan solo las ==12 skills críticas== para uso diario.

La lista exacta: \`sdd-lifecycle\`, \`nexus-database\`, \`karpathy-guidelines\`, \`token-budget-tracking-skill\`, \`code-review-and-quality\`, \`debugging-and-error-recovery\`, \`test-driven-development\`, \`planning-and-task-breakdown\`, \`context-engineering\`, \`web-research\`, \`diagram-design\` y \`security-and-hardening\`. Estas van a las tres herramientas (\`~/.zcode/skills/\`, \`~/.codex/skills/\`, \`~/.minimax/agents/mavis/skills/\`); el resto queda en el repo, disponible para carga manual o el protocolo de resolución.

## Skill Resolver Protocol: inyectar compacto, no caminos

Cuando un orquestador delega a un subagente, este nace sin saber qué skills existen. El **Skill Resolver Protocol** lo resuelve sin quemar contexto:

1. Obtener el registro (cache de sesión → Engram → archivo del proyecto).
2. Matchear skills por **contexto de código** (extensiones: \`.tsx\` → React) y **contexto de tarea** (acciones: "crear PR" → skill de PR).
3. Inyectar las **Compact Rules** pre-digeridas (5-15 líneas por skill): ==50-150 tokens por skill==, ~400-600 tokens en una delegación típica de 3-4 skills.
4. Tope: si matchean más de ==5 skills==, solo las 5 más relevantes (prioriza código sobre tarea).

La regla fina: se inyecta el **texto** de las reglas, no rutas a archivos — el subagente no debe leer ningún SKILL.md. Y hay feedback loop: el subagente reporta \`injected\` / \`fallback-registry\` / \`fallback-path\` / \`none\`; si no reporta \`injected\`, el orquestador debe recargar el registro y avisar del cache miss.

## Separación intencional: dos skills de seguridad

El diseño de skills del stack evita falsos duplicados: \`security-skill\` (para DEV, checks inline durante la implementación) y \`security-expert-skill\` (para GOV, auditorías completas pre-release) comparten dominio pero difieren en **agente objetivo, profundidad y fase** — por eso existen ambas. Duplicado real es: mismos triggers, mismo formato de salida, distinto nombre solamente.

## En el stack

\`\`\`bash
npx tsx src/zcode-sync.ts --sync             # 21 agentes + 12 skills críticas a 3 tools
npx tsx src/zcode-sync.ts --sync --tools zcode,codex   # filtrar destinos
\`\`\`

## Puntos clave

- Las skills son conocimiento de procedimiento inyectado bajo demanda; las activa la description (contrato de trigger, ≤1024 chars).
- El presupuesto de metadata (excerpt de 250 chars/skill en ZCode) castiga el exceso: más skills registradas = peor trigger para todas.
- 12 críticas se sincronizan a 3 herramientas; las ~108 restantes se quedan para carga dirigida.
- Skill Resolver: compact rules de 50-150 tokens por skill, máximo 5, texto inyectado (nunca rutas), con feedback loop anti-degradación.
- Dos skills del mismo dominio no son duplicato si cambia agente, profundidad o fase.`,
    },
    {
      id: 'plugins-y-multi-tool',
      title: 'Plugins y compatibilidad multi-tool: sync, hooks y commands',
      minutes: 9,
      type: 'curso',
      md: `## Un stack, tres herramientas de agente

Gentle-Vanguard no vive en una sola herramienta: sus agentes y skills se usan desde ==ZCode, Codex y MiniMax Code==. El desafío es que cada herramienta tiene sus convenciones — directorios distintos, formatos con matices, mecanismos propios de extensión. La estrategia es un **sync único** más un contrato de plugins estándar.

## El sync multi-tool

\`npx tsx src/zcode-sync.ts --sync\` es la fuente única de distribución:

- **Agentes**: los 21 archivos de \`.opencode/agents/\` se copian a \`~/.zcode/agents/\`.
- **Skills críticas** (12): a \`~/.zcode/skills/\`, \`~/.codex/skills/\` y \`~/.minimax/agents/mavis/skills/\` (MiniMax usa el framework pi-agent, con skills por agente — mavis es el orquestador). Filtrables con \`--tools zcode,codex,minimax\`.
- **Normalización de frontmatter**: el sync garantiza \`name\`+\`description\` en el frontmatter (description ≤1024 chars) que ZCode/Codex exigen.

**Regla operativa que ahorra horas**: los cambios requieren ==nueva sesión en cada herramienta== — no hay hot-reload. Editaste una skill y no ves el cambio? Reinicia la sesión.

Para las instrucciones de contexto, el enfoque es complementario: Codex y MiniMax leen \`AGENTS.md\` **nativamente** (es el estándar del ecosistema), por eso el repo mantiene una versión slim de bajo contexto con el manual completo bajo demanda.

## Hooks: reaccionar a eventos de la herramienta

La integración más fina son los **hooks** configurados en \`~/.zcode/cli/config.json\`:

- **SessionStart**: dispara el autostart del stack (con guard por repo — no corre en cualquier directorio).
- **PostToolUse** (Write|Edit): tras cada edición de archivo, actualiza el grafo (\`npm run graphify -- update .\`) — el índice se mantiene fresco sin que nadie lo pida.

Los scripts viven en \`src/zcode-hooks/\`: la lógica es del stack, el hook solo es el disparador.

## Commands: el slash como interfaz

Los comandos de ZCode (\`.zcode/commands/\`) exponen el stack como slash-commands: ==/graphify, /token-status, /db-health, /watchtower, /delegate, /web-research==. Es la capa de discoverability: nadie memoriza seis rutas de scripts, pero todos recuerdan un slash.

## El contrato de plugins (FF-011)

Para extensión de terceros, el stack define un contrato estándar (implementado desde v2.9.0):

1. **Discovery**: plugins en \`plugins/\` (built-in), \`~/.gentle-vanguard/plugins/\` (usuario) y paths de \`config/plugins.json\`.
2. **Manifest**: cada plugin trae \`plugin.json\` (nombre, versión, autor, descripción, versión mínima del stack) validado contra \`config/plugin-manifest-schema.json\`.
3. **Interfaz**: \`Invoke-Plugin(command, parameters)\` + \`Get-PluginMetadata()\` — contrato uniforme.
4. **Seguridad**: ejecución en sandbox (PSSession restringida), validación de firma, whitelist por manifest.
5. **Ciclo de vida**: Discover → Validate → Load → Initialize → Execute → Cleanup.
6. **Validación en CI**: el workflow autónomo valida todos los manifests en cada push/PR.

Los puntos de integración declarados: hooks de git, skills, subcomandos de la CLI y herramientas nuevas — un plugin puede extender cualquiera de esas superficies sin tocar el core.

## En el stack

\`\`\`bash
npx tsx src/zcode-sync.ts --sync          # redistribuir agentes/skills tras editar
npx tsx src/zcode-sync.ts --sync --dry --tools zcode   # preview sin escribir
npx tsx src/dashboard-start.ts            # el stack completo sigue local-first
\`\`\`

## Puntos clave

- Un sync (\`zcode-sync.ts --sync\`) distribuye 21 agentes + 12 skills a 3 herramientas, normalizando frontmatter.
- Sin hot-reload: cualquier cambio exige sesión nueva por herramienta.
- Hooks SessionStart (autostart con guard por repo) y PostToolUse Write|Edit (graphify update) automatizan higiene del índice.
- Slash-commands (/graphify, /token-status, /db-health, /watchtower, /delegate, /web-research) como capa de discoverability.
- Plugins de terceros: manifest validado en CI, sandbox, firma y ciclo de vida de 6 pasos.`,
    },
    {
      id: 'rag-y-crag',
      title: 'RAG y CRAG: retrieval con grader BM25 y web crawler dual-provider',
      minutes: 10,
      type: 'curso',
      md: `## RAG: dar al modelo exactamente lo que necesita, no todo

**RAG** (Retrieval-Augmented Generation) consiste en recuperar los fragmentos relevantes de una fuente de conocimiento e inyectarlos en el prompt antes de generar. La calidad de un sistema RAG no está en el modelo: está en el **retrieval**. Si recuperas fragmentos irrelevantes, el modelo alucina con confianza o responde a la pregunta equivocada.

## El problema del retrieval pobre y el patrón CRAG

¿Y si el retrieval es malo? **CRAG** (Corrective RAG) propone graduar la relevancia de lo recuperado y actuar en consecuencia: si la relevancia es alta, responder; si es baja, ==disparar un fallback== en lugar de responder con basura.

La implementación del stack (\`src/retrieval/retrieval-grader.ts\`) gradúa los chunks con **BM25 léxico — sin ML**, sin embeddings ni servicios externos:

\`\`\`bash
npx tsx src/retrieval/retrieval-grader.ts --query "..." --chunks '["...","..."]'
\`\`\`

Si el score cae bajo el umbral, el grader dispara el **keyword-fallback**: reintenta con términos extraídos antes de aceptar un contexto pobre. La decisión de diseño es pragmática: BM25 es determinista, auditable y gratis; para graduar relevancia de snippets no hace falta una red neuronal.

## El web crawler dual-provider

Para RAG sobre la web, \`src/web/web-crawler.ts\` implementa una **cadena de proveedores** con fallback sin API key:

| Operación | Primario | Fallback (cero-config) |
| --- | --- | --- |
| Scrape | Firecrawl (\`FIRECRAWL_API_KEY\`) | Jina Reader (\`r.jina.ai/<url>\` → markdown) |
| Search | Firecrawl | ==DuckDuckGo HTML → Bing RSS== |
| Crawl/Map | Firecrawl (requiere key) | error descriptivo |

Los **gotchas documentados** valen su peso en horas de debugging: Jina Reader ==bloquea User-Agents de navegador== (Chrome → 403; hay que usar \`curl/8.0.1\`); los href de DuckDuckGo son redirects \`//duckduckgo.com/l/?uddg=<encoded>\` que hay que decodificar con \`decodeURIComponent\`; y Bing sirve bot-detection al fetch de Node — por eso el único camino viable es el ==endpoint RSS==.

Cada proveedor cachea con \`cacheKey\` etiquetada (\`fb\`/\`fc\`) para no mezclar resultados entre proveedores, y el uso se registra en Nexus (\`web-crawler.usage\`).

## Web research select: busca → gradea → persiste

El pipeline completo (\`npm run web:select\`) encadena las piezas:

1. **Busca** con el crawler (cadena de proveedores).
2. **Gradea** los resultados con BM25 (el retrieval-grader, patrón CRAG).
3. **Persiste** el mejor subconjunto en \`.session/web-research/<slug>.json\`.

Dos modos: **snippet** (gradea títulos+snippets del buscador — rápido, cero scraping) y ==--deep== (scrapea los top-N candidatos y reemplaza el score con \`deepScore\` sobre el markdown completo, con tope de 20K caracteres — más preciso para research profundo). El output trae \`averageScore\`, orden descendente y verdict \`relevant\` si supera el umbral.

## El ecosistema de research alrededor

- **Research trends** (\`research-trends-cli.ts\`): agrega tendencias de GitHub, Hacker News, Stack Overflow, Dev.to y Reddit en un \`TrendReport\` normalizado (themes, hottest, emerging), consultable con \`themes --query "typescript OR rust"\`.
- El resultado de research alimenta skills como \`web-research\` y puede cruzarse con páginas trending vía crawler.

> La cadena completa es CRAG aplicado de punta a punta: recuperar (dual-provider con fallback), graduar (BM25 sin ML), corregir (keyword-fallback / retry con otro proveedor), y solo entonces generar. El modelo es el último eslabón, no el salvavidas.

## En el stack

\`\`\`bash
npm run web:select -- --query "customer retention strategies" --limit 5
npm run web:select -- --query "GDPR breach notification" --deep
npx tsx src/retrieval/retrieval-grader.ts --query "..." --chunks '["..."]'
npx tsx src/web/web-crawler-cli.ts health
\`\`\`

## Puntos clave

- RAG vale lo que vale su retrieval; CRAG añade la graduation de relevancia y el fallback ante pobreza.
- El grader del stack usa BM25 léxico (determinista, sin ML) con keyword-fallback.
- Crawler dual-provider: Firecrawl primario; Jina Reader + DuckDuckGo + Bing RSS como fallback cero-config.
- Gotchas reales: UA bloqueado en Jina, decodificar \`uddg\` en DDG, Bing solo por RSS.
- \`web:select\` persiste el top-N gradeado; \`--deep\` re-scorea sobre markdown completo (cap 20K chars).`,
    },
    {
      id: 'subagentes-en-la-practica',
      title: 'Subagentes en la práctica: delegar vs hacer directo',
      minutes: 9,
      type: 'curso',
      md: `## La decisión de todos los días

Toda la arquitectura de agentes se reduce a una decisión práctica repetida: **¿esto lo hago yo (orquestador) o lo delego?** Esta lección es la guía operativa, con los comandos exactos y los criterios para no delegar de más ni de menos.

## Los dos comandos esenciales

\`\`\`bash
npx tsx src/recommend-agent.ts --task "audit gdpr compliance" --topn 3
npm run delegate:run -- --task "audit gdpr compliance" --context "..." --topn 3
\`\`\`

Con \`--topn 3\` ves los tres candidatos rankeados — útil cuando sospechas que el dominio está entre dos agentes; \`recommend-agent\` solo recomienda, \`delegate:run\` compromete y delega con el tiering aplicado. Con \`--context\` inyectas el paquete de tarea (recuerda el presupuesto: 1.5-2.5k caracteres de objetivo, archivos, símbolos y checks).

## Cuándo delegar

- **Dominio claro con agente especializado**: "audit gdpr compliance" → \`gov-agent\`/\`legal-agent\`; "build a revenue forecast" → \`finance-agent\`. La tabla aprendida ya sabe esto; tu trabajo es no pelear contra ella sin datos.
- **Lanes independientes paralelizables**: tres revisiones de archivos disjuntos corren 3 lanes concurrentes (tope por riesgo: ==4 low / 3 medium / 2 high==).
- **Contexto cargado en el orquestador**: si tu sesión arrastra historia, el subagente nace limpio — delegar es también una técnica de gestión de contexto.
- **Tarea con contrato verificable**: si puedes escribir "checks de aceptación" concretos, el output contract del subagente te va a decir success/failed sin ambigüedad.

## Cuándo hacer directo

- **Tareas mecánicas puras**: "corrre este test", "muestra este archivo". El propio Skill Resolver Protocol las exime de inyección de skills — son demasiado simples para el overhead.
- **Microdecisiones**: si el trabajo cabe en 2-3 pasos, el costo fijo de delegar (packet + lanzamiento + merge) supera el beneficio.
- **Dependencia íntima del hilo conversacional**: si la tarea solo se entiende con el contexto completo de la conversación y no cabe en un packet, partirla para un subagente la distorsiona.
- **Cuando necesitas iterar en vivo**: un ajuste de una línea con feedback inmediato no justifica un round-trip de delegación.

> La pregunta filtro: ¿puedo escribir el objetivo, los archivos y la aceptación en menos de 2.5k caracteres? Si no, o la tarea está mal delimitada (descomponla) o es tuya.

## Diagnóstico cuando algo sale raro

1. **Agente reporta \`maximum steps reached\`** → no es fallo: la auto-reasignación suma +20 steps (tope 80) y preserva contexto (\`adaptive-steps.ts --resume <agent> --task_id <id>\`). Verifícalo con \`--status\`.
2. **La recomendación no convence** → mira la evidencia: la routing table (\`.session/routing/routing-table.json\`) muestra \`bestAgent\`, alternativas y success rates. Si \`totalAttempts\` es 0, estás en cold-start (STATIC_MAP) — desconfía un poco más.
3. **Resultado "confiadamente mediocre"** → revisa el packet: ¿incluiste los checks de aceptación? Un subagente sin criterio de éxito optimiza lo que interpreta, no lo que querías.
4. **Fusión conflictiva** → la política de merge del orquestador resuelve por prioridad: seguridad de validación > corrección funcional > estilo/documentación.

## Rutina de operación recomendada

\`\`\`bash
npx tsx src/adaptive-steps.ts --status        # configuración vigente de steps
npx tsx src/recommend-agent.ts --task "..." --topn 3   # siempre preview en dominio dudoso
npm run delegate:run -- --task "..." --topn 3          # commit
npm run token:trace                          # cuánto costó la delegación
\`\`\`

## En el stack

\`\`\`bash
npx tsx src/adaptive-steps.ts --status
npx tsx src/recommend-agent.ts --task "code review" --topn 3
npm run delegate:run -- --task "code review" --topn 3
npm run token:trace
\`\`\`

## Puntos clave

- \`recommend-agent --topn 3\` para preview, \`delegate:run\` para commit; \`--context\` viaja acotado (1.5-2.5k caracteres).
- Delega: dominio especializado, lanes paralelas, contexto cargado, contrato verificable.
- Directo: mecánico puro, 2-3 pasos, dependencia conversacional, iteración en vivo.
- \`maximum steps reached\` se auto-resuelve (+20, tope 80): no lo trates como fallo.
- Packet sin checks de aceptación = resultado ambicioso pero equivocado; el filtro de 2.5k caracteres también delimita la tarea.`,
    },
  ],
};
