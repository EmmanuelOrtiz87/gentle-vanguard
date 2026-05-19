# Demo 07 - Guion de Presentacin

Audiencia: Ejecutivos (5 min) + Equipo de desarrollo (15 min total)

---

## Preparacin (antes de entrar a la sala)

**0. Ejecutar preflight (paso clave en mquina nueva):**

```powershell
./demos/07-mixed-cookbook-real-request/preflight.ps1
```

Esto verifica Go, Git, activa el orquestador (si hace falta) y limpia datos previos.

**Despus del preflight:**

1. Terminal abierta en `.\gentle-vanguard`.
2. PowerShell con permisos de ejecucin:
   `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.
3. Repo limpio: `git status` sin cambios pendientes.

---

## Mapa de Tiempos

| Segmento             | Versin ejecutiva | Versin completa (dev) |
| -------------------- | :--------------: | :-------------------: |
| 0. Apertura          |      1 min       |         1 min         |
| 1. Orquestador       |      1 min       |         2 min         |
| 2. Contexto y tokens |      1 min       |         2 min         |
| 3. Implementacin     |                  |         4 min         |
| 4. Engram            |                  |         2 min         |
| 5. Review y auditora |      1 min       |         3 min         |
| 6. Cierre            |      1 min       |         1 min         |
| **Total**            |    **5 min**     |      **15 min**       |

---

## Segmento 0 - Apertura (1 min)

### Lo que dices

> "Hoy vemos un caso real de principio a fin. Un equipo recibe una solicitud: construir un CLI
> sencillo para gestionar tareas de standup. Vamos a ejecutarlo con el stack completo: desde que el
> orquestador lee el pedido hasta que cierra la sesin con evidencia auditable. No hay magia cada
> paso es un comando reproducible."

### Lo que muestras en pantalla

```powershell
# Confirmar que el stack est en pie
./scripts/utilities/gv.ps1 status
```

### Puntos de anclaje (ejecutivo)

- "Esto es un workflow, no un experimento."
- "Cualquier miembro del equipo puede reproducir este ciclo exacto."

---

## Segmento 1 - Orquestador y modo de comunicacin (2 min dev / 1 min exec)

### Lo que dices

> "El orquestador es el primer paso: verifica el estado del proyecto y recomienda qu modo de
> comunicacin usar con la IA antes de empezar a trabajar. No es una recomendacin manual lee el
> branch, el tipo de tarea, y elige automticamente."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/orchestrator-next-steps.ps1
./scripts/utilities/gv.ps1 response-mode
./scripts/utilities/gv.ps1 response-mode list
```

### Guion dev (ampliar)

> "Miren la seccin 'Communication Mode Recommendation'. Si el branch fuera `hotfix/...` la
> recomendacin cambiara a `ultra`. Para una tarea de demo como esta, eligi `executive + lite`
> respuestas concisas, sin overhead. Ese ajuste automtico reduce tokens en aproximadamente un 50%
> versus el modo default sin configurar."

### Puntos de anclaje (ejecutivo)

- "El equipo no decide esto manualmente cada vez el stack lo infiere."
- "50% menos de tokens = costo de AI recortado a la mitad en operaciones estndar."

---

## Segmento 2 - Reduccin de contexto y tokens (2 min dev / 1 min exec)

### Lo que dices

> "Antes de abrir el chat o invocar la IA, generamos un contexto compacto. Esto evita que el modelo
> reciba informacin que no necesita y eso baja el costo directo."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/response-mode-efficiency-matrix.ps1
```

### Guion dev (ampliar)

> "Esta matriz cubre las 27 combinaciones posibles: 3 idiomas 3 niveles de detalle 3 perfiles de
> compresin. La combinacin activa est resaltada. Si quieren ver los ahorros en CSV para un reporte:"

```powershell
./scripts/utilities/response-mode-efficiency-matrix.ps1 -AsCsv
```

> "Esto es til para justificacin de costo frente a finanzas o procurement."

### Puntos de anclaje (ejecutivo)

- "Visual claro: la columna 'Yearly Token Savings' muestra el ahorro proyectado anual."
- "No es un clculo terico est basado en el uso real del equipo calibrado por tarea."

---

## Segmento 3 - Implementacin asistida por IA (4 min dev solo versin completa)

### Lo que dices

> "Ahora la implementacin. El proyecto ya existe en el repo lo usamos como referencia. Vean que los
> comandos son idnticos en cualquier mquina: Go, sin dependencias externas."

### Lo que muestras en pantalla

```powershell
cd demos/shared/task-tracker
go run . add --title "prepare standup notes"
go run . list
go run . done --id 1
go run . stats
cd ../../..
```

### Output esperado

```
ok: task created (id=1)
[TODO] #1  prepare standup notes
ok: task completed (id=1)
tasks_total=1  tasks_done=1  tasks_pending=0
```

### Guion dev (detalle)

> "Este proyecto usa JSON local para persistencia sin base de datos, sin credenciales. La variable
> de entorno `TASK_TRACKER_DB` permite apuntar a otro archivo si lo necesitan en CI. Lo importante
> para el demo: cualquier feature pequeo que el stack implementa pasa por este mismo ciclo el
> proyecto real es ms grande, el proceso es idntico."

> "En un escenario real el loop sera: abrir contexto compacto pedir cambio a la IA validar respuesta
> commit. El response-mode ya estaba aplicado, as que la IA responde en el nivel correcto sin
> necesitar prompts extra."

### Pausa para preguntas tcnicas (30 seg)

---

## Segmento 4 - Continuidad con Engram (2 min dev solo versin completa)

### Lo que dices

> "Al cierre de cualquier sesin de trabajo o antes de pasar la tarea a otro miembro guardamos un
> resumen en Engram. Eso elimina el re-briefing en la siguiente sesin."

> "En una mquina nueva, este paso ya no depende de una carpeta precreada. El launcher la inicializa
> automticamente y el resto del demo no queda bloqueado."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/run-engram.ps1 --help
```

