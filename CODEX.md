# CODEX.md - Local-First Policy

## MANDATORY PRE-PROCESSING RULE (ALWAYS ACTIVE)

**BEFORE responding to ANY user input:**

1. **Run trigger detection** - Execute: `powershell -File tools/pre-process-input.ps1 -UserInput "USER_INPUT_HERE" -WorkspaceRoot "."`
2. **Parse output**:
   - If `TRIGGER_MATCH_FOUND` → Load indicated skill using `skill` tool BEFORE any other action
   - If `NO_TRIGGER_MATCH` → Continue with normal behavior
3. **Session start** - Always run `tools/session-autostart.cmd` on Windows for notifications, optimizations, validations
4. **Special case "iniciar sesion"** - Load `session-workflow-skill`, then follow its workflow

**This rule is MANDATORY and MUST be followed automatically. Do NOT wait to be asked.**

## Core Principle
This project follows a **LOCAL-FIRST** approach. AI agents must prioritize:
1. Local project knowledge (skills, documentation, scripts)
2. Persistent memory (engram)
3. Cached responses and context
4. External search ONLY when explicitly needed by orchestrator

## Tool Restrictions
- **websearch**: DENY - Do not search the web
- **codesearch**: DENY - Use local grep and project skills
- **webfetch**: DENY - Use local documentation

## Allowed by Default
✅ `grep` - Search local files
✅ `read` - Read local files
✅ `glob` - Find local files
✅ `mem_search` - Query engram memory
✅ `mem_context` - Get session context
✅ `bash` - Run local scripts

## When External Tools Are Allowed
Only when:
1. User explicitly requests external research
2. Orchestrator agent requires it for complex tasks
3. Local knowledge is proven insufficient after checking:
   - Project skills (`skills/`)
   - Engram memory (`mem_search`)
   - Project documentation (`docs/`, `README.md`)

## Efficiency Guidelines
- Use cached responses when available
- Leverage prompt caching (setCacheKey: true)
- Batch non-urgent operations
- Prefer local context over external API calls

## Response Style
- Language: Spanish (es) for communication
- Technical terms: Keep in English
- Be concise and direct
- No unnecessary explanations

## Configuration Files
See also:
- `opencode.json` - OpenCode configuration
- `CLAUDE.md` - Claude-specific rules
- `.cursorrules` - Cursor IDE rules
- `.windsurf/config.json` - Windsurf configuration
- `.clinerules` - Cline rules
