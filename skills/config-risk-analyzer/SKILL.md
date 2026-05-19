---
name: config-risk-analyzer
description: >
  Analyze risks in configuration files, detect inconsistencies, validate schemas. Trigger:
  "config-risk-analyze", "validate-config", "check-config-integrity".
---

# Config Risk Analyzer Skill

## Objetivo

Analizar riesgos en archivos de configuración, detectar inconsistencias, validar esquemas y prevenir
errores de configuración que puedan afectar la funcionalidad del proyecto.

## Triggers

- `config-risk-analyze`
- `validate-config`
- `check-config-integrity`
- `config-schema-validate`

## Responsabilidades

### 1. Análisis de Riesgos

- Detectar cambios en archivos de configuración
- Validar contra esquemas JSON
- Identificar inconsistencias cross-workspace
- Verificar compatibilidad entre configuraciones relacionadas

### 2. Validaciones Exhaustivas

- Validar tipos de datos
- Verificar valores requeridos
- Comprobar patrones y formatos
- Validar referencias cruzadas

### 3. Generación de Reportes

- Crear análisis de riesgos detallado
- Listar problemas encontrados
- Proponer soluciones alternativas
- Recomendar acciones correctivas

### 4. Delegación

- Identificar quién debe resolver cada problema
- Crear tickets de corrección
- Registrar en lecciones aprendidas
- Solicitar confirmación de resolución

## Archivos Monitoreados

- `opencode.json` - Configuración principal de OpenCode
- `config/*.json` - Todas las configuraciones del proyecto
- `scripts/utilities/*.config.json` - Configuraciones de herramientas
- `workspace.config.json` - Configuración del workspace

## Riesgos Conocidos (Lecciones Aprendidas)

### Error: agent.default debe ser objeto, no string

- **Fecha:** 2026-05-02
- **Causa:** opencode.json tenía strings en lugar de objetos
- **Impacto:** OpenCode no funcionaba
- **Solución:** Cambiar a estructura de objeto: `{ "name": "general" }`
- **Prevención:** Validar esquema antes de guardar

### Error: VerbosePreference incompatible con [switch]

- **Fecha:** 2026-05-02
- **Causa:** Pasar ActionPreference a parámetro switch
- **Impacto:** Norm enforcement fallaba
- **Solución:** Convertir a boolean: `$VerbosePreference -eq "Continue"`
- **Prevención:** Validar tipos de parámetros en PowerShell

### Inconsistencias cross-workspace

- **Fecha:** 2026-05-02
- **Causa:** Archivos desincronizados entre local y gentle-vanguard
- **Impacto:** Comportamiento inconsistente
- **Solución:** Ejecutar cross-workspace-validator -Fix
- **Prevención:** Validar sincronización en cada cambio

## Flujo de Validación

```
1. Detectar cambio en archivo de configuración
   ↓
2. Cargar esquema correspondiente
   ↓
3. Validar estructura y tipos
   ↓
4. Verificar referencias cruzadas
   ↓
5. Buscar en lecciones aprendidas
   ↓
6. Generar análisis de riesgos
   ↓
7. Proponer soluciones
   ↓
8. Delegar a agente correspondiente
   ↓
9. Registrar en lecciones aprendidas
   ↓
10. Confirmar resolución
```

## Integración

Este skill se integra con:

- `config-validator` agent - Para aplicar validaciones
- `cross-workspace-validator.ps1` - Para sincronización
- Hooks pre-commit - Para validación automática
- Engram - Para almacenar lecciones aprendidas

## Salida Esperada

```json
{
  "status": "success|warning|error",
  "file": "path/to/config.json",
  "timestamp": "2026-05-02T11:53:57Z",
  "validations": [
    {
      "type": "schema",
      "status": "passed|failed",
      "message": "Descripción del resultado"
    }
  ],
  "risks": [
    {
      "level": "critical|high|medium|low",
      "description": "Descripción del riesgo",
      "solution": "Solución propuesta",
      "delegateTo": "agent-name"
    }
  ],
  "lessonsLearned": [
    {
      "pattern": "Patrón de error detectado",
      "prevention": "Cómo prevenirlo"
    }
  ],
  "confirmationRequired": true|false
}
```
