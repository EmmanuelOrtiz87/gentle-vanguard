# Fase 4 — SIA: Self-Improving Agent Loop

## Objetivo

Implementar un loop de auto-mejora de 3 agentes dentro de la orquestación GV:

```
META-AGENT → escribe TARGET (código/tarea)
FEEDBACK-AGENT → revisa y critica el TARGET
TARGET → ejecuta (el propio código/tarea generado)
```

## Arquitectura

### Ciclo SIA (3 agentes)

```
┌─────────────────────────────────────────────┐
│               ORCHESTRATOR                    │
│  ┌──────────┐   ┌──────────────┐   ┌──────┐ │
│  │ META     │──▶│ FEEDBACK     │──▶│SELF  │ │
│  │ (escribe)│   │ (revisa)     │   │(eval)│ │
│  └──────────┘   └──────────────┘   └──────┘ │
│       │               │               │      │
│       ▼               ▼               ▼      │
│   target.ps1     review.md        score.json │
└─────────────────────────────────────────────┘
         │
         ▼
   ¿score ≥ threshold?
     ├── Sí → merge/archive
     └── No → loop: META recibe feedback + itera
```

### Componentes

| Componente     | Archivo                                | Propósito                     |
| -------------- | -------------------------------------- | ----------------------------- |
| Orquestador    | `scripts/sia/sia-orchestrator.ps1`     | Coordina el loop de 3 agentes |
| Meta-agent     | `config/agent-prompts/SIA-META.md`     | Prompt para generar target    |
| Feedback-agent | `config/agent-prompts/SIA-FEEDBACK.md` | Prompt para revisar target    |
| Benchmark      | `docs/sia/BENCHMARK-TASKS.md`          | Tareas internas de prueba     |
| Skill          | `skills/sia-skill/SKILL.md`            | Registro como skill GV        |

### Flujo

1. **META**: Recibe especificación → escribe `target.ps1` (o cualquier output)
2. **FEEDBACK**: Lee `target.ps1` → evalúa criterios → escribe `review.md`
3. **ORCHESTRATOR**: Lee `review.md` → calcula `score` (0-100)
4. **Decisión**: score ≥ 80 → éxito; score < 80 → loop (max 5 iteraciones)

### Criterios de evaluación (FEEDBACK-agent)

| Criterio    | Peso | Descripción                             |
| ----------- | ---- | --------------------------------------- |
| Correctness | 30%  | ¿El target resuelve el problema?        |
| Efficiency  | 20%  | ¿Es la solución óptima?                 |
| Style       | 15%  | ¿Sigue convenciones GV?                 |
| Safety      | 20%  | ¿Sin secretos, hardcodeo, side effects? |
| Docs        | 15%  | ¿Documentación adecuada?                |

### Benchmark tasks

| #   | Tarea                                                     | Categoría  | Score inicial esperado |
| --- | --------------------------------------------------------- | ---------- | ---------------------- |
| 1   | Escribir script PowerShell que liste skills por categoría | scripting  | —                      |
| 2   | Generar validación JSON con mensajes de error             | validation | —                      |
| 3   | Crear función de búsqueda semántica simple                | algorithm  | —                      |
| 4   | Refactorizar función monolítica en módulos                | refactor   | —                      |

### Registro en auto-delegation.json

```json
"skillToAgentProfile": {
  "sia-skill": "SIA"
},
"keywordMappings": {
  "SIA": [
    "\"self-improving\"",
    "\"auto-mejora\"",
    "\"sia loop\"",
    "\"meta-agent\"",
    "\"feedback agent\"",
    "\"self improvement\"",
    "\"improve yourself\"",
    "\"mejora continua\""
  ]
}
```

### Timeline estimado

| Paso                      | Duración  |
| ------------------------- | --------- |
| Crear orquestador SIA     | 1h        |
| Prompts META + FEEDBACK   | 30min     |
| Benchmark tasks           | 30min     |
| Prueba inicial (3 tareas) | 1h        |
| Ajuste thresholds         | 30min     |
| **Total**                 | **~3.5h** |
