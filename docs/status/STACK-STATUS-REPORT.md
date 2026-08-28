# Gentle-Vanguard — Stack Status Report

**Versión actual**: v3.8.2 **Última revisión canónica**: 2026-08-24 **Stack**: AI orchestration
layer multi-herramienta | 436+ TS scripts | 263 skills | 23 CI/CD workflows

---

## 1. ARQUITECTURA (5 Capas)

```
Layer 5: AGENTES  — 21 agents (Orchestrator + 20 sub-agentes: BA, SAD, DEV, QA, OPS, GOV, DOC, etc.)
Layer 4: COMANDOS — src/cli/gv.ts, src/pre-process-input.ts, src/core/detect-tool.ts | <!-- REF-OBSOLETA: pre-process-input.ps1 y detect-tool.ps1 eliminados; migrados a src/*.ts -->
Layer 3: MCP      — scripts/mcp/skill-server.ts (MCP protocol), src/mcp/mcp-bridge.ts | <!-- REF-OBSOLETA: mcp-bridge.ps1 eliminado; migrado a src/mcp/mcp-bridge.ts -->
Layer 2: SKILLS   — 263 skills (175 en skills/ + 88 en .opencode/skills)
Layer 1: MEMORIA  — Engram persistent memory (tools/engram.exe v1.15.10)
```

**Principio**: 100% agnóstico — funciona con OpenCode, Claude Code, Cline, Cursor, Windsurf, Codex,
VS Code, Copilot, Antigravity.

---

## 2. COMPONENTES DEL STACK

### 2.1 Core / Bootstrap

| Componente          | Archivo(s)                 | Estado    | Automatización             |
| ------------------- | -------------------------- | --------- | -------------------------- |
| Bootstrap workspace | `src/bootstrap.ts`         | ✅ Activo | Manual (setup inicial)     |
| CLI principal       | `src/cli/gv.ts`            | ✅ Activo | Manual                     |
| Tool detection      | `src/core/detect-tool.ts`  | ✅ Activo | Automático (cada turno)    |
| Pre-process hook    | `src/pre-process-input.ts` | ✅ Activo | Automático (cada turno)    |
| Session manager     | `src/session-manager.ts`   | ✅ Activo | Automático (start/end)     |
| Hashline integrity  | `src/hashline.ts`          | ✅ Activo | Automático (snapshot hook) |

### 2.2 Memoria Persistente (Engram)

| Componente          | Archivo(s)                                                                                                                                                                          | Estado    | Automatización                                    |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ------------------------------------------------- |
| Engram CLI          | `tools/engram.exe` v1.15.10                                                                                                                                                         | ✅ Activo | Automático (mem_save/mem_search en cada sesión)   |
| Engram RAG          | `src/engram-rag-reindex.ts` <!-- REF-OBSOLETA: scripts/utilities/ENGRAM-RAG/ eliminado; candidato: src/engram-rag-reindex.ts -->                                                    | ✅ Activo | Manual (query) / Automático (reindex en pipeline) |
| Engram orchestrator | `src/engram-session-bridge.ts` <!-- REF-OBSOLETA: scripts/utilities/ENGRAM/engram-orchestrator.ps1 eliminado; candidato: src/engram-session-bridge.ts / src/engram-auto-sync.ts --> | ✅ Activo | Automático (sesión)                               |

<!-- REF-OBSOLETA: scripts/utilities/ENGRAM/engram-orchestrator.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Vector index | TF-IDF 1,289 docs × 7,317 términos | ✅ Activo | Incremental rebuild |

### 2.3 ML / Auto-Delegación

| Componente       | Archivo(s)                                                                                                                                        | Estado    | Automatización            |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ------------------------- |
| ML Router        | `src/ml/ml-router.ts`                                                                                                                              | ✅ Activo | Automático (pre-process)  |
| Skill embedder   | `src/skills/skill-embedder.ts`                                                                                                                    | ✅ Activo | Automático (reindex)      |
| Context analyzer | `scripts/utilities/AUTO-DELEGATION/context-analyzer.ps1` <!-- REF-OBSOLETA: eliminado en migración PS1→TS; sin equivalente TS directo en src/ --> | ✅ Activo | Automático (sesión start) |

