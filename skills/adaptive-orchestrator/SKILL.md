---
name: adaptive-orchestrator
description: >
  Autonomous norm enforcement and learning system.
  Triggers: "enforce norms", "learn norms", "validate documentation placement",
  "check adaptive rules", "run norm enforcer", "update learned norms".
---

# Adaptive Orchestrator Skill (Full Stack)

Sistema autónomo COMPLETO que opera, aprende y se recupera sin intervención humana.

## Core Systems (5 Autonomous Layers)

### 1. Auto Norm Enforcer (`scripts/adaptive/auto-norm-enforcer.ps1`)
**Purpose**: Valida y aplica normativas autónomamente.

**Auto-trigger**: Session start/close
**What it does**: Crea directorios faltantes, aplica estándares, valida documentación.

### 2. Auto Norm Learner (`scripts/adaptive/auto-norm-learner.ps1`)
**Purpose**: Aprende normativas de experiencias y correcciones.

**Auto-trigger**: Session start/close
**What it does**: Consulta Engram, extrae patrones, promueve normas a `rules/custom/`.

### 3. Auto Backup Orchestrator (`scripts/adaptive/auto-backup-orchestrator.ps1`)
**Purpose**: Respaldo encriptado y recuperación autónoma.

**Auto-trigger**: Session start (restore if needed), Session close (backup)
**Security**: AES-256, clave derivada del stack, solo metadatos
**What it does**:
- Respalda Engram, normativas, estado de sesión (encriptado)
- Recupera automáticamente si hay falla
- `.backups/` en `.gitignore` (no expone datos sensibles)

### 4. Auto Doc-Drift Detector (`scripts/adaptive/auto-doc-drift-detector.ps1`)
**Purpose**: Detecta documentación desactualizada vs código.

**Auto-trigger**: Session close
**Security**: Solo metadatos (paths, timestamps), NO contenido de código/docs
**What it does**:
- Compara timestamps de código vs documentación
- Detecta funciones nuevas sin documentar
- Auto-delega actualización a subagente
- Aprende patrones: "código cambió, docs no"

### 5. Auto Testing Orchestrator (`scripts/adaptive/auto-testing-final.ps1`)
**Purpose**: Ejecución y auto-reparación de tests.

**Auto-trigger**: Session start/close (no-blocking)
**What it does**:
- Detecta tipo de proyecto (Node/Go/Python)
- Ejecuta tests automáticamente
- Auto-repara fallos via delegación
- Guarda resultados para **Judgment Day** (no es bloqueante para commits)

## Full Autonomous Flow

```
Session Event (Start/Close)
         │
         ▼
┌─────────────────────────────────┐
│  1. Auto Backup (restore if    │
│     session-start, backup if   │
│     session-close)              │
└───────────┬─────────────────────┘
            │
            ▼
┌─────────────────────────────────┐
│  2. Norm Enforcer             │
│     - Validate docs/           │
│     - Create missing dirs     │
└───────────┬─────────────────────┘
            │
            ▼
┌─────────────────────────────────┐
│  3. Norm Learner              │
│     - Query Engram            │
│     - Update norms            │
└───────────┬─────────────────────┘
            │
            ▼
┌─────────────────────────────────┐
│  4. Doc-Drift Detector       │
│     - Compare code vs docs   │
│     - Auto-delegate fixes    │
└───────────┬─────────────────────┘
            │
            ▼
┌─────────────────────────────────┐
│  5. Auto Testing (non-block) │
│     - Run tests              │
│     - Auto-repair          │
│     - Log for Judgment Day  │
└───────────┬─────────────────────┘
            │
            ▼
    ✅ Session Ready / Closed
```

## Integration with Commit Hooks (Non-blocking)

| Stage | System | Blocking? | Purpose |
|-------|--------|-----------|---------|
| **Pre-commit** | Hooks check-*.ps1 | ✅ YES | Validación rápida (seguridad, calidad) |
| **Session close** | 5 systems above | ❌ NO | Autonomía total, log para Judgment Day |
| **Judgment Day** | Adversarial review | ✅ YES | Revisión profunda antes de merge |

## Security Architecture

```
┌──────────────────────────────────────┐
│  All Backups: AES-256 Encrypted  │
│  Key: Derived from stack identity │
│  Storage: .backups/ (local)      │
│  Repo: .gitignore (no push)     │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Doc-Drift: Metadata Only        │
│  Logs: Paths, timestamps only    │
│  NO: Code content, doc content  │
└──────────────────────────────────────┘
```

## On-Demand Commands

| User Says | Action |
|-----------|--------|
| "run autonomous stack" | Ejecuta los 5 sistemas |
| "backup now" | `auto-backup-orchestrator.ps1 -Action backup` |
| "check drift" | `auto-doc-drift-detector.ps1 -Trigger manual` |
| "run tests autonomous" | `auto-testing-final.ps1 -Trigger manual` |
| "restore from backup" | `auto-backup-orchestrator.ps1 -Action restore` |

## Quick Test (Verify All Systems)

```powershell
cd C:\Workspace_local\workspace-foundation

# 1. Test backup
.\scripts\adaptive\auto-backup-orchestrator.ps1 -Action check -VerboseOutput

# 2. Test norm enforcer
.\scripts\adaptive\auto-norm-enforcer.ps1 -Trigger manual -AutoFix

# 3. Test norm learner
.\scripts\adaptive\auto-norm-learner.ps1 -Trigger manual

# 4. Test doc-drift
.\scripts\adaptive\auto-doc-drift-detector.ps1 -Trigger manual

# 5. Test auto-testing
.\scripts\adaptive\auto-testing-final.ps1 -Trigger manual
```

## Status: 99% Autonomous

✅ **Operación sin humanos**: Los 5 sistemas operan solos
✅ **Aprendizaje continuo**: Engram + normativas evolucionan
✅ **Seguridad**: Encriptación AES-256, sin exposición de código
✅ **Respaldo**: Recuperación automática ante fallos
✅ **Documentación siempre actualizada**: Doc-drift detector
⚠️ **Judgment Day**: Revisión profunda separada (no bloquea commits)

## Notes

- **Session boundaries**: Autonomía total (start/close)
- **Commits**: Hooks rápidos (seguridad, no bloqueantes para autonomía)
- **Judgment Day**: Ejecutar manualmente para revisión profunda
- **Escalation**: Solo si agota reintentos (3x) en auto-delegación