### Nota operativa

> "No duplicamos Engram dentro de `demos/`. La instalacin soportada vive en el stack
> (`gv.ps1 install-engram`) para evitar deriva entre mquinas."

> "Si Engram está activo, el ciclo es:"

```
mem_save    guarda decisiones clave (bug encontrado, patrn elegido, deuda tcnica identificada)
mem_search  al siguiente da, el agente retoma desde where we left off
```

### Guion dev (detalle)

> "Sin Engram, el equipo repite contexto verbal en cada sesin. Con Engram, el agente lee el
> historial, y el desarrollador arranca directamente en el problema. Reducin de overhead de
> re-briefing: estimado 10-20 minutos por sesin larga."

### Puntos de anclaje (si hay ejecutivos presentes)

- "Memoria organizacional. No depende de que una persona recuerde."

---

## Segmento 5 - Code Review y Auditora (3 min dev / 1 min exec)

### Lo que dices

> "El stack genera artefactos de review y auditora como parte del workflow no como paso extra. Esto
> es lo que le muestra a compliance, a QA, o a un cliente con requerimientos de trazabilidad."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/generate-session-review.ps1
./scripts/utilities/generate-audit-report.ps1 -Period weekly
```

### Guion dev (detalle)

> "Cada sesin genera su review en `docs/sessions/YYYY-MM-DD-TASK.md`. El audit report consolida
> actividad del perodo til para sprint retrospectivas o reportes de seguridad. Gentleman Guardian
> Angel agrega una capa de validacin de estructura de cdigo antes de que el artefacto llegue al
> review humano."

### Puntos de anclaje (ejecutivo)

- "Trazabilidad completa: quin trabaj qu, cundo, con qu resultado."
- "Sin proceso manual de documentacin el stack lo genera."

---

## Segmento 6 - Cierre de sesin (1 min)

### Lo que dices

> "El ltimo paso: cierre formal. Genera el artefacto de closure y deja el contexto listo para
> maana."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/gv.ps1 end-session demo-task-tracker
```

### Output esperado

Closure report guardado en `docs/sessions/` con:

- Tareas completadas.
- Modo de comunicacin usado.
- Preset aplicado (y si fue auto-aplicado).
- Hash del ltimo commit.

### Frase de cierre

> "Eso es un ciclo completo. Desde la solicitud hasta el artefacto de cierre reproducible, medible,
> auditable. Las preguntas habituales son sobre ROI y sobre cmo se integra con el stack existente.
> Cubramos eso ahora."

---

## FAQ Respuestas Preparadas

### "Cunto ahorra esto realmente?"

> "La matriz de ahorro que vieron estima entre 30% y 50% de tokens por tarea segn la combinacin. El
> mayor retorno no es el costo de tokens es el tiempo de ciclo. Un rework evitado en una tarea
> senior equivale a 2-4 horas. El stack reduce retrabajos porque mantiene contexto y aplica modo
> correcto desde el inicio."

### "Qu pasa si alguien no sigue el proceso?"

> "El workflow es permisivo no bloquea. Pero el orchestrator y el native lanzan advertencias que
> quedan en logs. A nivel de PR, si la review generada no pasa los puntos de governance, el revisor
> lo ve."

### "Funciona con nuestro stack actual?"

> "gentle-vanguard es agnstico al lenguaje. Lo que vieron en Go funciona igual en Python,
> TypeScript, o cualquier otro. La capa de integracin con la IA es via prompt no hay dependencia de
> IDE o provider especfico."

### "Cmo se integra con Jira / Azure DevOps / etc.?"

> "Los artefactos son markdown + JSON. Pueden conectar con cualquier sistema va webhook o pipeline
> CI. La integracin directa con Jira y Azure Boards est en el roadmap como extensin de gv CLI."

### "Qu tan difcil es adoptarlo para un equipo nuevo?"

> "Getting Started est en `docs/getting-started/`. Primera sesin funcional en menos de 30 minutos.
> La curva de adopcin ms comn: un par de sesiones para internalizar los presets, despus el flujo se
> vuelve automtico."

---

## Notas del Presentador

1. Si el demo falla en un comando, mostrar el output esperado del DEMO.md sin interrumpir el flujo.
2. Para audiencia 100% ejecutiva: saltar Segmentos 3 y 4, ir directo de 2 a 5.
3. Para audiencia 100% tcnica: ampliar Segmento 3 con un cambio real de cdigo y commit en vivo.
4. El proyecto task-tracker es intencionalmente simple si alguien pregunta "es solo esto?", la
   respuesta es: "El proyecto es simple para que el proceso sea el protagonista, no el cdigo."
5. Limpiar `demos/shared/task-tracker/tasks.json` antes de cada demo si hiciste una corrida de
   prueba.