<!-- REF-OBSOLETA: scripts/utilities/AUTO-DELEGATION/context-analyzer.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Skill recommender | `src/skills/skill-recommender.ts` | ✅ Activo | Automático (sesión start) | |
Routing tiers | ≥80% directo / ≥60% confirmar / <60% → BA explore | ✅ Activo | Automático |

### 2.4 Fine-Tuning (LoRA)

| Componente  | Archivo(s)                                                                                                                | Estado    | Automatización         |
| ----------- | ------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------------- |
| FT pipeline | `src/fine-tuning/ft-pipeline.ts` <!-- REF-OBSOLETA: src/fine-tuning/ no existe (solo protected FINE-TUNING/*.ps1.enc) --> | ✅ Activo | Automático (CI weekly) |

<!-- REF-OBSOLETA: src/fine-tuning/ft-pipeline.ts no existe (ruta migrada o eliminada) -->

| FT trainer | `src/fine-tuning/ft-trainer.ts` <!-- REF-OBSOLETA: src/fine-tuning/ no existe --> |
✅ Activo | Manual / CI |
<!-- REF-OBSOLETA: src/fine-tuning/ft-trainer.ts no existe (ruta migrada o eliminada) -->

| FT evaluator | `src/fine-tuning/ft-evaluator.ts` <!-- REF-OBSOLETA: src/fine-tuning/ no existe -->
| ✅ Activo | Manual / CI |
<!-- REF-OBSOLETA: src/fine-tuning/ft-evaluator.ts no existe (ruta migrada o eliminada) -->

| FT threshold detector | `src/fine-tuning/ft-threshold-detect.ts`
<!-- REF-OBSOLETA: src/fine-tuning/ no existe --> | ✅ Activo | Automático (CI) |
<!-- REF-OBSOLETA: src/fine-tuning/ft-threshold-detect.ts no existe (ruta migrada o eliminada) -->

| FT auto-prune | `src/fine-tuning/ft-auto-prune.ts`
<!-- REF-OBSOLETA: src/fine-tuning/ no existe --> | ✅ Activo | Automático (CI) |
<!-- REF-OBSOLETA: src/fine-tuning/ft-auto-prune.ts no existe (ruta migrada o eliminada) -->

| FT registry | `.ft/registry.json` | ✅ Activo | Automático | | Adapters activos | `.ft/adapters/`
| ⚠️ No implementado | Solo data-collector disponible | | Python trainer |
`scripts/utilities/FINE-TUNING/python/train_lora.py` | ⚠️ Presente | Manual (stub) |

### 2.5 Dashboard / Métricas

| Componente                 | Archivo(s)                                                                                                                        | Estado    | Automatización        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | --------- | --------------------- |
| Dashboard canónico (React) | `apps/web-dashboard/`                                                                                                             | ✅ Activo | CI/CD genera artifact |
| Metrics collector          | `src/metrics-collector.ts`                                                                                                        | ✅ Activo | Automático (sesión)   |
| Dashboard render           | `src/dashboard-start.ts` <!-- REF-OBSOLETA: scripts/metrics/dashboard-render.ps1 eliminado; candidato: src/dashboard-start.ts --> | ✅ Activo | Manual / CI           |

<!-- REF-OBSOLETA: scripts/metrics/dashboard-render.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Dashboard health | `src/dashboard-health-checker.ts` | ✅ Activo | CI | | Live feed | WebSocket de
`apps/web-dashboard/` | ✅ Activo | Automático |
<!-- REF-OBSOLETA: scripts/metrics/live-feed.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Metrics server | `apps/web-dashboard/server/websocket-server.ts`
<!-- REF-OBSOLETA: scripts/metrics/metrics-server.ps1 eliminado --> | ✅ Activo | Manual (HTTP

server) |
<!-- REF-OBSOLETA: scripts/metrics/metrics-server.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Telemetry writer | `scripts/metrics/telemetry-writer.ps1`
<!-- REF-OBSOLETA: eliminado en migración PS1→TS --> | ✅ Activo | Automático |
<!-- REF-OBSOLETA: scripts/metrics/telemetry-writer.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Weekly metrics | `src/core/operational-metrics-tracker.ts`
<!-- REF-OBSOLETA: scripts/monitoring/weekly-metrics.ps1 eliminado --> | ✅ Activo | Manual / CI |
<!-- REF-OBSOLETA: scripts/monitoring/weekly-metrics.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Executive dashboard | `scripts/monitoring/executive-dashboard.ps1`
<!-- REF-OBSOLETA: eliminado (cubierto por dashboard v3) --> | ✅ Activo | Manual |
<!-- REF-OBSOLETA: scripts/monitoring/executive-dashboard.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Token monitor | `src/tokens/token-usage-reader.ts`
<!-- REF-OBSOLETA: scripts/utilities/TOKEN/ eliminado; equivalentes TS: src/token-*.ts --> | ✅

Activo | Automático (cada turno) |

### 2.6 Seguridad

| Componente      | Archivo(s)                                                                                                                                | Estado    | Automatización |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------- |
| Secrets manager | `scripts/security/secrets-manager.ps1` <!-- REF-OBSOLETA: eliminado; ver rules/SECRETS-MANAGEMENT.md y config/secrets-governance.json --> | ✅ Activo | Manual         |

<!-- REF-OBSOLETA: scripts/security/secrets-manager.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Encryption (AES-256) | `scripts/security/encryption-manager.ps1`
<!-- REF-OBSOLETA: eliminado en migración PS1→TS --> | ✅ Activo | Manual |
<!-- REF-OBSOLETA: scripts/security/encryption-manager.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Input validator | `scripts/security/input-validator.ps1`
<!-- REF-OBSOLETA: eliminado; validación en src/pre-process-input.ts --> | ✅ Activo | Automático

(pre-commit) |
<!-- REF-OBSOLETA: scripts/security/input-validator.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Security logger | `scripts/security/security-logger.ps1`
<!-- REF-OBSOLETA: eliminado en migración PS1→TS --> | ✅ Activo | Automático |
<!-- REF-OBSOLETA: scripts/security/security-logger.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Security orchestrator | `src/security/security-orchestrator.ts` | ✅ Activo | Automático
(pre-push) | | Privacy sanitizer | `scripts/security/privacy-sanitizer.ps1`
<!-- REF-OBSOLETA: eliminado; ver src/security/privacy-gateway.ts --> | ✅ Activo | Automático

(pre-commit) |
<!-- REF-OBSOLETA: scripts/security/privacy-sanitizer.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Gitleaks | Lefthook + CI | ✅ Activo | Automático (pre-commit + push) | | Trivy (deps) | CI weekly
| ✅ Activo | CI automático | | SBOM validation | `src/generate-sbom.ts`
<!-- REF-OBSOLETA: scripts/security/sbom-validate.ps1 eliminado; candidato: src/generate-sbom.ts -->

| ✅ Activo | CI |
<!-- REF-OBSOLETA: scripts/security/sbom-validate.ps1 no tiene equivalente TS (migración PS1→TS) -->

| SLSA provenance | `src/slsa-provenance.ts` + `src/rdd/rdd-core.ts` (auto en release) | ✅ Activo |
Automático (release gate RDD) | | SLSA signing (L2/L3) | `src/slsa-signer.ts` (DSSE + Ed25519) +
`provenance/public-key.pem` | ✅ Activo | Automático (release gate RDD) | | Container/artifact scan
| `src/container-scan.ts` (Syft+Grype+Trivy, sin Docker) | ✅ Activo | Manual
(`npm run container:scan`) | | SIEM audit bridge | `src/infrastructure/siem-audit-bridge.ts` | ✅
Activo | Manual |

### 2.7 CI/CD (23 workflows)

| Workflow                                                                                                           | Trigger                                    | Estado     |
| ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ | ---------- |
| `test-suite.yml` <!-- REF-OBSOLETA: no existe; CI consolidado en .github/workflows/ci.yml -->                      | Push/PR develop/main                       | ✅ Activo  |
| `security-scan.yml` <!-- REF-OBSOLETA: no existe; seguridad en .github/workflows/security.yml -->                  | Push/PR + cron weekly                      | ✅ Activo  |
| `release.yml`                                                                                                      | Push tag v*.*.\*                           | ✅ Activo  |
| `dashboard-ci.yml` <!-- REF-OBSOLETA: no existe; ver apps/web-dashboard build en ci.yml -->                        | Push metrics + cron daily                  | ✅ Activo  |
| `maintenance-scheduled.yml` <!-- REF-OBSOLETA: no existe; mantenimiento en .github/workflows/scheduled.yml -->     | Cron weekly Sun                            | ✅ Activo  |
| `cross-platform-tests.yml` <!-- REF-OBSOLETA: no existe -->                                                        | Push/PR + cron daily                       | ✅ Activo  |
| `quality-gate.yml` <!-- REF-OBSOLETA: no existe; gates en reusable-governance.yml -->                              | Push/PR scripts/hooks/config               | ✅ Activo  |
| `sdd-gate.yml` <!-- REF-OBSOLETA: no existe; ver src/check-sdd-gate.ts y reusable-governance.yml -->               | PR a main/develop                          | ✅ Activo  |
| `script-governance.yml` <!-- REF-OBSOLETA: no existe -->                                                           | Push/PR scripts/docs/config                | ✅ Activo  |
| `sync-public.yml`                                                                                                  | Push develop/main                          | ✅ Activo  |
| `monthly-management-report.yml` <!-- REF-OBSOLETA: no existe; report en scheduled.yml -->                          | Cron monthly 1st                           | ✅ Activo  |
| `dashboard-auto-refresh.yml`                                                                                       | Cron daily                                 | ✅ Activo  |
| `autonomous-validation.yml` <!-- REF-OBSOLETA: no existe; ver ci.yml -->                                           | Push/PR + cron weekly                      | ✅ Activo  |
| `normative-enforcement.yml` <!-- REF-OBSOLETA: no existe; ver experimental-guard.yml / reusable-governance.yml --> | Push/PR scripts,rules,config + cron weekly | ✅ Activo  |
| Otros 14 (lint, format, audit, stale, etc.)                                                                        | Varios                                     | ✅ Activos |

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

| Componente         | Archivo(s)                                                                                                                                | Estado    | Automatización             |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------------------- |
| Auto-norm learner  | `src/auto-norm-learner.ts`                                                                                                                | ⚠️ Activo | Manual (bajo demanda)      |
| Auto-norm enforcer | `src/auto-norm-enforcer.ts`                                                                                                               | ✅ Activo | Automático (cada 5 turnos) |
| Failure learning   | `src/ml/learning-engine.ts` <!-- REF-OBSOLETA: scripts/adaptive/failure-learning-system.ps1 eliminado; candidato: src/ml/learning-engine.ts --> | ⚠️ Activo | Manual                     |

<!-- REF-OBSOLETA: scripts/adaptive/failure-learning-system.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Cache manager | `src/response-cache.ts`
<!-- REF-OBSOLETA: scripts/adaptive/cache-manager.ps1 eliminado; candidato: src/response-cache.ts -->

| ✅ Activo | Automático (sesión) |
<!-- REF-OBSOLETA: scripts/adaptive/cache-manager.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Auto-doc drift detector | `scripts/adaptive/auto-doc-drift-detector.ps1`
<!-- REF-OBSOLETA: eliminado en migración PS1→TS --> | ⚠️ Activo | Manual |
<!-- REF-OBSOLETA: scripts/adaptive/auto-doc-drift-detector.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Agent message bus | `src/agent-message-bus.ts` | ⚠️ Activo | Manual | | Auto-backup |
`src/backup-engram.ts`
<!-- REF-OBSOLETA: scripts/adaptive/auto-backup-orchestrator.ps1 eliminado; candidato: src/backup-engram.ts -->

| ✅ Activo | Automático (scheduled) |
<!-- REF-OBSOLETA: scripts/adaptive/auto-backup-orchestrator.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Judgment Day bridge | `src/correction-rules-engine.ts`
<!-- REF-OBSOLETA: scripts/adaptive/judgment-day-bridge.ps1 eliminado; candidato: src/correction-rules-engine.ts -->

| ⚠️ Activo | Event-driven |
<!-- REF-OBSOLETA: scripts/adaptive/judgment-day-bridge.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Karpathy enforcer | `src/karpathy-enforcer.ts` | ✅ Activo | Automático (pre-commit) | | Normative
audit pipeline | `src/infrastructure/normative-audit-pipeline.ts` | ✅ Activo | Automático
(pre-commit + CI) | | Event bus | `.event-bus/` (1 sub: judgment-day) | ✅ Activo | Event-driven |

### 2.10 Prompts / Contexto

| Componente                 | Archivo(s)                                                                                                                                            | Estado    | Automatización          |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------------------- |
| System prompt optimization | `config/system-prompt-optimization.json` <!-- REF-OBSOLETA: scripts/utilities/PROMPT/ eliminado; configs JSON en config/ -->                          | ✅ Activo | Automático (pre-sesión) |
| A/B testing prompts        | `src/ab-testing-framework.ts` <!-- REF-OBSOLETA: scripts/utilities/PROMPT/prompt-ab-testing.ps1 eliminado; candidato: src/ab-testing-framework.ts --> | ✅ Activo | Manual                  |

<!-- REF-OBSOLETA: scripts/utilities/PROMPT/prompt-ab-testing.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Prompt cache | `src/response-cache.ts`
<!-- REF-OBSOLETA: scripts/utilities/PROMPT/prompt-cache.ps1 eliminado; candidato: src/response-cache.ts -->

| ✅ Activo | Automático |
<!-- REF-OBSOLETA: scripts/utilities/PROMPT/prompt-cache.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Prompt versioning | `scripts/utilities/PROMPT/prompt-versioning.ps1`
<!-- REF-OBSOLETA: eliminado en migración PS1→TS --> | ✅ Activo | Automático |
<!-- REF-OBSOLETA: scripts/utilities/PROMPT/prompt-versioning.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Semantic compression | `config/system-prompt-optimization.json` | ✅ Activo | Automático (98%
reducción) | | Context budget audit | `scripts/optimization/context-budget-audit.ps1` | ⚠️ Activo |
Manual |
<!-- REF-OBSOLETA: scripts/optimization/context-budget-audit.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Token budget guard | `src/tokens/token-budget-guard.ts` | ✅ Activo | Automático (cada turno) |

### 2.11 Skills / Plugins

| Componente                    | Estado          | Automatización      |
| ----------------------------- | --------------- | ------------------- |
| Skill registry (263 skills)   | ✅ Activo       | Automático (sync)   |
| Skill factory                 | ✅ Activo       | Manual              |
| Skill auto-patch              | ✅ Activo       | Automático          |
| Skill nudge                   | ✅ Activo       | Automático (sesión) |
| Usage tracker                 | ✅ Activo       | Automático          |
| Plugin architecture (example) | ⚠️ Experimental | Manual              |
| Plugin loader                 | ✅ Activo       | Manual              |

### 2.12 Monitoreo / SRE

| Componente                | Estado    | Automatización                   |
| ------------------------- | --------- | -------------------------------- |
| Maintenance watchtower    | ✅ Activo | CI weekly (domingo)              |
| Health check              | ✅ Activo | CI / Manual                      |
| Continuous status monitor | ✅ Activo | Automático                       |
| Error budget enforcement  | ✅ Activo | CI                               |
| Cross-workspace validator | ✅ Activo | CI                               |
| Performance baselines     | ✅ Activo | CI                               |
| Resilience/Chaos          | ✅ Activo | Manual (`npm run chaos:run-all`) |

---

## 3. RESUMEN: AUTOMÁTICO vs MANUAL

### ✅ Automático (se ejecuta sin intervención)

- **Cada turno**: pre-process-input, token notification, ML routing, context optimization
- **Cada sesión**: session start/end, engram context, startup summary, skill recommendation
- **Git hooks**: 13 hooks en pre-commit/pre-push/commit-msg/post-commit
- **CI/CD**: 23 workflows (push, PR, cron diario/semanal/mensual)
- **Mantenimiento**: Watchtower (domingo), FT pipeline (semanal), auto-backup
- **Memoria**: Engram save/search/context en cada operación
- **Seguridad**: Gitleaks, Trivy, security orchestrator en hooks y CI, SBOM + SLSA provenance en
  release

### 🔧 Manual (requiere invocación)

- **Fine-tuning trainer**: ejecutar train_lora.py o pipeline FINE-TUNING manualmente (o vía CI)
  <!-- REF-OBSOLETA: ft-trainer.ps1 eliminado; solo scripts/utilities/FINE-TUNING/python/train_lora.py -->
- **Dashboard render**: generar dashboard HTML manualmente (o vía CI)
- **Auto-norm learner**: bajo demanda
- **Auto-doc drift detector**: bajo demanda
- **Profile import/export**: manual
- **RAG queries**: vía engram-rag-query.ps1
  <!-- REF-OBSOLETA: engram-rag-query.ps1 no existe; candidato: src/engram-rag-reindex.ts -->
- **Release**: push tag v*.*.\*
- **Multi-repo orchestration**: alpha, manual
- **Plugin usage**: manual (experimental)

---

## 4. ¿CÓMO FUNCIONA? FLUJO TÍPICO

### Inicio de sesión (automático):

```
Usuario escribe mensaje
  → src/pre-process-input.ts (cache SHA256, token notif, tool detection)
  → src/session-start-optimized.ts (autostart pipeline)
  → ML router analiza input → recomienda skill
  → Engram context load (memorias previas)
  → Context optimization (compresión, tiers)
  → Ejecución del mensaje con contexto optimizado
```

### Desarrollo de feature (SDD Lifecycle):

```
Requerimiento → BA/EXPLORE (análisis) → SAD (diseño) → DEV (impl) → QA (verificación)
  Cada fase con gate de validación automático
  PR bloqueado si falta SDD validado (sdd-gate.yml) <!-- REF-OBSOLETA: workflow sdd-gate.yml no existe; gate implementado en src/check-sdd-gate.ts -->
```

### CI/CD semanal (domingo 6am):

```
Maintenance Watchtower:
  1. Health check (95-96/96 checks; el resultado puede variar por checks transitorios)
  2. Rebuild automático de índices stale
  3. Reporte JSON
  4. Fine-tuning pipeline: collect → build → threshold → auto-prune
```

---

## 5. ¿QUÉ FALTA / SIGUIENTES PASOS?

### Del ROADMAP oficial (v3.8.0 → v3.x+):

| Prioridad   | Item                                                       | Estado actual                                                                                                                             |
| ----------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| ✅ Completa | **Secretlint pre-commit**                                  | ✅ Integrado en los hooks                                                                                                                 |
| ✅ Completa | **Coverage reporting (native TS runner + threshold gate)** | ✅ COMPLETADO (`src/coverage-runner.ts`, pre-push gate)                                                                                   |
| 🔜 Alta     | **EditorConfig + Prettier CI check**                       | 📋 Planificado                                                                                                                            |
| 🔜 Alta     | **Branch strategy / Release process docs**                 | 📋 Planificado                                                                                                                            |
| 🏆 Media    | **`gentle-vanguard init` — project scaffolding**           | 📋 Planificado (v3.0)                                                                                                                     |
| 🏆 Media    | **Automated release workflow (tag → release) ✅**          | ✅ COMPLETADO                                                                                                                             |
| 🏆 Media    | **SBOM generation (CycloneDX) via Trivy**                  | ✅ COMPLETADO (`sbom/` + `npm run sbom:generate`)                                                                                         |
| 🏆 Media    | **SLSA provenance (Build L1, native TS)**                  | ✅ COMPLETADO (`src/slsa-provenance.ts` + auto en RDD release)                                                                            |
| 📋 Baja     | **ADR tooling**                                            | ✅ COMPLETADO (`docs/adr/`, 15 ADRs)                                                                                                      |
| 📋 Baja     | **Cross-platform test matrix (Linux + macOS)**             | ⚠️ Parcial (workflow existe)                                                                                                              |
| 📋 Baja     | **Token dashboard v2 con tendencias históricas**           | 📋 Planificado                                                                                                                            |
| 🔮 Largo    | **Plugin Registry / Marketplace**                          | 🔮 Visión                                                                                                                                 |
| 🔮 Largo    | **MCP Native first-class**                                 | ⚠️ Parcial (skill-server.ts existe)                                                                                                       |
| 🔮 Largo    | **Web UI para dashboard**                                  | ⚠️ Parcial (dashboard HTML existe)                                                                                                        |
| 🔮 Largo    | **VS Code Extension**                                      | 🔮 Visión                                                                                                                                 |
| 🔮 Largo    | **Multi-repo orchestration**                               | ⚠️ Alpha (candidato: src/cross-workspace-validator.ts) <!-- REF-OBSOLETA: multi-repo-engine.ps1 eliminado; sin equivalente TS directo --> |

### Observaciones / Deuda técnica detectada:

| Issue                                 | Detalle                                                                                                                |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| ✅ **Versión unificada**              | v3.8.2 es la versión actual canónica; la consistencia de README/VERSION/badges queda pendiente de verificación externa |
| ⚠️ **FT Python stub**                 | `train_lora.py` es stub, no implementado                                                                               |
| ✅ **Adaptive scripts automatizados** | auto-norm-enforcer (cada 5 turnos), karpathy-enforcer (pre-commit), normative-audit (pre-commit + CI)                  |
| ⚠️ **Plugins experimentales**         | Plugin system existe pero sin uso real                                                                                 |
| ⚠️ **Dashboard v3**                   | Chart.js integrado pero no hay Web UI nativo (HTML estático)                                                           |
| ⚠️ **Multi-repo**                     | Alpha stage, no probado en producción                                                                                  |
| ⚠️ **event-bus sub-utilizado**        | Solo 1 subscription (judgment-day)                                                                                     |
| ⚠️ **Skills 263**                     | Inventario real auditado (175 skills/ + 88 .opencode/skills)                                                           |

---

## 6. MAPA DE ARCHIVOS CLAVE

| Recurso              | Ruta                                                                                                                  |
| -------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Entry point canónico | `docs/AGENTS.md`                                                                                                      |
| Bootstrap workspace  | `src/bootstrap.ts` <!-- REF-OBSOLETA: scripts/core/bootstrap-workspace.ps1 eliminado; candidato: src/bootstrap.ts --> |

<!-- REF-OBSOLETA: scripts/core/bootstrap-workspace.ps1 no tiene equivalente TS (migración PS1→TS) -->

| CLI | `src/cli/gv.ts` | | Orquestador principal | `config/orchestrator.json` | | Auto-delegación |
`config/auto-delegation.json` | | Routing de modelos | `config/model-router.json` | | SDD config |
`openspec/config.yaml` | | Prompts de agentes | `config/agent-prompts/` (10 roles) | | Normativas |
`rules/` (~60 archivos) | | Hooks | `src/hooks/`
<!-- REF-OBSOLETA: hooks/ (18 scripts .ps1) eliminado; hooks TS en src/hooks/ --> | | Skills |

`skills/` (175 dirs) + `.opencode/skills/` (88 dirs) | | Tests | `tests/` (unit, integration,
security, performance, e2e) | | Adaptadores | `adapters/` (Windsurf, Codex, Antigravity, Detection)
| | Plugins | `plugins/` (example-hello-world) | | Fine-tuning data | `.ft/` (registry, adapters,
benchmarks, datasets) | | Event bus | `.event-bus/` (subscriptions, history) | | Dashboard |
`apps/web-dashboard/`
<!-- REF-OBSOLETA: reports/dashboard-v2/dashboard.html no existe; dashboard React en apps/web-dashboard/ -->

| | Telemetría | `config/telemetry-dashboard-v2.json` | | Engram data | `.engram-data/` (memoria
persistente) |

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
| **CI/CD** (23 workflows)                          | ✅ Automatización completa               |
| **Git hooks** (13)                                | ✅ Protección pre-commit/pre-push        |
| **Cross-tool** (10 herramientas)                  | ✅ Adaptadores + MCP bridge              |
| **Token optimization**                            | ✅ 98% compresión, cache SHA256          |
| **Multi-repo orchestration**                      | ⚠️ Alpha                                 |
| **Plugin system**                                 | ⚠️ Experimental                          |
| **Web UI**                                        | ⚠️ Parcial (HTML estático)               |
| **VS Code Extension**                             | 🔮 No iniciado                           |
