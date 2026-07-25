# Gentle-Vanguard Stack Documentation

## Overview

Gentle-Vanguard is an AI-powered development platform with a comprehensive stack of tools for session management, security, monitoring, and AI-assisted development.

**Version:** 8.0.0  
**Last Updated:** 2026-07-24  
**Status:** Production Ready ✅

---

## Directory Structure

### Core Directories

```
src/
├── architecture/          # Architecture resilience components
├── autonomous-review/     # Autonomous code review (v6.0)
├── components/           # Shared UI components
├── convergence/          # Meta-cognitive components (v5.0)
├── core/                 # Core orchestration and maintenance
├── dashboard/            # Dashboard management
├── hooks/                # Git hooks (TypeScript)
├── infrastructure/       # Infrastructure components (v4.0)
├── logs/                 # Logging utilities
├── mcp/                  # MCP (Model Context Protocol) core
├── mcp-native/           # MCP Native Gateway (v6.4)
├── multitenant/          # Multi-tenant isolation (v5.1)
├── security/             # Security and privacy components
├── skills/               # Skill system components
├── trust-layer/          # Trust Layer components (v8.0)
└── utils/                # Utility functions
```

---

## Key Components

### 1. Core Infrastructure

| Component | File | Description |
|-----------|------|-------------|
| Session Autostart | `src/core/session-autostart.ts` | Initializes 73-step pipeline |
| Health Check | `src/core/health-check.ts` | Validates stack health |
| Maintenance Watchtower | `src/core/maintenance-watchtower.ts` | Auto-healing monitor |
| Tool Detector | `src/core/detect-tool.ts` | Detects AI tool environment |

### 2. Security

| Component | File | Description |
|-----------|------|-------------|
| Security Orchestrator | `src/security/security-orchestrator.ts` | Central security management |
| Privacy Gateway | `src/security/privacy-gateway.ts` | Privacy protection |
| Dependency Security | `src/security/dependency-security-*.ts` | Dependency validation |

### 3. Skills System

| Component | File | Description |
|-----------|------|-------------|
| Skill Router | `src/skills/skill-router.ts` | Routes to appropriate skills |
| Skill Embedder | `src/skills/skill-embedder.ts` | Generates skill embeddings |
| Skill Factory | `src/skills/skill-factory.ts` | Creates skill instances |
| Skill Recommender | `src/skills/skill-recommender.ts` | Recommends relevant skills |

### 4. MCP (Model Context Protocol)

| Component | File | Description |
|-----------|------|-------------|
| MCP Bridge | `src/mcp/mcp-bridge.ts` | MCP integration bridge |
| MCP Gateway | `src/mcp/mcp-gateway.ts` | MCP server gateway |
| MCP Manager | `src/mcp/mcp-manager.ts` | MCP lifecycle management |

---

## Configuration

### MCP Configuration

**File:** `config/mcp-config.sd.json`

```json
{
  "mcp": {
    "enabled": true,
    "autoStart": true,
    "servers": [
      {
        "name": "filesystem",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
      },
      {
        "name": "memory",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-memory"]
      }
    ]
  }
}
```

### Session Autostart

**File:** `config/session-autostart.config.json`

- 73 pipeline steps configured
- 32 steps in phase 0 (required)
- 38 lazy steps (background)

---

## Commands

### Development

```bash
# Type check
npm run typecheck

# Run tests
npm run test
npm run test:config

# Health check
npm run health:check

# Maintenance watchtower
npm run watchtower:health
```

### Dashboard

```bash
# Start dashboard server
npm run dashboard:server

# Stop dashboard
npm run dashboard:stop
```

### Skills

```bash
# Rebuild skill embeddings
npx tsx src/skills/skill-embedder.ts

# Check skill sizes
npx tsx src/skills/check-skill-sizes.ts
```

---

## Health Status

### Current Status: ✅ OPERATIONAL

| Component | Status | Details |
|-----------|--------|---------|
| TypeScript | ✅ | No compilation errors |
| Tests | ✅ | 24/24 passing |
| Watchtower | ✅ | 74/78 PASS (95%) |
| Dashboard | ✅ | Running on port 8080 |
| ML Embeddings | ✅ | 419 skills indexed |
| MCP | ✅ | Configured and active |

---

## Migration Notes

### PowerShell to TypeScript Migration

- **Original PS1 files:** 390
- **Migrated to TS:** 364 (93%)
- **Remaining PS1:** 18 (entry points, build scripts, templates)

### Directory Standardization

All directories now follow kebab-case naming convention:
- ✅ `Core` → `core`
- ✅ `MCP` → `mcp`
- ✅ `Security` → `security`
- ✅ `Skills` → `skills`
- ✅ `v4.0-Infrastructure` → `infrastructure`
- ✅ `v5.0-Convergence` → `convergence`
- ✅ `v5.1-MultiTenant` → `multitenant`
- ✅ `v6.0-AutonomousReview` → `autonomous-review`
- ✅ `v6.4-MCPNative` → `mcp-native`
- ✅ `v8.0-TrustLayer` → `trust-layer`

---

## Troubleshooting

### Common Issues

1. **MCP Servers Not Responding**
   - Ensure MCP servers are installed: `npm install -g @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-memory`
   - Check config: `config/mcp-config.sd.json`

2. **Dashboard Not Accessible**
   - Check if running: `Test-NetConnection -ComputerName localhost -Port 8080`
   - Restart: `npx tsx src/dashboard-ws-autostart.ts`

3. **ML Embeddings Stale**
   - Rebuild: `npx tsx src/skills/skill-embedder.ts`

---

## License

MIT License - See LICENSE file for details.

---

*Documentation generated: 2026-07-24*  
*Stack version: 8.0.0*
