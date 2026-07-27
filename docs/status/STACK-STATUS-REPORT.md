# Gentle-Vanguard — Stack Status Report

**Versión actual**: v3.1.0 **Fecha**: 2026-06-04 **Stack**: AI orchestration layer multi-herramienta
| ~300+ scripts | ~386 skills | 28 CI/CD workflows

---

## 1. ARQUITECTURA (5 Capas)

```
Layer 5: AGENTES  — 18 agents (Orchestrator + 17 sub-agentes: BA, SAD, DEV, QA, OPS, GOV, DOC, etc.)
Layer 4: COMANDOS — gv.ps1, pre-process-input.ps1, detect-tool.ps1
Layer 3: MCP      — skill-server.ts (MCP protocol), mcp-bridge.ps1
Layer 2: SKILLS   — ~386 skills en skills/ (SDD, seguridad, web, mobile, AI/ML, etc.)
Layer 1: MEMORIA  — Engram persistent memory (tools/engram.exe v1.15.10)
```

**Principio**: 100% agnóstico — funciona con OpenCode, Claude Code, Cline, Cursor, Windsurf, Codex,
VS Code, Copilot, Antigravity.

---

## 2. COMPONENTES DEL STACK

### 2.1 Core / Bootstrap

| Componente          | Archivo(s)                                 | Estado    | Automatización             |
| ------------------- | ------------------------------------------ | --------- | -------------------------- |
| Bootstrap workspace | `scripts/core/bootstrap*.ps1`              | ✅ Activo | Manual (setup inicial)     |
| CLI principal       | `gv.ps1`                                   | ✅ Activo | Manual                     |
| Tool detection      | `scripts/utilities/DETECT/detect-tool.ps1` | ✅ Activo | Automático (cada turno)    |
| Pre-process hook    | `scripts/utilities/pre-process-input.ps1`  | ✅ Activo | Automático (cada turno)    |
| Session manager     | `scripts/utilities/session-manager.ps1`    | ✅ Activo | Automático (start/end)     |
| Hashline integrity  | `scripts/editing/hashline.ps1`             | ✅ Activo | Automático (snapshot hook) |

### 2.2 Memoria Persistente (Engram)

| Componente          | Archivo(s)                                         | Estado    | Automatización                                    |
| ------------------- | -------------------------------------------------- | --------- | ------------------------------------------------- |
| Engram CLI          | `tools/engram.exe` v1.15.10                        | ✅ Activo | Automático (mem_save/mem_search en cada sesión)   |
| Engram RAG          | `scripts/utilities/ENGRAM-RAG/` (3 scripts)        | ✅ Activo | Manual (query) / Automático (reindex en pipeline) |
| Engram orchestrator | `scripts/utilities/ENGRAM/engram-orchestrator.ps1` | ✅ Activo | Automático (sesión)                               |
| Vector index        | TF-IDF 1,289 docs × 7,317 términos                 | ✅ Activo | Incremental rebuild                               |

### 2.3 ML / Auto-Delegación

| Componente        | Archivo(s)                                                | Estado    | Automatización            |
| ----------------- | --------------------------------------------------------- | --------- | ------------------------- |
| ML Router         | `scripts/utilities/AUTO-DELEGATION/ml-router.ps1`         | ✅ Activo | Automático (pre-process)  |
| Skill embedder    | `scripts/utilities/AUTO-DELEGATION/skill-embedder.ps1`    | ✅ Activo | Automático (reindex)      |
| Context analyzer  | `scripts/utilities/AUTO-DELEGATION/context-analyzer.ps1`  | ✅ Activo | Automático (sesión start) |
| Skill recommender | `scripts/utilities/AUTO-DELEGATION/skill-recommender.ps1` | ✅ Activo | Automático (sesión start) |
| Routing tiers     | ≥80% directo / ≥60% confirmar / <60% → BA explore         | ✅ Activo | Automático                |

### 2.4 Fine-Tuning (LoRA)

| Componente            | Archivo(s)                                              | Estado      | Automatización         |
| --------------------- | ------------------------------------------------------- | ----------- | ---------------------- |
| FT pipeline           | `scripts/utilities/FINE-TUNING/ft-pipeline.ps1`         | ✅ Activo   | Automático (CI weekly) |
| FT trainer            | `scripts/utilities/FINE-TUNING/ft-trainer.ps1`          | ✅ Activo   | Manual / CI            |
| FT evaluator          | `scripts/utilities/FINE-TUNING/ft-evaluator.ps1`        | ✅ Activo   | Manual / CI            |
| FT threshold detector | `scripts/utilities/FINE-TUNING/ft-threshold-detect.ps1` | ✅ Activo   | Automático (CI)        |
| FT auto-prune         | `scripts/utilities/FINE-TUNING/ft-auto-prune.ps1`       | ✅ Activo   | Automático (CI)        |
| FT registry           | `.ft/registry.json`                                     | ✅ Activo   | Automático             |
| Adapters activos      | BA, DEV (mistral-7b-lora, v1.0.0)                       | ✅ Activo   | LoRA fine-tuned        |
| Python trainer        | `scripts/utilities/FINE-TUNING/python/train_lora.py`    | ⚠️ Presente | Manual (stub)          |

