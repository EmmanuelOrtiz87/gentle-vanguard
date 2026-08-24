# Normativa MCP — ciclo de vida y verificación

## Objetivo

Definir cuándo debe activarse cada MCP y evitar que el dashboard confunda una
configuración habilitada o un PID local con una conexión MCP real.

## Definiciones

- **Configurado**: aparece en `opencode.json`, `.zcode/config.json` o el registro del stack.
- **Host-managed**: OpenCode/ZCode inicia y mantiene el servidor stdio; no requiere un PID file del stack.
- **Stack-managed**: Gentle-Vanguard inicia y supervisa el proceso.
- **Verificado**: el host realizó handshake y `tools/list`, o la prueba específica del servidor pasó.
- **Stopped**: no hay proceso observado. No implica por sí solo un error.
- **Error**: fallo de handshake, herramienta, proceso gestionado o configuración inválida.

## Política

La fuente canónica es `config/mcp-lifecycle-policy.json`. Resumen operativo:

| MCP | Activación | Motivo |
|---|---|---|
| Engram | Siempre | Memoria persistente del proyecto |
| CodeGraph | Caliente durante desarrollo | Inteligencia de símbolos y grafo |
| Skill Server | Caliente al usar skills | Catálogo interno |
| LSP | Bajo demanda | Navegación y diagnósticos TypeScript |
| Filesystem | Bajo demanda | Superficie de permisos restringida |
| Chrome DevTools | Bajo demanda | Verificación visual |
| Fetch | Bajo demanda | Investigación externa y contenido no confiable |
| Sequential Thinking | Bajo demanda | Tareas complejas |
| Memory MCP | Deshabilitado por política | Redundante con Engram |

## Reglas de seguridad y operación

1. `enabled` nunca equivale a `connected`.
2. Para stdio, el dashboard debe mostrar `host-managed` y `unverified` cuando no tenga handshake propio.
3. Los PID files son evidencia auxiliar; un PID obsoleto no debe convertir automáticamente el workspace en `degraded`.
4. Un MCP con efectos laterales requiere activación explícita y permisos mínimos.
5. Engram permanece como fuente única de memoria; no se mezclan memorias sin migración aprobada.
6. Cada MCP nuevo requiere auditoría de descripción, permisos, transporte, origen y exposición antes de activarse.

## Verificación práctica

```powershell
npm run mcp:test                 # skill-server: compilación + tools/list
npm run mcp:fetch:test           # fetch: prueba segura bajo demanda
Invoke-RestMethod http://localhost:8080/api/health
Invoke-RestMethod http://localhost:8080/api/mesh
```

La health API prueba la capacidad del stack; la conexión efectiva de un MCP
host-managed debe verificarse también desde OpenCode/ZCode mediante handshake y
`tools/list`.
