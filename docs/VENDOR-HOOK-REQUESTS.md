# Vendor Hook Requests - Pre-Processing Support

## Overview
We need AI tool vendors to support a `pre_process` hook that automatically runs BEFORE any user input is processed by the AI.

## The Problem
Currently, we have rules in config files (`.clinerules`, `.cursorrules`, `AGENTS.md`) but they're just text. The AI reads them but doesn't reliably follow them BEFORE every response.

## Proposed Solution: `pre_process` Hook

### OpenCode
**File**: `opencode.json`
```json
{
  "hooks": {
    "pre_process": {
      "enabled": true,
      "mandatory": true,
      "description": "Runs BEFORE any AI response",
      "script": "tools/pre-process-input.ps1",
      "args": {
        "UserInput": "${user_input}",
        "WorkspaceRoot": "."
      },
      "parseOutput": {
        "triggerFound": "TRIGGER_MATCH_FOUND",
        "noMatch": "NO_TRIGGER_MATCH"
      },
      "actions": {
        "onMatch": "The AI MUST load the indicated skill using `skill` tool",
        "onNoMatch": "Continue with normal behavior"
      }
    }
  }
}
```

**Status**: ✅ Config structure added (2026-04-29)
**Needed**: Actual enforcement by OpenCode runtime

---

### Cline (VS Code Extension)
**File**: `.clinerules` or `.vscode/settings.json`
```json
{
  "cline": {
    "hooks": {
      "preProcess": {
        "enabled": true,
        "mandatory": true,
        "script": "tools/pre-process-input.ps1"
      }
    }
  }
}
```

**Status**: ❌ Not supported yet
**Needed**: Add hook support in Cline extension settings

---

### Cursor
**File**: `.cursorrules` or Cursor IDE config
```json
{
  "cursor": {
    "hooks": {
      "preProcess": {
        "enabled": true,
        "script": "tools/pre-process-input.ps1"
      }
    }
  }
}
```

**Status**: ❌ Not supported yet
**Needed**: Add hook support in Cursor IDE

---

### Windsurf
**File**: `.windsurf/config.json`
```json
{
  "hooks": {
    "pre_process": {
      "enabled": true,
      "script": "tools/pre-process-input.ps1"
    }
  }
}
```

**Status**: ❌ Not supported yet
**Needed**: Add hook support in Windsurf

---

### Continue.dev
**File**: IDE extension config
```json
{
  "continue": {
    "hooks": {
      "preProcess": {
        "enabled": true,
        "script": "tools/pre-process-input.ps1"
      }
    }
  }
}
```

**Status**: ❌ Not supported yet
**Needed**: Add hook support in Continue.dev extension

---

## Current Workaround (AI Self-Enforcement)

While waiting for vendors to implement hooks, we rely on **AI self-enforcement**:

1. AI reads `AGENTS.md` ✅
2. AI sees `MANDATORY PRE-PROCESSING RULE` ✅
3. AI **should** run `pre-process-input.ps1` before EVERY response ❌ (not happening reliably)

**Our implementation (2026-04-29):**
- ✅ `tools/pre-process-input.ps1` (fixed and working)
- ✅ `config/orchestrator.json` (unified config)
- ✅ `opencode.json` (hook config added)
- ✅ All tool configs updated (`.clinerules`, `.cursorrules`)

---

## Request to Vendors

**Subject**: Add `pre_process` hook support for mandatory pre-processing

**Message**:
We've implemented a cross-tool automation system that requires running a script BEFORE any user input is processed. Currently, this relies on AI self-enforcement which is unreliable.

We request adding a `pre_process` hook in your tool's config that:
1. Intercepts user input before AI processes it
2. Runs a specified script with the user input as argument
3. Parses the output to determine next action
4. Optionally blocks AI response until hook completes

This would enable true automation across all AI coding tools.

**Implementation Example** (from our `opencode.json`):
```json
{
  "hooks": {
    "pre_process": {
      "enabled": true,
      "mandatory": true,
      "script": "path/to/script.ps1",
      "args": { "UserInput": "${user_input}" }
    }
  }
}
```

---

## Status Summary

| Tool | Hook Support | Config Added | Status |
|------|--------------|-------------|--------|
| **OpenCode** | ❌ Needed | ✅ Yes | Waiting for runtime support |
| **Cline** | ❌ Needed | ✅ Yes (`.clinerules`) | Waiting for extension update |
| **Cursor** | ❌ Needed | ✅ Yes (`.cursorrules`) | Waiting for IDE update |
| **Windsurf** | ❌ Needed | ❌ | Waiting for config support |
| **Continue.dev** | ❌ Needed | ❌ | Waiting for extension update |

---

**Date**: 2026-04-29
**Contact**: EmmanuelOrtiz87 (emmanueltiz@gmail.com)
