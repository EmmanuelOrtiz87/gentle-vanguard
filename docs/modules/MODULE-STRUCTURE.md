# 📚 MODULE STRUCTURE — Gentle-Vanguard Architecture
## Complete Index of 80+ Per-Domain Modules (F2.5)

**Generated:** 2026-08-29  
**Status:** Reference Documentation  
**Maintenance:** Keep aligned with actual directory structure

---

## 🗂️ DIRECTORY STRUCTURE

### Core Stack (`src/`)

#### 1. **Core Infrastructure** (`src/core/`)

##### `maintenance-watchtower/` (15 modules, ~600 lines barrel)
**Purpose:** Health monitoring, checks, and auto-healing

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `context.ts` | ~200 | State, server, logger setup |
| `checks-dashboard/` | ~400 | Dashboard component health |
| `checks-infra/` | ~350 | Infrastructure: DB, process, watchtower |
| `checks-config/` | ~250 | Configuration validation |
| `checks-security/` | ~300 | Security gates: secrets, audit |
| `checks-routing/` | ~280 | Delegation + agent routing |
| `checks-skills/` | ~220 | Skill availability + loading |
| `checks-stack/` | ~180 | Stack versions + dependencies |
| `helpers.ts` | ~150 | Constants, loggers, utilities |
| + 6 more modules | - | Report generation, telemetry, etc. |

**Entry Point:** `src/core/maintenance-watchtower.ts` (thin barrel, 470L)

---

#### 2. **Orchestration & Routing** (`src/orchestration/`)

##### `adaptive-router/` (7 modules, ~600 lines barrel)
**Purpose:** Dynamic agent delegation with learning loop

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `types.ts` | ~50 | Type definitions (RouterArgs, AgentPerformance, etc.) |
| `config.ts` | ~80 | Configuration loading, paths |
| `seed.ts` | ~120 | Seed domain + override tables |
| `collect.ts` | ~350 | Metrics collection from sources |
| `table.ts` | ~200 | Routing table computation |
| `index.ts` | ~200 | Main logic, CLI entry |

**Entry Point:** `src/orchestration/adaptive-router.ts` (thin barrel, 26L)

**Key Features:**
- Domain-based agent performance tracking
- Skill usage and delegation metrics
- Auto-learning routing table from metrics

---

#### 3. **Security & Secret Management** (`src/security/`)

##### `secret-scanner/` (6 modules, ~1500 lines barrel)
**Purpose:** Secret detection, entropy analysis, redaction

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `patterns.ts` | ~744 | 80+ regex patterns for secrets |
| `scanner.ts` | ~341 | Core scanning engine |
| `config.ts` | ~161 | Configuration + allowlist |
| `entropy.ts` | ~20 | Shannon entropy calculation |
| `ignore.ts` | ~91 | .secretlintignore parsing |
| `report.ts` | ~44 | Report formatting |

**Entry Point:** `src/security/secret-scanner.ts` (thin barrel, 40L)

**Coverage:** API keys, tokens, SSH keys, passwords, private keys, credentials

---

#### 4. **Resilience & Caching** (`src/resilience/`)

##### `response-cache/` (5 modules, ~1200 lines barrel)
**Purpose:** Response caching, semantic matching, telemetry

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `semantic.ts` | ~234 | BM25 similarity matching |
| `sqlite.ts` | ~337 | SQLite persistence layer |
| `telemetry.ts` | ~108 | Hit/miss tracking, alerts |
| `cache.ts` | ~342 | Main caching logic |
| `cli.ts` | ~186 | CLI interface |

**Entry Point:** `src/resilience/response-cache.ts` (thin barrel, 31L)

**Metrics:** Hit rate, eviction policy (LRU), latency tracking

---

### Session Management (`src/session/`)

##### `session-close-orchestrator/` → `session-close/` (8 modules, ~280 lines barrel)
**Purpose:** Graceful session shutdown with 5 phases

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `helpers.ts` | ~150 | Constants, loggers, utilities |
| `process.ts` | ~180 | Process cleanup |
| `disk.ts` | ~120 | File system cleanup |
| `database.ts` | ~90 | DB transaction cleanup |
| `metadata.ts` | ~60 | Session metadata finalization |
| `index.ts` | ~180 | Phase orchestration |

**Entry Point:** `src/session/session-close-orchestrator.ts` (thin barrel, 33L)

