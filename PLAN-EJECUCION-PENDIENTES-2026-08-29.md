# 🎯 PLAN DE EJECUCIÓN — PENDIENTES DEL STACK
## Gentle-Vanguard Local Workspace
**Fecha:** 29 Agosto 2026 | **Status:** Iniciado  
**Usuario:** Emmanuel Ortiz  
**Objetivo:** Resolver todos los pendientes sin gaps, warnings, simulaciones, incompletos

---

## 📊 RESUMEN EJECUTIVO

**Total de Tareas:** 18  
**Tokens Estimados:** ~77,500  
**Duración Estimada:** 2-3 semanas (parallelizable en 1 semana con focus)

| Prioridad | Count | Tokens | Timeline |
|-----------|-------|--------|----------|
| 🔴 CRÍTICO | 4 | 22,000 | Semana 1 |
| 🟠 ALTO | 7 | 34,000 | Semana 1-2 |
| 🟡 MEDIO | 7 | 21,500 | Semana 2-3 |

---

## 🔴 FASE 1: CRÍTICOS (Semana 1)

### 1. Dashboard E2E Tests - Auth Flow
**ID:** `dash-e2e-auth` | **Tokens:** 8,000 | **Blocker:** NO (puede parallelizar)

```
Tareas:
  [ ] Crear test suite en tests/e2e/dashboard-auth.test.ts
  [ ] Implement auth flow E2E (login, session, logout)
  [ ] Implement WebSocket handshake test
  [ ] Implement tenant auth verification
  [ ] Mock server responses (fixtures)
  [ ] Run tests locally, verify all pass
```

**Verificación:**
```bash
npm run test:dashboard
# Esperado: ✅ All tests pass, 0 failures
```

---

### 2. Validate CI Pipeline - 147 Commits
**ID:** `validate-ci-147` | **Tokens:** 3,000 | **Blocker:** NO

```
Tareas:
  [ ] Verify .github/workflows/ci.yml
  [ ] Ensure all 147 F2.5 commits are included
  [ ] Check TypeCheck job passes
  [ ] Check Lint job passes
  [ ] Check Test jobs pass
  [ ] Document any CI failures + fixes
```

**Verificación:**
```bash
npm run typecheck  # Exit 0
npm run lint       # Exit 0, --max-warnings 0
npm run test:config && npm run test:workflows  # Exit 0
```

---

### 3. Module Documentation - All 80+ Splits
**ID:** `module-docs` | **Tokens:** 6,000 | **Depends-on:** dash-e2e-auth (para entender scope)

Major modules to document:
- ✅ real-data/ (6 modules)
- ✅ websocket-server/ (18 modules)
- ✅ maintenance-watchtower/ (15 modules)
- ✅ secret-scanner/ (6 modules)
- ✅ response-cache/ (5 modules)
- ✅ session-close/ (8 modules)
- ✅ research-trends/ (7 modules)
- ✅ token-ingest/ (4 modules)
- ✅ humanizer/ (5 modules)
- ✅ adaptive-router/ (7 modules)
- ✅ workload-guard/ (4 modules)
- + 5 más

```
Tareas:
  [ ] Create MODULE-STRUCTURE.md (index of all 80+ modules)
  [ ] For each major feature, create docs/modules/{feature}/README.md
  [ ] Add JSDoc comments to all exports
  [ ] Document per-module responsibilities + entry points
  [ ] Add architecture diagrams for complex features
```

**Verificación:**
```bash
# Cada módulo debe tener:
# 1. JSDoc @module comment
# 2. Clear responsibilities
# 3. Example usage in README
```

---

### 4. Full TypeCheck & Lint - Zero Warnings
**ID:** `typecheck-pass` | **Tokens:** 2,000 | **Depends-on:** module-docs (puede ejecutarse en paralelo)

```
Tareas:
  [ ] npm run typecheck → must exit 0
  [ ] npm run lint → must exit 0 with --max-warnings 0
  [ ] npm run prettier --check → must pass
  [ ] Document any issues found
  [ ] Fix all issues (no --ignore)
```

---

## 🟠 FASE 2: ALTOS (Semana 1-2)

### 5. Unit Tests - Critical Modules
**ID:** `unit-tests-critical` | **Tokens:** 12,000 | **Depends-on:** module-docs

Target modules:
- `src/tokens/token-ingest/` (4 modules)
- `src/orchestration/adaptive-router/` (7 modules)
- `src/security/secret-scanner/` (6 modules)
- `src/resilience/response-cache/` (5 modules)

