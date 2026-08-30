# Knowledge Base - Gentle-Vanguard

> **Version**: 3.8.2
> **Last Updated**: 2026-08-29

## Overview

This is the Knowledge Base vault for Gentle-Vanguard — a structured repository of session summaries,
architecture decisions, research notes, and project documentation.

## Structure

```
knowledge-base/
├── 00-inbox/           # Unsorted notes (temporary)
├── 01-projects/        # Active projects
├── 02-architecture/    # Architecture Decision Records (ADRs)
├── 03-skills/          # Skill documentation
├── 04-sessions/        # Session summaries
├── 05-research/        # Research notes
├── 06-templates/       # Note templates
└── 07-archive/         # Archived content
```

## Auto-Sync

This vault is automatically synchronized with Engram memory:

- **Engram observations** (`decision`, `architecture`, `bugfix`, `pattern`) → `00-inbox/`
- **Vault notes** in `01-projects/`, `02-architecture/`, `03-skills/`, and `05-research/` → Engram
- **Session summaries** → `04-sessions/` when explicitly requested with `session-summary`

## Usage

Access via:

- **CLI**: `pnpm kb:sync -- --stats`
- **Automation**: `src/knowledge/knowledge-base-sync.ts` is invoked by session autostart
- **Manual**: `pnpm kb:sync -- --mode full`
- **Safe preview**: `pnpm kb:sync -- --mode full --dry-run`

## Integration

- **Engram**: Persistent memory across sessions; the sync uses the native `engram export` and `engram save` contracts
- **Obsidian**: Local Markdown vault; sync never deletes existing notes

---

_Part of Gentle-Vanguard v3.4.0_
