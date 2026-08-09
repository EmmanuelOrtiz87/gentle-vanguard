# Plugin System Local-First

> **Roadmap**: "Plugin system local-first — Plugins comunitarios sin dependencia cloud, solo git + archivos locales".

El stack Gentle-Vanguard permite extender su funcionalidad con **plugins comunitarios** que viven en
el filesystem local y se comparten mediante **git** o copia directa de directorios. No hay registry
cloud, no hay servidor central, no hay instalación de dependencias nuevas.

## Concepto

Un **plugin** es un directorio con:

- `plugin.json` — manifest con metadatos, entry point y hooks.
- scripts TS/JS — `index.ts` (entry) y, opcionalmente, scripts por hook.

Los plugins **no se importan en el proceso principal del stack**. El plugin-manager los ejecuta como
**procesos separados** (`npx tsx <script>` o `node <script>`), de modo que un plugin nunca puede
corromper ni inyectar estado en el proceso que lo gestiona.

## Dónde se descubren los plugins

| Ubicación                     | Fuente      | Propósito                                |
| ----------------------------- | ----------- | ---------------------------------------- |
| `plugins/`                    | `repo`      | Plugins incluidos/bundled con el stack   |
| `~/.gentle-vanguard/plugins`  | `user`      | Plugins instalados por el usuario        |
| rutas extra (`pluginsPaths`)  | `custom`    | Configuradas en `config/plugins.json`    |

## Formato del manifest (`plugin.json`)

```json
{
  "id": "example-hello",
  "name": "Example Hello",
  "version": "1.0.0",
  "description": "Plugin de ejemplo local-first",
  "author": "Gentle-Vanguard",
  "entry": "index.ts",
  "hooks": [
    { "event": "session-start", "script": "hooks/session-start.ts" }
  ],
  "enabled": true
}
```

| Campo        | Requerido | Descripción                                                              |
| ------------ | --------- | ------------------------------------------------------------------------ |
| `id`         | ✅        | Identificador único kebab-case (`^[a-z0-9][a-z0-9-]*$`)                   |
| `version`    | ✅        | Semver `MAJOR.MINOR.PATCH`                                               |
| `name`       | —         | Nombre legible (por defecto usa `id`)                                    |
| `description`| —         | Qué hace el plugin                                                       |
| `author`     | —         | Autor (persona u organización)                                           |
| `entry`      | —         | Script de entrada TS/JS (default `index.ts`). Backward-compat con `main`.|
| `hooks`      | —         | Array de eventos que escucha (`{ event, script }` o string con nombre)   |
| `enabled`    | —         | Estado por defecto (default `true`; el registry tiene prioridad)         |

El esquema canónico vive en `config/plugin-manifest-schema.json`. Los plugins del formato legacy
FF-011 (con `main: *.ps1`) siguen siendo detectados pero se marcan como inválidos si su entry no
existe.

## Eventos de hook disponibles

Eventos definidos por el stack y a los que los plugins pueden suscribirse:

| Evento         | Momento                                   | Script sugerido |
| -------------- | ----------------------------------------- | --------------- |
| `session-start`| Inicio de sesión (autostart pipeline)     | `hooks/session-start.ts` |
| `session-end`  | Cierre de sesión                          | `hooks/session-end.ts` |
| `pre-commit`   | Antes de un commit (git hook)             | `hooks/pre-commit.ts` |
| `post-commit`  | Después de un commit                      | `hooks/post-commit.ts` |
| `pre-deploy`   | Antes de un deploy                        | `hooks/pre-deploy.ts` |

Los eventos son cadenas libres: un plugin puede declarar cualquier evento que el stack (u otro
consumidor) dispare vía `runHooks(event)`. El runner ejecuta cada hook en un **proceso separado**
con timeout de 60s y recoge `stdout`/`stderr`/`status`.

## Comandos CLI

