---
created: 2026-05-18 11:02:34
tags: [engram, architecture]
engram_id: 937
type: architecture
---

# Cross-tool nivelación completa — skill/mem emulation + antigravity profile

**What**: Nivelación completa de todas las herramientas del stack Gentle-Vanguard: emulación de skill tool y mem tools para herramientas sin soporte nativo, adaptive profile dedicado para antigravity, detección mejorada.

**Why**: Cline, Cursor, Windsurf, Codex, Copilot, Antigravity no tienen skill tool ni mem tools nativos. Ahora todas tienen emulación vía skillRegistry (.atl/skill-registry.md), engramPaths, criticalSkills sections en sus configs.

**Where**:
- .clinerules (+7): skillRegistry, engram refs, agent rules
- .cursor/rules/core-workflow.md (+14): skill loading + mem emulation sections
- .windsurf/config.json (+17): skillEmulation, engramPaths, skillRegistry, fix project name
- .antigravity/config.json (+65): v2.0 completo con emulación y session management
- .codex/config.json (+28): workspace, skillEmulation, contextManagement
- .codex/config.toml (+8): project_docs references
- .continue/config.json (+4): skillRegistry, engramPaths
- scripts/utilities/adaptive-antigravity-profile.ps1 (new): perfil dedicado
- scripts/utilities/detect-tool.ps1 (+11): detección de .antigravity/
- config/orchestrator.json (edited): antigravity apunta a su propio adaptiveProfile

**Learned**: Tools sin skill/mem nativos no pueden obtenerlos (son capacidades de OpenCode), pero la emulación vía config files + skill registry + engram paths es suficiente para darles el mismo nivel de funcionalidad. Antigravity compartía perfil con Cursor; ahora tiene su propio adaptive-antigravity-profile.ps1.

---
*Imported from Engram on 2026-09-06*
