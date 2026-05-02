# Developer Setup Guide

Step-by-step guide for new developers joining the team.

## Overview

This guide sets up your machine for development with:
- Foundation - Development Stack (skills, hooks, CLI)
- AI-assisted development workflow
- Code review automation

**Time to complete**: ~15-30 minutes

## Step 1: Install Core Tools

### Required

```powershell
# 1. Git (if not installed)
winget install Git.Git

# 2. PowerShell 7 (recommended)
winget install Microsoft.PowerShell

# 3. OpenCode (AI Agent)
# Download from https://opencode.ai and install
```

### Verify Installations

```powershell
git --versión
pwsh --versión  # or powershell --versión
```

## Step 2: Install Foundation - Development Stack

### Option A: Automated (Recommended)

```powershell
# Clone the foundation repository
git clone <repository-url> C:\foundation

# Run bootstrap
cd C:\foundation
.\scripts\bootstrap-machine.ps1

# Restart terminal
```

### Option B: Manual

```powershell
# 1. Create foundation directory
New-Item -ItemType Directory -Path "$env:USERPROFILE\.gentleman" -Force

# 2. Copy skills from repository
# (Clone repo and copy skills folder)

# 3. Add to PATH
[Environment]::SetEnvironmentVariable(
    "PATH",
    "$env:USERPROFILE\.gentleman\bin;$env:PATH",
    "User"
)
```

### Verify Foundation

```powershell
gf validate
gf info
gf list
```

### Optional: Local Workspace Autostart (Local-only)

If you keep a personal workspace root (example: `C:\Workspace_local`), you can add a local-only startup helper to run health checks automatically. This is optional and should stay **local** (not a shared repo rule).

```powershell
# Local-only helper
C:\Workspace_local\tools\session-autostart.cmd
```

Notes:
- Do not enforce this path for other developers.
- Keep local-only helpers out of shared policies.

## Step 3: Configure Git

```powershell
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"

# Default branch
git config --global init.defaultBranch main

# Enable hooks
git config --global core.hooksPath "$env:USERPROFILE\.git-hooks"
```

## Step 4: Update Optional Tooling (Recommended)

```powershell
.\scripts\utilities\wf.ps1 update-tools
```

## Step 5: Configure AI Agent

### OpenCode (Recommended)

1. Download from [opencode.ai](https://opencode.ai)
2. Install and configure your API key
3. Select model (big-pickle, claude-3.5-sonnet, etc.)

### Other AI Agents

Foundation works with any AI agent:
- Claude Desktop
- GitHub Copilot
- Cursor
- Windsurf

## Step 6: Setup Your First Project

```powershell
# Navigate to your workspace
cd C:\Workspace

# Setup existing project with foundation
C:\foundation\scripts\setup-project.ps1 -ProjectPath "C:\Workspace\my-project"

# Or create new project
gf new --name my-project --type service
```

## Daily Workflow

### Morning

```powershell
# Check for updates
gf check

# Update if needed
gf update-all

# Validate setup
gf validate
```

### Before Commit

```powershell
# Run project validation
.\scripts\validation\validate-project.ps1

# Or use git hooks automatically
git add .
git commit -m "feat(scope): description"
# Hooks run automatically
```

## Troubleshooting

### "gf command not found"

```powershell
# Check PATH
$env:PATH -split ";" | Select-String "gentleman"

# Add manually if missing
[Environment]::SetEnvironmentVariable(
    "PATH",
    "$env:USERPROFILE\.gentleman\bin;$env:PATH",
    "User"
)
```

### "Permission denied on scripts"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Git hooks not running"

```powershell
# Check hooks path
git config --global core.hooksPath

# Should be: C:\Users\<you>\.git-hooks
```

## Checklist

- [ ] git installed and configured
- [ ] PowerShell 7 installed
- [ ] OpenCode (or other AI agent) installed
- [ ] Foundation - Development Stack installed
- [ ] Git identity configured
- [ ] `gf validate` passes

## Getting Help

- Foundation docs: `docs/`
- Skills: `skills/SKILL_INDEX.md`
- CLI help: `gf --help`

## Next Steps

1. Read [ARCHITECTURE.md](../reference/ARCHITECTURE.md) to understand the system
2. Explore available [skills](../../skills/SKILL_INDEX.md)
3. Setup your first project

- Los hooks automticos de Foundation - Development Stack ahora cubren 7 dimensiones: Seguridad, Calidad, Arquitectura, Testing, API, Documentacin y Gitflow. Consulta REVIEW-INDEX.md para detalles y cmo personalizar reglas.
- Para personalizar reglas de revisión, edita los archivos SKILL.md en cada subcarpeta de skills/.
- Los scripts de chequeo estn en scripts/hooks/ y pueden adaptarse a las necesidades del proyecto.


