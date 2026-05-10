# Guía para Próxima Sesión

**Última sesión**: 2026-05-10  
**Sesión**: session-2026-05-10-03  
**Estado**: Foundation v2.9.0 — workspace verificado  
**Branch activo**: `main`

## Estado del Workspace

Workspace completamente operativo con 126 skills, auto-delegación activa, CI/CD con 15 workflows, 6 normativas activas, y tool configs para 8 herramientas.

**Fuente de verdad canónica**: `docs/AGENTS.md` (tool-agnostic) + `config/auto-delegation.json` + `rules/` + Engram.

Para verificar al inicio:
```powershell
pwsh -File scripts/utilities/agent-verify.ps1
```

## Novedades de esta Sesión (2026-05-10-02)

### Fix: Fuente de Verdad
- **ROTO**: `.clinerules` + `.cursorrules` decían "See `CLAUDE.md` for the single source of truth"
- **CORREGIDO**: Ahora apuntan a `docs/AGENTS.md` + `config/auto-delegation.json` + `rules/` + Engram
- `CLAUDE.md` es ahora tool-specific, referencia a `docs/AGENTS.md` como canonical entry point

### Fix: SKILL.md Frontmatter Regex
- `pre-process-input.ps1:42` — regex capturaba solo el primer trigger quoteado; corregido con `[regex]::Matches()` multi-capture
- `trigger-detector.ps1:26` — mismo bug; corregido con capture broader primero
- `skills/session-workflow-skill/SKILL.md` — frontmatter cambiado de YAML single-quoted a `description: >` estándar

### Mejora: session-autostart.cmd
- Workspace root detection automática
- Pre-flight health check (CRITICAL + WARN)
- Paths consistentes relativos a workspace root

### Nuevo: session-autostart.sh (Linux/macOS/WSL)
- `scripts/utilities/session-autostart.sh` — creado, análogo al .cmd
- Mismos health checks + 8 fases de autostart
- Usa `pwsh` para invocar los scripts PowerShell compartidos

### Nuevo: Tool Configs para 7 Herramientas
- `.cursor/config.json`, `.cline/config.json`, `.vscode/settings.json`
- `.codex/config.json`, `.antigravity/config.json`
- Todos con LOCAL-FIRST, pre-processing mandatory, español default
- `.windsurf/config.json` + `.continue/config.json` ya existían y fueron verificados

### Nuevo: Premortem Skill
- `skills/premortem-skill/SKILL.md` — método Klein (HBR) + Kahneman
- Registrado en `auto-delegation.json` como agente `PREMORTEM` (temp 0.5, parallel_capacity 8)
- 18 keywords mapeadas, perfil dedicado, subagent-mapping con parallel_subagents: true

### FF-011: Plugin Architecture Implementado
- `scripts/utilities/SKILLS-TOOLS/plugins-discovery.ps1` — Nuevo: descubrimiento, listado, validación de plugins con 4 acciones (discover/list/validate/paths)
- `scripts/utilities/SKILLS-TOOLS/plugin-loader.ps1` — Nuevo: motor runtime con 7 funciones (Get-PluginManifest, Get-PluginMetadata, Invoke-Plugin, Register-Plugin, Unregister-Plugin, Get-RegisteredPlugins, Initialize-Plugins)
- `config/plugin-manifest-schema.json` — Mejorado: añadidos campos `main`, `dependencies`, estructura commands con oneOf (string | object)
- `plugins/examples/hello-world.ps1` — Fix: referencia FF-016 → FF-011
- `.github/workflows/autonomous-validation.yml` — Nuevo step `Validate Plugins` que corre `plugins-discovery.ps1 -Action validate`
- `tests/unit/plugin-architecture.tests.ps1` — Expandido: 24 tests (antes 7) incluyendo discovery, loader, CI integration
- `docs/reference/PLUGIN-ARCHITECTURE.md` — Actualizado con sección Implementation y CI Integration

### Tool Configs Verificadas
- `.cline/config.json`, `.cursor/config.json`, `.antigravity/config.json` — No referencian directamente AGENTS.md (usan tool-specific rules)
- `.cursorrules`, `.clinerules`, `.github/copilot-instructions.md` — Todos referencian `docs/AGENTS.md` como canonical source ✓
- `.windsurf/config.json`, `.continue/config.json` — Incluyen `AGENTS.md` en configFiles ✓
- `.codex/config.json` — Incluye `AGENTS.md` en rules array ✓

### Backlog Actualizado
- `docs/backlog/items.json` — Añadidos FF-007/008/017 (done) y FF-011/016/018 (pending) — ahora 13 items total (10 done, 3 pending)
- `docs/backlog/README.md` — Regenerado con tabla actualizada

### TypeScript CI/CD Añadido
- `test-suite.yml` — Nuevo step `tsc --noEmit` para `adapters/mcp-bridge/` que verifica tipos TypeScript en CI

### Cross-Link: Normativas
- NORMATIVAS-CODIGO, ERROR-HANDLING, PERFORMANCE, SESSION, AI-NORMATIVES
- Ahora todas tienen references recíprocas completas

## Auditoría Completa (2026-05-10)
- ✅ `plugins/examples/hello-world.ps1` — Eliminado (duplicado de `plugins/example-hello-world/`)
- ✅ `docs/reference/MIGRACION-NORMATIVAS-GLOBALES.md` — Eliminado (huérfano, nunca referenciado)
- ✅ `skills/SKILL_INDEX.md` — Añadidos `daily-workflow` y `premortem-skill` (faltaban)
- ✅ `docs/reference/FUTURE-FEATURES-BACKLOG.md` — Ya tiene notice de deprecation (ok)
- ⚠️ `.agents/skills/accessibility|seo/SKILL.md` — 4 broken links EXTERNOS (URLs web, no locales) — pre-existentes, no requieren acción
- ✅ Audit sweep: 0 errores, 0 duplicados, SKILL_INDEX sincronizado (126 skills)
- ✅ Plugin tests: 28/28 pass (sin regresión)

### Estado Final del Backlog
- **FF-016** — Token Efficiency / RTK: Evaluado → **deferred**. Stack actual suficiente (11+ scripts, 30-40% compresión, ~32% max budget). No justificado sin bottleneck real.
- **FF-018** — TUI Installer: Verificado → **done**. Ya existía en `scripts/utilities/foundation-installer-tui.ps1` (395 líneas, TUI completo).
- **Todos los FF-001 a FF-018 resueltos** — 12 done, 1 deferred, 0 pendientes.

## Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `docs/AGENTS.md` | **Entry point canónico (tool-agnostic)** |
| `config/auto-delegation.json` | Routing + agent profiles |
| `config/orchestrator.json` | Config del orquestador principal |
| `opencode.json` | Tool-agnostic agent config |
| `rules/AI-NORMATIVES.md` | Normativas AI (13 reglas) |
| `rules/NORMATIVAS-CODIGO.md` | Estándares de código |
| `rules/NORMATIVAS-ERROR-HANDLING.md` | Manejo de errores |
| `rules/NORMATIVAS-PERFORMANCE.md` | Performance budgets + SLOs |
| `rules/NORMATIVAS-SESSION.md` | Session lifecycle |
| `rules/DEVELOPMENT-STANDARDS.md` | Estándares de desarrollo |
| `skills/premortem-skill/SKILL.md` | Premortem analysis |
| `scripts/utilities/session-autostart.cmd` | Autostart Windows |
| `scripts/utilities/session-autostart.sh` | Autostart Linux/macOS |

---

**Creado**: 2026-05-10 — **Estado**: ACTUALIZADO — **Foundation v2.9.0**
