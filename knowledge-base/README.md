# Knowledge Base - Gentle-Vanguard

> **Version**: v3.4.0  
> **Last Updated**: 2026-07-27

## Overview

This is the Knowledge Base vault for Gentle-Vanguard — a structured repository of session summaries, architecture decisions, research notes, and project documentation.

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

- **Session summaries** → `04-sessions/`
- **Architecture decisions** → `02-architecture/`
- **Research findings** → `05-research/`

## Usage

Access via:
- **CLI**: `npx tsx src/knowledge-base-sync.ts --stats`
- **Automation**: Runs automatically at session start
- **Manual**: `npx tsx src/knowledge-base-sync.ts --mode full`

## Integration

- **Engram**: Persistent memory across sessions
- **Dashboard**: Real-time knowledge panel
- **CodeGraph**: Semantic code navigation

---

*Part of Gentle-Vanguard v3.4.0*
