# GENTLEMAN FOUNDATION — INFORME DE STATUS COMPLETO
**Fecha:** 2026-05-05 (rev. 2 — post sesión de implementación)  
**Versión del stack:** v2.6.5  
**Clasificación:** Resumen técnico ejecutivo + Estado operacional  
**Destinatario:** Gerencia / Equipo técnico  
**Generado por:** `wf version` + revisión manual post-release + `agent-verify` 14/14 PASS

---

## 1. RESUMEN EJECUTIVO

Gentleman Foundation es una **plataforma de orquestación de agentes de IA** local-first, diseñada para sistematizar el ciclo de desarrollo de software con IA como co-piloto inteligente. No es un producto SaaS ni una dependencia de terceros: es infraestructura propia que controla el flujo de trabajo, la gobernanza de calidad, el gasto de tokens y la especialización de agentes.

**Estado actual (v2.6.5 — rev. 2):**

| Dimensión | Estado |
|---|---|
| CI/CD Pipeline | 10 workflows activos, todos con hardening completo |
| Quality Gate | 14/14 checks pasan en agent-verify (0 warnings) |
| Tests automáticos | 12 tests / 0 fallos / 0 warnings |
| Normativas de código | 3 normativas vivas (PS, CI, Testing) |
| Gestión de releases | Automatizada — tag → GitHub Release |
| Seguridad | SECURITY.md + dependabot activo + OWASP scan en CI |
| Skills disponibles | 125 skills bajo demanda |
| Backlog oficial | 7/7 items completados (FF-001 a FF-013) |
| Sync drift | CLEAN — 0 drifts detectados |
| Homologación workspace_local | **PENDIENTE — ver sección 9** |

**Propuesta de valor central:**
- Reducción de re-trabajo mediante routing inteligente de agentes especializados
- Control total del gasto de tokens (presupuesto diario, alertas, bloqueos automáticos)
- Gobernanza de calidad integrada en cada commit (no como paso adicional)
- Portabilidad: funciona con 9 herramientas de IA distintas sin cambiar el flujo de trabajo
- Normativas vivas: las reglas de código se aplican automáticamente en CI

---

## 2. ARQUITECTURA DEL STACK

```
CAPA 4 — INTERFAZ         wf.ps1 (CLI unificado, 44+ comandos)
CAPA 3 — ORQUESTACIÓN     Orchestrator v2.6.5, 7 agentes especializados
CAPA 2 — SKILLS           125 skills cargados bajo demanda
CAPA 1 — INFRAESTRUCTURA  Event bus, token guard, telemetría, git hooks, sesiones
CAPA 0 — CI/CD            10 GitHub Actions workflows con hardening enterprise
```

### 2.1 Componentes principales

| Componente | Archivo / Directorio | Estado |
|---|---|---|
| CLI principal | `scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1` | Operacional — 44+ comandos |
| Orchestrator config | `config/orchestrator.json` v2.6.5 | Operacional |
| Auto-delegación | `config/auto-delegation.json` | Operacional |
| Event bus | `scripts/.../event-bus.ps1` | Operacional — 5 governance gates |
| Token Budget Guard | `scripts/.../TELEMETRY-METRICS/token-budget-guard.ps1` | Operacional |
| Context Dashboard | `scripts/.../TELEMETRY-METRICS/context-dashboard.ps1` | Operacional |
| HTML Dashboard | `scripts/.../TELEMETRY-METRICS/generate-dashboard.ps1` | Operacional |
| Agent Router | `scripts/.../AI-AGENT-MANAGEMENT/agent-router.ps1` | Operacional |
| Dispatch paralelo | `scripts/.../dispatch-agent.ps1` | Operacional — 3 modos |
| Session Manager | `scripts/.../SESSION-MANAGEMENT/` | Operacional |
| SDD Gate | `scripts/hooks/check-sdd-gate.ps1` | Operacional — bloquea sin SDD |
| SDD Metrics | `scripts/.../TELEMETRY-METRICS/sdd-process-metrics.ps1` | Operacional |
| Sync Drift Report | `scripts/utilities/sync-drift-report.ps1` | Operacional — JSON + HTML |
| WF Benchmark | `scripts/utilities/wf-benchmark.ps1` | Operacional — SLO thresholds |
| Git Hooks | `hooks/*.ps1` + `.git/hooks/pre-commit` | Operacional |
| Testing (Pester) | `tests/unit/*.tests.ps1` | Operacional — 0 fallos |
| Skills index | `skills/SKILL_INDEX.md` + 125 skills | Operacional |
| Telemetría distribuida | `config/distributed-tracing-config.json` | Operacional |
| Seguridad / RBAC | `config/access-control.json` + `SECURITY.md` | Operacional |

