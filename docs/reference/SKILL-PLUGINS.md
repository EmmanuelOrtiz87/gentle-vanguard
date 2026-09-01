# Skill Plugins — Contrato y Ciclo de Vida (F3.4)

Sistema de plugins que permite a un tercero (estudiante, comunidad) instalar una skill externa con
`gv skill install <url-o-ruta>` pasando validación de esquema, permisos y escaneo de secretos, y
quedar registrada en el índice del stack.

- Código: `src/plugins/` (`skill-manifest.ts`, `skill-registry.ts`, `skill-install.ts`,
  `skill-cli.ts`)
- CLI: `gv skill <subcomando>` (delega en `src/plugins/skill-cli.ts`)
- Índice: `.runtime/skill-plugins.json` (con hash SHA-256 de integridad)
- Tests: `tests/unit/skill-plugins.test.ts`, fixtures en `tests/fixtures/skill-plugins/`

## Contrato del manifest

Una skill instalable se declara de DOS formas equivalentes (basta una):

### Opción A — `gv-plugin.json` (explícita, preferida)

```json
{
  "name": "mi-skill-genial",
  "version": "1.2.0",
  "description": "Enseña X mediante ejemplos progresivos y ejercicios.",
  "source": "https://github.com/alguien/mi-skill-genial",
  "license": "MIT",
  "permissions": ["filesystem-read"],
  "entrypoint": "SKILL.md",
  "metadata": { "author": "Alguien", "homepage": "https://..." }
}
```

### Opción B — frontmatter de `SKILL.md` (formato real del repo)

```yaml
---
name: mi-skill-genial
description: >
  Enseña X mediante ejemplos progresivos y ejercicios. (Descripción larga con `>` folded.)
metadata:
  source: https://github.com/alguien/mi-skill-genial
  license: MIT
  version: 1.2.0 # OBLIGATORIO para instalar como plugin
  permissions: filesystem-read # o lista separada por comas
  author: Alguien
---
```

El parser soporta el formato que ya usan las ~199 skills del repo: escalares, descripciones `>`
multilínea, arrays con `-` (guión) y el bloque anidado `metadata:` a un nivel.

### Reglas de validación (zod)

| Campo         | Regla                                                                                     |
| ------------- | ----------------------------------------------------------------------------------------- |
| `name`        | kebab-case (`^[a-z0-9]+(-[a-z0-9]+)*$`), 2–64 chars. Es el nombre del directorio destino. |
| `version`     | semver estricto (`1.2.0`, permite prerelease/build).                                      |
| `description` | 10–4000 chars.                                                                            |
| `permissions` | array no vacío del enum cerrado; `none` es exclusivo. Default `["none"]`.                 |
| `entrypoint`  | ruta relativa dentro de la skill (sin `/` inicial ni `..`). Default `SKILL.md`.           |
| `license`     | identificador estilo SPDX (opcional).                                                     |
| `source`      | proveniencia: URL o ruta (opcional).                                                      |
| `metadata`    | objeto libre (autor, homepage, tags; opcional).                                           |

## Modelo de permisos

Enum cerrado (cualquier otro valor RECHAZA la instalación):

| Permiso            | Significado                                       |
| ------------------ | ------------------------------------------------- |
| `filesystem-read`  | La skill necesita leer archivos del workspace.    |
| `filesystem-write` | La skill escribe archivos.                        |
| `network`          | La skill accede a red (fetch, APIs).              |
| `subprocess`       | La skill lanza procesos hijos.                    |
| `none`             | Solo lectura de contexto por el agente (default). |

`none` no puede combinarse con otros permisos. Los permisos son **declarativos**: quedan registrados
en el índice para auditoría y revisión humana antes de confiar en una skill externa. Las skills
instaladas quedan estampadas con `source: external-installed` (mismo convenio que las skills
adoptadas `external-adopted` de Fases 1-3).

## Fuentes de instalación

