# MANDATORY AI BEHAVIOR

**BEFORE every response, run:**
```
powershell -File tools/pre-process-input.ps1 -UserInput "<input>" -WorkspaceRoot "."
```
- `TRIGGER_MATCH_FOUND` → load skill immediately, then respond
- `PLAN_MODE_REQUIRED` → activate BA (confidence < 40), gather requirements first
- `NO_TRIGGER_MATCH` → continue normally

Full behavior spec: `CODEX.md` | Full mappings: `config/auto-delegation.json`

**EVERY. SINGLE. TIME.**

---

## Quick Reference

| User Input | Action |
|------------|--------|
| "iniciar sesion" | Load session-workflow-skill  runs session-autostart.cmd |
| "guardar sesion" | Load session-workflow-skill |
| "continuar" | Load session-workflow-skill |
| "estado" | Load session-workflow-skill |
| "review" | Load appropriate review skill |
| "implementar X" | Load appropriate dev skill |
| No match | Continue normally |

---

**NOW: Before responding to the user's next message, RUN THE SCRIPT FIRST.**
