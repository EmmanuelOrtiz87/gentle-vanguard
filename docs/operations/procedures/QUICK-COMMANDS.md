# Quick Commands — Gentle-Vanguard

> **Versión**: 3.8.2 | **Última actualización**: 2026-08-24

---

## Session & Workspace

```bash
# Iniciar sesión completa (con pipeline de 100 steps)
npx tsx src/session/session-autostart.ts

# Health check completo del stack
npm run health:check
npm run health:check:fast    # Versión optimizada

# Verificar stack (alias para health:check)
npm run stack:verify
npm run stack:verify:quick
```

---

## Circuit Breaker & Resilience

```bash
# Circuit breaker API
npm run cb:status        # Ver estado del circuit breaker
npm run cb:reset         # Resetear circuit breaker
npm run cb:force-open    # Forzar estado OPEN
```

---

## Adaptive Router & Monitoring

```bash
# Router adaptativo
npm run router:adaptive       # Ejecutar router adaptativo
npm run router:suggest        # Mostrar sugerencias de routing

# Monitoreo y performance
npm run monitor:convergence   # Monitor de convergencia
npm run perf:slo              # SLO Performance
npm run perf:analyze          # Análisis de performance
```

---

## Engram Memory Management

```bash
# Engram operations
npm run engram:sync      # Sincronizar Engram
npm run engram:backup    # Backup de Engram
npm run engram:compact   # Compactar datos
```

---

## Findings & Results

```bash
# Findings ledger
npm run findings:ledger     # Ver findings
npm run findings:gatekeeper # Gatekeeper de resultados
```

---

## Proactive Intelligence Engine (PIE)

```bash
# PIE operations - análisis predictivo
npm run pie:analyze   # Analizar patrones históricos
npm run pie:suggest   # Mostrar sugerencias contextuales
```

---

## Testing

```bash
# Test runners
npm run test:optimized    # Test runner optimizado
npm run test:parallel       # Tests en paralelo (4 workers)
npm run test:quick          # Tests rápidos (solo críticos)

# Tests completos
npm run test               # Run all tests
npm run test:config        # Config validation tests
npm run test:workflows     # CI/CD workflow tests
npm run test:research      # Research scripts tests
```

---

## Content Operations

```bash
# Content Operations Engine (offline-first content pipeline)
npm run content:list       # Listar jobs (--date, --platform, --id, --status)
npm run content:validate   # Validar jobs contra manifest + registry
npm run content:prepare    # Empaquetar jobs validados offline (idempotente)
npm run content:status     # Resumen de estados del pipeline
npm run content:report     # Reporte markdown del pipeline
npm run content:export     # Exportar kit offline ZIP (Windows)
npm run content:test       # Tests unitarios del engine (15)

# Ejemplos
npx tsx src/content-operations/cli.ts list --date=2026-08-18
npx tsx src/content-operations/cli.ts validate --id=GV-2026-08-18-LINKEDIN
npx tsx src/content-operations/cli.ts transition --id=GV-2026-08-18-LINKEDIN --to=VALIDATED
```

---

## Database (Nexus)

```bash
# Nexus database operations
npm run db:init         # Inicializar + migraciones
npm run db:health       # Check integridad
npm run db:backup       # Backup online
npm run db:restore      # Restaurar backup
npm run db:list         # Listar backups disponibles
npm run db:optimize     # WAL checkpoint + VACUUM
npm run db:prune        # Limpiar datos antiguos
npm run db:prune:backup # Mantener solo 10 backups
```

---

## Dashboard

```bash
# Dashboard operations
npm run dashboard:build    # Build dashboard
npm run dashboard:dev      # Dev server (Vite)
npm run dashboard:server   # WebSocket server
npm run dashboard          # Full start (WS + Vite + Chrome)
```

---

## Maintenance & Watchtower

```bash
# Watchtower health monitoring
npm run watchtower              # Ejecutar watchtower
npm run watchtower:health       # Health check rápido

# Auto-heal y reportes
npm run watchtower -- --Action autoheal
npm run watchtower -- --Action report -OutputFile status.json
```

---

## Cloud Connectors

```bash
# Hybrid cloud executor
npm run hybrid:executor

# AWS / Azure delegators
npm run aws:delegator
npm run azure:delegator
```

---

## Backlog & Task Management

```bash
# Backlog manager
npm run backlog              # Listar backlog
npm run backlog:add          # Agregar ítem
npm run backlog:list         # Listar ítems
npm run backlog:stats        # Estadísticas
npm run backlog:report       # Reporte completo
```

---

## Validator & Quality Gates

```bash
# Validadores
npm run lint:json            # Validar JSON files
npm run lint:workflows       # Validar workflows
npm run hashline             # HashLine context

# Security
npm run secretlint           # Detectar secrets
```

---

## Legacy Scripts (PowerShell)

> ⚠️ Estos scripts están en proceso de migración a TypeScript

```powershell
# Context log (PowerShell)
.\scripts\utilities\session-context-log.ps1 -Action status
.\scripts\utilities\session-context-log.ps1 -Action close

# MCP Gateway (PowerShell)
.\scripts\utilities\MCP\mcp-manager.ps1 -Action list
.\scripts\utilities\MCP\mcp-manager.ps1 -Action health

# SDD Preflight
.\scripts\utilities\sdd-preflight.ps1 -Interactive
```

---

## Environment Info

- **Stack Version**: 3.5.0
- **TypeScript**: 5.x (strict mode)
- **Node**: >= 20.0.0
- **Package Manager**: pnpm 11.15.1
- **Health Checks**: 82
- **Pipeline Steps**: 100+
- **Available Skills**: 42+

---

_Para ver todos los comandos disponibles: `npm run` (sin argumentos)_