---

## 3. CAPACIDADES FUNCIONALES

### 3.1 Orquestación de Agentes (Core)

Modelo de 7 agentes especializados con routing automático por keywords, confianza y contexto:

| Agente | Rol | Temperatura | Hallucination Guard | Escalada a |
|---|---|---|---|---|
| **BA** | Business Analyst — Requisitos, BDD | 0.70 | Low | Orchestrator |
| **SAD** | Solution Architect — Diseño, SDD, API | 0.30 | Medium | Orchestrator |
| **DEV** | Developer — Implementación, refactoring | 0.15 | High | QA |
| **QA** | Quality Assurance — Tests, validación | 0.10 | Critical | Orchestrator |
| **OPS** | DevOps — Deploy, CI/CD, infraestructura | 0.10 | Critical | Orchestrator |
| **GOV** | Governance — Compliance, auditoría | 0.10 | Critical | Orchestrator |
| **DOC** | Documentation — READMEs, specs, guías | 0.40 | Low | Orchestrator |

**Flujo de routing:**
```
Input usuario
    └─ pre-process-input.ps1 (MANDATORY)
        ├─ TRIGGER_MATCH_FOUND  → cargar skill + delegar agente
        ├─ PLAN_MODE_REQUIRED   → activar BA exploration
        └─ NO_TRIGGER_MATCH     → continuar con baseline
```

**Routing por confianza (tiered routing):**
- Tier 1 (≥80%): dispatch inmediato sin confirmación
- Tier 2 (60–79%): dispatch mostrando agente+skill al usuario
- Tier 3 (<60%): activar BA antes de ejecutar

### 3.2 CLI Unificado — wf.ps1 (44+ comandos)

**Sesión y flujo:**
```
start-session    Inicia sesión con tracking completo
end-session      Cierra sesión con audit + reporte
day-end-closure  Cierre de día con compresión de contexto
task-brief       Brief de tarea para nuevo chat thread
context-pack     Pack compacto para handoff de contexto
```

**Agentes y skills:**
```
dispatch <AGENTS> <TASK>   Dispatch paralelo/secuencial de agentes
agent <AGENT> <TASK>       Dispatch de agente individual con skill loading
skills                     Lista todos los skills disponibles
```

**Calidad y gobernanza:**
```
review           Code review con múltiples dimensiones
audit            Audit completo de foundation
verify           Autoverificación del workspace (agent-verify.ps1)
judgment-day     QA gate completo antes de merge/release
sdd-gate         Verifica que el SDD esté validado antes de commitear (FF-001)
```

**Métricas y SLOs:**
```
sdd-metrics      SDD process metrics — cycle time, status distribution (FF-002)
sync-drift       Drift report entre foundation y workspace projects (FF-004)
benchmark [cmds] Benchmark de comandos wf contra SLO thresholds (FF-006)
export-metrics   Exporta métricas en CSV/JSON
```

**Versión y stack:**
```
version          Muestra versión actual del stack (FF-version)
platform-info    Información del entorno (OS, PS, herramientas)
stack-dashboard  Dashboard visual del stack activo
```

**Contexto y tokens:**
```
context-dashboard [chars]  Vista unificada de salud de contexto
context-metrics            Métricas de uso de contexto
token-guard                Estado del token budget guard
compact-start              Inicio de compresión de contexto
```

