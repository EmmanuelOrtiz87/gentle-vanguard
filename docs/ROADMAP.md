# Gentle-Vanguard Roadmap

> Version: v2.29.0-alpha | Updated: 2026-06-03
> Source: Post-audit analysis of implemented vs pending capabilities

---

## Legend

| Badge | Meaning |
|-------|---------|
| ✅ DONE | Implemented, integrated, verified |
| 🔄 IN PROGRESS | Active development |
| 📋 PENDING | Planned, not started |
| ❌ BLOCKED | Blocked by external dependency |

---

## v2.26.0 — Current State (All ✅)

All foundational capabilities are implemented and verified:

- SDD Lifecycle (9 phases, executable pipeline)
- 15 specialized agents with model routing
- 399 skills + Skill Factory for scaffolding
- Prompt Optimization Framework (-98% tokens, 5-8x cost reduction)
- 29 quality gates across 7 stages
- 26 GitHub Actions workflows
- Judgment Day (dual adversarial review)
- Engram memory system with backup
- MCP Skill Server (143+ skills via JSON-RPC)
- Dashboard v2 (i18n, tooltips, auto-refresh, export)
- Hashline integrity verification
- Team Mode (parallel multi-agent orchestration)
- CodeGraph (588 nodes, 1197 edges)
- pnpm security (--ignore-scripts policy)
- Session Reference System
- JSON Validator + Tool Config Safety
- Optimization Stack (8 rules, health check)

---

## v2.27.0 — Current State (All ✅)

All four roadmap items implemented, integrated, tested, and verified:

| Item | Status | Effort | Impact | Description |
|------|--------|--------|--------|-------------|
| Auto-delegation router con ML | ✅ DONE | 3 wk | High | TF-IDF n-gram skill embedder + cosine similarity router. 387 skills indexadas, 1,070 términos. Routing tiers: direct (≥80%), confirm (≥60%), clarify (<60%). |
| Engram RAG pipeline con vectores | ✅ DONE | 2 wk | High | TF-IDF vector index de 1,289 docs × 7,317 términos. Queries por similitud coseno. Sin dependencias externas (no Python, no APIs). |
| Dashboard v3 con gráficos interactivos | ✅ DONE | 2 wk | Medium | Chart.js 4.4.7 vía CDN. 6 tipos de gráfico (line/bar/doughnut/radar/gauge). 4 nuevos charts interactivos. Endpoint /api/traceability/agents. |
| MCP bridge para cline/cursor/windsurf | ✅ DONE | 1 wk | Medium | mcp-bridge.ps1 con 4 acciones (status/setup/verify/launch). 3 tools con MCP skills. Opencode usa skills nativas. |

### v2.27.0 Key Results

- **Vector index**: 387 skills (auto-delegation) + 1,289 docs (Engram RAG)
- **Response time**: ~400ms per query (auto-delegation), ~2s per index build (Engram)
- **Dashboard**: 10 Chart.js charts (token trend, cost, sessions, commits, savings, cost comparison, token distribution, agent radar, SLA gauge, trace)
- **MCP Bridge**: 4 tools integrados (cursor, windsurf, cline via MCP; opencode via native skills)

---

## v2.28.0 — Current State (All ✅)

All three roadmap items implemented, integrated, tested, and verified in commit a1adc7d6:

| Item | Status | Effort | Impact | Description |
|------|--------|--------|--------|-------------|
| Skill recommendation engine | ✅ DONE | 2 wk | High | `skill-recommender.ps1` — sugiere skills relevantes al contexto actual basado en auto-delegation router + TF-IDF embeddings |
| Auto-documentación de arquitectura | ✅ DONE | 3 wk | High | `codegraph-diagram.ps1` + `pr-docs-hook.ps1` — genera diagramas Mermaid desde CodeGraph. Documentación automática en cada PR |
| Multi-repo orchestration (alpha) | ✅ DONE | 4 wk | High | `multi-repo-engine.ps1` — orquestación cruzada entre repositorios. Resolución de dependencias, PRs coordinados |

### v2.28.0 Key Results

- **Skill Recommendation**: Context-aware skill suggestions via TF-IDF cosine similarity
- **Auto-Docs**: Mermaid diagrams (call graph, data flow, module dependency) auto-generated from CodeGraph
- **Multi-Repo Alpha**: Cross-repo PR coordination, dependency resolution, automated sync
- **Tests**: Full test suite in `tests/unit/v284-scripts.tests.ps1`

---

## v2.29.0-alpha

| Item | Status | Effort | Impact | Description |
|------|--------|--------|--------|-------------|
| Agentes con fine-tuning por dominio | ✅ DONE | 6 wk | Very High | Data pipeline PS1, LoRA trainer (Python), registry, inference, evaluator. Dashboard FT section. 2 adapters registrados (BA, DEV). 15/15 tests. Pipeline `ft-pipeline.ps1 -Stage full` operativo. Pendiente: entrenamiento real LoRA (requiere GPU) |
| Benchmarking automatizado de skills | 📋 PENDING | 3 wk | Medium | Suite de benchmarks: accuracy, latency, token efficiency por skill. Reportes semanales |
| Observabilidad distribuida cross-session | 📋 PENDING | 4 wk | High | OpenTelemetry tracing entre sesiones y herramientas. Dashboard de trazabilidad E2E |
| Auto-update launcher | 📋 PENDING | 2 wk | Medium | Mecanismo de auto-update: check remote version, download, apply. CI/CD pipeline de distribución |
| Docker containerized tests | 📋 PENDING | 2 wk | Medium | Tests en contenedores Docker para reproducibilidad. Matrix OS en CI |
| S3 distribution | 📋 PENDING | 1 wk | Low | Distribución global vía S3 para assets y releases |

---

## Release Cadence

| Cycle | Frequency | Scope |
|-------|-----------|-------|
| Minor | Cada 2-3 semanas | Features individuales, bugs, optimizaciones |
| Major | Cada 3 meses | Releases con breaking changes o grandes features |
| Patch | As needed | Hotfixes críticos |

---

## How to Contribute

1. Check `docs/ROADMAP.md` for current priorities
2. Create SDD spec for the feature (EXPLORE → SPEC)
3. Implement via SDD pipeline (TASKS → DESIGN → APPLY)
4. Verify with QA agent (VERIFY → ARCHIVE)
5. PR con spec validado y gates aprobados
