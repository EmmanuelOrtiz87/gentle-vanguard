# Unified Automation Architecture - Cross-Tool Solution

## The Problem
We have rules in `AGENTS.md`, `.clinerules`, `.cursorrules` but they're just text. The AI (me) reads them but doesn't automatically obey them BEFORE every response.

## Recommended Solution (3 Layers)

### Layer 1: Tool-Agnostic Config (DONE )
**File**: `config/orchestrator.json`
- Unified settings for all tools
- Defines pre-processing hook location
- Sets mandatory enforcement flags

### Layer 2: Tool-Specific Rules (DONE )
**Files**: `AGENTS.md`, `.clinerules`, `.cursorrules`, `CLAUDE.md`, `.windsurf/config.json`
- All updated with MANDATORY PRE-PROCESSING RULE
- Same rule text across all tools
- Ensures AI reads the same instruction everywhere

### Layer 3: Enforcement Mechanism (MISSING )

**Option A: AI Self-Enforcement (Current Workaround)**
- AI (me) must follow the rule in `AGENTS.md` line 5-17
- Requires strict discipline from AI
- Buggy `pre-process-input.ps1` needs fixing

**Option B: True Tool-Level Hook (Recommended)**
Each tool needs to support a `pre_process` hook:

```json
// opencode.json
{
  "hooks": {
    "pre_process": {
      "enabled": true,
      "mandatory": true,
      "script": "scripts/utilities/pre-process-input.ps1",
      "args": ["-UserInput", "${user_input}", "-WorkspaceRoot", "."]
    }
  }
}
```

```json
// .vscode/settings.json (for Cline)
{
  "cline.hooks.preProcess": {
    "enabled": true,
    "script": "scripts/utilities/pre-process-input.ps1"
  }
}
```

## What Needs to Happen

| Tool | What's Needed for True Automation |
|------|----------------------------------|
| **OpenCode** | Add `hooks.pre_process` support in `opencode.json` |
| **Cline** | Add hook support in VS Code extension settings |
| **Cursor** | Add hook support in `.cursorrules` or IDE config |
| **Windsurf** | Add hook support in `.windsurf/config.json` |
| **Continue.dev** | Add hook support in IDE extension |
| **Claude** | Add hook support in `CLAUDE.md` or API level |

## Current Status (Without Tool Support)

Without tool-level hooks, we rely on **AI self-enforcement**:
1. AI reads `AGENTS.md` 
2. AI sees `MANDATORY PRE-PROCESSING RULE` 
3. AI **should** run `pre-process-input.ps1` before EVERY response  (not happening reliably)

## Immediate Fix Needed

Fix `pre-process-input.ps1` to actually work:
- Debug trigger extraction from SKILL.md files
- Ensure it returns correct output
- AI must run it before EVERY user response

## For You to Decide

**Which approach do you want?**

1. **Fix AI self-enforcement** (quick fix) - debug `pre-process-input.ps1` and make AI follow rules strictly
2. **Request tool vendors** (long-term) - ask OpenCode, Cline, Cursor to add `pre_process` hook support
3. **Hybrid** (recommended) - do both: fix current implementation + request proper tool support

**My recommendation**: Fix the script and make the rule ABSOLUTELY MANDATORY in all configs (which we've done), then ensure AI follows it unconditionally.
