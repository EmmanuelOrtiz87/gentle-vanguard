# Automatización — Análisis v2.30.0

**Propósito**: Identificar qué componentes manuales se pueden automatizar y qué items del ROADMAP
implementar.

---

## 1. COMPONENTES MANUALES → AUTOMATIZAR

### Prioridad Alta (impacto inmediato, esfuerzo bajo)

| Componente                  | Manual hoy    | Automatización propuesta                                   | Esfuerzo |
| --------------------------- | ------------- | ---------------------------------------------------------- | -------- |
| **Auto-norm learner**       | Bajo demanda  | Trigger automático post-commit si `rules/` cambió          | 1-2h     |
| **Auto-doc drift detector** | Bajo demanda  | CI semanal (domingo) junto a maintenance-watchtower        | 1-2h     |
| **Failure learning**        | Bajo demanda  | Hook post-error en session-manager + consolidación semanal | 2-3h     |
| **Context budget audit**    | Manual        | Check automático en pre-compact-hook + alerta si > umbral  | 1h       |
| **RAG queries**             | Manual script | Auto-RAG en cada turno si Engram devuelve hits relevantes  | 1-2h     |

### Prioridad Media (buen ROI, esfuerzo medio)

| Componente                | Manual hoy    | Automatización propuesta                          | Esfuerzo |
| ------------------------- | ------------- | ------------------------------------------------- | -------- |
| **FT Python trainer**     | Stub sin impl | Completar `train_lora.py` + CI semanal automático | 3-5h     |
| **SIEM audit bridge**     | Manual        | Event-driven desde event-bus (subscription SIEM)  | 2-3h     |
| **Karpathy enforcer**     | Manual        | Pre-commit hook que verifica guidelines en diff   | 2h       |
| **Agent message bus**     | Manual        | Integrar con event-bus para mensajes inter-agente | 3-4h     |
| **Profile import/export** | Manual        | Script auto-save/auto-load en session start/end   | 1h       |

### Prioridad Baja (ROI bajo o depende de otra iniciativa)

| Componente                   | Manual hoy   | Automatización propuesta              | Esfuerzo |
| ---------------------------- | ------------ | ------------------------------------- | -------- |
| **Resilience/Chaos**         | Manual       | CI semanal con Pester Chaos tests     | 3-4h     |
| **Plugin loader**            | Manual       | Auto-detect plugin/ en startup        | 1-2h     |
| **Multi-repo orchestration** | Alpha manual | Pipeline CI con multi-repo-engine.ps1 | 4-6h     |

---

## 2. ROADMAP GAPS — IMPLEMENTAR

### Fase 1 (v2.31.0 — v2.32.0)

| Item                           | Prioridad | Estado     | Acción                                                    |
| ------------------------------ | --------- | ---------- | --------------------------------------------------------- |
| **Secretlint pre-commit**      | Alta      | 📋 Planned | Integrar Secretlint en lefthook pre-commit                |
| **Coverage reporting**         | Alta      | 📋 Planned | Agregar Pester CodeCoverage gate en CI                    |
| **EditorConfig + Prettier CI** | Alta      | 📋 Planned | Agregar workflow format-check + lefthook                  |
| **Branch strategy docs**       | Alta      | 📋 Planned | Documentar git-flow adaptado en `docs/BRANCH-STRATEGY.md` |

### Fase 2 (v3.0)

| Item                           | Prioridad | Estado     | Acción                                                    |
| ------------------------------ | --------- | ---------- | --------------------------------------------------------- |
| **gentle-vanguard init**       | High      | 📋 Planned | Script scaffolding interactivo (`gv init`)                |
| **ADR tooling**                | Medium    | 📋 Planned | Script `adr-new.ps1` + CI para validar ADRs               |
| **Cross-platform test matrix** | Medium    | ⚠️ Parcial | Expandir cross-platform-tests.yml a Linux + macOS runners |
| **Token dashboard v2**         | Low       | 📋 Planned | Dashboard HTML con históricos semanales/mensuales         |

### Fase 3 (v3.x+)

| Item                              | Esfuerzo | Estado     | Acción                                               |
| --------------------------------- | -------- | ---------- | ---------------------------------------------------- |
| **Plugin Registry / Marketplace** | Grande   | 🔮 Visión  | Catálogo de skills publicables + `gv plugin install` |
| **MCP Native**                    | Medio    | ⚠️ Parcial | Migrar skill-server.ts a protocolo MCP nativo        |
| **Web UI**                        | Grande   | ⚠️ Parcial | SPA React para dashboard + metrics en vivo           |
| **VS Code Extension**             | Grande   | 🔮 Visión  | Extensión VS Code con panel de control               |
| **Multi-repo orchestration**      | Medio    | ⚠️ Alpha   | Madurar multi-repo-engine.ps1 a producción           |

---

## 3. QUICK WINS (Esta Semana)

Los items de Prioridad Alta de la sección 1 se pueden implementar en **~5-7h totales**:

1. **Auto-doc drift detector** en CI semanal → 1-2h
2. **Auto-norm learner** post-commit hook → 1-2h
3. **Context budget audit** en pre-compact-hook → 1h
4. **RAG auto-query** en pre-process-input → 1-2h

---

## 4. DEUDA TÉCNICA

| Issue                           | Impacto                  | Propuesta                                                 |
| ------------------------------- | ------------------------ | --------------------------------------------------------- |
| `train_lora.py` es stub         | Bloquea fine-tuning real | Implementar o reemplazar con llamada a API de LoRA        |
| event-bus sub-utilizado (1 sub) | Infra infrautilizada     | Migrar adaptive scripts a event-driven                    |
| Plugins experimentales sin uso  | Código muerto            | Decidir: eliminar o promover a ciudadano de primera clase |
| Dashboard v3 sin Web UI         | Solo HTML estático       | Postergar a v3.x (Fase 3)                                 |
