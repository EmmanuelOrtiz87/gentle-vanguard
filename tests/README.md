# Tests Directory

## Descripcin

Directorio centralizado para toda la suite de testing del proyecto workspace-foundation.

**Versin**: 1.0.0
**ltima actualizacin**: 2026-04-21
**Estado**:  PRODUCCIN

---

## Estructura de Directorios
``` 
tests/
  README.md                                      # Este archivo
  unit/
      engram-memory-manager.tests.ps1
      foundation-core.tests.ps1
  integration/
      auto-delegation-router.integration.tests.ps1
      engram-orchestrator.integration.tests.ps1
  performance/
      engram-performance.perf.tests.ps1
  security/
      input-validation.security.tests.ps1
```

## Tipos de Tests

| Tipo | Descripción |
|------|-------------|
| `unit/` | Pruebas unitarias de funciones core |
| `integration/` | Pruebas de integración entre módulos |
| `performance/` | Pruebas de rendimiento y carga |
| `security/` | Pruebas de seguridad y validación |