# NORMATIVA DE SEGURIDAD: PNPM + --ignore-scripts

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Eliminar riesgos de seguridad en la cadena de suministro de dependencias npm.
Se adopta **pnpm** como gestor exclusivo y **--ignore-scripts** como flag obligatorio
para evitar ejecución de código arbitrario en scripts post-instalación de paquetes.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **pnpm como único gestor** — prohibido `npm install`, `yarn add`, o cualquier otro gestor. | CI/CD reject |
| 2 | **`--ignore-scripts` SIEMPRE** en toda instalación. `pnpm install --ignore-scripts` | CI/CD reject |
| 3 | **`package-lock.json` prohibido** en el repositorio. Solo `pnpm-lock.yaml`. | Pre-commit hook lo rechaza |
| 4 | **Scripts post-install deshabilitados** — ni `prepare`, `postinstall`, `preinstall` se ejecutan automáticamente. | Auditoría trimestral |
| 5 | **`engines` en package.json** debe declarar `"pnpm": ">=11.0.0"` | CI/CD reject |

## Comandos Aprobados

| Operación | Comando |
|-----------|---------|
| Instalar todo | `pnpm install --ignore-scripts --frozen-lockfile` |
| Agregar dep | `pnpm add <pkg> --ignore-scripts` |
| Agregar dep dev | `pnpm add -D <pkg> --ignore-scripts` |
| Compilar MCP | `pnpm build:mcp` |
| Ejecutar tests | `pnpm test` |

## Excepciones

Solo scripts de compilación explícitamente invocados vía `pnpm build:*` están permitidos.
Ningún script se ejecuta automáticamente en `postinstall` sin revisión de seguridad.

## CI/CD Enforcement

Agregar en workflows de GitHub Actions:

```yaml
- run: pnpm install --ignore-scripts --frozen-lockfile
- run: pnpm build:mcp
```

## Referencias

- `package.json` — engines.pnpm >= 11.0.0
- `scripts/build:mcp` — compila el servidor MCP de skills
- `opencode.json` — MCP server registrado con ruta `dist/scripts/mcp/skill-server.js`
