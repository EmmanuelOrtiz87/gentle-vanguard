# create-gentle-vanguard — Bootstrap del stack

`create-gentle-vanguard` es el template de bootstrap del stack Gentle-Vanguard. Permite crear un
proyecto nuevo con la estructura base del stack en un solo comando, sin dependencias cloud y 100%
local-first.

## Uso

Desde la raíz del repositorio (o vía npm script):

```bash
# Interactivo (pregunta el nombre del proyecto)
npx tsx src/create-gentle-vanguard.ts

# Con nombre explícito
npx tsx src/create-gentle-vanguard.ts --name mi-app

# Con directorio de destino explícito
npx tsx src/create-gentle-vanguard.ts --name mi-app --target ../mi-app

# Preview: qué copiaría, sin escribir nada
npx tsx src/create-gentle-vanguard.ts --name mi-app --dry-run

# Sin ejecutar npm install al final
npx tsx src/create-gentle-vanguard.ts --name mi-app --no-install

# No interactivo (auto-acepta npm install)
npx tsx src/create-gentle-vanguard.ts --name mi-app --yes
```

También están disponibles como scripts npm:

| Comando                   | Descripción                                                                   |
| ------------------------- | ----------------------------------------------------------------------------- |
| `npm run create`          | Asistente real de creación (interactivo o con flags)                          |
| `npm run create:template` | Demo en dry-run: `--name gentle-vanguard-app --target ../gentle-vanguard-app` |

## Flags

| Flag              | Alias | Descripción                                            |
| ----------------- | ----- | ------------------------------------------------------ |
| `--name <nombre>` | `-n`  | Nombre del proyecto (se slugifica a nombre de paquete) |
| `--target <dir>`  | `-t`  | Directorio de destino (default: `./<nombre>`)          |
| `--dry-run`       | `-d`  | Muestra qué copiaría, sin escribir nada                |
| `--no-install`    |       | No ejecutar `npm install` al final                     |
| `--yes`           | `-y`  | No preguntar nada (auto-acepta `npm install`)          |
| `--help`          | `-h`  | Muestra la ayuda del CLI                               |

## Qué copia

El template copia la estructura base del stack aplicando una ignore list (`node_modules`, `.git`,
`.runtime`, `.session`, `.telemetry`, `.codegraph`, `dist`, `coverage`, `keys`, `protected`,
`graphify-out`, lockfiles, configs `*.local.json`, etc.):

- `config/` — configuración del stack (orchestrator, model-router, sesión…)
- `src/` — fuentes TypeScript del stack (CLI, core, mcp, database, cli…)
- `adapters/`, `scripts/`, `rules/`, `tests/`, `docs/` — soporte del stack
- `.opencode/` — agentes y skills de opencode
- Archivos raíz de soporte: `tsconfig.json`, `eslint.config.js`, `opencode.json`, `AGENTS.md`,
  `.gitignore`, `.env.example`, configs de hooks/lint/security

**NO copia**: `node_modules`, `.git`, directorios de runtime/estado (`.runtime`, `.session`,
`.telemetry`, `.codegraph`, `graphify-out`, `keys`, `protected`, `logs`, `backups`, …), `apps/`,
`dist/`, `coverage/`, lockfiles ni overrides locales (`*.local.json`, `.env`).

## Genera además

- `package.json` base (nombre del proyecto, scripts esenciales, deps mínimas: `tsx`, `typescript`,
  `eslint`, `glob`, `zod` — cero dependencias cloud).
- `README.md` con instrucciones de inicio rápido.

## Siguientes pasos en el proyecto creado

```bash
cd <proyecto>
npm install
npm run stack:setup -- --yes   # deps de máquina, Nexus DB, git hooks, graphify
npm start                      # dashboard / quick-start
```

## Implementación

- `src/create-gentle-vanguard.ts` — CLI TypeScript nativo. Expone helpers puros (`isIgnored`,
  `filterCopyable`, `sanitizeProjectName`, `buildBasePackageJson`, `buildReadme`, `walkProject`)
  testeados sin tocar disco.
- `tests/unit/create-gentle-vanguard.test.ts` — test unit del filtrado de la ignore list y helpers
  puros.
- El `--dry-run` lista los archivos que copiaría agrupados por directorio, con total de archivos y
  tamaño estimado.

## Notas

- Reutiliza los scripts del stack (`src/stack-setup.ts`, `src/core/run-command.ts`) en vez de
  duplicar funcionalidad.
- El destino no debe existir y no estar vacío (si existe, aborta con error).
