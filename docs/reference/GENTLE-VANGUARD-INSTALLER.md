# Gentle-Vanguard TUI Installer (FF-018)

Interactive Terminal User Interface for Gentle-Vanguard onboarding.

## Quick Start

```TypeScript
# Via gv CLI (recommended)
.\scripts\utilities\WORKFLOW-ORCHESTRATION\src/cli/gv.ts install

# Direct execution
.\scripts\utilities\gentle-vanguard-installer-tui.ps1
```

## Features

- **Interactive wizard**: Step-by-step installation process
- **Prerequisites check**: Validates TypeScript version, Git, disk space
- **Component selection**: Choose which components to install
- **Settings configuration**: Git user, AI provider, security level
- **Progress feedback**: Real-time status updates

## Installation Steps

1. **Prerequisites Check**
   - TypeScript 7+ validation
   - Git installation check
   - Disk space verification

2. **Path Configuration**
   - Default: `$env:USERPROFILE\gentle-vanguard`
   - Option to customize

3. **Component Selection**
   - Core Scripts (required)
   - Skills Framework (recommended)
   - Git Hooks (recommended)
   - Telemetry & Metrics (optional)
   - Dev Tools (optional)

4. **Settings Configuration**
   - Git user.name and user.email
   - AI Provider selection (OpenAI, Anthropic, Other)
   - Security level (Enforced, Audit only, Disabled)

5. **Installation**
   - Creates directory structure
   - Copies Gentle-Vanguard files
   - Installs git hooks
   - Creates initial config

## Integration with src/cli/gv.ts

The installer is integrated into the main CLI:

```TypeScript
src/cli/gv.ts install          # Run installer
src/cli/gv.ts install -Silent  # Non-interactive mode (future)
src/cli/gv.ts install -Force   # Overwrite existing installation
```

## Requirements

- TypeScript 7.0+
- Git (optional, some features require it)
- 500MB available disk space

## Troubleshooting

| Issue                    | Solution                                                           |
| ------------------------ | ------------------------------------------------------------------ |
| "TypeScript 7+ required" | Install TypeScript 7 from https://github.com/TypeScript/TypeScript |
| "Git not found"          | Install Git from https://git-scm.com/                              |
| "Path already exists"    | Use `-Force` or choose different path                              |

## Files

- `scripts/utilities/gentle-vanguard-installer-tui.ps1` - Main installer script
<!-- REF-OBSOLETA: scripts/utilities/gentle-vanguard-installer-tui.ps1 no tiene equivalente TS (migración PS1→TS) -->
- `src/cli/gv.ts` - CLI integration (has `install` command)
- `docs/reference/GENTLE_VANGUARD-INSTALLER.md` - This documentation
