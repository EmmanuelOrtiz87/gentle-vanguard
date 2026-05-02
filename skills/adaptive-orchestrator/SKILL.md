---
name: adaptive-orchestrator
description: >
  Autonomous norm enforcement and learning system.
  Triggers: "enforce norms", "learn norms", "validate documentation placement",
  "check adaptive rules", "run norm enforcer", "update learned norms".
---

# Adaptive Orchestrator Skill (Full Stack)

sistema autnomo COMPLETO que opera, aprende y se recupera sin intervencin humana.

## Core Systems (5 Autonomous Layers)

### 1. Auto Norm Enforcer (`scripts/adaptive/auto-norm-enforcer.ps1`)
**Purpose**: Valida y aplica normativas autnomamente.

**Auto-trigger**: Session start/close
**What it does**: Crea directorios faltantes, aplica estndares, valida documentacin.

### 2. Auto Norm Learner (`scripts/adaptive/auto-norm-learner.ps1`)
**Purpose**: Aprende normativas de experiencias y correcciónes.

**Auto-trigger**: Session start/close
**What it does**: Consulta Engram, extrae patrones, promueve normas a `rules/custom/`.

### 3. Auto Backup Orchestrator (`scripts/adaptive/auto-backup-orchestrator.ps1`)
**Purpose**: Respaldo encriptado y recuperacin autnoma.

**Auto-trigger**: Session start (restore if needed), Session close (backup)
**Security**: AES-256, clave derivada del stack, solo metadatos
**What it does**:
- Respalda Engram, normativas, estado de sesin (encriptado)
- Recupera automticamente si hay falla
- `.backups/` en `.gitignore` (no expone datos sensibles)

### 4. Auto Doc-Drift Detector (`scripts/adaptive/auto-doc-drift-detector.ps1`)
**Purpose**: Detecta documentacin desactualizada vs cdigo.

**Auto-trigger**: Session close
**Security**: Solo metadatos (paths, timestamps), NO contenido de cdigo/docs
**What it does**:
- Compara timestamps de cdigo vs documentacin
- Detecta funciones nuevas sin documentar
- Auto-delega actualizacin a subagente
- Aprende patrones: "cdigo cambi, docs no"

### 5. Auto Testing Orchestrator (`scripts/adaptive/auto-testing-final.ps1`)
**Purpose**: Ejecucin y auto-reparacin de tests.

**Auto-trigger**: Session start/close (no-blocking)
**What it does**:
- Detecta tipo de proyecto (Node/Go/Python)
- Ejecuta tests automticamente
- Auto-repara fallos via delegacin
- Guarda resultados para **Judgment Day** (no es bloqueante para commits)

## Full Autonomous Flow

```
Session Event (Start/Close)
         
         

  1. Auto Backup (restore if    
     session-start, backup if   
     session-close)              

            
            

  2. Norm Enforcer             
     - Validate docs/           
     - Create missing dirs     

            
            

  3. Norm Learner              
     - Query Engram            
     - Update norms            

            
            

  4. Doc-Drift Detector       
     - Compare code vs docs   
     - Auto-delegate fixes    

            
            

  5. Auto Testing (non-block) 
     - Run tests              
     - Auto-repair          
     - Log for Judgment Day  

            
            
     Session Ready / Closed
```

## Integration with Commit Hooks (Non-blocking)

| Stage | System | Blocking? | Purpose |
|-------|--------|-----------|---------|
| **Pre-commit** | Hooks check-*.ps1 |  YES | Validacin rpida (seguridad, calidad) |
| **Session close** | 5 systems above |  NO | Autonoma total, log para Judgment Day |
| **Judgment Day** | Adversarial review |  YES | revisión profunda antes de merge |

## Security Architecture

```

  All Backups: AES-256 Encrypted  
  Key: Derived from stack identity 
  Storage: .backups/ (local)      
  Repo: .gitignore (no push)     



  Doc-Drift: Metadata Only        
  Logs: Paths, timestamps only    
  NO: Code content, doc content  

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

 **Operacin sin humanos**: Los 5 sistemas operan solos
 **Aprendizaje continuo**: Engram + normativas evolucionan
 **Seguridad**: Encriptacin AES-256, sin exposicin de cdigo
 **Respaldo**: Recuperacin automtica ante fallos
 **Documentacin siempre actualizada**: Doc-drift detector
 **Judgment Day**: revisión profunda separada (no bloquea commits)

## Notes

- **Session boundaries**: Autonoma total (start/close)
- **Commits**: Hooks rpidos (seguridad, no bloqueantes para autonoma)
- **Judgment Day**: Ejecutar manualmente para revisión profunda
- **Escalation**: Solo si agota reintentos (3x) en auto-delegacin


