# Gentle-Vanguard Architecture

## Overview

Gentle-Vanguard is a comprehensive AI-powered development platform orchestration system designed for
local-first operation with enterprise-grade observability.

## Core Philosophy

- **Local-First**: No cloud dependencies, 100% offline capable
- **Zero External Services**: No SaaS, no external APIs required
- **Self-Contained**: Everything needed is in the repository
- **Extensible**: Plugin architecture for skills and capabilities

## System Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                    GENTLE-VANGUARD v3.5.0                   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐    │
│  │   ORCH.     │  │   SESSION    │  │   KNOWLEDGE     │    │
│  │  (Router)   │  │  Manager     │  │   Base          │    │
│  └──────┬──────┘  └──────┬───────┘  └────────┬────────┘    │
│         │                 │                   │             │
│  ┌──────┴─────────────────┴───────────────────┴────────┐    │
│  │                  AGENT BUS                         │    │
│  └──────┬─────────────────┬───────────────────┬────────┘    │
│         │                 │                   │             │
│  ┌──────┴──────┐  ┌───────┴───────┐  ┌────────┴────────┐    │
│  │ BA Agent    │  │  Arch Agent   │  │  Dev Agent      │    │
│  │ (Explore)   │  │   (Design)    │  │   (Apply)       │    │
│  └─────────────┘  └───────────────┘  └─────────────────┘    │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐     │
│  │ QA Agent    │  │  Ops Agent    │  │  Gov Agent      │    │
│  │ (Verify)    │  │   (Deploy)    │  │   (Compliance)  │    │
│  └─────────────┘  └───────────────┘  └─────────────────┘     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐ │
│  │           INFRASTRUCTURE LAYER                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │ │
│  │  │  Nexus   │  │  Engram  │  │  MCP     │  │  Code    │ │ │
│  │  │   DB     │  │  Memory  │  │  Bridge  │  │  Graph   │ │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐ │
│  │           OBSERVABILITY LAYER                           │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │   Health     │  │   Tracing    │  │  Audit Trail │ │ │
│  │  │   Check      │  │   System     │  │              │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Session Management

**File**: `src/core/session-autostart.ts`

- **Purpose**: Initialize workspace on session start
- **Features**:
  - Lock file management (prevents duplicate runs)
  - Pipeline execution (30 steps + 69 lazy)
  - Audit logging integration
  - Auto-checkpoint creation
- **Pipeline Phases**:
  - Phase 0: Critical bootstrap
  - Phase 1: Core initialization
  - Phase 2: Lazy background tasks

### 2. Multi-Agent System

**Base**: TF-IDF Semantic Routing

419 skills indexed with cosine similarity for agent routing.

**Available Agents**:

| Agent         | Code         | Purpose               |
| ------------- | ------------ | --------------------- |
| Orchestrator  | orchestrator | Main coordinator      |
| BA Explore    | sdd-explore  | Requirements analysis |
| SAD Design    | sdd-design   | Architecture design   |
| DEV Apply     | sdd-apply    | Implementation        |
| QA Verify     | sdd-verify   | Testing               |
| Documentation | doc-agent    | Technical writing     |
| Operations    | ops-agent    | CI/CD, deployment     |
| Governance    | gov-agent    | Security, compliance  |

### 3. Infrastructure Layer

#### Nexus DB (SQLite)

- **Location**: `.runtime/gentle-vanguard.db`
- **Tables**: 23 operational tables
- **Features**: WAL mode, migrations, backups
- **Migrations**: 7 applied

#### Engram Memory

- **Type**: Persistent memory system
- **Integration**: MCP server
- **Features**: Session history, observations, RAG

#### MCP Bridge

- **Tools**: 5 active (codegraph, engram, chrome-devtools, filesystem, memory)
- **Mode**: stdio/local
- **Purpose**: Unified tool access

#### CodeGraph

- **Nodes**: 24,685
- **Edges**: 25,146
- **Features**: Cross-file relationships, community detection

### 4. Observability

#### Health Checks