**Eventos:**
```
events list         Lista eventos estándar + suscriptores
events emit         Emite evento (con governance gate activo)
events history      Historial de eventos (últimos 20)
events subscribe    Suscribir handler a evento
```

**Versionado y releases:**
```
checkpoint          Crear checkpoint en git
list-checkpoints    Ver checkpoints disponibles
rollback-checkpoint Revertir a checkpoint
clean-branches      Limpiar branches obsoletas
```

### 3.3 CI/CD Pipeline (10 workflows — enterprise hardened)

Todos los workflows cumplen el estándar CI-HARDENING-STANDARDS.md v1.0:
- `permissions:` mínimos declarados explícitamente
- `concurrency:` group para evitar runs redundantes
- `timeout-minutes:` en cada job
- Acciones pinadas a versión major

| Workflow | Trigger | Función | Timeout |
|---|---|---|---|
| `foundation-quality-gate` | push/PR main/develop | Quality gate principal — 7D | 30 min |
| `workflow-lint` | push/PR any | Valida estructura de workflows | 10 min |
| `script-governance` | push/PR *.ps1 | Governance de scripts PS1 | 25 min |
| `ps-lint` | push/PR *.ps1 | PSScriptAnalyzer — Error=bloquea | 15 min |
| `sdd-gate` | push/PR main | Verifica SDD spec antes de merge | 20 min |
| `owasp-scan` | weekly + push main | OWASP dependency check | 25 min |
| `dependency-backup` | weekly | Backup de dependencias | 20 min |
| `autonomous-validation` | push main | Validación autónoma del stack | 25 min |
| `release` | tag v*.*.* | GitHub Release automático | 30 min |
| `dependabot` | weekly Mon | Actualiza versiones de actions | automático |

**Nota:** el tag `v2.6.5` ya disparó `release.yml` — el GitHub Release se genera automáticamente leyendo `CHANGELOG.md`.

### 3.4 Sistema de Skills (125 disponibles)

Skills cargados bajo demanda, organizados por dominio:

| Dominio | Skills incluidos |
|---|---|
| Frontend | angular-spa-skill, react-19-skill, nextjs-15-skill, tailwind-4-skill, zustand-5-skill |
| Backend | golang-api-skill, django-drf-skill, typescript-skill, zod-4-skill, api-design-skill |
| Mobile | android-kotlin-skill, android-jetpack-compose-skill, flutter-skill, ios-swiftui-patterns-skill, react-native-skill |
| Testing | testing-skill, testing-strategy-skill, playwright-skill, pytest-skill, testing-coverage-skill |
| DevOps | docker-devops-skill, kubernetes-deployment, terraform-infrastructure, git-workflow-skill |
| AI | ai-sdk-5-skill, mcp-skill, cloud-agent-connector-skill |
| DB | database-relational-skill, database-nosql-skill |
| Security | security-skill, security-expert-skill, security-pentester |
| Workflow | sdd-lifecycle, project-orchestrator-skill, release-management-skill, code-review-orchestrator-skill |
| Roles | data-analyst, data-scientist, product-manager, devops-sre, customer-success-manager, legal-compliance-officer |

### 3.5 Normativas de Código (nuevas en v2.6.5)

Tres normativas vivas en `rules/` que se aplican automáticamente en CI:

| Normativa | Archivo | Aplicación |
|---|---|---|
| PowerShell Standards | `rules/POWERSHELL-STANDARDS.md` | PSScriptAnalyzer CI (`ps-lint.yml`) |
| CI Hardening Standards | `rules/CI-HARDENING-STANDARDS.md` | Audit checklist + `agent-verify.ps1` |
| Testing Standards | `rules/TESTING-STANDARDS.md` | Pester CI + cobertura targets |

**Lo que garantizan:**
- **PS-STANDARDS:** headers de archivo, param declarations, manejo de errores, output seguro (no expone secrets en logs), `Join-Path` obligatorio para rutas, funciones `Verb-Noun`, sin `Invoke-Expression`.
- **CI-HARDENING:** permissions mínimas en workflows, concurrency group, timeout-minutes en todos los jobs, acciones pinadas, cron con comentario UTC+GMT-3.
- **TESTING:** pirámide 70/20/10 (unit/integration/E2E), todo script nuevo debe tener test de existencia+parse, coverage targets por criticidad.

