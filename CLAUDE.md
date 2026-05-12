# foundation — Entry Point for Claude-Compatible Tools

**Loaded by**: OpenCode, Claude Code, Windsurf, Claude | Canonical entry: `docs/AGENTS.md`

## 🔴 CRITICAL: First Action — Tool Detection

Run this IMMEDIATELY before any other action:

```powershell
$detected = pwsh -NoProfile -File scripts/utilities/detect-tool.ps1 -AsJson | ConvertFrom-Json
$detected.name
# → "opencode", "claude-code", "cline", "cursor", "windsurf", or "unknown"
```

Based on result, load config from `config/orchestrator.json#toolProfiles.<name>`.

If **opencode**: promptFile=CLAUDE.md, configFile=opencode.json, responseProfile=ultra, lang=es
If **claude-code**: promptFile=CLAUDE.md, configFile=.claude/settings.json, responseProfile=ultra, lang=es
If **cline**: promptFile=.clinerules, configFile=.clinerules, responseProfile=ultra, lang=es

**Why**: Each tool has different capabilities (skill tool, mem tools, file access). Detection ensures correct routing, compression, and security profiles.

## 🚀 Mandatory Startup Sequence

After detection, execute ALL steps in order:

1. `scripts/utilities/session-autostart.cmd` — activates notifications, security, engram, token guard, karpathy enforcer
2. `engram_mem_session_start` — register session ID
3. `engram_mem_context` — restore previous context
4. `git status` — verify workspace state
5. Read `docs/AGENTS.md` — completes canonical bootstrap

## 🗺️ Core Rules

1. **LOCAL-FIRST**: Project knowledge before external sources
2. **NO websearch/codesearch/webfetch** unless orchestrator authorizes
3. **pre-process-input.ps1** BEFORE responding — trigger routing via `config/auto-delegation.json`
4. Check `skills/` directory for reusable patterns before writing code
5. Use Engram memory: `mem_search` for past decisions, `mem_save` after significant work

## 📝 Response Compression (MANDATORY)

Profile: **ultra** | Detail: **simple** | Chat: **chat-compact** (max 4 lines)

1. NO preamble/postamble — just do it
2. NO echoing user's question
3. NO progress commentary during multi-step tasks
4. Batch independent tool calls in parallel
5. Answer THEN act: 1-3 line answer, then tools
6. Use abbreviations: db/auth/config/req/res/fn/impl

## ⚙️ Settings

- Temperature: 0.3 | Max tokens: 4500 | Cache: enabled (setCacheKey: true)
- Lang: es | Session pattern: session-YYYY-MM-DD-XX
- Engram project: workspace_local

## 📚 Key References

| Resource | Path |
|----------|------|
| Tool-agnostic bootstrap | `docs/AGENTS.md` |
| Orchestrator config | `config/orchestrator.json` |
| Trigger→skill mappings | `config/auto-delegation.json` |
| AI normatives | `rules/AI-NORMATIVES.md` |
| Session lifecycle | `rules/NORMATIVAS-SESSION.md` |
| Performance | `rules/NORMATIVAS-PERFORMANCE.md` |
