# MODELO FALLBACK - Solución de Emergencia

## Problema Identificado
- Los subagentes (task) están hardcodeados para usar opencode/deepseek-v4-flash-free
- No hay tokens disponibles en opencode
- La herencia con [INHERITED_MODEL_CONFIG] no funciona en el sistema nativo de task()

## Solución Propuesta: Ejecución Directa
En lugar de usar subagentes (task), ejecutar el trabajo directamente como orchestrator.

## Ventajas:
1. Usa kimi-2-5 (el modelo del orchestrator)
2. No consume tokens de opencode
3. Trabajo se hace igual
4. Mayor control

## Implementación:
- Crear los skills manualmente (como ya están creados)
- Ejecutar optimizaciones directamente
- Documentar que task() usa opencode por diseño del sistema

## Status: ✅ ACEPTADO PARA CONTINUAR
