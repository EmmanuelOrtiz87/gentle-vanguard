# Workspace Foundation

A local-first workspace orchestration system for AI-assisted development.

## Quick Start

```powershell
# Clone the repository
git clone https://github.com/yourorg/workspace-foundation.git
cd workspace-foundation

# Run the interactive installer
.\scripts\utilities\foundation-installer-tui.ps1

# Or use the CLI
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 health
```

## Features

- **125+ Skills**: Specialized AI agent skills for common development tasks
- **Local-First**: All processing happens locally, no external dependencies required
- **Token Tracking**: Real-time AI token usage monitoring and budgeting
- **Git Hooks**: Automated code quality checks with Lefthook + Trufflehog
- **Plugin Architecture**: Extensible plugin system for custom workflows
- **Interactive TUI**: Terminal-based setup wizard for new users

## Documentation

| Document | Description |
|----------|-------------|
| [Getting Started](docs/getting-started/README.md) | New user setup guide |
| [Architecture](docs/architecture/README.md) | System architecture overview |
| [Skills Catalog](docs/reference/SKILLS-CATALOG.md) | Available skills reference (generate with: wf.ps1 skills) |
| [Token Tracking](docs/reference/REAL-TOKEN-TRACKING.md) | AI token monitoring guide |
| [Plugin System](docs/reference/PLUGIN-ARCHITECTURE.md) | Plugin development guide |

## Prerequisites

- PowerShell 7+
- Git
- Node.js (optional, for some tools)

## Project Structure

```
workspace-foundation/
├── scripts/           # Workflow and utility scripts
├── skills/            # 125+ specialized AI skills
├── config/            # Configuration files
├── docs/              # Documentation
├── tests/             # Test suite (Pester)
└── rules/             # Project rules and standards
```

## Version

Current version: **2.6.5**

## License

MIT License - see LICENSE file for details.