| Comando                                              | Descripción |
| ---------------------------------------------------- | ----------- |
| `npx tsx src/plugin-manager.ts list`                 | Lista plugins descubiertos (válidos e inválidos) |
| `npx tsx src/plugin-manager.ts --status`             | Resumen de estado (habilitados/deshabilitados/inválidos) |
| `npx tsx src/plugin-manager.ts install <git-url\|path>` | Instala desde git (clone) o path local (copia) |
| `npx tsx src/plugin-manager.ts install <target> --user` | Instala en `~/.gentle-vanguard/plugins` |
| `npx tsx src/plugin-manager.ts remove <id>`          | Desinstala (quita del registry y borra el directorio) |
| `npx tsx src/plugin-manager.ts remove <id> --keep-files` | Solo lo desregistra, conserva el directorio |
| `npx tsx src/plugin-manager.ts enable <id>`          | Habilita (persistido en `config/plugin-registry.json`) |
| `npx tsx src/plugin-manager.ts disable <id>`         | Deshabilita |
| `npx tsx src/plugin-manager.ts hooks <event>`        | Ejecuta los hooks de los plugins que escuchan `<event>` |

### Scripts npm

```bash
npm run plugin:list
npm run plugin:status
npm run plugin:install -- <git-url|path>
npm run plugin:install -- <target> --user
npm run plugin:remove -- <id>
npm run plugin:enable -- <id>
npm run plugin:disable -- <id>
npm run plugin:hooks -- session-start
```

## Instalación

### Desde git

```bash
npx tsx src/plugin-manager.ts install https://github.com/usuario/mi-plugin.git
# clona el repo a plugins/mi-plugin, valida el manifest y lo registra
```

Usa `git clone --depth 1` vía `runSync` (`src/core/run-command.ts`). El directorio destino se
deriva del nombre del repo; se puede forzar con `--name <kebab-case>`.

### Desde un path local

```bash
npx tsx src/plugin-manager.ts install /ruta/a/mi-plugin --user
# copia el directorio a ~/.gentle-vanguard/plugins/mi-plugin y lo registra
```

Cualquier instalación valida el manifest (id único, semver, entry existente). Si la validación
falla, el directorio se descarta y no se registra nada.

## Estado persistido

`config/plugin-registry.json` guarda la lista de plugins y su estado:

```json
{
  "version": "1.0.0",
  "plugins": {
    "example-hello": { "enabled": true, "source": "repo", "installedAt": "..." }
  }
}
```

- `config/plugin-registry.json` — fuente de verdad para `enable`/`disable`.
- `config/plugins.json` — paths de descubrimiento (`pluginsPaths`) y política de seguridad
  (`security.requireSignature`, `security.allowUnsigned`, `security.sandboxedExecution`).
  El campo legacy `enabledPlugins` se mantiene por compatibilidad FF-011 pero el registry lo
  reemplaza.

## Ejemplo incluido: `plugins/example-hello/`

```text
plugins/example-hello/
├── plugin.json            # manifest (id, version, entry, hooks)
├── index.ts               # entry: imprime "Hello from plugin"
└── hooks/
    └── session-start.ts   # hook del evento session-start
```

```bash
npx tsx src/plugin-manager.ts list                      # muestra example-hello (valid, enabled)
npx tsx src/plugin-manager.ts enable example-hello      # habilita
npx tsx src/plugin-manager.ts disable example-hello     # deshabilita
npm run plugin:hooks -- session-start                   # ejecuta el hook del plugin de ejemplo
```

## Integración con la pipeline de sesión

El step lazy `plugin-registry-load` en `config/session-autostart.config.json` ejecuta
`plugin-manager.ts list --quiet` al inicio de sesión (no bloqueante). Esto valida que el registry
se cargue y los manifests sigan siendo válidos sin perturbar la pipeline.

## Seguridad

- **Sin ejecución en el proceso principal**: los hooks y entries se lanzan como subprocesos
  (`runNpxTsxSync`/`runSync`), nunca con `import` dinámico. Un plugin no puede acceder al estado
  interno del stack.
- **Validación de ids**: los ids kebab-case evitan path traversal en el nombre de directorio.
- **Timeout por hook**: 60s para evitar plugins colgados.
- **Validación post-instalación**: si el manifest o el entry fallan, se descarta el directorio.
- La política de firma/arenero (`config/plugins.json.security`) queda disponible para endurecer
  la instalación de plugins de terceros no confiables.

## Verificación

```bash
npm run typecheck   # 0 errores
npm run lint        # 0 errores
npm run plugin:list
npm run plugin:hooks -- session-start
```