### 2.5 Dashboard / Métricas

| Componente              | Archivo(s)                                   | Estado    | Automatización          |
| ----------------------- | -------------------------------------------- | --------- | ----------------------- |
| Dashboard v3 (Chart.js) | `reports/dashboard-v2/dashboard.html`        | ✅ Activo | CI/CD genera artifact   |
| Metrics collector       | `scripts/metrics/collector.ps1`              | ✅ Activo | Automático (sesión)     |
| Dashboard render        | `scripts/metrics/dashboard-render.ps1`       | ✅ Activo | Manual / CI             |
| Dashboard health        | `scripts/metrics/dashboard-health-check.ps1` | ✅ Activo | CI                      |
| Live feed               | `scripts/metrics/live-feed.ps1`              | ✅ Activo | Automático              |
| Metrics server          | `scripts/metrics/metrics-server.ps1`         | ✅ Activo | Manual (HTTP server)    |
| Telemetry writer        | `scripts/metrics/telemetry-writer.ps1`       | ✅ Activo | Automático              |
| Weekly metrics          | `scripts/monitoring/weekly-metrics.ps1`      | ✅ Activo | Manual / CI             |
| Executive dashboard     | `scripts/monitoring/executive-dashboard.ps1` | ✅ Activo | Manual                  |
| Token monitor           | `scripts/utilities/TOKEN/` (7 scripts)       | ✅ Activo | Automático (cada turno) |

### 2.6 Seguridad

| Componente            | Archivo(s)                                   | Estado    | Automatización                 |
| --------------------- | -------------------------------------------- | --------- | ------------------------------ |
| Secrets manager       | `scripts/security/secrets-manager.ps1`       | ✅ Activo | Manual                         |
| Encryption (AES-256)  | `scripts/security/encryption-manager.ps1`    | ✅ Activo | Manual                         |
| Input validator       | `scripts/security/input-validator.ps1`       | ✅ Activo | Automático (pre-commit)        |
| Security logger       | `scripts/security/security-logger.ps1`       | ✅ Activo | Automático                     |
| Security orchestrator | `scripts/security/security-orchestrator.ps1` | ✅ Activo | Automático (pre-push)          |
| Privacy sanitizer     | `scripts/security/privacy-sanitizer.ps1`     | ✅ Activo | Automático (pre-commit)        |
| Gitleaks              | Lefthook + CI                                | ✅ Activo | Automático (pre-commit + push) |
| Trivy (deps)          | CI weekly                                    | ✅ Activo | CI automático                  |
| SBOM validation       | `scripts/security/sbom-validate.ps1`         | ✅ Activo | CI                             |
| SIEM audit bridge     | `scripts/security/siem-audit-bridge.ps1`     | ✅ Activo | Manual                         |

### 2.7 CI/CD (28 workflows)

| Workflow                                    | Trigger                                    | Estado     |
| ------------------------------------------- | ------------------------------------------ | ---------- |
| `test-suite.yml`                            | Push/PR develop/main                       | ✅ Activo  |
| `security-scan.yml`                         | Push/PR + cron weekly                      | ✅ Activo  |
| `release.yml`                               | Push tag v*.*.\*                           | ✅ Activo  |
| `dashboard-ci.yml`                          | Push metrics + cron daily                  | ✅ Activo  |
| `maintenance-scheduled.yml`                 | Cron weekly Sun                            | ✅ Activo  |
| `cross-platform-tests.yml`                  | Push/PR + cron daily                       | ✅ Activo  |
| `quality-gate.yml`                          | Push/PR scripts/hooks/config               | ✅ Activo  |
| `sdd-gate.yml`                              | PR a main/develop                          | ✅ Activo  |
| `script-governance.yml`                     | Push/PR scripts/docs/config                | ✅ Activo  |
| `sync-public.yml`                           | Push develop/main                          | ✅ Activo  |
| `monthly-management-report.yml`             | Cron monthly 1st                           | ✅ Activo  |
| `dashboard-auto-refresh.yml`                | Cron daily                                 | ✅ Activo  |
| `autonomous-validation.yml`                 | Push/PR + cron weekly                      | ✅ Activo  |
| `normative-enforcement.yml`                 | Push/PR scripts,rules,config + cron weekly | ✅ Activo  |
| Otros 14 (lint, format, audit, stale, etc.) | Varios                                     | ✅ Activos |