**Phases:** 1. Alerts, 2. Process Stop, 3. Disk Cleanup, 4. DB Finalize, 5. Audit

---

### Research & Analysis (`src/research/`)

##### `research-trends/` (7 modules, ~1200 lines barrel)
**Purpose:** GitHub, HN, Stack Overflow, Dev.to trends analysis

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `schemas.ts` | ~157 | Type definitions |
| `config.ts` | ~45 | Configuration |
| `http.ts` | ~116 | HTTP + rate limiting |
| `sources/` | ~540 | GitHub, HN, SO, Dev.to, Reddit fetchers |
| `report.ts` | ~238 | Report generation |
| `fetch.ts` | ~128 | Unified fetch abstraction |
| `index.ts` | ~50 | CLI + main |

**Entry Point:** `src/research/research-trends.ts` (thin barrel, 19L)

---

### Token Management (`src/tokens/`)

##### `token-ingest/` (4 modules, ~1100 lines barrel)
**Purpose:** Multi-source token consumption tracking

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `readers.ts` | ~465 | Read tokens from opencode.db, zcode, codex, minimax |
| `nexus.ts` | ~344 | Nexus DB write operations |
| `ingest.ts` | ~286 | Consolidation logic |
| `index.ts` | ~50 | CLI entry |

**Entry Point:** `src/tokens/token-ingest.ts` (thin barrel, 49L)

**Sources:** OpenCode, ZCode, Codex, MiniMax

---

##### `token-optimization-orchestrator/` (6 modules)
**Purpose:** Cost optimization via profiles, compression, routing

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `cli.ts` | ~180 | CLI interface |
| `config.ts` | ~140 | Profile configuration |
| `metrics.ts` | ~220 | Savings calculation |
| `optimize.ts` | ~250 | Compression strategies |
| `pipeline.ts` | ~180 | Orchestration |
| `types.ts` | ~80 | Type definitions |

**Entry Point:** `src/tokens/token-optimization-orchestrator.ts` (thin barrel)

---

### Utilities & Analysis

##### `humanize/` (5 modules, ~1100 lines barrel)
**Purpose:** Natural language output formatting

##### `ml/knowledge-synthesizer/` (7 modules)
**Purpose:** Knowledge extraction, synthesis, ML embeddings

---

## 🌐 Dashboard Stack (`apps/web-dashboard/`)

### Server Components (`apps/web-dashboard/server/`)

#### 1. **Real-Time Data Pipeline** → `real-data/` (6 modules)
**Purpose:** Metrics, traces, alerts, user feedback aggregation

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `helpers.ts` | ~111 | Utilities, mocking |
| `metrics.ts` | ~931 | Compute, memory, token metrics |
| `traces.ts` | ~281 | Trace data aggregation |
| `alerts.ts` | ~200 | Alert rules + thresholds |
| `feedback.ts` | ~150 | User feedback collection |
| `index.ts` | ~50 | Barrel exports |

**Entry Point:** `apps/web-dashboard/server/real-data.ts` (thin barrel, 17L)

---

#### 2. **WebSocket Server** → `websocket-server/` (18 modules)

##### `ws-hub/` (6 core modules)
**Purpose:** Connection management, context, broadcast

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `context.ts` | ~250 | Global server state |
| `connection.ts` | ~280 | Connection lifecycle |
| `session-store.ts` | ~180 | Session persistence |
| `skill-execution.ts` | ~120 | Skill invocation |
| `metrics.ts` | ~150 | Per-connection metrics |
| `broadcast.ts` | ~200 | Push notifications |

##### `handlers/` (12 per-domain route handlers)
**Purpose:** API endpoint handlers for different features

| Handler | Responsibility |
|---------|-----------------|
| `auth.ts` | Login, logout, session |
| `admin.ts` | Admin operations |
| `metrics.ts` | Real-time metrics |
| `mcp.ts` | MCP protocol |
| `health.ts` | Health checks |
| `observability.ts` | Traces, logs |
| `knowledge.ts` | Knowledge APIs |
| `mesh.ts` | Agent mesh |
| `agent.ts` | Agent management |
| `marketplace.ts` | Skill marketplace |
| `content-ops.ts` | Content operations |
| + 1 more | - |

**Entry Point:** `apps/web-dashboard/server/websocket-server.ts` (330L entry)

---

