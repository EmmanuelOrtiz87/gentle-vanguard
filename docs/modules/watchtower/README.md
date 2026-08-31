# 🔍 Maintenance Watchtower Module Architecture

**Location:** `src/core/maintenance-watchtower/`  
**Barrel Entry:** `src/core/maintenance-watchtower.ts` (470 lines)  
**Status:** Core Component  
**Team:** @gentle-vanguard/core

---

## Overview

The Maintenance Watchtower is the operational health monitoring and auto-healing system for
Gentle-Vanguard. It performs 96 comprehensive checks across 22 stack components and can auto-heal
detected issues.

**Key Responsibility:** Ensure stack health, detect degradation, auto-heal when possible, and report
anomalies.

---

## Module Architecture

### Core Modules (15 + barrel)

```
maintenance-watchtower/
├── context.ts              # Global state, loggers, server refs
├── helpers.ts              # Constants, utilities, result builders
├── checks-dashboard/       # Component checks: metrics, WS, auth
├── checks-infra/           # Infrastructure: DB, process, hygiene
├── checks-config/          # Config validation, drift detection
├── checks-security/        # Security gates, secret scanning
├── checks-routing/         # Delegation paths, agent routing
├── checks-skills/          # Skill availability, loading
├── checks-stack/           # Versions, dependencies, locks
├── report.ts               # Report generation + formatting
├── autoheal.ts             # Auto-correction logic
├── telemetry.ts            # Metrics collection
├── cli.ts                  # CLI interface
└── index.ts                # Main orchestration
```

---

## Health Checks (96 Total)

**Run:** `npm run watchtower:health`

### Categories

- Database (12 checks)
- Processes (8 checks)
- Dashboard (8 checks)
- Security (10 checks)
- Configuration (8 checks)
- Routing (6 checks)
- Skills (8 checks)
- Stack (8 checks)
- - 20 more across components

---

## Auto-Healing

Automatically fixes:

- Orphaned/duplicate processes
- Stale lock files
- Database issues (WAL checkpoint)
- Cache corruption
- Expired sessions

**Enable:** `npm run watchtower:autoheal`

---

## Integration

**Runs:** Lazy on session start, periodic (30m default), on watchtower calls  
**Reports:** Nexus DB, alerts, CLI, logs  
**Monitoring:** Dashboard real-time health widget

---

**See:** `docs/modules/MODULE-STRUCTURE.md` for full architecture  
**Tests:** `tests/unit/watchtower/*.test.ts`