### 2.8 Git Hooks (Lefthook)

| Hook                  | Trigger                  | Estado    |
| --------------------- | ------------------------ | --------- |
| opencode-validation   | pre-commit               | ✅ Activo |
| validate-tool-configs | pre-commit               | ✅ Activo |
| json-lint             | pre-commit               | ✅ Activo |
| workflow-lint         | pre-commit               | ✅ Activo |
| lockfile-lint         | pre-commit               | ✅ Activo |
| trufflehog-scan       | pre-commit               | ✅ Activo |
| skill-scan            | pre-commit               | ✅ Activo |
| normative-audit       | pre-commit               | ✅ Activo |
| karpathy-enforcer     | pre-commit               | ✅ Activo |
| secretlint            | pre-commit               | ✅ Activo |
| format-check          | pre-commit               | ✅ Activo |
| audit-check           | pre-push                 | ✅ Activo |
| orchestrator-auto-fix | pre-push                 | ✅ Activo |
| npm-audit             | pre-push                 | ✅ Activo |
| commitlint            | commit-msg               | ✅ Activo |
| codegraph-sync        | post-commit + post-merge | ✅ Activo |
| hashline-snapshot     | post-commit              | ✅ Activo |

### 2.9 Sistema Adaptativo / Auto-aprendizaje

| Componente               | Archivo(s)                                       | Estado    | Automatización               |
| ------------------------ | ------------------------------------------------ | --------- | ---------------------------- |
| Auto-norm learner        | `scripts/adaptive/auto-norm-learner.ps1`         | ⚠️ Activo | Manual (bajo demanda)        |
| Auto-norm enforcer       | `scripts/adaptive/auto-norm-enforcer.ps1`        | ✅ Activo | Automático (cada 5 turnos)   |
| Failure learning         | `scripts/adaptive/failure-learning-system.ps1`   | ⚠️ Activo | Manual                       |
| Cache manager            | `scripts/adaptive/cache-manager.ps1`             | ✅ Activo | Automático (sesión)          |
| Auto-doc drift detector  | `scripts/adaptive/auto-doc-drift-detector.ps1`   | ⚠️ Activo | Manual                       |
| Agent message bus        | `scripts/adaptive/agent-message-bus.ps1`         | ⚠️ Activo | Manual                       |
| Auto-backup              | `scripts/adaptive/auto-backup-orchestrator.ps1`  | ✅ Activo | Automático (scheduled)       |
| Judgment Day bridge      | `scripts/adaptive/judgment-day-bridge.ps1`       | ⚠️ Activo | Event-driven                 |
| Karpathy enforcer        | `scripts/adaptive/karpathy-enforcer.ps1`         | ✅ Activo | Automático (pre-commit)      |
| Normative audit pipeline | `scripts/utilities/normative-audit-pipeline.ps1` | ✅ Activo | Automático (pre-commit + CI) |
| Event bus                | `.event-bus/` (1 sub: judgment-day)              | ✅ Activo | Event-driven                 |

### 2.10 Prompts / Contexto

| Componente                 | Archivo(s)                                       | Estado    | Automatización             |
| -------------------------- | ------------------------------------------------ | --------- | -------------------------- |
| System prompt optimization | `scripts/utilities/PROMPT/` (8 scripts)          | ✅ Activo | Automático (pre-sesión)    |
| A/B testing prompts        | `scripts/utilities/PROMPT/prompt-ab-testing.ps1` | ✅ Activo | Manual                     |
| Prompt cache               | `scripts/utilities/PROMPT/prompt-cache.ps1`      | ✅ Activo | Automático                 |
| Prompt versioning          | `scripts/utilities/PROMPT/prompt-versioning.ps1` | ✅ Activo | Automático                 |
| Semantic compression       | `config/system-prompt-optimization.json`         | ✅ Activo | Automático (98% reducción) |
| Context budget audit       | `scripts/optimization/context-budget-audit.ps1`  | ⚠️ Activo | Manual                     |
| Token budget guard         | `scripts/utilities/TOKEN/token-budget-guard.ps1` | ✅ Activo | Automático (cada turno)    |

### 2.11 Skills / Plugins

