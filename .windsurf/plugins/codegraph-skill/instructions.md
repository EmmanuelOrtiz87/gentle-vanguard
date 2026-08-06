# codegraph-skill

> Gentle-Vanguard Skill

## Description

>

## Triggers

## Instructions

# CodeGraph Skill

## Overview

CodeGraph pre-indexes the codebase into a queryable SQLite graph (symbols, call chains, imports,
routes). Agents answer structural questions with 1-3 MCP calls instead of 30-50+ grep/glob/read.

## When to Use

- **Before modifying code**: `codegraph_context` for entry points and related symbols
- **Impact analysis**: `codegraph affected` for transitively affected tests
- **Code exploration**: `codegraph_explore` instead of grep/glob/read loops
- **Symbol search**: `codegraph query` (FTS5-powered)
- **Architecture**: `codegraph files` for indexed project structure

## MCP Tools

| Tool                 | Purpose                                                     |
| -------------------- | ----------------------------------------------------------- |
| `codegraph_context`  | Task context — entry points, related symbols, code snippets |
| `codegraph_explore`  | Explore structure and relationships                         |
| `codegraph_query`    | FTS5-powered symbol search                                  |
| `codegraph_files`    | Indexed project structure                                   |
| `codegraph_affected` | Tests transitively affected by source changes               |
| `codegraph_status`   | Index status and statistics                                 |
| `codegraph_sync`     | Sync changes (file watcher, 2s debounce)                    |
| `codegraph_index`    | Re-index all files                                          |

CLI: `codegraph init -i`, `status`, `query "session"`, `context "..."`, `files`, `sync`, `index`.
Full examples in [references/detail.md](references/detail.md).

## Semantic Search

| Script                          | Purpose                                               |
| ------------------------------- | ----------------------------------------------------- |
| `codegraph-semantic-search.ps1` | FTS5 + fuzzy synonym matching with relevance scoring  |
| `codegraph-enrich.ps1`          | Layer detection, complexity tags, metadata enrichment |

Synonym map: auth, error, config, db, api, test, ui, cache, net (5-10 terms each). Usage:
`.\scripts\codegraph\codegraph-semantic-search.ps1 -Query "where is auth handled"`.

## Configuration

```json
{
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "serve", "--mcp"],
      "enabled": true
    }
  }
}
```

Index: `.codegraph/codegraph.db` (SQLite, `.gitignore`d). Auto-sync 2s debounce. Supports 19+
languages (TS, JS, Python, Go, Rust, Java, C#, PHP, Ruby, C, C++, Swift, Kotlin, Dart, Svelte, Vue,
Liquid, Pascal, Scala). Framework routes for Django, Flask, FastAPI, Express, Laravel, Rails,
Spring, Gin, Axum, ASP.NET, Vapor, React Router, SvelteKit.

---

> **Detailed reference**: [references/detail.md](references/detail.md)
