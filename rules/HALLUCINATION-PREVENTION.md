# HALLUCINATION-PREVENTION — Prevención de Alucinaciones en Código Generado

**Versión:** 1.0 | **Vigente desde:** July 14, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Establecer barreras sistemáticas contra la generación de código que haga referencia a símbolos,
rutas o comportamientos inexistentes en la base de código real (alucinaciones). Todo código generado
debe estar anclado al índice CodeGraph.

## 2. Verificación Contra CodeGraph

### 2.1 Consulta Obligatoria

- Antes de referenciar cualquier símbolo (función, clase, variable, tipo, interfaz), ejecutar
  `codegraph_search` para confirmar su existencia y ubicación exacta
- Si el símbolo no existe en el índice, no generarlo — preguntar al usuario o proponer creación

### 2.2 Modo Verify

- Todo bloque de código generado debe pasar por `codegraph_node` + `codegraph_callers` para
  verificar que las llamadas y dependencias existen realmente
- El modo verify se activa automáticamente mediante el flag `--verify` en el pipeline

## 3. Anti-Patrones

| Anti-Patrón                         | Riesgo                       | Mitigación                           |
| ----------------------------------- | ---------------------------- | ------------------------------------ |
| Inventar rutas de import            | Import no resuelto           | `codegraph_search` antes de escribir |
| Asumir API sin consultar código     | Llamada a método inexistente | `codegraph_node` sobre el módulo     |
| Generar config sin verificar schema | Archivo inválido             | Validar contra JSON schema existente |
| Pseudocódigo en lugar de real       | Código no compila            | Ejecutar `npm run typecheck`         |
| Reusar firmas de otro proyecto      | Type mismatch                | No asumir — verificar tipo real      |

## 4. Pipeline de Prevención

1. `codegraph_search` → confirmar existencia de símbolos referenciados
2. `codegraph_callers` → verificar que las funciones llamadas existen
3. Generar código anclado a rutas y firmas reales
4. `npm run typecheck` (o equivalente) — mandatory post-generation
5. Si typecheck falla, corregir contra el error real, no inventar arreglos

## 5. Excepciones

- Código nuevo sin dependencias del código existente puede saltarse pasos 1-2, pero debe pasar el
  paso 4 antes de considerarse válido
- Prototipos descartables (branch `explore/*`) exentos de verify completo
