# Project Structure - Foundation (v2.0)

## Canonical Structure

After refactoring (April 2026), Foundation uses ONE single source of truth for each category:

```
foundation/
 config/                 #  Single config location (was: .workspace/config/)
 docs/                  #  Documentation (no duplicates)
 hooks/                 #  Git hooks (unified)
 scripts/                #  All scripts (no scripts/utilities/ subdirs)
 skills/                #  Single skills location (was: scripts/utilities/skills/ + skills/)
 templates/              # Templates for new projects
 tests/                # Test files
 scripts/utilities/                # Runtime tools (autostart, token-guard, etc)
 .workspace/           #  Legacy - to be deprecated
 .atl/                 # Agent Toolkit Layer (skill registry)
 .audit/               # Audit logs and metrics
 .engram/              # Engram memory data
 .session/             # Session data
 .telemetry/           # Telemetry data
 AGENTS.md             # Agent instructions
 README.md             # Root documentation
 CHANGELOG.md         # versión history
```

## Rules

| Category    | Location   | Legacy to Remove                 |
| ----------- | ---------- | -------------------------------- |
| **Skills**  | `skills/`  | `scripts/utilities/skills/` DONE |
| **Config**  | `config/`  | `.workspace/config/` DONE        |
| **Scripts** | `scripts/` | Various - review needed          |
| **Docs**    | `docs/`    | OK - no duplicates               |

## Migration Status

| Date       | Change                                           | Status |
| ---------- | ------------------------------------------------ | ------ |
| 2026-04-27 | Eliminated `scripts/utilities/skills/` duplicate | DONE   |
| 2026-04-27 | Merged `.workspace/config/` `config/`            | DONE   |
| 2026-04-27 | Unified `content-output-skill`                   | DONE   |