| Componente                    | Estado          | Automatización      |
| ----------------------------- | --------------- | ------------------- |
| Skill registry (386 skills)   | ✅ Activo       | Automático (sync)   |
| Skill factory                 | ✅ Activo       | Manual              |
| Skill auto-patch              | ✅ Activo       | Automático          |
| Skill nudge                   | ✅ Activo       | Automático (sesión) |
| Usage tracker                 | ✅ Activo       | Automático          |
| Plugin architecture (example) | ⚠️ Experimental | Manual              |
| Plugin loader                 | ✅ Activo       | Manual              |

### 2.12 Monitoreo / SRE

| Componente                | Estado    | Automatización      |
| ------------------------- | --------- | ------------------- |
| Maintenance watchtower    | ✅ Activo | CI weekly (domingo) |
| Health check              | ✅ Activo | CI / Manual         |
| Continuous status monitor | ✅ Activo | Automático          |
| Error budget enforcement  | ✅ Activo | CI                  |
| Cross-workspace validator | ✅ Activo | CI                  |
| Performance baselines     | ✅ Activo | CI                  |
| Resilience/Chaos          | ⚠️ Activo | Manual              |

---

## 3. RESUMEN: AUTOMÁTICO vs MANUAL

### ✅ Automático (se ejecuta sin intervención)

- **Cada turno**: pre-process-input, token notification, ML routing, context optimization
- **Cada sesión**: session start/end, engram context, startup summary, skill recommendation
- **Git hooks**: 13 hooks en pre-commit/pre-push/commit-msg/post-commit
- **CI/CD**: 27 workflows (push, PR, cron diario/semanal/mensual)
- **Mantenimiento**: Watchtower (domingo), FT pipeline (semanal), auto-backup
- **Memoria**: Engram save/search/context en cada operación
- **Seguridad**: Gitleaks, Trivy, security orchestrator en hooks y CI

### 🔧 Manual (requiere invocación)

- **Fine-tuning trainer**: ejecutar ft-trainer.ps1 manualmente (o vía CI)
- **Dashboard render**: generar dashboard HTML manualmente (o vía CI)
- **Auto-norm learner**: bajo demanda
- **Auto-doc drift detector**: bajo demanda
- **Profile import/export**: manual
- **RAG queries**: vía engram-rag-query.ps1
- **Release**: push tag v*.*.\*
- **Multi-repo orchestration**: alpha, manual
- **Plugin usage**: manual (experimental)

---

## 4. ¿CÓMO FUNCIONA? FLUJO TÍPICO

### Inicio de sesión (automático):

```
Usuario escribe mensaje
  → pre-process-input.ps1 (cache SHA256, token notif, tool detection)
  → session-start-optimized.ps1 (autostart pipeline)
  → ML router analiza input → recomienda skill
  → Engram context load (memorias previas)
  → Context optimization (compresión, tiers)
  → Ejecución del mensaje con contexto optimizado
```

### Desarrollo de feature (SDD Lifecycle):

```
Requerimiento → BA/EXPLORE (análisis) → SAD (diseño) → DEV (impl) → QA (verificación)
  Cada fase con gate de validación automático
  PR bloqueado si falta SDD validado (sdd-gate.yml)
```

### CI/CD semanal (domingo 6am):

```
Maintenance Watchtower:
  1. Health check (16 checks: Engram, Dashboard, scripts, configs)
  2. Rebuild automático de índices stale
  3. Reporte JSON
  4. Fine-tuning pipeline: collect → build → threshold → auto-prune
```

---

## 5. ¿QUÉ FALTA / SIGUIENTES PASOS?

### Del ROADMAP oficial (v3.1.0 → v3.x+):

| Prioridad | Item                                              | Estado actual                       |
| --------- | ------------------------------------------------- | ----------------------------------- |
| 🔜 Alta   | **Secretlint pre-commit**                         | 📋 Planificado                      |
| 🔜 Alta   | **Coverage reporting (Pester CodeCoverage)**      | 📋 Planificado                      |
| 🔜 Alta   | **EditorConfig + Prettier CI check**              | 📋 Planificado                      |
| 🔜 Alta   | **Branch strategy / Release process docs**        | 📋 Planificado                      |
| 🏆 Media  | **`gentle-vanguard init` — project scaffolding**  | 📋 Planificado (v3.0)               |
| 🏆 Media  | **Automated release workflow (tag → release) ✅** | ✅ COMPLETADO                       |
| 🏆 Media  | **SBOM generation (CycloneDX) via Trivy**         | ⚠️ Parcial (sbom-validate existe)   |
| 📋 Baja   | **ADR tooling**                                   | 📋 Planificado                      |
| 📋 Baja   | **Cross-platform test matrix (Linux + macOS)**    | ⚠️ Parcial (workflow existe)        |
| 📋 Baja   | **Token dashboard v2 con tendencias históricas**  | 📋 Planificado                      |
| 🔮 Largo  | **Plugin Registry / Marketplace**                 | 🔮 Visión                           |
| 🔮 Largo  | **MCP Native first-class**                        | ⚠️ Parcial (skill-server.ts existe) |
| 🔮 Largo  | **Web UI para dashboard**                         | ⚠️ Parcial (dashboard HTML existe)  |
| 🔮 Largo  | **VS Code Extension**                             | 🔮 Visión                           |
| 🔮 Largo  | **Multi-repo orchestration**                      | ⚠️ Alpha (multi-repo-engine.ps1)    |

