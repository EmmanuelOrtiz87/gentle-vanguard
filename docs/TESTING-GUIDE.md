# Testing Guide - Automated Test Suite

## Visión General

Este documento describe la suite de testing automatizado para workspace-foundation.

**Versión**: 1.0.0
**Fecha**: 2026-04-21
**Estado**: ✅ ACTIVO

---

## Tipos de Tests

### 1. Unit Tests
**Ubicación**: `tests/unit/*.tests.ps1`
**Framework**: Pester
**Propósito**: Verificar funciones individuales

**Cobertura**:
- Engram Memory Manager
- Dynamic Optimizer
- AI Tool Detector
- Cleanup Project

### 2. Integration Tests
**Ubicación**: `tests/integration/*.integration.tests.ps1`
**Framework**: Pester
**Propósito**: Verificar interacción entre componentes

**Cobertura**:
- Workflows end-to-end
- Integración Engram-Orquestador
- Consolidación automática

### 3. Performance Tests
**Ubicación**: `tests/performance/*.perf.tests.ps1`
**Framework**: Pester
**Propósito**: Verificar rendimiento

**Thresholds**:
- Engram creation: <50ms
- Consolidation: <100ms
- Compression: <200ms
- Optimization: <150ms

### 4. Security Tests
**Ubicación**: `tests/security/*.security.tests.ps1`
**Framework**: Pester
**Propósito**: Verificar seguridad

**Cobertura**:
- Validación de entrada
- Manejo de errores
- Encriptación
- Acceso a archivos

---

## Ejecutar Tests

### Todos los Tests
```powershell
.\scripts\testing\run-tests.ps1 -TestType all -GenerateReport
```

### Solo Unit Tests
```powershell
.\scripts\testing\run-tests.ps1 -TestType unit
```

### Solo Integration Tests
```powershell
.\scripts\testing\run-tests.ps1 -TestType integration
```

### Solo Performance Tests
```powershell
.\scripts\testing\run-tests.ps1 -TestType performance
```

### Solo Security Tests
```powershell
.\scripts\testing\run-tests.ps1 -TestType security
```

---

## Configuración

**Archivo**: `config/testing.config.json`

### Parámetros Principales

```json
{
  "testCoverage": {
    "minimumThreshold": 0.80,
    "targetThreshold": 0.90
  },
  "cicd": {
    "runOnCommit": true,
    "runOnPR": true,
    "failOnCoverageLow": true
  }
}
```

---

## Integración CI/CD

### Pre-Commit Hook
```bash
# Ejecuta unit tests antes de commit
git hook pre-commit: run-tests.ps1 -TestType unit
```

### Pre-Push Hook
```bash
# Ejecuta todos los tests antes de push
git hook pre-push: run-tests.ps1 -TestType all
```

### Pull Request
```bash
# Ejecuta tests en cada PR
CI/CD: run-tests.ps1 -TestType all -GenerateReport
```

---

## Reportes

### Ubicación
- Resultados: `test-results/`
- Cobertura: `coverage/`

### Formatos
- Console (salida en pantalla)
- JSON (datos estructurados)
- HTML (reporte visual)
- JUnit (compatible con CI/CD)

### Generación
```powershell
.\scripts\testing\run-tests.ps1 -GenerateReport
```

---

## Mejores Prácticas

### ✅ Hacer
- [x] Escribir tests para nuevas funciones
- [x] Mantener cobertura >80%
- [x] Ejecutar tests antes de commit
- [x] Revisar reportes de cobertura
- [x] Actualizar tests con cambios

### ❌ No Hacer
- [ ] Saltarse tests
- [ ] Reducir cobertura
- [ ] Ignorar fallos
- [ ] Hardcodear valores
- [ ] Dejar tests pendientes

---

## Troubleshooting

### Problema: Tests no se encuentran
**Solución**: Verificar estructura de directorios

```
tests/
├── unit/
├── integration/
├── performance/
└── security/
```

### Problema: Pester no instalado
**Solución**: Instalar módulo

```powershell
Install-Module -Name Pester -Force
```

### Problema: Tests fallan
**Solución**: Revisar logs

```powershell
.\scripts\testing\run-tests.ps1 -LogLevel debug
```

---

## Próximos Pasos

- [ ] Agregar más tests de cobertura
- [ ] Implementar load testing
- [ ] Agregar security scanning
- [ ] Integrar con SonarQube
- [ ] Crear dashboard de tests

---

## Referencias

- `config/testing.config.json` - Configuración
- `scripts/testing/run-tests.ps1` - Test runner
- `tests/unit/` - Unit tests
- `tests/integration/` - Integration tests