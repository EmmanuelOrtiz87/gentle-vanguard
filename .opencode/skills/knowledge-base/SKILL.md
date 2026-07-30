---
name: knowledge-base
description: Knowledge Base Skill — Gentle-Vanguard
triggers:
  - knowledge base
---

# Knowledge Base Skill — Gentle-Vanguard

Access and manage the Obsidian-compatible knowledge base vault.

## Trigger

"knowledge base", "vault", "obsidian", "notas", "kb", "knowledge", "wiki", "documentacion",
"documentation"

## Workflow

### 1. Initialize vault (if needed)

```
scripts/utilities/knowledge-base/knowledge-base-autoinit.ps1 [-Force]
```

### 2. List notes

```
scripts/utilities/knowledge-base/knowledge-base-manager.ps1 -Action list [-Folder <folder>]
```

Folders: 00-inbox, 01-projects, 02-architecture, 03-skills, 04-sessions, 05-research, 06-templates,
07-archive

### 3. Search notes

```
scripts/utilities/knowledge-base/knowledge-base-manager.ps1 -Action search -Query "<query>"
```

### 4. Create note

```
scripts/utilities/knowledge-base/knowledge-base-manager.ps1 -Action create-note -NoteType <type> -Title "<title>"
```

Types: project, session, skill, decision (templates in `06-templates/`)

### 5. Sync with Engram

```
scripts/utilities/knowledge-base/knowledge-base-sync.ps1 -Mode full [-Quiet]
```

### 6. Get stats

```
scripts/utilities/knowledge-base/knowledge-base-manager.ps1 -Action stats
```

## Resources

- `config/knowledge-base-config.json` — vault config
- `knowledge-base/` — vault root, 8 folders, `.obsidian/` config
- `scripts/utilities/knowledge-base/knowledge-base-manager.ps1`
- `scripts/utilities/knowledge-base/knowledge-base-sync.ps1`
- `scripts/utilities/knowledge-base/knowledge-base-autoinit.ps1`
- `docs/knowledge-base/ARCHITECTURE.md`
- `docs/knowledge-base/USAGE.md`
