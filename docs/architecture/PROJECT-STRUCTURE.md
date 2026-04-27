# Project Structure - Foundation (v2.0)

## Canonical Structure

After refactoring (April 2026), Foundation uses ONE single source of truth for each category:

```
workspace-foundation/
├── config/                 # ✅ Single config location (was: .workspace/config/)
├── docs/                  # ✅ Documentation (no duplicates)
├── hooks/                 # ✅ Git hooks (unified)
├── scripts/                # ✅ All scripts (no tools/ subdirs)
├── skills/                # ✅ Single skills location (was: tools/skills/ + skills/)
├── templates/              # Templates for new projects
├── tests/                # Test files
├── tools/                # Runtime tools (autostart, token-guard, etc)
├── .workspace/           # ⚠️ Legacy - to be deprecated
├── .atl/                 # Agent Toolkit Layer (skill registry)
├── .audit/               # Audit logs and metrics
├── .engram/              # Engram memory data
├── .session/             # Session data
├── .telemetry/           # Telemetry data
├── AGENTS.md             # Agent instructions
├── README.md             # Root documentation
└── CHANGELOG.md         # Version history
```

## Rules

| Category | Location | Legacy to Remove |
|----------|----------|-----------------|
| **Skills** | `skills/` | `tools/skills/` ✅ DONE |
| **Config** | `config/` | `.workspace/config/` ✅ DONE |
| **Scripts** | `scripts/` | Various - review needed |
| **Docs** | `docs/` | OK - no duplicates |

## Migration Status

| Date | Change |Status|
|------|-------|------|
| 2026-04-27 | Eliminated `tools/skills/` duplicate | ✅ DONE |
| 2026-04-27 | Merged `.workspace/config/` → `config/` | ✅ DONE |
| 2026-04-27 | Unified `content-output-skill` | ✅ DONE |