### 3.6 Event Bus con Governance

5 governance gates activos en cada `emit`:
1. Verificación de evento en registry (schema validation)
2. Campos requeridos por schema (enforcement)
3. Límite de tamaño de payload (10KB max)
4. Rate limiting por sliding window 60s
5. Bloqueo con registro en historial si falla cualquier check

**10 eventos estándar:**
`dispatch.started`, `dispatch.completed`, `agent.dispatched`, `agent.completed`, `session.started`, `session.ended`, `workflow.checkpoint`, `workflow.publish`, `validation.started`, `validation.completed`

### 3.7 Token Budget Guard

**Fuente canónica:** `config/orchestrator.json#subagent_orchestration.token_budget_guard`

| Parámetro | Valor |
|---|---|
| Presupuesto diario | 30,000 tokens |
| Soft threshold | 70% → WARN, log y continúa |
| Hard threshold | 90% → BLOCK, rechaza dispatch |
| Budget por agente | 750 tokens |
| Overhead coordinación | 125 tokens |
| Estimación unificada | `chars / 4 = tokens` |

### 3.8 SDD Gate (FF-001 — nuevo en v2.6.4)

`check-sdd-gate.ps1` bloquea commits a ramas protegidas si no existe al menos un SDD con status `validated`, `done` o `active`.

- **Hook:** integrado en `pre-commit` y en CI `sdd-gate.yml`
- **Bypass:** solo con override documentado y reason obligatorio
- **Métricas:** `wf sdd-metrics` muestra distribución de estados, cycle time por fase y SLO compliance

### 3.9 Sync Drift Report (FF-004 — nuevo en v2.6.4)

`sync-drift-report.ps1` detecta desincronizaciones entre foundation y proyectos workspace:
- Archivos críticos faltantes en destino
- Referencias rotas entre docs
- Score de drift (0–100)
- Salida: consola + JSON (`-AsJson`) + HTML opcional

### 3.10 WF Benchmark (FF-006 — nuevo en v2.6.4)

`wf-benchmark.ps1` ejecuta comandos wf y mide tiempo vs SLO thresholds:
- `status` SLO: 5s | `health` SLO: 15s | `verify` SLO: 30s
- Salida: tabla con PASS/WARN/FAIL por comando + JSON (`-AsJson`)
- Integrado como `wf benchmark [cmd1,cmd2,...]`

### 3.11 Seguridad (v2.6.5)

| Capa | Mecanismo | Estado |
|---|---|---|
| Vulnerability reporting | `SECURITY.md` — 48h ack SLA, private reporting | Activo |
| Dependency scanning | `dependabot.yml` — weekly GH Actions updates | Activo |
| OWASP scan | `owasp-scan.yml` — weekly + merge a main | Activo |
| Static analysis | PSScriptAnalyzer (ps-lint.yml) — Error=bloquea | Activo |
| Secret detection | No secrets en logs (hook-output-safety) | Activo |
| RBAC | `config/access-control.json` + owner-auth.json | Activo |
| Trivy (IaC) | `scripts/.../security-scan.ps1` | Activo |

### 3.12 Dashboard HTML de Métricas (actualizado en rev. 2)

Generado por `wf dashboard` → `reports/dashboard.html` (gitignored — generado localmente).

**Secciones del dashboard:**
1. **Overview** — 10 metric cards: Sessions, Dispatches, Tokens, Events, Avg Duration, Efficiency, Context Adoption, Daily Budget, Runtime Requests, Runtime Latency
2. **Costs & Savings** — 15 cards + Cost by Model table + Agent cost allocation table + Daily Cost trend chart
3. **Executive ROI** — 10 cards + Monthly ROI bar chart + 3-Month Cost Trend + Recent Monthly Breakdown table
4. **Stack Metrics** — Token Guard, Context Efficiency, Runtime Telemetry, Governance Signals panels
5. **Metrics Explorer** — 7 raw data tables (todos los CSVs fuente)
6. **Events** — historial de eventos con status (emitted/blocked)

