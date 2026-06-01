# SIA Benchmark Tasks

Tareas internas para probar y calibrar el loop SIA.

## Task 1: PowerShell Skill Lister

**Spec**: Escribir un script PowerShell que liste todas las skills en `skills/` agrupadas por directorio, mostrando nombre, trigger principal, y source. Output en tabla formateada.

**Expected**: `scripts/sia/bench/skill-lister.ps1`

**Success criteria**:
- Recorre `skills/*/SKILL.md`
- Extrae `name:` y `description:` del frontmatter
- Muestra tabla con columnas alineadas

## Task 2: JSON Schema Validator

**Spec**: Generar script PowerShell que valide un archivo JSON contra un schema dado, mostrando errores con ruta completa del campo fallido.

**Expected**: `scripts/sia/bench/json-validator.ps1`

**Success criteria**:
- Soporta tipos: string, number, boolean, array, object
- Errores con `field.path -> expected type, got actual`
- Exit code: 0 si válido, 1 si inválido

## Task 3: Semantic Search Function

**Spec**: Crear función PowerShell que implemente búsqueda semántica simple usando cosine similarity sobre embeddings basados en palabras clave (sin dependencias externas).

**Expected**: `scripts/sia/bench/semantic-search.ps1`

**Success criteria**:
- Tokeniza texto en palabras
- Crea vector de frecuencia
- Calcula cosine similarity
- Retorna top-N resultados

## Task 4: Monolith Refactor

**Spec**: Dado un script monolítico de 200+ líneas, refactorizarlo en módulos separados con funciones especializadas y un main que los coordine.

**Expected**: `scripts/sia/bench/refactored/`

**Success criteria**:
- Mínimo 3 módulos
- Cada módulo tiene una responsabilidad única
- Main script es < 30 líneas
- Comportamiento preservado

## Running

```powershell
# Run a benchmark task through SIA
.\scripts\sia\sia-orchestrator.ps1 -TaskSpec (Get-Content docs/sia/BENCHMARK-TASKS.md -Raw) -OutputDir ".sia-bench"
```
