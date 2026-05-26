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
  -JsonString '<YOUR_JSON>' -Context "manual-check"
```

---
**Version**: 1.0.0 | **Created**: 2026-05-26