**Funcionalidades nuevas (rev. 2):**
- **Export PDF:** botón `📄 PDF` → `window.print()` con `@media print` CSS optimizado; funciona 100% offline
- **Export PNG:** botón `📷 PNG` → captura la sección activa vía `html2canvas` CDN como archivo PNG descargable; degrada con mensaje si no hay conexión
- **Alert thresholds configurables:** todos los umbrales de alertas y parámetros del cost model se leen de `config/metrics-config.json` (`alert_thresholds` + `cost_model`); valores hardcoded solo como fallback

**Fuentes de datos:**
- `config/metrics-config.json` — thresholds y cost model
- `config/orchestrator.json` — versión y daily budget
- `.event-bus/history.json` — historial de eventos
- `docs/management/telemetry-master.csv` — telemetría maestra de sesiones
- `docs/sessions/metrics/*.csv` — token-guard, context-usage, agent-usage, judgment-history, text-simplification
- `.runtime/telemetry/cloud-agent-telemetry.csv` — telemetría real de providers

**Cómo generarlo:** `wf dashboard` o directamente `.\ scripts\utilities\TELEMETRY-METRICS\generate-dashboard.ps1`

### 3.13 Colector de Telemetría de Providers (nuevo en rev. 2)

`scripts/utilities/AI-AGENT-MANAGEMENT/collect-provider-telemetry.ps1` — reemplaza las filas de ejemplo en `cloud-agent-telemetry.csv` con datos reales:

| Estado | Acción |
|---|---|
| `enabled: true` + API key presente | Llamada real de test → registra latencia/tokens/status auténticos |
| `enabled: true` + API key faltante | Registra `MISSING_KEY` (sin llamada a la API) |
| `enabled: false` | Registra `DISABLED` (omitible con `-SkipDisabled`) |
| Endpoint inválido / inseguro | Registra `INVALID_ENDPOINT` / `INSECURE_ENDPOINT` |

**Uso:**
```powershell
# Probar sin escribir (ver qué haría)
pwsh -File collect-provider-telemetry.ps1 -DryRun
# Ejecutar real (requiere API keys configuradas en .env.local)
pwsh -File collect-provider-telemetry.ps1
# Ignorar providers deshabilitados
pwsh -File collect-provider-telemetry.ps1 -SkipDisabled
```

**Configuración de providers:** `config/cloud-agents.json` (template) + `config/cloud-agents.local.json` (secrets locales, gitignored).

---

## 4. CONFIGURACIÓN ACTUAL (PARÁMETROS CLAVE)

### 4.1 Context Window

```
maxContextWindow:    128,000 tokens
safetyMargin:         15,000 tokens
effectiveWindow:     113,000 tokens (usable)
compressionRatio:        0.85
autoCompactThreshold:  12,000 tokens → compact automático
```

### 4.2 Thresholds de alerta de prompt

```
YELLOW: 1,100 chars → WARN + compresión
RED:    1,600 chars → AUTO_COMPACT
```

### 4.3 Response Policy

```
communication_language:   es
baseline_profile:         ultra (compresión máxima)
compression:              ultra (todos los presets)
allow_overrides:          governed override únicamente
```

### 4.4 Token Autopilot

```
profile:          hard
trigger:          HARD_LIMIT
auto_apply_on:    context-pack, compact-start, audit, publish, end-session, dispatch
```

---

## 5. MÉTRICAS DE CALIDAD

### 5.1 Agent-Verify (14 checks)

