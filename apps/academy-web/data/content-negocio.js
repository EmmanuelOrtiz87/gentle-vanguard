/* Gentle-Vanguard Academy — Track "negocio" (8 lecciones).
   Derivado de: 11-SPRINT-B-SELL-ENABLE/PRICING-MODEL.md,
   11_OPPORTUNITY_SOLUTION_LAB/ (README, GTM-BRIDGE, 11_SOLUTION_PACKS),
   ADR-0017 (local-first / server-optional) del repo. Tono: microemprendimiento tech profesional. */

window.GV_CONTENT = window.GV_CONTENT || {};

window.GV_CONTENT["negocio"] = {
  lessons: [
    {
      id: "modelo-de-negocio",
      title: "El modelo de negocio: producto + servicios diversificados",
      minutes: 12,
      type: "curso",
      md: `## Qué es y para qué sirve

Gentle-Vanguard no es ni una startup que busca escala a cualquier costo ni una consultora que vende horas sueltas. Es un ==microemprendimiento tech local-first== con dos motores complementarios:

- **Producto propio (open-core)**: el stack — CLI/orquestación, Nexus, Engram, graphify, watchtower, dashboard, skills — corre completo en la máquina del usuario sin depender de un server. El core es abierto e inspeccionable; lo que podría monetizarse después (hosting, features de promoción externa, soporte) se construye encima.
- **Servicios**: desarrollo a medida con el stack, consultoría/diagnóstico y capacitación (charla, workshop, academia). Los servicios financian el producto y el producto diferencia los servicios.

## Por qué diversificar

Un solo motor es frágil: el producto solo tarda años en generar ingreso recurrente; los servicios solos te venden el tiempo y nada más. La combinación crea tres circuitos virtuales:

1. **Cada servicio usa el producto** → cada proyecto mejora el stack (skills nuevas, recetas, packs).
2. **Cada mejora del producto habilita un servicio mejor** → el diagnóstico de mañana es más rápido que el de ayer.
3. **Cada capacitación genera demanda de servicios** → el alumno que adopta el método contrata implementación.

El ==Opportunity & Solution Lab== (Master Kit) es el motor comercial que industrializa esto: captura problemas reales de mercado, los agrupa en demanda recurrente y los convierte en ==solution packs== reutilizables (propuesta → diseño → receta → demo → estimación → contenido).

Hay un tercer activo que no aparece en la tabla pero diferencia todo: el modelo ==local-first== como argumento de venta. Para el cliente significa que sus datos y su operación no viven en un servidor ajeno: sin vendor lock-in, sin costo de infraestructura recurrente para empezar, y auditoría posible (todo corre en una máquina que puede inspeccionar). Pocas ofertas de IA pueden decir eso con honestidad.

## Las líneas de ingreso

| Línea | Qué se vende | Unidad |
| --- | --- | --- |
| Capacitación | Charla, workshop, academia, ejecutivo | Por persona / por grupo / por cohorte |
| Consultoría | Diagnóstico AI workflow (OPP-004), auditorías | Por proyecto |
| Desarrollo | Implementación de packs (WhatsApp AI, Excel, CRM) | Por proyecto |
| Producto (futuro) | Hosting/SaaS opt-in, soporte, features de promoción | Recurrente (cuando exista) |

## En la práctica

La regla operativa del Lab ordena la prioridad: **construir assets reutilizables antes que desarrollos a medida**. Ante un encargo, la primera pregunta no es "¿cuánto cobro?" sino "¿esto alimenta un pack?". Un desarrollo que solo sirve una vez es un costo; un desarrollo que se convierte en pack es inventario.

> La honestidad como activo comercial: el stack prohíbe presentar promesas como hechos ("production ready" sin gate de evidencia). Esa misma disciplina es el diferenciador de venta: cada afirmación del pitch tiene un comando que la demuestra.

## Puntos clave

- Dos motores: producto open-core local-first + servicios (desarrollo, consultoría, capacitación).
- Diversificación con circuito virtuoso: servicios → mejoran producto → habilitan mejores servicios.
- El Lab industrializa la demanda: problema real → pack reutilizable.
- Regla de prioridad: assets reutilizables antes que bespoke.`
    },
    {
      id: "oferta-y-audiencias",
      title: "Oferta y audiencias: a quién le vende cada formato",
      minutes: 12,
      type: "curso",
      md: `## Qué es y para qué sirve

La oferta educativa es una ==escalera==: cada peldaño da un "recibo de valor" distinto y prepara el siguiente. Vender el formato correcto a la audiencia correcta evita el error clásico: regalar una academia a quien necesitaba una charla, o cobrar una charla a quien quería dominio.

## Los cuatro formatos

### Charla (45–60 min)

- **Qué es**: introducción en vivo al método — qué es un stack local-first, qué puede y qué no puede hacer la IA con dirección.
- **A quién**: audiencia amplia y fría: meetups, comunidades, empresas curioseando. Es el top de embudo, no un producto de margen.
- **Asset**: deck \`01_CHARLA_45_60_V3\`.

### Workshop (2–3 h)

- **Qué es**: un caso de uso concreto, hands-on. Primer peldaño de adopción real (nivel "Starter" del plan comercial).
- **A quién**: tech leads con su equipo (5–15 personas) que ya usan IA sin método.
- **Asset**: deck \`02_WORKSHOP_2_3H_V3\`; encaja natural con los packs OPP-001 (WhatsApp AI) y OPP-002 (Excel).

### Academy (12 módulos, ~22 h)

- **Qué es**: formación profunda con ejercicios verificados por comando y capstone. Habilidad durable, no inspiración.
- **A quién**: individuos que quieren dominio real del método (desarrolladores, ingenieros que automatizan su propio trabajo).
- **Asset**: 12 módulos completos del kit + este sitio como material vivo.

### Executive / institucional

- **Qué es**: cohorte privada para un equipo con calendario y caso a medida, o **licencia del currículo** para institución que lo dicta.
- **A quién**: managers que necesitan reporte de adopción; colegios/universidades que licencian contenido.
- **Asset**: deck \`03_EXECUTIVE_INSTITUTIONAL_V3\`; encaja con OPP-003 (Lead CRM) y OPP-004 (diagnóstico).

## Matriz audiencia → oferta

| Audiencia | Formato de entrada | Siguiente paso natural |
| --- | --- | --- |
| Comunidad / meetup | Charla | Workshop abierto |
| Tech lead + equipo | Workshop corporativo | Diagnóstico (OPP-004) o implementación |
| Dev individual | Workshop abierto o Academy | Academy completa |
| Manager / empresa | Executive session | Contrato de servicios |
| Institución educativa | Licencia Academy | Cohortes anuales |

## En la práctica

Un detalle operativo que el modelo de pricing subraya: **pineá la duración publicada antes de publicar precio** (el kit define workshop 2–3 h y foundations 4–5 h; cambiar la duración después invalida el cálculo de costo y el precio). La duración no es un dato de marketing: es una variable del modelo.

Cada formato tiene job distinto: la charla **genera confianza**, el workshop **genera el primer resultado medible**, la academia **genera habilidad**, el ejecutivo **genera contrato**. No mezcles jobs: una charla de 60 minutos no cierra un contrato corporativo, pero llena el workshop del mes siguiente. Medí cada peldaño por su propio job (asistentes → conversión a workshop → conversión a academy/servicios), no por ingreso directo.

## Puntos clave

- Cuatro formatos: charla 45–60 / workshop 2–3 h / academy 12 módulos / executive-institucional.
- La escalera: confianza → primer resultado → habilidad → contrato.
- A cada audiencia su formato; el deck correcto ya existe por oferta (V3).
- La licencia institucional se cotiza por cohorte o año — es otra negociación, no un precio por persona.`
    },
    {
      id: "pricing-y-propuesta-de-valor",
      title: "Pricing y propuesta de valor: el modelo de decisión",
      minutes: 14,
      type: "curso",
      md: `## Qué es y para qué sirve

El ==PRICING-MODEL== del kit no es una lista de precios: es un **modelo de decisión** para llegar a ellos. Fija la estructura de costo, el precio mínimo viable (PMV) y los anclajes de mercado; los números finales son decisión del dueño. La regla del plan comercial es tajante: *no publicar precios hasta definir duración, inclusiones, términos de cancelación y límites de soporte*.

## La estructura de costo

Cada oferta carga: preparación amortizada (repartida entre ediciones), horas de dictado (1:1 con la duración publicada), soporte post-clase (ventana y tope definidos ANTES del precio), infraestructura por edición y comisiones/impuestos. Solo el corporativo añade horas custom.

Las fórmulas centrales:

\`\`\`text
C_ed  = (horas_prep / a + horas_dictado + horas_soporte) x H + I
PMV   = (C_ed / n) / (1 - m - c)      [cohorte abierta, por persona]
P_gc  = C_ed x (1 + m) + horas_custom x H   [grupo cerrado]
\`\`\`

Donde \`H\` es el valor de tu hora, \`n\` el tamaño de cohorte, \`a\` las ediciones que amortizan la prep, \`I\` la infra, \`m\` el margen y \`c\` la comisión de pasarela.

El ==PMV es el piso==: por debajo, perdés plata o trabajás gratis. El precio de lista se decide después, contra mercado y posicionamiento.

## Dos mercados, dos anclas

| Mercado | Ancla | Rango observado (2026) |
| --- | --- | --- |
| B2C Argentina | Coderhouse / Platzi | USD 20–220 por curso |
| Corporativo internacional | Pertama / Improving | USD 200–1.000 por persona por workshop de 4 h |

**No mezcles los anchos**: el mismo workshop puede valer USD ~60/persona en cohorte abierta local y USD 1.500–3.000 el grupo cerrado regional. El techo de EE.UU. (USD 3.000+) es referencia, no tu precio.

## Tiers por oferta (estructura sugerida)

- **Early-adopter**: precio a cambio de algo — feedback escrito usable, testimonio, permiso de publicar resultados. Nunca por debajo del PMV.
- **Estándar**: cohorte abierta, material + grabación durante la cohorte y 30 días, soporte email 30 días.
- **Corporativo**: grupo cerrado hasta 15, caso adaptado, reporte de adopción para el lead.

## Decisiones de posicionamiento que condicionan el precio

1. Elegir beachhead primero (recomendación del plan: **B2B pequeño LatAm**, equipos de ingeniería).
2. Grabaciones: durante cohorte + 30 días, no descargables.
3. **El soporte post-clase es un costo, no un regalo**: publicar ventana, canal y tope junto con el precio.
4. Moneda: USD, ARS o híbrido con TC del día — decisión del dueño.

## En la práctica

Antes de cotizar: verificá los precios de referencia vigentes (los del modelo son de 2026-08 y las plataformas cambian con promociones), recalcu lá el PMV con TU \`H\` y TU pasarela, y chequeá el tope de facturación de tu categoría de Monotributo contra la proyección anual de ediciones.

## Puntos clave

- PMV = piso matemático; precio de lista = decisión de posicionamiento sobre el piso.
- Dos mercados (B2C AR / corporativo USD) con anclas incompatibles: elegir uno primero.
- Early-adopter se cobra en feedback + testimonio, no solo en plata.
- Restricciones fiscales AR (Factura C, tope de categoría, exportación de servicios) se verifican con contador antes de cotizar grande.`
    },
    {
      id: "go-to-market",
      title: "Go-to-market: campañas, redes y el GTM-BRIDGE",
      minutes: 12,
      type: "curso",
      md: `## Qué es y para qué sirve

==Go-to-market (GTM)== es el puente entre tener oferta y tener clientes. El stack no improvisa: cada pieza necesaria ya existe como asset, y el **GTM-BRIDGE** (Master Kit) mapea necesidad → asset para que una oportunidad validada pueda salir al mercado **el mismo día**.

## El mapa de assets (GTM-BRIDGE)

| Necesidad | Asset | Dónde vive |
| --- | --- | --- |
| Identidad de marca | Brand system v1 (tokens, logos SVG, reglas) | \`14-BRAND-SYSTEM/\` |
| Piezas de campaña + copy | Campaña de lanzamiento (HTML+PNG por red, copy ES) | \`15-LAUNCH-CAMPAIGN-2026-08/\` |
| Pricing | Modelo de decisión | \`11-SPRINT-B-SELL-ENABLE/PRICING-MODEL.md\` |
| Contratos | T&C, privacidad, reembolso (borradores DOCX) | \`11-SPRINT-B-SELL-ENABLE/\` |
| Decks | Charla / workshop / ejecutivo V3 | \`13-EDUCATIONAL-MATERIALS-V3/\` |
| Academia | 12 módulos completos | \`09-ACADEMY-MODULE_LESSONS/\` |
| Certificados | 7 templates PNG/PDF/DOCX | \`08-CERTIFICATES_AND_VISUALS/\` |
| Flyers | Se regeneran de la campaña adaptando copy | \`15-LAUNCH-CAMPAIGN-2026-08/html/\` |

## La secuencia de venta por pack (repetible)

1. **Qualify**: ¿el lead tiene forma de OPP-001..004? (templates de \`03_OPPORTUNITIES\`).
2. **Propose**: \`BUSINESS_PROPOSAL.md\` + \`TECHNICAL_PROPOSAL.md\` del pack, estimación con \`ESTIMATION_TEMPLATE.md\`.
3. **Demo**: correr la demo del pack (offline, etiquetada como demo — nunca producción).
4. **Price**: mapear la estimación a los tiers del PRICING-MODEL.
5. **Present**: el deck V3 como columna vertebral de la reunión; PNGs de campaña como material de follow-up.
6. **Close**: acuerdo de consultoría + T&C (tras revisión legal) + certificado en la entrega.

## Redes y campañas

La campaña de lanzamiento trae piezas por red con copy en español: **X/Twitter** (hilos técnicos, demos en vídeo corto), **LinkedIn** (contenido profesional, casos B2B, el deck ejecutivo), **Instagram** (visual de marca, behind-the-scenes del stack), **TikTok** (formato corto educativo, "un comando, un resultado"). Regla: todo artefacto client-facing deriva de los tokens del brand system — nada sale con colores o tipografía fuera de sistema.

El bridge además fija la disciplina de crecimiento del catálogo: **cada pack nuevo debe agregar su fila a la tabla "pack → deck/campaign fit" antes del primer contacto con cliente**. Sin mapeo de assets, el pack no sale a la calle — así el GTM nunca queda a medio construir.

## En la práctica

El flujo semanal concreto: publicar contenido de la campaña en 2 redes según el beachhead (LinkedIn + X para B2B), responder cada comentario con el deck de charla como puente, agendar demos del pack que matchee, y registrar cada contacto en el pipeline de \`03_OPPORTUNITIES\`. El ==LAB de oportunidades es el puente==: convierte señales de mercado en packs, y el GTM-BRIDGE convierte packs en reuniones.

> Regla del LAB: el material demo se etiqueta como demo. Presentar una integración demo como producción es la violación más grave de la honestidad comercial del kit.

## Puntos clave

- GTM-BRIDGE: cada necesidad comercial ya tiene asset — la venta no espera a que se diseñe nada.
- Secuencia repetible de 6 pasos: qualify → propose → demo → price → present → close.
- Cada red con su job: X/LinkedIn tiran B2B, Instagram/TikTok construyen marca y alcance.
- Todo client-facing sale de los tokens de marca; las demos siempre etiquetadas como demos.`
    },
    {
      id: "casos-de-uso-verticales",
      title: "Casos de uso verticales: los 4 solution packs",
      minutes: 12,
      type: "curso",
      md: `## Qué es y para qué sirve

Los ==solution packs== son la respuesta industrializada a demanda real repetida: cada pack nace de señales de mercado (requests públicas repetidas 2026), se documenta como propuesta de negocio + receta técnica, y se vende en niveles. Cuatro packs forman el catálogo vertical actual.

## OPP-001 — WhatsApp + AI Customer Service

- **Señal de demanda**: respuestas automáticas, FAQs, precios/disponibilidad, captura y calificación de leads, follow-up, turnos, escalamiento humano con contexto de conversación.
- **Posicionamiento**: NO vender "un chatbot" — vender un flujo de atención controlado que reduce trabajo repetitivo preservando escalamiento humano.
- **Niveles**: L1 FAQ/demo → L2 workflow con API → L3 CRM + calendario + handoff → L4 observabilidad, evaluación, gobernanza y soporte.
- **Deck líder**: workshop 2–3 h; pieza de apoyo: TECH-02 (dashboard).

## OPP-002 — Excel / Report Automation

- **Señal**: optimización de reportes, reducción de pasos manuales, VBA/macros, consolidación de datos, validación, KPIs recurrentes.
- **Posicionamiento**: reducir el tiempo de preparación recurrente sin forzar reescritura completa del sistema.
- **Niveles**: L1 fórmulas/templates → L2 VBA/Power Query/scripts → L3 pipeline Python/SQL → L4 servicio de reporting integrado.
- **Deck líder**: charla 45–60; pieza: LAUNCH-01 (hero).

## OPP-003 — Lead Qualification + CRM

- **Dolor repetido**: respuesta lenta a leads, copy/paste, datos inconsistentes, calificación pobre, follow-up perdido, handoff difícil.
- **Flujo**: inbound → qualify → structure → score → follow-up → handoff humano → KPI.
- **Deck líder**: ejecutivo/institucional; pieza: SERVICES-01.

## OPP-004 — AI Workflow Diagnostic

- **Qué es**: la oferta paraguas que alimenta todo el catálogo.
- **Inputs**: procesos, tareas repetitivas, documentos, sistemas, dolores, restricciones, herramientas, uso actual de IA.
- **Outputs**: mapa de estado actual, inventario de problemas, mapa de oportunidades, matriz riesgo/esfuerzo, quick wins, propuesta de piloto y roadmap.
- **Deck líder**: ejecutivo/institucional; pieza: STORY-01 (hook).

## Cómo se usan en venta

| Situación del lead | Pack de entrada | Expansión |
| --- | --- | --- |
| "Atendemos WhatsApp y no damos abasto" | OPP-001 L1→L2 | L3/L4 con soporte |
| "Los reportes de Excel nos comen el lunes" | OPP-002 L1→L2 | L3 pipeline |
| "Perdemos leads por responder tarde" | OPP-003 | Integración con calendario/CRM |
| "Queremos IA pero no sabemos dónde" | OPP-004 | Cualquiera de los otros tres |

## En la práctica

Cada pack trae su documentación completa: \`BUSINESS_PROPOSAL.md\` y \`TECHNICAL_PROPOSAL.md\` para la venta, \`IMPLEMENTATION_RECIPE.md\` (o \`RECIPE.md\`) para la ejecución, y alcance client-facing. Eso significa que vender no requiere armar propuesta desde cero: se adapta la existente con el \`REQUIREMENTS_TEMPLATE\` y se estima con el template de estimación. La velocidad de propuesta es ventaja competitiva real cuando el cliente compara tres proveedores.

El diagnóstico (OPP-004) es la puerta de entrada más honesta cuando el cliente no sabe qué quiere: produce un mapa con matriz riesgo/esfuerzo y quick wins, y de ahí sale el piloto. Los demos de OPP-001 y OPP-002 corren offline — etiquetados demo siempre.

## Puntos clave

- Cuatro packs verticales, cada uno con propuesta de negocio, receta técnica y alcance client-facing.
- Todos se venden por niveles L1→L4: entrada accesible, expansión con valor creciente.
- OPP-004 es el paraguas: diagnostica primero, implementa después.
- Regla: demo se etiqueta como demo — nunca producción.`
    },
    {
      id: "marketing-servicios-profesionales",
      title: "Marketing de servicios profesionales",
      minutes: 11,
      type: "curso",
      md: `## Qué es y para qué sirve

Vender servicios profesionales no es perseguir leads: es construir ==reputación compuesta== — que la evidencia pública de tu competencia haga el pre-venta antes de la primera reunión. El microemprendimiento tech no tiene budget de ads; tiene demostraciones verificables, contenido técnico y referencias. Ese es el marketing.

## Los cuatro pilares

### 1. Contenido que demuestra

Cada pieza de contenido sigue la regla del stack: hecho con comando. Un post que dice "automatizamos X y ahorramos Y horas (medido, fecha, método)" vende más que diez frases motivacionales. Formatos que ya tenés: resultados del propio stack (\`token:trace\`, watchtower 97/97), mini-casos de los packs, material de la campaña de lanzamiento por red.

### 2. Referencias y testimonios

El tier early-adopter del pricing existe exactamente para esto: descuento a cambio de **feedback escrito usable y testimonio**. Sin ese canje, un descuento es solo precio bajo. Pedí el testimonio en el momento de máxima satisfacción (fin del workshop, entrega del piloto), con permiso explícito para publicarlo con evidencia.

### 3. Reputación técnica

Charlas en comunidades, el repositorio open-core inspeccionable, la Academia como muestra de método. La reputación se construye en público: el cliente que puede auditar tu stack antes de contratarte ya está medio convencido.

### 4. El contrato bueno

Un buen contrato llega de un buen fit, y el fit se filtra temprano:

1. **Qualify** con los templates del Lab — ¿tiene forma de pack? Si no la tiene, es un proyecto a medida: cotizalo como tal o declinalo.
2. **Propose** con \`BUSINESS_PROPOSAL.md\` + \`TECHNICAL_PROPOSAL.md\` del pack y estimación con el template — nunca propuesta en blanco.
3. **Demo** en la primera o segunda reunión (etiquetada demo).
4. **Price** sobre el modelo, no sobre miedo.
5. **Close** con acuerdo de consultoría + T&C + certificado en la entrega.

## Cómo obtener buenos contratos (y evitar los malos)

- **Señales verdes**: hay un dueño interno identificado, hay datos accesibles, el dolor es medible ("4 h/semana en reportes"), el presupuesto existe aunque no esté cerrado.
- **Señales rojas**: "hacenos algo con IA, después vemos qué", pedir demo gratis a medida sin compromiso, presupuesto que solo funciona si trabajás por debajo de tu PMV.
- La regla del LAB ordena todo: **assets reutilizables antes que bespoke**. Un encargo que no alimenta un pack tiene que pagar el precio completo de lo bespoke.

## En la práctica

Flujo semanal sostenible para una persona: 2 piezas de contenido (reutiliza la campaña), 1 actividad de comunidad (charla, respuesta técnica detallada), seguimiento de los leads del pipeline con el deck correcto, y pedir testimonio en cada entrega. La reputación compuesta es lenta de construir y imposible de copiar — ahí está el foso defensivo del microemprendimiento.

## Puntos clave

- Marketing = reputación compuesta: contenido con evidencia, testimonios canjeados, reputación técnica pública.
- El early-adopter se cobra en feedback + testimonio + permiso de publicar.
- Buen contrato = buen fit: qualify con templates del Lab, propose con propuesta estructurada.
- Señal roja número uno: trabajo a medida por debajo del PMV que no alimenta ningún pack.`
    },
    {
      id: "operacion-como-empresa",
      title: "Operación como empresa: contratos, soporte y unit economics",
      minutes: 12,
      type: "curso",
      md: `## Qué es y para qué sirve

Un microemprendimiento que factura necesita operar como empresa chiquita: contratos claros, soporte acotado, entregas certificadas y **números por unidad económica**. Sin esto, cada cliente exitoso te acerca al colapso operativo; con esto, cada cohorte te dice si el negocio escala.

## Contratos

El kit trae tres documentos base como borradores DOCX (la revisión legal está pendiente — **no usar sin revisión profesional**):

- **Términos y condiciones** — alcance de la licencia de materiales (uso personal), condiciones de acceso.
- **Política de privacidad** — qué datos se recogen en cohortes y demos.
- **Política de reembolso** — ventana y condiciones por oferta.

Para servicios: acuerdo de consultoría (template en el repo privado). La secuencia de cierre del GTM-BRIDGE lo exige: acuerdo + T&C + certificado en la entrega.

## Soporte con límites publicados

El PRICING-MODEL es explícito: **el soporte post-clase es un costo, no un regalo**. Cada oferta publica junto al precio: ventana (sugerido: 30 días), canal (email) y tope de horas o régimen ("mejor esfuerzo"). El precio sin límite de soporte es una promesa insostenible — y sostener promesas insostenibles es lo que quema microemprendimientos.

## Certificados

La entrega de academy/workshop cierra con certificado (7 templates PNG/PDF/DOCX en el kit). Función comercial: marca el cierre del compromiso, habilita el pedido de testimonio y da al alumno un activo compartible (marketing orgánico).

## Unit economics

Las métricas por edición que el modelo deja calcular:

| Métrica | Cómo se calcula |
| --- | --- |
| C_ed (costo por edición) | (prep amortizada + dictado + soporte) x H + I |
| PMV | (C_ed / n) / (1 − m − c) |
| Margen real por edición | Ingresos − C_ed − comisiones |
| Ocupación | inscritos / plazas (define si abre la edición) |
| Ingreso por hora propia | (Ingresos − costos directos) / horas totales reales |

Hábito mínimo: después de cada edición, completar la tabla con los números REALES (las horas reales de soporte, la ocupación real). Tres ediciones de datos valen más que cualquier proyección.

## Fiscal (Argentina) — verificar con contador

- **Factura C** como monotributista: las empresas grandes que esperan Factura A con IVA créditable pueden ser obstáculo — preguntar antes de cotizar grande.
- **Tope de facturación** de la categoría: proyectar ediciones x precio por año fiscal; si una cohorte corporativa te acerca al tope, decidir (subir categoría, dividir, derivar).
- **Exportación de servicios** (tier US/EU): tratamiento especial — consultarlo antes del primer contrato exterior.
- **Medios de pago**: transferencia (menor costo), Mercado Pago (~3,5%), Stripe/PayPal para USD (comisión mayor). La \`c\` del modelo depende de esta elección.

## En la práctica

Antes de abrir la primera cohorte pagante: T&C y reembolso revisados por profesional, soporte definido por oferta, template de certificado elegido, y la tabla de unit economics lista para llenar con datos reales. Operar como empresa no es burocracia — es lo que permite decir "sí" al cliente número diez sin pánico.

## Puntos clave

- Tres contratos base (T&C, privacidad, reembolso) como borradores — requieren revisión legal antes de usar.
- Soporte publicado con ventana, canal y tope; el precio nunca promete soporte infinito.
- Certificado en cada entrega: cierre del compromiso + activo de marketing.
- Unit economics por edición con números reales; restricciones fiscales AR verificadas con contador.`
    },
    {
      id: "roadmap-de-crecimiento",
      title: "Roadmap de crecimiento: de local-first a server/SaaS opt-in",
      minutes: 12,
      type: "curso",
      md: `## Qué es y para qué sirve

El destino declarado del stack NO es "mudarse a la nube". Es ==LOCAL-FIRST / SERVER-OPTIONAL== (ADR-0017): la operación local es la ruta soportada; server, Kubernetes, cloud y SaaS son **caminos de evolución opt-in** que nunca se presentan como requisito. El roadmap de crecimiento respeta esa arquitectura: crece el negocio sin traicionar el modelo.

## Los cuatro perfiles operativos (ADR-0017)

| Perfil | Qué es | Cuándo |
| --- | --- | --- |
| \`local-default\` | Una máquina, identidad local, sin tenants | Hoy — el default soportado |
| \`local-multi-tenant\` | Local con límites de datos por tenant | Equipos/múltiples contextos en una máquina |
| \`server-promotion\` | Deployment en server propio | Cuando hay clientes que lo piden Y los inputs externos existen |
| \`saas-federated\` | SaaS con federación de identidad | Producto como línea de ingreso principal |

## Qué cambia al promocionar externamente

Los ==promotion gates== son contratos opt-in: digest pinning de imágenes, evidencia de firma Cosign, CNI/NetworkPolicy, sandbox de MCP, identidad OIDC/LDAP. En modo local son informativos (exit 0); en modo \`--promotion\` son **bloqueantes**. Y la regla clave: esos inputs los aporta el operador — el stack nunca fabrica evidencia de seguridad que no tiene.

Cambia también la identidad (deployment-scoped → federada), la tenencia (tenants explícitos en Nexus ya preparados con \`tenant_id\`) y la operación (observabilidad server, DR real).

## Qué NO cambia

- El núcleo: CLI/orquestación, Nexus SQLite, Engram, graphify, watchtower, dashboard loopback.
- Las normativas y el ciclo SDD — el método es invariante al deployment.
- La honestidad del catálogo: promesas prohibidas en todos los perfiles.
- El negocio de servicios: sigue financiando el desarrollo del producto.

## La secuencia de crecimiento del negocio

1. **Ahora (local-default)**: servicios + capacitación usan el stack local. Cada proyecto mejora el producto. El ingreso es de servicios.
2. **Corta**: packs maduros (OPP-001..004) reducen el costo de entrega y suben el margen; la Academy forma usuarios que demandan implementación.
3. **Media**: cuando aparezcan clientes que necesiten acceso multi-equipo, activar \`local-multi-tenant\` y ofrecer soporte/consultoría de adopción (recurring liviano).
4. **Larga**: \`server-promotion\` solo cuando los inputs externos existan y un cliente pague por ello — el gate bloqueante protege de promociones prematuras.
5. **SaaS (\`saas-federated\`)**: producto como línea principal, con la identity federation como proyecto de ingeniería explícito, no como supuesto.

## En la práctica

La decisión mensual es simple: ¿este esfuerzo acerca los packs o la Academy (ingreso de servicios hoy), o construye inputs de promoción (futuro opt-in)? Mientras ningún cliente pague por server, la promoción externa es backlog documentado, no deuda urgente. La disciplina del ADR es también disciplina de inversión: no construir infraestructura de SaaS sin demanda que la pague.

> La pregunta de examen: "¿esto es requisito local o input de promoción?" Si es input de promoción, no bloquea nada hoy — y no debería consumir tu mejor hora.

## Puntos clave

- Cuatro perfiles (local-default → saas-federated); hoy el soportado es local-default.
- Promotion gates: informativos en local, bloqueantes en promoción; los inputs los aporta el operador.
- Invariante: núcleo local, normativas, SDD y honestidad — el método no cambia con el deployment.
- Secuencia: servicios financian producto; server/SaaS solo con demanda e inputs reales (ADR-0017).`
    }
  ]
};
