# CODEX.md - Local-First Policy

## MANDATORY PRE-PROCESSING RULE (ALWAYS ACTIVE)

**BEFORE responding to ANY user input:**

1. **Run**: `powershell -File tools/pre-process-input.ps1 -UserInput "USER_INPUT_HERE" -WorkspaceRoot "."`
2. **Parse output**:
   - `TRIGGER_MATCH_FOUND` → load skill BEFORE any other action
   - `PLAN_MODE_REQUIRED` → activate BA agent (confidence < 40)
   - `NO_TRIGGER_MATCH` → continue normally
3. **Session start**: run `tools/session-autostart.cmd` on first turn

**This rule is MANDATORY. Do NOT wait to be asked.**

## Core Principle
**LOCAL-FIRST**: project knowledge → engram (`mem_search`) → local grep/read → external only if authorized.
- NO websearch / codesearch / webfetch by default
- Full trigger mappings: `config/auto-delegation.json#keywordMappings`

## Response Style
- Language: Spanish (es) for communication, English for technical terms
- Temperature: 0.3 | Max tokens: 4500
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
