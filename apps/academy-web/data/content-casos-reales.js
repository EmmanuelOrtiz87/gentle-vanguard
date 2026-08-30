/* Gentle-Vanguard Academy — referencia: caso comparativo y medición. */
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT['casos-reales'] = {
  lessons: [
    {
      id: 'metodologia-antes-despues',
      title: 'Caso comparativo: antes y después, sin inventar resultados',
      minutes: 14,
      type: 'referencia',
      md: `## Qué sí se puede afirmar

Un caso comparativo debe separar **hechos observados**, **objetivos operativos** y **placeholders**. La existencia de Gentle-Vanguard no demuestra por sí sola que un equipo sea más rápido o barato.

### Metodología reproducible

1. Elegir una tarea equivalente: construir o mejorar Analytics, Dashboard, CMS o Academy.
2. Registrar el baseline sin el stack: fecha, personas, archivos, comandos, tokens, tiempo activo, bloqueos y resultado.
3. Repetir con Gentle-Vanguard, manteniendo alcance, modelo, máquina y criterios de aceptación comparables.
4. Validar con tests/build/revisión humana y guardar los artefactos fechados.
5. Comparar medianas de al menos tres repeticiones, no una única corrida.

| Dimensión | Antes | Después | Fuente requerida |
| --- | --- | --- | --- |
| Tokens | \`[PENDIENTE: baseline]\` | \`[PENDIENTE: token:status]\` | rollout bruto + Nexus |
| Tiempo activo | \`[PENDIENTE]\` | \`[PENDIENTE]\` | cronómetro o trazas |
| Costo monetario | \`[PENDIENTE]\` | \`[PENDIENTE]\` | factura/proveedor |
| Organización | trabajo manual y contexto disperso | sesión, agentes y artefactos trazables | log + resumen |
| Resolución | resultado y defectos encontrados | resultado, tests y rollback si aplica | CI/local + revisión |

> **No rellenar los campos pendientes con estimaciones.** Si no existe una fuente fechada, escribir “no medido”.

## Ejemplo de alcance

Para Analytics se mide una consulta y su exportación; para Dashboard, una métrica real y su fallback HTTP; para CMS, un flujo de contenido y su validación; para Academy, una lección, navegación y enlaces. No se deben sumar cuatro productos y atribuir toda mejora al stack sin aislar variables.

### Snapshot real disponible en este repositorio

El 2026-08-29 se observaron: Graphify **4.875 nodos / 9.252 aristas / 3.652.706 bytes**, Nexus **29 tablas / 68.219 filas / 17 migraciones**, y token budget diario **6.844.488 usados frente a 5.000.000 (137%)**. Son lecturas operativas de ese momento, no un benchmark antes/después ni un costo monetario.

## Gráfico honesto

\`\`\`text
Métrica                 Antes             Después             Estado
Tokens                  [no medido]       6.844.488*          observado*
Costo monetario         [no medido]       [no disponible]     no medido
Tiempo                  [no medido]       [no medido]         no medido
Calidad                 [criterio]        [tests + revisión]  verificar

* token:status --json, 2026-08-29; diario agregado, no causalidad.
\`\`\`

El caso se vuelve publicable cuando cada valor tiene timestamp, comando o archivo fuente, alcance y limitación.

## Puntos clave

- Un caso real documenta el método antes de mostrar el resultado.
- Nexus y los rollouts tienen autoridades distintas; no mezclar agregados con uso bruto.
- Los costos en dinero requieren datos del proveedor. Tokens no equivalen automáticamente a dólares.
- La conclusión válida puede ser “no medido todavía”.`,
    },
    {
      id: 'cuatro-superficies-trabajo',
      title: 'Ejemplo de construcción: Analytics, Dashboard, CMS y Academy',
      minutes: 12,
      type: 'referencia',
      md: `## Un mismo método, cuatro superficies

El objetivo es mostrar **cómo organizar el trabajo**, no prometer una mejora porcentual.

| Superficie | Entrada | Evidencia de resolución | Límite |
| --- | --- | --- | --- |
| Analytics | pregunta y contrato de métrica | test API, export y fuente | no sustituye datos de negocio |
| Dashboard | métrica/traza real | build, health, WS/HTTP y provenance | sin mock data; localhost por defecto |
| CMS | modelo y workflow de contenido | validación, tests y revisión | no implica backend/SaaS |
| Academy | lección y navegación | sintaxis, rutas y enlaces | sitio estático, sin LMS |

### Secuencia recomendada

\`\`\`text
alcance → evidencia baseline → explore/design → implement → verify
   ↑                                                ↓
   └──── Engram (decisiones) ← Nexus (métricas) ← trazas
\`\`\`

Para cada superficie guardá: commit o diff, comandos ejecutados, duración, tokens, resultado de tests y decisiones. Si cambia el modelo, proveedor, máquina o alcance, se inicia una nueva cohorte de medición.

### Organización y resolución

- **Organización**: BA/SAD/DEV/QA/DOC pueden trabajar con delegación, pero el resultado se atribuye a la sesión y a sus agentes, no a una cifra genérica.
- **Resolución**: un problema queda resuelto solo cuando la prueba adecuada pasa y una persona puede reproducirla.
- **Costo**: separar tokens, tiempo humano, tiempo de máquina y costo monetario. Reportar “no disponible” si falta la factura.

## Puntos clave

El valor del stack es trazabilidad y reducción de contexto repetido como hipótesis verificable. El caso no debe convertir capacidades disponibles en resultados comerciales no medidos.`,
    },
  ],
};
