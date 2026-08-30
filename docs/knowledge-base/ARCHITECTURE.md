# Knowledge Base Architecture - Gentle-Vanguard

## Overview

This document defines the architecture for the **Knowledge Base** system in Gentle-Vanguard,
integrating Obsidian as the primary knowledge management tool while maintaining 100% local-first
philosophy.

## Current State

| Component         | Location                             | Purpose             | Status    |
| ----------------- | ------------------------------------ | ------------------- | --------- |
| Engram            | Native `engram` CLI                  | Persistent memory   | Active    |
| Vault             | `knowledge-base/`                    | Obsidian Markdown   | Active    |
| Skills            | `skills/`                            | Skill registry      | Indexed   |
| ML Embeddings     | `.atl/skill-embeddings.json`         | TF-IDF vectors      | Active    |
| Document Analysis | `skills/document-analysis-skill/`    | PDF/DOCX processing | Active    |

## Architecture Decision

**Selected Solution:** Obsidian Vault (local-first)

### Rationale

1. **Markdown-native** - 100+ .md files already in project
2. **Local-first** - Aligns with Gentle-Vanguard philosophy
3. **No operational overhead** - No server maintenance
4. **AI-ready** - Plugins for embeddings and RAG
5. **Portable** - Vault is just a folder

## System Architecture

```
knowledge-base/                    # Root vault
├── .obsidian/                     # Obsidian config (gitignored)
├── 00-inbox/                      # Unsorted notes
├── 01-projects/                   # Active projects
│   ├── gentle-vanguard/
│   └── [other-projects]/
├── 02-architecture/               # Architecture decisions
├── 03-skills/                     # Skill documentation
├── 04-sessions/                   # Session artifacts
├── 05-research/                   # Research notes
├── 06-templates/                  # Note templates
│   ├── project.md
│   ├── session.md
│   ├── skill.md
│   └── decision.md
├── 07-archive/                    # Archived content
└── graph.json                     # Knowledge graph
```

## Integration Points

### 1. Engram Integration

- Engram continues as **session memory** (short-term)
- Knowledge Base serves as **long-term knowledge**
- Sync mechanism: `engram export` → selected observations in `00-inbox/`; vault notes are persisted with `engram save`.
- Sync is additive and never deletes vault notes. Use `--dry-run` before a write.

### 2. Document Analysis Integration

- Processed documents stored in vault
- Embeddings generated via Document Analysis Skill
- Searchable via Obsidian plugins or ml-router

### 3. Session Pipeline Integration

- Session summaries auto-archived to vault
- Session artifacts linked from `.session/`
- Cross-references maintained via tags

### 4. ML Embeddings Integration

- Skill embeddings already in `.atl/`
- Can be imported to Obsidian for visualization
- Bidirectional search capability

## Data Flow

```
User Session
    │
    ├──► Engram (session memory)
    │        │
    │        └──► Sync to Knowledge Base (end of session)
    │
    ├──► Document Analysis (process docs)
    │        │
    │        └──► Store in vault + generate embeddings
    │
    └──► Session Pipeline
             │
             └──► Auto-archive to vault
```

## Sync Strategy

### Automatic Sync (End of Session)

1. Export session summary to `04-sessions/`
2. Tag notes with session ID
3. Update index in `00-inbox/`
4. Run embedding reindex

### Manual Sync

- Use `pnpm kb:sync -- --mode full`
- Sync specific folders or full vault

## Search Strategy

1. **Obsidian native** - Ctrl+Shift+F
2. **Dataview queries** - For structured data
3. **ML Router** - Semantic search via embeddings
4. **Engram** - Session-specific queries

## Backup Strategy

- Vault backed up via existing backup system
- Daily snapshots to `.session/snapshots/`
- Git sync for version control (optional)

## Security

- Vault stored in project root (not git-tracked)
- Sensitive notes use Obsidian encryption
- No external API calls (100% local)

## Maintenance

- Weekly vault cleanup (move inbox to folders)
- Monthly archive review
- Quarterly embedding reindex

## Related Files

- `src/knowledge/knowledge-base-manager.ts`
- `src/knowledge/knowledge-base-sync.ts`
- `config/knowledge-base-config.json`
- `docs/knowledge-base/README.md` for the current live documentation entry point.
- `.archive/docs/stale-guides/knowledge-base-USAGE.md` for the archived legacy usage guide.
