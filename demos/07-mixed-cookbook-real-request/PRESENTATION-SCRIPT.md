# Demo 07 - Guion de Presentación

Audiencia: Ejecutivos (5 min) + Equipo de desarrollo (15 min total)

---

## Preparación (antes de entrar a la sala)

1. Terminal abierta en `C:\Workspace_local\workspace-foundation`.
2. PowerShell con permisos de ejecución: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.
3. Go instalado y en PATH (`go version` debe responder).
4. Repo limpio: `git status` sin cambios pendientes.
5. Si quieres mostrar Engram en vivo: confirmar `engram --version` activo o dejar que `run-engram.ps1` complete el setup básico en primer uso.
6. `.engram-data/` se crea automáticamente en la primera invocación; su ausencia inicial ya no debe tratarse como error del demo.

---

## Mapa de Tiempos

| Segmento              | Versión ejecutiva | Versión completa (dev) |
|-----------------------|:-----------------:|:----------------------:|
| 0. Apertura           | 1 min             | 1 min                  |
| 1. Orquestador        | 1 min             | 2 min                  |
| 2. Contexto y tokens  | 1 min             | 2 min                  |
| 3. Implementación     | —                 | 4 min                  |
| 4. Engram             | —                 | 2 min                  |
| 5. Review y auditoría | 1 min             | 3 min                  |
| 6. Cierre             | 1 min             | 1 min                  |
| **Total**             | **5 min**         | **15 min**             |

---

## Segmento 0 - Apertura (1 min)

### Lo que dices

> "Hoy vemos un caso real de principio a fin.
> Un equipo recibe una solicitud: construir un CLI sencillo para gestionar tareas de standup.
> Vamos a ejecutarlo con el stack completo: desde que el orquestador lee el pedido
> hasta que cierra la sesión con evidencia auditable.
> No hay magia — cada paso es un comando reproducible."

### Lo que muestras en pantalla

```powershell
# Confirmar que el stack está en pie
./scripts/utilities/wf.ps1 status
```

### Puntos de anclaje (ejecutivo)

- "Esto es un workflow, no un experimento."
- "Cualquier miembro del equipo puede reproducir este ciclo exacto."

---

## Segmento 1 - Orquestador y modo de comunicación (2 min dev / 1 min exec)

### Lo que dices

> "El orquestador es el primer paso: verifica el estado del proyecto
> y recomienda qué modo de comunicación usar con la IA antes de empezar a trabajar.
> No es una recomendación manual — lee el branch, el tipo de tarea, y elige automáticamente."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/orchestrator-next-steps.ps1
./scripts/utilities/wf.ps1 response-mode
./scripts/utilities/wf.ps1 response-mode list
```

### Guion dev (ampliar)

> "Miren la sección 'Communication Mode Recommendation'.
> Si el branch fuera `hotfix/...` la recomendación cambiaría a `ultra`.
> Para una tarea de demo como esta, eligió `executive + lite` — respuestas concisas, sin overhead.
> Ese ajuste automático reduce tokens en aproximadamente un 50% versus el modo default sin configurar."

### Puntos de anclaje (ejecutivo)

- "El equipo no decide esto manualmente cada vez — el stack lo infiere."
- "50% menos de tokens = costo de AI recortado a la mitad en operaciones estándar."

---

## Segmento 2 - Reducción de contexto y tokens (2 min dev / 1 min exec)

### Lo que dices

> "Antes de abrir el chat o invocar la IA, generamos un contexto compacto.
> Esto evita que el modelo reciba información que no necesita — y eso baja el costo directo."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/response-mode-efficiency-matrix.ps1
```

### Guion dev (ampliar)

> "Esta matriz cubre las 27 combinaciones posibles: 3 idiomas × 3 niveles de detalle × 3 perfiles de compresión.
> La combinación activa está resaltada.
> Si quieren ver los ahorros en CSV para un reporte:"

```powershell
./scripts/utilities/response-mode-efficiency-matrix.ps1 -AsCsv
```

> "Esto es útil para justificación de costo frente a finanzas o procurement."

### Puntos de anclaje (ejecutivo)

- "Visual claro: la columna 'Yearly Token Savings' muestra el ahorro proyectado anual."
- "No es un cálculo teórico — está basado en el uso real del equipo calibrado por tarea."

---

## Segmento 3 - Implementación asistida por IA (4 min dev — solo versión completa)

### Lo que dices

> "Ahora la implementación. El proyecto ya existe en el repo — lo usamos como referencia.
> Vean que los comandos son idénticos en cualquier máquina: Go, sin dependencias externas."

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

> "Este proyecto usa JSON local para persistencia — sin base de datos, sin credenciales.
> La variable de entorno `TASK_TRACKER_DB` permite apuntar a otro archivo si lo necesitan en CI.
> Lo importante para el demo: cualquier feature pequeño que el stack implementa
> pasa por este mismo ciclo — el proyecto real es más grande, el proceso es idéntico."

> "En un escenario real el loop sería: abrir contexto compacto → pedir cambio a la IA
> → validar respuesta → commit. El response-mode ya estaba aplicado,
> así que la IA responde en el nivel correcto sin necesitar prompts extra."

