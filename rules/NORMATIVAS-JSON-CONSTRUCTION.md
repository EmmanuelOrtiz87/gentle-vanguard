# JSON Construction Normative — Agent Mandatory

## Rule: JSON_VALIDITY_CHECK

**Applies to**: All AI agents calling tools with JSON parameters

### Requirement

Before ANY tool call with JSON parameters, the agent MUST:

1. **Count opening/closing symbols**:
   - Quotes `"`: must be even
   - Braces `{` and `}`: must be balanced
   - Brackets `[` and `]`: must be balanced

2. **Verify JSON ends correctly**:
   - Must end with `}` (object) or `]` (array)
   - No trailing commas before closing

3. **Quick mental check**:
   - Did I close all strings I opened?
   - Did I close all braces/brackets?
   - Is the last character `}` or `]`?

### Examples

**BAD** (causes error):
```json
{"project": "workspace_gentle_vanguard
```
- Missing closing quote
- Missing closing brace

**GOOD**:
```json
{"project": "workspace_gentle_vanguard"}
```

### Enforcement

This is a **CRITICAL** rule. Violation = malformed tool call = wasted tokens + failed operation.

### When in doubt

Use the JSON validator:
```powershell
pwsh -NoProfile -File scripts/utilities/json-validator.ps1 `
  -JsonString '{"test": "value"}' -Context "manual-check"
```

### Common Error: Truncated JSON in Tool Calls

**Problem**: When calling tools like `engram_mem_session_end` with long summaries, the JSON gets truncated, causing "Unterminated string" errors.

**Example of ERROR**:
```
{"summary": "Very long text...", "id": "session-202.
                                    ^
                                    JSON truncated here
```

**Root cause**: Long strings in JSON parameters get cut off by the system.

**Solution**: Keep JSON parameters concise:
```json
{"summary": "Implemented JSON validator, tests, docs. All pushed.", "id": "session-20250526-001"}
```

**Best practices**:
1. Keep summaries under 200 characters
2. Use abbreviations (e.g., "docs" instead of "documentation")
3. Remove unnecessary details (dates, full paths)
4. Focus on WHAT was done, not HOW

**Example transformation**:
- ❌ BAD (truncated): `{"summary": "Session completed successfully. Implemented JSON validator with strict validation, integrated into pre-process-input.ps1, created mandatory construction normative..."
- ✅ GOOD (concise): `{"summary": "Implemented JSON validator with tests and docs. All changes pushed to develop."}

---
**Version**: 1.0.0 | **Created**: 2026-05-26