```
Tareas:
  [ ] Create tests/unit/{module}/*.test.ts for each module
  [ ] Test critical functions + edge cases
  [ ] Mock dependencies (DB, file system, etc.)
  [ ] Aim for 80%+ coverage on critical path
  [ ] Run coverage report: npm run test:coverage
```

**Verificación:**
```bash
npm run test:coverage
# Esperado: Overall coverage ≥60% (target 80% on critical modules)
```

---

### 6. Dependency Graph Visualization
**ID:** `dependency-graph` | **Tokens:** 5,000 | **Blocker:** NO

```
Tareas:
  [ ] Use graphify to generate dependency data
  [ ] Create visualization (DOT format or HTML)
  [ ] Identify circular dependencies (must be 0)
  [ ] Document module dependencies in docs/architecture/DEPENDENCY-GRAPH.md
```

---

### 7. Academy Update - F2.5 Splits Explained
**ID:** `academy-update` | **Tokens:** 4,000 | **Depends-on:** module-docs

```
Tareas:
  [ ] Update gentle-vanguard-academy with F2.5 section
  [ ] Create lesson: "Module Organization & Barrels"
  [ ] Create lesson: "How to navigate 80+ modules"
  [ ] Add code examples (before/after monolith)
  [ ] Link to MODULE-STRUCTURE.md
```

---

### 8. Nexus DB - Indices + Optimization
**ID:** `nexus-indexes` | **Tokens:** 7,000 | **Blocker:** NO

```
Tareas:
  [ ] Audit current Nexus schema (23 tables)
  [ ] Identify missing indices on foreign keys
  [ ] Add indices for common queries (metrics, traces, sessions)
  [ ] Run ANALYZE and VACUUM
  [ ] Document schema + indices in docs/database/NEXUS-SCHEMA.md
  [ ] Benchmark before/after query performance
```

---

### 9. Process Hygiene - Production Validation
**ID:** `process-hygiene-prod` | **Tokens:** 4,000 | **Blocker:** NO

```
Tareas:
  [ ] Run npm run process:hygiene in test scenario
  [ ] Verify orphan detection works correctly
  [ ] Verify cleanup doesn't break active processes
  [ ] Document any edge cases found
  [ ] Add integration test for hygiene flow
```

---

## 🟡 FASE 3: MEDIUM (Semana 2-3)

### 10. Dashboard WebSocket Health
**ID:** `dashboard-ws-health` | **Tokens:** 5,000 | **Depends-on:** None

```
Tareas:
  [ ] Add health check endpoint to WS server
  [ ] Add reconnection logic (exponential backoff)
  [ ] Add latency tracking to metrics
  [ ] Add WS connection state monitoring
  [ ] Document in apps/web-dashboard/server/README.md
```

---

### 11. HTML Presentations Update
**ID:** `html-presentations` | **Tokens:** 3,000 | **Depends-on:** module-docs

```
Tareas:
  [ ] Find all .html presentation files
  [ ] Update with F2.5 impact metrics
  [ ] Add architecture diagrams (new structure)
  [ ] Show before/after compilation times
  [ ] Ensure all links still work
```

---

### 12. README Synchronization
**ID:** `readme-sync` | **Tokens:** 2,000 | **Depends-on:** module-docs

```
Tareas:
  [ ] Update root README.md with F2.5 overview
  [ ] Update docs/GETTING-STARTED.md with new structure
  [ ] Update docs/stack-manual-full.md (architecture section)
  [ ] Verify all links + references still correct
  [ ] Check for stale documentation
```

---

### 13. Changelog - F2.5 Detailed Entry
**ID:** `changelog-f25` | **Tokens:** 1,500 | **Depends-on:** module-docs

```
Tareas:
  [ ] Add comprehensive F2.5 section to CHANGELOG.md
  [ ] List all 16+ major splits with line count changes
  [ ] Document benefits + gotchas learned
  [ ] Link to architecture ADRs
```

---

### 14. GraphQL Update - Code Graph
**ID:** `graphify-update` | **Tokens:** 2,000 | **Depends-on:** None

```
Tareas:
  [ ] npm run graphify -- build
  [ ] npm run graphify -- verify
  [ ] Check for broken symbols in 80+ new modules
  [ ] Generate updated GRAPH_REPORT.md
```

---

### 15. Watchtower Health Checks - Updated
**ID:** `watchtower-health` | **Tokens:** 2,000 | **Depends-on:** None

