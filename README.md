# Workspace Foundation (Project Template)

Base template for creating standardized projects with integrated automation, validation, and AI support.

## Requirements

This project requires a standard development environment for Go and integration with AI via the Model Context Protocol (MCP).
- **Runtime**: Go 1.21+
- **Integration**: MCP Server support.

## Initialization

To set up a new project:

```powershell
./scripts/bootstrap-project.ps1
```

Este comando verificará automáticamente que la base de `workspace-foundation` esté presente y configurada.

## Validación de Sesión

Antes de finalizar una sesión de trabajo y subir los cambios al repositorio, es obligatorio ejecutar el script de validación:

```powershell
./scripts/validate-project.ps1
```

## Estructura del Proyecto

- `/internal`: Lógica de servidor web y adaptadores de Bitbucket.
- `/mcp`: Servidor Model Context Protocol para integración con asistentes de IA.
- `/scripts`: Automatizaciones específicas (Reviews, Bootstraps).
- `/html`: Plantillas dinámicas utilizando HTMX.

## Health Check
Puedes verificar el estado de las conexiones con Jira y Bitbucket ejecutando la herramienta `mcp_health_check` desde el servidor MCP.

---
*Proyecto derivado de Workspace Foundation.*