```
required-files         PASS   VERSION, SECURITY.md, CLAUDE.md, AI-NORMATIVES.md
required-scripts       PASS   pre-process-input, validate-configs, install-hooks
quality-gate-workflows PASS   script-governance, workflow-lint, foundation-quality-gate, ps-lint, sdd-gate, owasp-scan
workflow-hardening     PASS   todos los workflows tienen permissions + timeout + concurrency
hooks-installed        PASS   pre-commit hook instalado y activo
tests-passing          PASS   0 fallos en suite Pester
scripts-parse          PASS   0 errores de parseo en scripts/
config-valid           PASS   auto-delegation.json, orchestrator.json, quality-gates.json válidos
skills-count           PASS   125 skills detectados
event-registry         PASS   10 eventos estándar registrados
session-tracking       PASS   session tracking operacional
telemetry-config       PASS   distributed-tracing-config.json válido
security-policy        PASS   security-policy.json + access-control.json presentes
sdd-docs               PASS   al menos 1 SDD validado
```

### 5.2 Tests Automáticos

| Suite | Archivo | Tests | Status |
|---|---|---|---|
| Foundation Core | `tests/unit/foundation-core.tests.ps1` | 12 | PASS |
| v2.6.4 Scripts | `tests/unit/v264-scripts.tests.ps1` | 14 | PASS |
| Integration | `tests/integration/` | disponible | — |

---

## 6. HISTORIAL DE VERSIONES RECIENTES

| Versión | Fecha | Highlights |
|---|---|---|
| v2.6.5 rev.2 | 2026-05-05 | **Rev. 2:** real provider telemetry, dashboard PDF/PNG export, alert thresholds en config |
| v2.6.5 | 2026-05-05 | PSScriptAnalyzer CI, release automático, normativas PS+CI+Testing, wf version, dependabot, SECURITY.md |
| v2.6.4 | 2026-05-05 | SDD Gate (FF-001), SDD Metrics (FF-002), Sync Drift (FF-004), WF Benchmark (FF-006) |
| v2.6.3 | anterior | Context Dashboard, Event Bus Phase 3, Override Governance |
| v2.6.2 | anterior | Dispatch paralelo, Event Bus Phase 2 |
| v2.6.1 | anterior | Token Budget Guard unificado, telemetría distribuida |

---

## 7. BACKLOG OFICIAL (docs/backlog/items.json)

Todos los 7 ítems del backlog oficial están en estado `done`:

| ID | Título | Estado |
|---|---|---|
| FF-001 | SDD CI Hardening | ✅ done |
| FF-002 | Process Metrics | ✅ done |
| FF-003 | Check Noise Reduction | ✅ done |
| FF-004 | Sync Drift Prevention | ✅ done |
| FF-005 | PR Template Quality | ✅ done |
| FF-006 | Local Workflow Performance | ✅ done |
| FF-013 | Runtime Router Gating | ✅ done |

**Estado del backlog:** 7/7 completados — backlog limpio.

---

## 8. PRÓXIMOS PASOS (MADUREZ SUGERIDA)

El backlog oficial está vacío. Las siguientes áreas son sugerencias de madurez para roadmap futuro:

