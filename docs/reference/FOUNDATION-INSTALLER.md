# Foundation TUI Installer (FF-018)

Interactive Terminal User Interface for Foundation onboarding.

## Quick Start

```powershell
# Via wf CLI (recommended)
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 install

# Direct execution
.\scripts\utilities\foundation-installer-tui.ps1
```

## Features

- **Interactive wizard**: Step-by-step installation process
- **Prerequisites check**: Validates PowerShell version, Git, disk space
- **Component selection**: Choose which components to install
- **Settings configuration**: Git user, AI provider, security level
- **Progress feedback**: Real-time status updates

## Installation Steps

1. **Prerequisites Check**
   - PowerShell 7+ validation
   - Git installation check
   - Disk space verification

2. **Path Configuration**
   - Default: `$env:USERPROFILE\foundation`
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
   - Copies Foundation files
   - Installs git hooks
   - Creates initial config

## Integration with wf.ps1

The installer is integrated into the main CLI:

```powershell
wf.ps1 install          # Run installer
wf.ps1 install -Silent  # Non-interactive mode (future)
wf.ps1 install -Force   # Overwrite existing installation
```

## Requirements

- PowerShell 7.0+
- Git (optional, some features require it)
- 500MB available disk space

## Troubleshooting

| Issue | Solution |
|-------|-----------|
| "PowerShell 7+ required" | Install PowerShell 7 from https://github.com/PowerShell/PowerShell |
| "Git not found" | Install Git from https://git-scm.com/ |
| "Path already exists" | Use `-Force` or choose different path |

## Files

- `scripts/utilities/foundation-installer-tui.ps1` - Main installer script
- `scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1` - CLI integration (has `install` command)
- `docs/reference/FOUNDATION-INSTALLER.md` - This documentation
