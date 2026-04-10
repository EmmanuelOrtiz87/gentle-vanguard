---
name: foundation-manager
description: Use when checking updates, synchronizing foundation, managing tools, or maintaining the development stack. Triggers for: "update foundation", "check updates", "sync skills", "install tools", "maintenance".
---

# Foundation Manager Skill

## Purpose

Manage Gentleman Foundation installation, keep skills and tools updated, and coordinate the development stack.

## When Activated

This skill activates when:
- User asks to update or sync skills
- User asks to check for updates
- User asks about installed tools or their status
- User needs to install or configure tools
- User mentions maintenance or version checking

## Core Commands

### Check for Updates

```powershell
gf check
```

Checks:
- Foundation source for new commits
- Skills count vs available
- Tools installation status

### Update Skills

```powershell
gf update
```

Syncs skills from source to `~/.gentleman/skills/`.

### Update Everything

```powershell
gf update-all
```

Updates:
1. Foundation source (git pull)
2. All skills
3. Tools status

### Tools Status

```powershell
gf tools
```

Shows installation status for:
- `gg` - Gentleman Guardian Angel
- `gga` - GGA CLI
- `engram` - Engram Memory
- `gentle-ai` - Gentle-AI CLI

## Update Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    UPDATE WORKFLOW                           │
└─────────────────────────────────────────────────────────────┘

     gf check
         │
         ▼
    ┌─────────────┐
    │ Updates?    │
    └──────┬──────┘
           │
     ┌─────┴─────┐
     │           │
    YES          NO
     │           │
     ▼           ▼
gf update-all   Already current
     │
     ▼
┌─────────────────────────────────────────┐
│  1. Update foundation (git pull)        │
│  2. Sync skills (symlink/copy)          │
│  3. Check tools status                  │
│  4. Validate installation               │
└─────────────────────────────────────────┘
```

## Version Strategy

### Semantic Versioning

Foundation versions follow `vMAJOR.MINOR.PATCH`:
- `MAJOR` - Breaking changes
- `MINOR` - New skills/features
- `PATCH` - Bug fixes

### Update Frequency

| Component | Recommended | Reason |
|-----------|-------------|--------|
| Foundation | Weekly | Core stability |
| Skills | Daily/On-demand | Rapid iteration |
| Tools | Monthly | Stability |

## Troubleshooting

### Skills Out of Sync

```powershell
# Force resync
gf update --force
```

### Tools Not Found

```powershell
# Install missing tools
winget install Gentleman.GG
npm install -g @engram/memory
```

### Git Conflict on Update

```powershell
# Manual resolution needed
cd $GFRoot
git status
git stash
git pull
git stash pop
```

## Skill Dependencies

This skill coordinates with:
- `project-scaffolding-skill` - Project setup
- `security-skill` - Pre-commit hooks
- `git-workflow-skill` - Version control

## Quick Reference

```powershell
# Full workflow
gf check          # Check what needs updating
gf update         # Update skills only
gf update-all     # Update everything
gf validate       # Verify after update
gf tools          # Check tool status
```