| Tipo    | Ejemplo                             | Mecanismo                                              |
| ------- | ----------------------------------- | ------------------------------------------------------ |
| Local   | `./mi-skill`                        | copia directa                                          |
| Git     | `https://github.com/user/repo.git`  | `git clone --depth 1` (argv array, `windowsHide`)      |
| Archivo | `https://.../skill.tar.gz` o `.zip` | `fetch` + `tar -xf` (bsdtar nativo Win10+/macOS/Linux) |

Tras el fetch, el instalador localiza el directorio que contiene `SKILL.md` o `gv-plugin.json` (raíz
o subdirectorio inmediato — soporta repos con la skill en un subdirectorio).

## Pipeline de instalación

1. **Fetch** del fuente (local/git/archivo) a un directorio temporal.
2. **Validación de manifest** (zod): esquema + permisos del enum cerrado.
3. **Escaneo de secretos** del payload: reutiliza el secret scanner real del repo
   (`src/security/secret-scanner/`, 80 patrones) sobre todos los archivos de texto (`.md`, `.ts`,
   `.sh`, `.env`, …). Cual hallazgo de riesgo alto/medio **rechaza** la instalación y no se escribe
   nada.
4. **Copia** a `skills/<name>/`.
5. **Estampado de frontmatter** (solo si `entrypoint` es `SKILL.md`): se agregan a `metadata:`
   `source: external-installed`, `installed-from`, `installed-at` y `checksum` (SHA-256 del
   SKILL.md). El body se preserva intacto.
6. **Registro** idempotente en `.runtime/skill-plugins.json` con integridad SHA-256.

## Ciclo de vida

```
install -> enabled ── disable ──> disabled ── enable ──> enabled
                └──── deprecate ──> deprecated
cualquier estado ── remove ──> (fuera)
```

- `enabled`: disponible para los agentes.
- `disabled`: instalada pero ignorada.
- `deprecated`: marcada como obsoleta (se lista con `[~]`).
- `remove`: borra `skills/<name>/` y la entrada del índice.

Reinstalar la misma skill es idempotente: conserva `installedAt` y el estado; refresca el resto.

## CLI

```
npx tsx src/cli/gv.ts skill list                     # estado del índice (parseable)
npx tsx src/cli/gv.ts skill install <url-o-ruta>     # instala (valida + escanea + registra)
npx tsx src/cli/gv.ts skill enable|disable|deprecate <name>
npx tsx src/cli/gv.ts skill remove <name>
npx tsx src/cli/gv.ts skill verify                   # verifica hash de integridad del índice
npx tsx src/cli/gv.ts skill get <name>               # detalle JSON de una entrada
```

Todos aceptan `--json` para salida máquina. Exit code: 0 = éxito, 1 = fallo.

## Guía de autoría (para estudiantes/comunidad)

1. Crea un directorio con tu `SKILL.md` (o añade un `gv-plugin.json` si quieres control total).
2. Frontmatter mínimo instalable:

   ```yaml
   ---
   name: mi-skill
   description: Qué hace y cuándo usarla (descripción de disparadores clara).
   metadata:
     version: 1.0.0
     license: MIT
     permissions: none # declara SOLO lo que realmente necesitas
   ---
   ```

3. NUNCA incluyas credenciales, tokens ni claves en el payload — el instalador lo rechazará.
4. Distribuye como repo git, `.tar.gz` o directorio local y comparte la URL:
   `gv skill install <tu-url>`.
5. Verifica el resultado con `gv skill list` / `gv skill get <name>`.

## Seguridad

- Enum de permisos cerrado y validado en instalación.
- Escaneo de secretos con los 80 patrones reales del stack antes de copiar nada.
- Índice con hash SHA-256 (`gv skill verify` detecta manipulación manual del JSON).
- Proveniencia completa por entrada: origen, fecha, checksum, tipo de fuente.
- Todos los spawns siguen `src/core/run-command.ts` (argv arrays, `windowsHide`, sin cadenas shell,
  sin `npx.cmd`) conforme a la regla de oro de procesos-ocultos de AGENTS.md.