- **Watchtower**: 95 checks in 21 components (`npm run watchtower:health`)
- **Components**: Dashboard, CodeGraph, ML, Engram, MCP, Session, etc.
- **Command**: `npm run health:check`

#### Distributed Tracing

- **Spans**: Stored in `.telemetry/spans/`
- **Traces**: JSONL format
- **Export**: OTLP to localhost:4318

#### Audit Trail (NEW - Wave 2)

- **Events**: 2 generated
  - `session.start`: Session initialization
  - `config.load`: Pipeline configuration
- **Location**: `.session/audit/logs/`
- **CLI**: `npx tsx src/infrastructure/audit-pipeline.ts`
- **Status**: ✅ OPERATIVO

### 5. State Persistence

#### Checkpoints

- **Manual**: `npm run checkpoint:create`
- **Automatic**: On session start (if successful)
- **Location**: `.session/checkpoints/`
- **Existing**: 3 checkpoints

#### Snapshots

- **Location**: `.session/snapshots/`
- **Format**: JSON manifests
- **Use**: Rollback capability

## Data Flow

```
User Input → Pre-Process → Skill Router → Agent Selection
                                              ↓
                    Session Context ← Execution → Agent(s)
                          ↓
    Audit Trail ← State Persistence → Health Metrics
```

## Configuration Files

### Key Configs

- `config/session-autostart.config.json`: Pipeline definition
- `config/auto-delegation.json`: Agent routing
- `config/token-budget-guard.json`: Resource limits
- `opencode.json`: Agent definitions

### Tool Configs

- `.lefthook.yml`: Git hooks
- `.gitignore`: 259 patterns
- `.secretlintrc.json`: Security scanning

## Testing Architecture

| Test Type | Location           | Count | Status |
| --------- | ------------------ | ----- | ------ |
| Config    | `tests/config/`    | 24    | PASS   |
| E2E       | `tests/e2e/`       | 10    | PASS   |
| Workflows | `tests/workflows/` | 2     | PASS   |
| Unit      | (in progress)      | -     | -      |

## Security Model

- **Local Auth**: `config/owner-auth.json.enc`
- **Permissions**: `opencode.json` agent-level
- **Secrets**: secretlint + trufflehog
- **Policy**: LOCAL-FIRST, no cloud by default

## Performance Metrics

| Metric          | Value             |
| --------------- | ----------------- |
| Health Score    | 94/100            |
| Skills Coverage | 419/419 (100%)    |
| Test Pass Rate  | 36/36 (100%)      |
| Commits Wave 2  | 6 successful      |
| Audit Events    | 2 real events     |
| Checkpoints     | 3 existing + auto |

## Development Guidelines

### Adding a New Skill

1. Create `.opencode/skills/{name}/SKILL.md`
2. Update `.atl/skill-registry.md`
3. Run `npx tsx src/skills/skill-embedder.ts`
4. Verify routing with `npx tsx src/skills/skill-router.ts --query "{trigger}"`

### Adding Audit Events

1. Import audit functions
2. Call `auditLog()` at key points
3. Verify with `npx tsx src/infrastructure/audit-pipeline.ts status`

### Running Health Checks

```bash
npm run health:check          # 19 checks
npm run watchtower:health     # 95 checks
npm run test                  # 36 tests
```

## Future Evolution (Backlog)

### Wave 3-A ✅ IN PROGRESS

- State persistence auto-activation
- Test coverage >80%
- Documentation consolidation

### Wave 3/4 📋 BACKLOG

- Docker containerization (under analysis)
- Multi-model routing
- NPM package publication
- VS Code extension

## Maintenance

### Daily Checks

```bash
npm run health:check
npm run watchtower:health
```

### Session Start

```bash
npx tsx src/session/session-autostart.ts
```

### Backup

```bash
npm run db:backup
```

## Conclusion

Gentle-Vanguard is a production-ready orchestration platform with:

- ✅ 100% local operation
- ✅ 419 skills indexed
- ✅ Audit trail operational
- ✅ Auto-checkpoint enabled
- ✅ 94/100 stack health score

Next: Wave 3-A completion (test coverage expansion)
