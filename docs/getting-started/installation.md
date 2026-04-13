# Workspace Foundation Installation

Complete guide to set up Workspace Foundation on a new machine.

## Prerequisites

### Required
- **Git** - https://git-scm.com/
- **PowerShell 7+** - https://aka.ms/powershell

### Recommended
- **Go 1.21+** - For Go-based tools
- **Node.js 20+** - For Node.js projects
- **Docker** - For containerized development

## Quick Install

### Windows (PowerShell)

```powershell
# Clone or download workspace-foundation
git clone https://github.com/your-org/workspace-foundation.git
cd workspace-foundation

# Initialize workspace
.\scripts\wf.ps1 init

# Create your first project
.\scripts\wf.ps1 new --name my-project --kind service
```

### Linux/macOS

```bash
# Clone or download workspace-foundation
git clone https://github.com/your-org/workspace-foundation.git
cd workspace-foundation

# Initialize workspace
pwsh ./scripts/wf.ps1 init

# Create your first project
pwsh ./scripts/wf.ps1 new --name my-project --kind service
```

## Detailed Setup

### 1. Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
```

### 2. Install Tools

```powershell
# Using the CLI
.\scripts\wf.ps1 tools --install

# Or manually
.\scripts\wf.ps1 init --force
```

### 3. Install AI Tools (Optional but Recommended)

The workspace-foundation includes integration with:

| Tool | Purpose | Install |
|------|---------|---------|
| **OpenCode** | AI coding agent | https://opencode.ai |
| **Claude Code** | AI coding agent | https://claude.ai/code |
| **gentle-ai** | AI ecosystem configurator | `go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest` |
| **gga** | AI code review on commits | `git clone https://github.com/Gentleman-Programming/gentleman-guardian-angel.git && cd gentleman-guardian-angel && bash install.sh` |
| **engram** | Persistent memory | `go install github.com/Gentleman-Programming/engram/cmd/engram@latest` |

Windows one-shot update (no brew required): `./scripts/utilities/wf.ps1 update-tools`

Windows one-shot update (no brew required): `./scripts/utilities/wf.ps1 update-tools`

### 4. Install Skills

Skills are automatically installed for detected AI agents. To manually install:

```powershell
# For Claude Code
cp -r tools/Gentleman-Skills/curated/* ~/.claude/skills/

# For OpenCode
cp -r tools/Gentleman-Skills/curated/* ~/.config/opencode/skills/
```

## Project Creation

### Interactive Mode (Recommended for beginners)

```powershell
.\scripts\wf.ps1 new --interactive
```

The wizard will ask:
- Project name
- Project type (service, cli, library, frontend, fullstack, microservices)
- Architecture pattern
- AI model configuration
- Source (new or clone)

### Command Line Mode

```powershell
# Basic service
.\scripts\wf.ps1 new --name my-api --kind service

# With options
.\scripts\wf.ps1 new `
    --name my-project `
    --kind frontend `
    --framework react `
    --architecture clean `
    --ai-mode cloud `
    --ai-provider openai `
    --ai-model gpt-4
```

## Available Options

| Option | Description | Values |
|--------|-------------|--------|
| `--name` | Project name | String |
| `--kind` | Project type | service, cli, library, frontend, fullstack, microservices |
| `--framework` | Frontend framework | react, vue, angular, nextjs |
| `--architecture` | Architecture pattern | layered, clean, modular, microservices |
| `--preset` | Project preset | default |
| `--ai-mode` | AI assistance mode | none, local, cloud |
| `--ai-provider` | AI provider | openai, anthropic, gemini, ollama |
| `--ai-model` | Model name | gpt-4, claude-3-opus, etc. |
| `--clone` | Clone from URL | Git repository URL |
| `--output` | Output path | Directory path |

## Post-Installation

### Validate Your Setup

```powershell
.\scripts\wf.ps1 validate
```

### Create a Project

```powershell
# Interactive
.\scripts\wf.ps1 new --interactive

# Or specify all options
.\scripts\wf.ps1 new --name my-service --kind service
```

### Run Tests

```powershell
# In your project directory
npm test  # Node.js
go test ./...  # Go
```

## Troubleshooting

### "pwsh not found"

Install PowerShell 7+ from https://aka.ms/powershell

### "Git not found"

Install Git from https://git-scm.com/

### Permission errors (Linux/macOS)

```bash
chmod +x ./scripts/*.ps1
chmod +x ./scripts/*.sh
```

### Module not found

```powershell
# Windows
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Linux/macOS
pwsh -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
```