| # | Área | Esfuerzo | Valor | Estado |
|---|---|---|---|---|
| 1 | ~~Dashboard ejecutivo con datos reales~~ | — | — | ✅ **Completado rev. 2** |
| 2 | **Alertas automáticas** — Slack/Teams webhook cuando SLO de benchmark excede threshold | M | Alto | ⏳ Pendiente |
| 3 | **Cobertura de tests integración** — expandir `tests/integration/` para flujos críticos de routing | M | Medio | ⏳ Pendiente |
| 4 | **Portabilidad Linux/macOS** — abstraer rutas Windows con `Join-Path` universal en hooks/scripts | S | Medio | ⏳ Parcial (autonomous-validation corregido) |
| 5 | **Report mensual automatizado** — `wf export-metrics` + `generate-management-report.ps1` programado | S | Medio | ⏳ Pendiente |
| 6 | **Homologación workspace_local** — propagar foundation a proyectos bajo `C:\Workspace_local\` | L | Alto | ⏳ **Ver sección 9** |

---

## 9. ANÁLISIS DE HOMOLOGACIÓN — workspace_local

### 9.1 ¿Qué es la homologación workspace_local?

Propagar los assets, skills, scripts y configuraciones de `gentleman-foundation` a todos los proyectos bajo `C:\Workspace_local\` para que operen con el mismo estándar de gobernanza, calidad y observabilidad.

### 9.2 Estado actual — Prerequisites

| Prerequisite | Estado | Detalle |
|---|---|---|
| agent-verify 14/14 PASS | ✅ Cumplido | 0 errors, 0 warnings, working tree clean |
| Backlog limpio | ✅ Cumplido | 7/7 ítems completados |
| Sync drift CLEAN | ✅ Cumplido | 0 drifts detectados por sync-drift-report |
| CI/CD pipeline verde | ✅ Cumplido | HEAD `6aa883a` — todos los workflows passing |
| Telemetría real | ✅ Cumplido | collect-provider-telemetry.ps1 operacional (rev. 2) |
| Dashboard documentado | ✅ Cumplido | PDF/PNG export + thresholds configurables (rev. 2) |
| foundation-sync.json presente | ✅ Cumplido | `config/foundation-sync.json` con role: "source" |
| wf.ps1 accesible | ⚠️ Parcial | 3 copias detectadas — path canónico: `scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1`; wf-benchmark usa ruta incorrecta |
| Tests de integración | ⚠️ Parcial | `tests/integration/` disponible pero vacío; solo unit tests activos |
| Portabilidad Windows/Linux | ⚠️ Parcial | Hooks y `wf-benchmark.ps1` con rutas Windows; autonomous-validation corregido |

### 9.3 Bloqueadores antes de homologar

Son ítems pequeños pero deben resolverse para que la homologación no propague deuda técnica:

1. **wf-benchmark.ps1 no encuentra wf.ps1** — `SKIP` en todas las mediciones porque busca en path incorrecto. Antes de homologar, el benchmark debe poder ejecutarse limpio; de lo contrario los proyectos destino no tendrán SLO baseline.

2. **foundation-sync.json desactualizado** — El JSON declara `foundationVersion: "2.1.0"` y lista paths de scripts con estructura anterior (`scripts/utilities/invoke-cloud-agent.ps1` en vez de `scripts/utilities/AI-AGENT-MANAGEMENT/`). Propagar esta versión rompería la sincronización en proyectos destino.

3. **Tests de integración vacíos** — `tests/integration/` existe pero no tiene specs. Homologar sin cobertura de integración implica que los proyectos destino no tendrán gate de regresión para los flujos de routing críticos.

### 9.4 Recomendación de secuencia

```
1. Fix wf-benchmark path  (rápido — 1 línea en wf-benchmark.ps1)
2. Actualizar foundation-sync.json  (catálogo de assets + versión actual 2.6.5)
3. Agregar ≥1 test de integración  (routing crítico: pre-process-input → skill load)
4. agent-verify 14/14 + benchmark PASS → verde completo
5. Ejecutar homologación  (sync-drift + distribute assets a workspace_local)
```

**Estimación:** ítems 1–3 son sesión corta (1–2h). Item 5 depende de cuántos proyectos destino existen en `C:\Workspace_local\`.

---

## 10. CÓMO USAR EL STACK (QUICK START)

```powershell
# 1. Verificar estado del stack
wf verify

# 2. Ver versión y skills disponibles
wf version

# 3. Iniciar sesión de trabajo
wf start-session

# 4. Ejecutar quality gate antes de release
wf judgment-day

# 5. Ver dashboard de métricas
wf dashboard
# → abre reports/dashboard.html en el browser

# 6. Benchmark del stack
wf benchmark status,health,verify

# 7. Sincronizar foundation con proyectos workspace
wf sync-drift

# 8. Commit con validación automática
git add . && git commit -m "feat: ..."
# → pre-commit hook valida automáticamente
```

---

*Gentleman Foundation v2.6.5 rev.2 — Local-First AI Orchestration Platform*  
*Generado: 2026-05-05 | Rev. 2: 2026-05-05 | Repo: https://github.com/EmmanuelOrtiz87/gentleman-foundation*  
*agent-verify: 14/14 PASS | sync-drift: CLEAN | backlog: 7/7 done*