### Frontend i18n (`apps/web-dashboard/src/`)

##### `i18n/` (2 modules extracted from `useLocale.ts`)
**Purpose:** Internationalization: 3 languages (ES/EN/PT)

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `metric-catalog.ts` | ~517 | Metric translations + metadata |
| `ui-strings.ts` | ~1,413 | UI string translations |

**Entry Point:** `apps/web-dashboard/src/hooks/useLocale.ts` (thin, 35L)

---

## 🛠️ Utilities & Infrastructure

### MCP & Language Services (`src/mcp/`)

#### `mcp-lsp-server/` (3 modules)
**Purpose:** Language Server Protocol for code intelligence

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `position.ts` | ~80 | Line/col conversion |
| `language-service.ts` | ~200 | Symbol resolution |
| `handlers.ts` | ~150 | RPC message handlers |

---

#### `mcp-bridge.ts`
**Purpose:** Bridge between MCP servers and dashboard

#### `mcp-gateway.ts`
**Purpose:** MCP server discovery and routing

---

### Web Services (`src/web/`)

#### `web-crawler/` (2 modules)
**Purpose:** Unified web content fetching

| Module | Lines | Responsibility |
|--------|-------|-----------------|
| `types.ts` | ~80 | Type definitions |
| `schemas.ts` | ~120 | URL validation schemas |

---

## 📊 STATISTICS

| Category | Count | Total Lines | Avg per Module |
|----------|-------|-------------|----------------|
| Core (src) | ~45 modules | ~15K lines | ~330 lines |
| Dashboard Server | ~18 modules | ~3.5K lines | ~195 lines |
| Dashboard Client | ~2 modules | ~2K lines | ~1K lines |
| MCP/Utils | ~8 modules | ~800 lines | ~100 lines |
| **TOTAL** | **~80+ modules** | **~22K lines** | **~270 lines** |

---

## 🔗 DEPENDENCIES & INTEGRATION

### Import Patterns

**Barrel Re-exports (thin entry files):**
```typescript
// src/orchestration/adaptive-router.ts
export * from './adaptive-router/index.js';

// Or preserve CLI logic:
// import.meta.url check for CLI guard
// main() entry point
```

**Module imports (from callers):**
```typescript
// Old: single monolith
import { collectSkillUsage, buildRoutingTable } from './src/orchestration/adaptive-router'

// New: same API, modular implementation
import { collectSkillUsage, buildRoutingTable } from './src/orchestration/adaptive-router'
// ↓ resolves to ./adaptive-router/index.ts which re-exports all 6 modules
```

### Zero Breaking Changes
- All barrel exports maintain backward compatibility
- No changes required in callers
- TypeScript resolves same way as before

---

## 📝 MODULE DOCUMENTATION CHECKLIST

For each module, ensure:

- [ ] `index.ts` barrel exists (or thin entry file)
- [ ] JSDoc `@module` comment on barrel
- [ ] All exports have @doc comments
- [ ] README.md with responsibilities
- [ ] Example usage in docstring
- [ ] Dependencies listed
- [ ] Tests exist (unit tests per module)

---

## 🚀 ADDING NEW MODULES

Pattern:
1. Create `src/domain/feature/` directory
2. Move code into per-concern files
3. Create `src/domain/feature/index.ts` barrel
4. Update parent's barrel if exists
5. Verify imports unchanged
6. Add `# @module` comment
7. Document in this file

---

## 📖 REFERENCES

**F2.5 Architecture Decision:**  
- ADR: `docs/architecture/F2.5-refactor-rationale.md`
- Commit pattern: "refactor(*): split NNNN-line X into per-domain modules"

**Maintenance:**
- Watchtower checks: `npm run watchtower:health`
- CodeGraph: `npm run graphify -- verify`
- Coverage: `npm run test:coverage`

---

## ✅ VALIDATION

All 80+ modules verified:
- ✅ TypeScript: `tsc --noEmit` PASS
- ✅ ESLint: `npm run lint --max-warnings 0` PASS
- ✅ Format: `npm run prettier --check` PASS
- ✅ Tests: `npm run test:config && npm run test:workflows` PASS (24+4)
- ✅ DB: `npm run db:health` HEALTHY

---

**Last Updated:** 2026-08-29  
**Maintenance Owner:** Gentle-Vanguard Core Team  
**Next Review:** 2026-09-15

