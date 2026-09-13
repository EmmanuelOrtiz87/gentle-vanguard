---
created: 2026-09-04 01:19:17
tags: [engram, decision]
engram_id: 3661
type: decision
---

# GV Analytics usa opencode/big-pickle (modelo del orquestador) para IA real

**What**: GV Analytics ahora usa el modelo del orquestador `opencode/big-pickle` (free) para análisis con IA real. El endpoint `/api/analyze` devuelve `llmSource: "agent"` en vez de `"heuristic"`.

**Why**: El usuario quiere que analytics use la misma configuración de opencode que el orquestador. No Ollama, no littlellm (sin crédito). El provider `custom` (AWS Lambda) devolvía 401 sin API key.

**Where**:
- `apps/gv-analytics/server/llm-client.ts` — `detectOpencode()` detecta el modelo del orquestador; `generateWithOpencode()` spawna el CLI de opencode (`opencode run --model opencode/big-pickle --format json`) y parsea eventos JSON (type: "text")
- `apps/gv-analytics/config/cloud-agents.local.json` — provider `opencode` habilitado (auth_type: "none")
- `src/agent-delegator.ts` + `src/orchestration/agent-delegator.ts` — fix del guard CLI en Windows (auto-url-fix + export main)

**Learned**:
- El CLI real de opencode está en `C:\Users\emman\AppData\Local\Microsoft\WinGet\Links\opencode.exe` (v1.18.21). El wrapper `C:\Users\emman\bin\opencode` es solo un demo.
- `opencode run --model <model> --format json "<prompt>"` emite eventos JSON; extraer `type: "text"` → `part.text`.
- El patrón `import.meta.url === file://${process.argv[1]}` NO funciona en Windows (backslashes vs forward slashes) — usar `pathToFileURL(process.argv[1]).href`.
- El servidor se reinicia con `taskkill /F /PID <pid>` + `node --import tsx server/index.ts` (el start.sh usa nohup/proc que no funcionan bien en Windows).

---
*Imported from Engram on 2026-09-06*
