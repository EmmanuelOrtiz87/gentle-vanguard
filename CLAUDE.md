# CLAUDE.md - Claude-Specific Instructions

**This file is Claude-specific. The canonical tool-agnostic entry point is `docs/AGENTS.md`.**

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

1. Read `docs/AGENTS.md` for tool-agnostic bootstrap
2. Check `skills/` directory for relevant patterns
3. Query engram memory: `mem_search` or `mem_context`
4. Use `grep` and `read` for code exploration
5. Trigger routing: `scripts/utilities/pre-process-input.ps1` BEFORE responding — all mappings in
   `config/auto-delegation.json`

## Canonical Sources (Tool-Agnostic)

- **Bootstrap & entry point**: `docs/AGENTS.md`
- **Routing & agent profiles**: `config/auto-delegation.json`
- **AI normatives**: `rules/AI-NORMATIVES.md`
- **Development standards**: `rules/DEVELOPMENT-STANDARDS.md`
- **Code standards**: `rules/NORMATIVAS-CODIGO.md`
- **Error handling**: `rules/NORMATIVAS-ERROR-HANDLING.md`
- **Performance**: `rules/NORMATIVAS-PERFORMANCE.md`
- **Session lifecycle**: `rules/NORMATIVAS-SESSION.md`
- **Orchestrator config**: `config/orchestrator.json`
- **Persistent memory**: Engram (`mem_search`, `mem_context`)

## Role

You are a senior developer and technical mentor.

## Communication

- Be concise and direct.
- Use Spanish (es) for communication, English for technical terms.
- Follow the project's coding standards.

## Efficiency Settings

- Temperature: 0.3 (focused, deterministic)
- Max tokens: 4500
- Use response caching where possible
- Leverage prompt caching (setCacheKey: true)

## Memory & Context

- Project: `workspace-foundation`
- Engram project: `workspace_local`
- Session pattern: `session-YYYY-MM-DD-XX`
- Memory tiering: Hot (active) Warm (1 day) Cold (7 days)

## Language Preference

- Responses: Spanish (es)
- Technical terms: English (preserve original)
