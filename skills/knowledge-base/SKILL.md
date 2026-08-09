---
name: knowledge-base
aliases: ["knowledge-base"]
description: >
  Knowledge Base Skill — Gentle-Vanguard
triggers:
  - knowledge base
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.063Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\knowledge-base\SKILL.md
  version: "1.0.0"
---

# Knowledge Base Skill — Gentle-Vanguard

Access and manage the Obsidian-compatible knowledge base vault.

## Trigger

"knowledge base", "vault", "obsidian", "notas", "kb", "knowledge", "wiki", "documentacion",
"documentation"

## Workflow

### 1. Initialize vault (if needed)

```
C:/Workspace_local/gentle-vanguard/src/knowledge-base-autoinit.ts [-Force]
```

### 2. List notes

```
C:/Workspace_local/gentle-vanguard/src/knowledge-base-manager.ts -Action list [-Folder <folder>]
```

Folders: 00-inbox, 01-projects, 02-architecture, 03-skills, 04-sessions, 05-research, 06-templates,
07-archive

### 3. Search notes

```
C:/Workspace_local/gentle-vanguard/src/knowledge-base-manager.ts -Action search -Query "<query>"
```

### 4. Create note

```
C:/Workspace_local/gentle-vanguard/src/knowledge-base-manager.ts -Action create-note -NoteType <type> -Title "<title>"
```

Types: project, session, skill, decision (templates in `06-templates/`)

### 5. Sync with Engram

```
C:/Workspace_local/gentle-vanguard/src/knowledge-base-sync.ts -Mode full [-Quiet]
```

### 6. Get stats

```
C:/Workspace_local/gentle-vanguard/src/knowledge-base-manager.ts -Action stats
```

## Resources

- `config/knowledge-base-config.json` — vault config
- `knowledge-base/` — vault root, 8 folders, `.obsidian/` config
- `C:/Workspace_local/gentle-vanguard/src/knowledge-base-manager.ts`
- `C:/Workspace_local/gentle-vanguard/src/knowledge-base-sync.ts`
- `C:/Workspace_local/gentle-vanguard/src/knowledge-base-autoinit.ts`
- `docs/knowledge-base/ARCHITECTURE.md`
- `docs/knowledge-base/USAGE.md`
