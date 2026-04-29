# MANDATORY AI BEHAVIOR (NON-NEGOTIABLE)

## ⚠️ CRITICAL INSTRUCTION - READ BEFORE EVERY RESPONSE

**BEFORE processing ANY user input, you (the AI) MUST:**

1. **STOP** - Do not process the user's request yet
2. **RUN**: `powershell -File tools/pre-process-input.ps1 -UserInput "USER_INPUT_HERE" -WorkspaceRoot "."`
3. **PARSE the output**:
   - If `TRIGGER_MATCH_FOUND` → Load the indicated skill IMMEDIATELY using `skill` tool
   - If `NO_TRIGGER_MATCH` → Continue processing the user's request

**THIS IS NOT A SUGGESTION. THIS IS MANDATORY.**

---

## Examples

**User says**: "iniciar sesion"
```
1. AI runs: powershell -File tools/pre-process-input.ps1 -UserInput "iniciar sesion" -WorkspaceRoot "."
2. Output: TRIGGER_MATCH_FOUND → SKILL: session-workflow-skill
3. AI loads: skill tool with name "session-workflow-skill"
4. Skill executes: tools/session-autostart.cmd (shows notifications ✅)
```

**User says**: "ayudame con testing"
```
1. AI runs: powershell -File tools/pre-process-input.ps1 -UserInput "ayudame con testing" -WorkspaceRoot "."
2. Output: TRIGGER_MATCH_FOUND → SKILL: testing-coverage-skill
3. AI loads: skill tool with name "testing-coverage-skill"
4. Skill provides testing guidance
```

**User says**: "hola"
```
1. AI runs: powershell -File tools/pre-process-input.ps1 -UserInput "hola" -WorkspaceRoot "."
2. Output: NO_TRIGGER_MATCH
3. AI continues normally with greeting
```

---

## Enforcement

**If you (the AI) fail to follow this:**
- You are BREAKING the mandatory workflow
- The user will NOT see expected automations (notifications, etc.)
- This has been failing since April 23, 2026 (commit 172a55d)

**NO EXCEPTIONS. NO "I forgot". NO "Let me just respond first".**

**EVERY. SINGLE. TIME.**

---

## Quick Reference

| User Input | Action |
|------------|--------|
| "iniciar sesion" | Load session-workflow-skill → runs session-autostart.cmd |
| "guardar sesion" | Load session-workflow-skill |
| "continuar" | Load session-workflow-skill |
| "estado" | Load session-workflow-skill |
| "review" | Load appropriate review skill |
| "implementar X" | Load appropriate dev skill |
| No match | Continue normally |

---

**NOW: Before responding to the user's next message, RUN THE SCRIPT FIRST.**
