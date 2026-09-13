---
created: 2026-08-11 09:58:05
tags: [engram, decision]
engram_id: 2749
type: decision
---

# Session-Based Fallback implementado - Herencia dinámica de modelo

**What**: Implementado Session-Based Fallback en GGA para herencia dinámica de modelo del orquestador a subagentes.

**Why**: Los subagentes no heredaban el modelo del orquestador (kimi-2-5) y opencode asignaba modelo free (deepseek-v4-flash-free) sin crédito. Cuando la delegación fallaba, el orquestador ahora ejecuta directamente la tarea.

**Where**:
- src/gga.ts - Funciones getCurrentSessionId(), detectNewSession(), activateSessionFallbackMode(), loadGGAState() modificada, GuardianAngel() con fallback final al orquestador
- src/model-enforcer.ts - detectOrchestratorModel() herencia dinámica desde opencode.json
- src/agent-delegator.ts - Corregido error de destructuring

**Learned**:
- Nueva sesión detectada vía SESSION_ID o timestamp+PID
- Modo fallback persistente durante toda la sesión tras 2+ fallos
- Reset automático a normalidad al iniciar nueva sesión
- Fallback final: si todos los modelos fallan, orquestador ejecuta con getDetectedModel()
- Trade-off: Se pierde paralelización pero se garantiza ejecución

**Verification**:
- Typecheck: exit 0 ✅
- Lint: exit 0 ✅
- Delegación test: ✓ Success with provider: kimi-2-5 ✅

---
*Imported from Engram on 2026-09-06*
