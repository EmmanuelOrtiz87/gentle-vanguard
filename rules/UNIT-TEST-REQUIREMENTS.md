# UNIT-TEST-REQUIREMENTS — Requisitos de Pruebas Unitarias

**Versión:** 1.0 | **Vigente desde:** July 14, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Definir los requisitos mínimos de pruebas unitarias para todo el código TypeScript en `src/`,
garantizando cobertura suficiente para mantener la calidad y prevenir regresiones.

## 2. Alcance

- Todo archivo `src/**/*.ts` debe tener su correspondiente archivo de prueba
- Quedan excluidos: archivos de tipos `*.d.ts`, entry points `src/index.ts`, barrel exports
- Las pruebas se ubican en `tests/unit/` siguiendo la convención `<module>.test.ts`

## 3. Cobertura Mínima

| Categoría                | Cobertura Mínima | Herramienta de Medición |
| ------------------------ | ---------------- | ----------------------- |
| Código general en `src/` | 70%              | Vitest `--coverage`     |
| Archivos críticos        | 80%              | Vitest `--coverage`     |
| Funciones de validación  | 90%              | Vitest `--coverage`     |
| Handlers de error        | 85%              | Vitest `--coverage`     |

## 4. Archivos Críticos (80%)

- `src/health-check.ts`
- `src/session-autostart.ts`
- `src/maintenance-watchtower.ts`
- Todo archivo en `src/security/`

## 5. Convención de Nomenclatura

```
tests/unit/<module>.test.ts
```

Ejemplos:

- `src/health-check.ts` → `tests/unit/health-check.test.ts`
- `src/session-autostart.ts` → `tests/unit/session-autostart.test.ts`
- `src/maintenance-watchtower.ts` → `tests/unit/maintenance-watchtower.test.ts`

## 6. Ejecución y Verificación

- Las pruebas se ejecutan con `npx vitest run --reporter=verbose`
- Cobertura se mide con `npx vitest run --coverage`
- El pipeline CI bloquea si la cobertura está por debajo del mínimo
- Los resultados se almacenan en `.session/test-results/` con timestamp

## 7. Excepciones

- Archivos en `src/vite-env.d.ts` o similares de declaración exentos
- Archivos con menos de 10 líneas lógicas pueden agruparse en una sola suite de prueba
- Exención temporal aprobada por código review con justificación documentada

## 8. Penalizaciones

- PR que reduce cobertura por debajo del mínimo → bloqueado automáticamente
- Archivo sin pruebas >7 días desde su creación → alerta semanal en dashboard
- Incumplimiento reiterado → revisión de arquitectura obligatoria
