# Knowledge Base Usage Guide

## Overview

The **Gentle-Vanguard Knowledge Base** is an Obsidian-compatible vault for managing all project
knowledge, integrated with Engram for session memory and the existing document pipeline.

## Quick Start

### Initialize the Vault

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action init
```

### Check Vault Status

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action stats
```

### Validate Vault Structure

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action validate
```

## Creating Notes

### Create a Project Note

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 `
  -Action create-note `
  -NoteType project `
  -Title "My New Project" `
  -Tags "priority:high,owner:team"
```

### Create a Session Note

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 `
  -Action create-note `
  -NoteType session `
  -Title "session-2026-07-03" `
  -Tags "focus:feature-x"
```

### Create a Skill Note

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 `
  -Action create-note `
  -NoteType skill `
  -Title "my-custom-skill" `
  -Tags "automation,custom"
```

### Create an Architecture Decision (ADR)

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 `
  -Action create-note `
  -NoteType decision `
  -Title "ADR-001-Use-Obsidian-For-KB" `
  -Tags "approved"
```

## Searching Notes

### List All Notes

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action list
```

### Search by Keyword

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action search -Query "session_summary"
```

## Syncing Data

### Full Sync (All Sources)

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode full
```

### Sync Only from Engram

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode engram
```

### Sync Only Sessions

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode sessions
```

### Sync Only Documents

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode documents
```

### Dry Run (Preview Changes)

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode full -DryRun
```

## Vault Structure

```
knowledge-base/
├── 00-inbox/              # Unsorted notes
├── 01-projects/           # Active projects
│   └── gentle-vanguard/   # Project-specific notes
├── 02-architecture/       # Architecture decisions (ADRs)
├── 03-skills/             # Skill documentation
├── 04-sessions/           # Session summaries
├── 05-research/           # Research notes
├── 06-templates/          # Note templates
│   ├── project.md
│   ├── session.md
│   ├── skill.md
│   └── decision.md
└── 07-archive/            # Archived content
```

## Note Templates

### Frontmatter Schema

All notes should include frontmatter:

```yaml
---
created: 2026-07-03
tags: [tag1, tag2]
status: active|archived|deprecated
---
```

### Required Tags

- `project` - Project notes
- `session` - Session summaries
- `skill` - Skill documentation
- `decision` - Architecture decisions
- `research` - Research notes
- `inbox` - Unsorted notes
- `archive` - Archived notes

## Integration with Stack

### Engram Integration

- Engram handles **session memory** (short-term)
- Knowledge Base handles **long-term knowledge**
- Run sync to export Engram insights to vault

### Session Pipeline Integration

Session summaries are automatically synced to `04-sessions/`

### Document Analysis Integration

Processed documents can be stored in `05-research/`

## Automation

### Add to Session Autostart

Edit `config/session-autostart.config.json` and add:

```json
{
  "name": "knowledge-base-sync",
  "script": "scripts/utilities/knowledge-base/knowledge-base-sync.ps1",
  "args": "-Mode full",
  "lazy": true
}
```

### Manual Sync During Session

```powershell
# At end of session
& scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode full
```

## Best Practices

1. **Daily**: Review `00-inbox/` and move notes to appropriate folders
2. **Weekly**: Run full sync to keep vault updated
3. **Monthly**: Archive old sessions and review research notes
4. **Use Tags**: Always include relevant tags in frontmatter
5. **Link Notes**: Use `[[note-name]]` for cross-references

## Troubleshooting

### Vault Not Found

```powershell
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action init
```

### Engram Not Syncing

```powershell
# Verify Engram is installed
engram --version

# Run sync with verbose output
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode engram
```

### Validation Failures

```powershell
# Check vault structure
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action validate
```

## Related Documentation

- [Architecture](ARCHITECTURE.md)
- [Configuration](../config/knowledge-base-config.json)
- [Script Source](../scripts/utilities/knowledge-base/knowledge-base-manager.ps1)
