# NORMATIVA — Design System Oficial y Activos de Marca

> **Estado:** ACTIVA · **Desde:** 2026-09-02 · **Decisión base:**
> `docs/brand/BRAND-DECISION-2026-09-01.md` (v2 Premium + logo v1 monogram con gradiente v2)

## 1. Objetivo

Definir qué piezas del sistema de diseño y la marca son **oficiales del stack**, dónde viven, cómo
se versionan y qué política de almacenamiento aplica a cada una — sin romper la política de apps
desacopladas (`apps/` = repo git anidada local-only).

## 2. Ubicación y jerarquía canónica

| Pieza                    | Ubicación                                                                      | Versionado git                                   | Rol                                                                       |
| ------------------------ | ------------------------------------------------------------------------------ | ------------------------------------------------ | ------------------------------------------------------------------------- |
| Decisión de marca        | `docs/brand/BRAND-DECISION-2026-09-01.md`                                      | Root repo                                        | Autoridad máxima (qué es la marca)                                        |
| Kit operacional          | `docs/brand/BRAND-KIT.md`                                                      | Root repo                                        | Punto de entrada para agentes/estándar de uso                             |
| Tokens técnicos (SoT)    | `docs/brand/TOKENS-v2.json`                                                    | Root repo                                        | Fuente única de valores                                                   |
| Logo oficial + variantes | `assets/logo.svg`, `assets/logo-mono-{light,dark}.svg`, `assets/logo-icon.svg` | Root repo                                        | Activos operativos                                                        |
| Config visual/CLI        | `config/brand.json` → `assets/tokens.{json,css,scss}`                          | Root repo                                        | Colores CLI/banners (generado: `npm run gv:tokens`)                       |
| Paquete de componentes   | `packages/gv-design-system/` (v2.0.0)                                          | **Root repo (excepción al ignore de packages/)** | Tokens consumibles + 7 componentes React + MCP server                     |
| CSS canónico clases      | `assets/gv-design-system.css`                                                  | Root repo                                        | **CONGELADO** (solo `--gv-*` actualizables; nuevo trabajo usa el paquete) |
| Herramienta visual       | `apps/design-hub/` (:8095)                                                     | Apps repo (desacoplada)                          | Gestión visual interactiva                                                |
| Skill cross-tool         | `.agents/skills/gv-design-system/` (sync 3 herramientas)                       | Root repo                                        | Auto-trigger de agentes                                                   |

**Regla de lectura para agentes:** `AGENTS.md` → `BRAND-DECISION` → `BRAND-KIT` → `TOKENS-v2.json` →
`assets/logo.svg` → Design Hub.

## 3. Contenido

- **Diseño oficial = v2 Premium**: bg `#0F1115`, purple `#a78bfa`, cyan `#22d3ee`, cyanDeep
  `#0891b2`, texto `#e8eef4`/`#8b95a8`, display **Space Grotesk**. Set completo en `TOKENS-v2.json`.
- **Logo oficial = monograma v1 con gradiente v2** (`assets/logo.svg`). Los archivos
  `docs/brand/assets/logo-*-v2.svg` (network) son históricos/rechazados; v3 Kinetic está archivada
  en Design Hub > Labs.
- Paquete `gv-design-system` v2.0.0 sirve exactamente ese canon (verificado vía MCP `list_tokens`).

## 4. Decisiones

1. **`packages/gv-design-system/` se versiona en el root repo** (excepción explícita en
   `.gitignore`: `packages/*` + `!packages/gv-design-system/`). Motivo: es infraestructura oficial
   del stack consumida por agentes (MCP) y apps (workspace); un dist stale ya causó un incidente de
   build (2026-09-02). Se versiona **src y dist** (dist pequeño, regenerable, pero trackearlo
   elimina la clase de drift stale). `node_modules/` queda ignorado como siempre.
2. Los demás paquetes (`packages/adaptive|custom|shared`) permanecen **local-only** bajo la política
   de desacoplamiento; si alguno se vuelve oficial, requiere update de esta normativa + excepción de
   gitignore explícita.
3. `config/brand.json` NO es la fuente de valores (lo es `TOKENS-v2.json`); es la configuración
   consumible por generadores CLI/visuales y siempre se regenera desde el canon
   (`npm run gv:tokens`).
4. Cambios de marca = editar `TOKENS-v2.json` → regenerar (paquete: build-tokens; CLI: gv:tokens) →
   actualizar espejo del Design Hub (`apps/design-hub/public/tokens/`) → commit en root (y apps repo
   si toca el hub).
5. Apps desacopladas (`apps/`): cada app copia el logo/tokens que consume (snapshot); NO se
   re-refactoriza centralizadamente — la homologación se hizo en la migración 2026-09-02.
6. **Footer homologado (2026-09-08)**: TODAS las apps usan el mismo patrón —
   `<span class="gv-footer-brand">Gentle<span>Vanguard</span></span> · <tagline app> — vX.Y.Z · <año>`.
   CSS canónico: `.gv-footer-brand { color: var(--gv-text, #e8eef4); font-weight: 800 }` +
   `.gv-footer-brand span { background: var(--gv-gradient); background-clip: text; color: transparent }`
   ("Gentle" blanco, "Vanguard" gradiente v2). Contenido extra app-específico (quick links, Labs) va
   DESPUÉS del bloque estándar. NOTA: `--gv-text-brand` (#a78bfa, púrpura) NO es válido para el
   brand del footer — el blanco canónico es `--gv-text`.
7. **Wordmark topbar — especificidad (2026-09-08)**: el CSS legacy v1 congelado
   (`assets/gv-design-system.css`) trae `.gv-brand span { color: var(--gv-primary) }` (0,1,1), que
   pinta "Gentle" cyan en cualquier app que cargue ese stylesheet. Las apps que lo cargan deben usar
   `.gv-brand .gv-wordmark { color: #e8eef4 }` (0,2,0) o equivalente de mayor especificidad. No
   editar el v1 congelado.
8. **Favicon obligatorio por app (2026-09-08)**: toda app con server propio debe servir
   `/favicon.svg` (monograma GV, `apps/<app>/public/favicon.svg`). Referencia: ruta añadida en
   `apps/command-center/server.ts`. Un 404 de favicon rompe la identidad en la tab del navegador.

## 5. Cumplimiento

- Auditoría de trazabilidad: grep de colores v1 (`#00BFFF|#A855F7|#121212`...) en CSS activo debe
  dar 0 (excepciones documentadas: labs del hub, assets históricos de docs/brand).
- `node apps/design-hub/tools/validate.js` verde (hub sin 404s, logo oficial en uso).
- `npx tsx packages/gv-design-system/src/cli/build-tokens.ts` sin divergencias src↔dist.
- Nueva UI debe pasar `impeccable detect` (waivers solo vía `.impeccable/config.json`).
