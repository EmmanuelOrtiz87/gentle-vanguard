# Workspace Foundation

This is the agnostic base project designed to manage development infrastructure, AI tools, and default skills.

## Architecture

- **Core**: Automation scripts in `scripts/`.
- **Tools**: Binaries and tool repositories (Engram, Gentleman Skills) in `tools/`.
- **Config**: Global definitions in `config/workspace.config.json`.
- **Projects**: Directory intended for projects that implement this base.

## Initialization

To configure a new machine from scratch, run:
```powershell
./scripts/bootstrap.ps1
```

### Gentleman Skills
Este proyecto actúa como el host principal de `Gentleman-Skills`. Los proyectos hijos (como Dashboard) deben referenciar la ruta `tools/Gentleman-Skills` para cargar las capacidades del agente.

## Uso en Proyectos Derivados

Cualquier proyecto nuevo (ej. `bitbucket-dashboard`) debe:
1. Ubicarse en una ruta relativa que permita acceder a Foundation.
2. Tener un script `bootstrap-project.ps1` que llame al bootstrap de Foundation.
3. No duplicar lógica de herramientas; usar los lanzadores de Foundation (`run-engram.ps1`).

## Flujo de Trabajo y Validación

Cualquier cambio en la base debe ser validado antes de finalizar la sesión:
```powershell
./scripts/validate-project.ps1
```
Esto garantiza que GGA, Gentleman-Skills y la integridad del repositorio estén en orden.

## Health Check
El sistema incluye validaciones en:
- **Nivel OS**: `bootstrap.ps1` verifica binarios y paths.
- **Nivel IA**: El servidor MCP incluye la herramienta `mcp_health_check` para validar conectividad con APIs externas (Jira/Bitbucket).

---
*Mantenido por el Agente IA de Engram.*