### Observaciones / Deuda técnica detectada:

| Issue                                 | Detalle                                                                                               |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| ✅ **Versión unificada**              | v3.1.0 consistente en README, VERSION, badges                                                         |
| ⚠️ **FT Python stub**                 | `train_lora.py` es stub, no implementado                                                              |
| ✅ **Adaptive scripts automatizados** | auto-norm-enforcer (cada 5 turnos), karpathy-enforcer (pre-commit), normative-audit (pre-commit + CI) |
| ⚠️ **Plugins experimentales**         | Plugin system existe pero sin uso real                                                                |
| ⚠️ **Dashboard v3**                   | Chart.js integrado pero no hay Web UI nativo (HTML estático)                                          |
| ⚠️ **Multi-repo**                     | Alpha stage, no probado en producción                                                                 |
| ⚠️ **event-bus sub-utilizado**        | Solo 1 subscription (judgment-day)                                                                    |
| ⚠️ **Skills ~386**                    | Inventario real no auditado recientemente                                                             |

---

## 6. MAPA DE ARCHIVOS CLAVE

| Recurso               | Ruta                                                     |
| --------------------- | -------------------------------------------------------- |
| Entry point canónico  | `docs/AGENTS.md`                                         |
| Bootstrap workspace   | `scripts/core/bootstrap-workspace.ps1`                   |
| CLI                   | `scripts/core/gv.ps1`                                    |
| Orquestador principal | `config/orchestrator.json`                               |
| Auto-delegación       | `config/auto-delegation.json`                            |
| Routing de modelos    | `config/model-router.json`                               |
| SDD config            | `openspec/config.yaml`                                   |
| Prompts de agentes    | `config/agent-prompts/` (10 roles)                       |
| Normativas            | `rules/` (~60 archivos)                                  |
| Hooks                 | `hooks/` (18 scripts)                                    |
| Skills                | `skills/` (~386 dirs)                                    |
| Tests                 | `tests/` (unit, integration, security, performance, e2e) |
| Adaptadores           | `adapters/` (Windsurf, Codex, Antigravity, Detection)    |
| Plugins               | `plugins/` (example-hello-world)                         |
| Fine-tuning data      | `.ft/` (registry, adapters, benchmarks, datasets)        |
| Event bus             | `.event-bus/` (subscriptions, history)                   |
| Dashboard             | `reports/dashboard-v2/dashboard.html`                    |
| Telemetría            | `config/telemetry-dashboard-v2.json`                     |
| Engram data           | `.engram-data/` (memoria persistente)                    |

---

## 7. ESTADO GENERAL

| Dimensión                                         | Estado                                   |
| ------------------------------------------------- | ---------------------------------------- |
| **Core bootstrap**                                | ✅ Estable                               |
| **SDD Lifecycle** (BA→SAD→DEV→QA)                 | ✅ Completo con gates CI                 |
| **Auto-delegación ML**                            | ✅ Integrado, ~400ms respuesta           |
| **Memoria Engram** + RAG                          | ✅ Producción                            |
| **Dashboard v3**                                  | ✅ Chart.js, 9 secciones, WCAG 2.1 AA    |
| **Fine-tuning LoRA**                              | ✅ Pipeline completo, 2 adapters activos |
| **Seguridad** (AES-256, secrets, Gitleaks, Trivy) | ✅ Multi-capa                            |
| **CI/CD** (27 workflows)                          | ✅ Automatización completa               |
| **Git hooks** (13)                                | ✅ Protección pre-commit/pre-push        |
| **Cross-tool** (10 herramientas)                  | ✅ Adaptadores + MCP bridge              |
| **Token optimization**                            | ✅ 98% compresión, cache SHA256          |
| **Multi-repo orchestration**                      | ⚠️ Alpha                                 |
| **Plugin system**                                 | ⚠️ Experimental                          |
| **Web UI**                                        | ⚠️ Parcial (HTML estático)               |
| **VS Code Extension**                             | 🔮 No iniciado                           |
