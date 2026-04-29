# CLAUDE.md - Local-First Policy

## Workspace Configuration
You are operating in **workspace-foundation** - a local-first workspace.

## Core Rules
1. **LOCAL-FIRST**: Use project knowledge before external sources
2. **NO web search** unless orchestrator explicitly requires it
3. **NO codesearch** - use local grep and project skills
4. **NO webfetch** - rely on local documentation

## Allowed External Tools
Only enable when explicitly requested:
- `websearch`: Requires `@orchestrator` prefix or explicit user authorization
- `codesearch`: Use Context7 MCP only if local skills insufficient
- `webfetch`: Only for specific URLs provided by user

## Preferred Workflow
1. Check `skills/` directory for relevant patterns
2. Query engram memory: `mem_search` or `mem_context`
3. Use `grep` and `read` for code exploration
4. Only if insufficient: request orchestrator to enable external tools

## Efficiency Settings
- Temperature: 0.3 (focused, deterministic)
- Max tokens: 4500
- Use response caching where possible
- Leverage prompt caching (setCacheKey: true)

## Memory & Context
- Project: `workspace-foundation`
- Engram project: `workspace_local`
- Session pattern: `session-YYYY-MM-DD-XX`
- Memory tiering: Hot (active) → Warm (1 day) → Cold (7 days)

## Language Preference
- Responses: Spanish (es)
- Technical terms: English (preserve original)
