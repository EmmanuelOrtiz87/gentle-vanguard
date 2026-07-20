# CodeGraph Skill — Detailed Reference

## CLI Examples

```powershell
# Initialize index
codegraph init -i

# Check status
codegraph status

# Search symbols
codegraph query "session"

# Build task context
codegraph context "find all session management functions"

# Show file structure
codegraph files

# Find affected tests
codegraph affected src/architecture/resilience/ResilienceManager.ts

# Sync changes
codegraph sync

# Re-index all
codegraph index
```

## Semantic Search Examples

```powershell
# Basic semantic search
.\scripts\codegraph\codegraph-semantic-search.ps1 -Query "where is auth handled" -MaxResults 10

# Enrich with metadata
.\scripts\codegraph\codegraph-enrich.ps1 -Query "session" -EnrichLevel full
```

## Best Practices

1. **Trust CodeGraph results** — `codegraph_context` returns accurate symbols and relationships. No need to verify via grep/read.
2. **Use `codegraph_context` first** before editing code.
3. **Sync after editing** — `codegraph sync` or wait 2s for file watcher debounce.