```
Tareas:
  [ ] npm run watchtower:health
  [ ] Verify all 96 checks still pass
  [ ] Check new modules are covered by checks
  [ ] Document any new health concerns
```

---

### 16. Token Ingest - Real Data Collection
**ID:** `token-ingest-test` | **Tokens:** 3,000 | **Depends-on:** None

```
Tareas:
  [ ] Start token-ingest daemon
  [ ] Run a real opencode session
  [ ] Verify tokens are being collected
  [ ] Check Nexus DB for token records
  [ ] Document metrics collected
```

---

### 17. Test Coverage Report
**ID:** `test-coverage` | **Tokens:** 3,000 | **Depends-on:** unit-tests-critical

```
Tareas:
  [ ] npm run test:coverage
  [ ] Generate HTML report
  [ ] Identify coverage gaps
  [ ] Target: 60%+ baseline (80%+ for critical)
  [ ] Document hotspots for future testing
```

---

### 18. Lint Pass - Zero Warnings
**ID:** `lint-pass` | **Tokens:** 1,000 | **Depends-on:** module-docs (parallelizable)

```
Tareas:
  [ ] npm run lint -- --max-warnings 0
  [ ] Fix all eslint violations
  [ ] Fix all prettier violations
  [ ] Run npm run lint again (must exit 0)
```

---

## 🚀 EJECUCIÓN

### Orden Recomendado (Optimizado)

```
PARALELO (Semana 1):
├─ dash-e2e-auth (8K tokens)
├─ validate-ci-147 (3K tokens)
├─ module-docs (6K tokens) ← depende de dash-e2e-auth (después)
├─ graphify-update (2K tokens)
├─ watchtower-health (2K tokens)
└─ token-ingest-test (3K tokens)

DESPUÉS MÓDULO-DOCS:
├─ unit-tests-critical (12K tokens)
├─ typecheck-pass (2K tokens)
├─ lint-pass (1K tokens)
├─ academy-update (4K tokens)
└─ html-presentations (3K tokens)

FINAL:
├─ test-coverage (3K tokens)
├─ dependency-graph (5K tokens)
├─ nexus-indexes (7K tokens)
├─ process-hygiene-prod (4K tokens)
├─ dashboard-ws-health (5K tokens)
├─ readme-sync (2K tokens)
└─ changelog-f25 (1.5K tokens)
```

---

## ✅ CRITERIOS DE ÉXITO (NO PARCIALIDADES)

### Cada tarea debe cumplir:
1. ✅ **Completitud:** 100% de requisitos implementados
2. ✅ **Sin Warnings:** 0 errores, 0 advertencias en cualquier verificación
3. ✅ **Integración:** Todas las piezas conectadas (no componentes aislados)
4. ✅ **Documentación:** Cada cambio documentado
5. ✅ **Pruebas:** Tests ejecutados, all pass
6. ✅ **Funcionalidad:** Cada feature verificada end-to-end
7. ✅ **Sincronización:** Stack coherente, sin gaps
8. ✅ **Git:** Commits limpios, descriptivos, sin WIP

### Verificación Final (Antes de dar por completo):
```bash
npm run typecheck       # Exit 0, no errors
npm run lint            # Exit 0, --max-warnings 0
npm run test:config     # All pass
npm run test:workflows  # All pass
npm run watchtower:health  # 96/96 PASS
npm run test:coverage   # ≥60% baseline
git status              # Clean (no pending changes)
```

---

## 📅 TIMELINE

- **Phase 1 (Critical):** Today (29 Aug) → 30 Aug
- **Phase 2 (High):** 30 Aug → 2 Sep
- **Phase 3 (Medium):** 2 Sep → 5 Sep
- **Validation:** 5 Sep → 6 Sep
- **Done:** 6 Sep (ready for owner push)

---

## 🎯 RESULTADO ESPERADO

Al completar este plan, el stack local será:

✅ **Completo** — todos los pendientes cerrados  
✅ **Correcto** — 0 errores, 0 warnings  
✅ **Sincronizado** — todo coherente + documentado  
✅ **Integrado** — componentes conectados, funcional  
✅ **Verificado** — tests pass, coverage baseline ok  
✅ **Documentado** — README, Academy, módulos claros  
✅ **Listo para push** — owner puede mergear a main sin fricción

---

**INICIO:** 2026-08-29 06:47 UTC-3  
**STATUS:** 🟢 INICIADO  
**PRÓXIMO PASO:** Comenzar Phase 1 Critical Tasks