### Pausa para preguntas técnicas (30 seg)

---

## Segmento 4 - Continuidad con Engram (2 min dev — solo versión completa)

### Lo que dices

> "Al cierre de cualquier sesión de trabajo — o antes de pasar la tarea a otro miembro —
> guardamos un resumen en Engram. Eso elimina el re-briefing en la siguiente sesión."

> "En una máquina nueva, este paso ya no depende de una carpeta precreada.
> El launcher la inicializa automáticamente y el resto del demo no queda bloqueado."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/run-engram.ps1 --help
```

> "Si Engram está activo, el ciclo es:"

```
mem_save   → guarda decisiones clave (bug encontrado, patrón elegido, deuda técnica identificada)
mem_search → al siguiente día, el agente retoma desde where we left off
```

### Guion dev (detalle)

> "Sin Engram, el equipo repite contexto verbal en cada sesión.
> Con Engram, el agente lee el historial, y el desarrollador arranca directamente en el problema.
> Redución de overhead de re-briefing: estimado 10-20 minutos por sesión larga."

### Puntos de anclaje (si hay ejecutivos presentes)

- "Memoria organizacional. No depende de que una persona recuerde."

---

## Segmento 5 - Code Review y Auditoría (3 min dev / 1 min exec)

### Lo que dices

> "El stack genera artefactos de review y auditoría como parte del workflow — no como paso extra.
> Esto es lo que le muestra a compliance, a QA, o a un cliente con requerimientos de trazabilidad."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/generate-session-review.ps1
./scripts/utilities/generate-audit-report.ps1 -Period weekly
```

### Guion dev (detalle)

> "Cada sesión genera su review en `docs/sessions/YYYY-MM-DD-TASK.md`.
> El audit report consolida actividad del período — útil para sprint retrospectivas o reportes de seguridad.
> Gentleman Guardian Angel agrega una capa de validación de estructura de código
> antes de que el artefacto llegue al review humano."

### Puntos de anclaje (ejecutivo)

- "Trazabilidad completa: quién trabajó qué, cuándo, con qué resultado."
- "Sin proceso manual de documentación — el stack lo genera."

---

## Segmento 6 - Cierre de sesión (1 min)

### Lo que dices

> "El último paso: cierre formal. Genera el artefacto de closure y deja el contexto listo para mañana."

### Lo que muestras en pantalla

```powershell
./scripts/utilities/wf.ps1 end-session demo-task-tracker
```

### Output esperado

Closure report guardado en `docs/sessions/` con:
- Tareas completadas.
- Modo de comunicación usado.
- Preset aplicado (y si fue auto-aplicado).
- Hash del último commit.

### Frase de cierre

> "Eso es un ciclo completo. Desde la solicitud hasta el artefacto de cierre —
> reproducible, medible, auditable.
> Las preguntas habituales son sobre ROI y sobre cómo se integra con el stack existente.
> Cubramos eso ahora."

---

## FAQ — Respuestas Preparadas

### "¿Cuánto ahorra esto realmente?"

> "La matriz de ahorro que vieron estima entre 30% y 50% de tokens por tarea según la combinación.
> El mayor retorno no es el costo de tokens — es el tiempo de ciclo.
> Un rework evitado en una tarea senior equivale a 2-4 horas.
> El stack reduce retrabajos porque mantiene contexto y aplica modo correcto desde el inicio."

### "¿Qué pasa si alguien no sigue el proceso?"

> "El workflow es permisivo — no bloquea.
> Pero el orchestrator y el GGA lanzan advertencias que quedan en logs.
> A nivel de PR, si la review generada no pasa los puntos de governance, el revisor lo ve."

### "¿Funciona con nuestro stack actual?"

> "Workspace-foundation es agnóstico al lenguaje. Lo que vieron en Go funciona igual en Python, TypeScript, o cualquier otro.
> La capa de integración con la IA es via prompt — no hay dependencia de IDE o provider específico."

### "¿Cómo se integra con Jira / Azure DevOps / etc.?"

> "Los artefactos son markdown + JSON. Pueden conectar con cualquier sistema vía webhook o pipeline CI.
> La integración directa con Jira y Azure Boards está en el roadmap como extensión de wf CLI."

### "¿Qué tan difícil es adoptarlo para un equipo nuevo?"

> "Getting Started está en `docs/getting-started/`. Primera sesión funcional en menos de 30 minutos.
> La curva de adopción más común: un par de sesiones para internalizar los presets,
> después el flujo se vuelve automático."

---

## Notas del Presentador

1. Si el demo falla en un comando, mostrar el output esperado del DEMO.md sin interrumpir el flujo.
2. Para audiencia 100% ejecutiva: saltar Segmentos 3 y 4, ir directo de 2 a 5.
3. Para audiencia 100% técnica: ampliar Segmento 3 con un cambio real de código y commit en vivo.
4. El proyecto task-tracker es intencionalmente simple — si alguien pregunta "¿es solo esto?", la respuesta es: "El proyecto es simple para que el proceso sea el protagonista, no el código."
5. Limpiar `demos/shared/task-tracker/tasks.json` antes de cada demo si hiciste una corrida de prueba.
