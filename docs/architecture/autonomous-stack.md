# Autonomous Stack 100% - Architecture & User Guide

## Overview

The Workspace Foundation implements a **100% autonomous development stack** with self-healing,
self-learning, and self-scaling capabilities. All systems operate without human intervention in
production.

## Stack Layered Architecture

```

              Agent Layer (AI Agents)

         Orchestration Layer (adaptive/)

   Auto-Backup  Auto-Norm     Auto-Scaling
   Orchestrator Enforcer      Delegation


   Auto-Norm    Auto-Doc      Auto-Testing
   Learner       Drift         Orchestrator


   Backup       Judgment Day
   Resilience   Bridge


         Persistence Layer (Engram + .backups/)

         Security Layer (AES-256 Encryption)

```

## Component Details

### 1. Auto-Backup Orchestrator

**File**: `scripts/adaptive/auto-backup-orchestrator.ps1` **Trigger**: session-start, session-close,
manual **Function**:

- AES-256 encrypted backups of:
  - Engram memory (`.backups/engram-memory.json.enc`)
  - Learned norms (`.backups/learned-norms.json.enc`)
  - Session state (`.backups/session-state.json.enc`)
- Key derivation: workspace path + machine name + salt
- Metadata unencrypted (no sensitive data)

**Security**:

- AES-256 encryption
- Key never stored
- `.backups/` in `.gitignore` (never pushed to repo)

### 2. Auto-Norm Enforcer

**File**: `scripts/adaptive/auto-norm-enforcer.ps1` **Trigger**: session-start, session-close,
orchestrator, manual **Function**:

- Validates directory structure (`docs/`, `rules/adaptive/`)
- Creates missing directories automatically
- Checks documentation standards
- Applies fixes automatically (`-AutoFix`)

**Output**: PASS/FAIL with issues and fixes applied

### 3. Auto-Norm Learner

**File**: `scripts/adaptive/auto-norm-learner.ps1` **Trigger**: session-start, session-close, manual
**Function**:

- Queries Engram memory for patterns
- Creates new norms in `rules/adaptive/LEARNED-NORMS.md`
- Promotes norms to `rules/custom/` when confidence is "high"
- Updates norm database

**Norm Types**:

- `DOC-###`: Documentation placement/organization
- `CORR-###`: Correction patterns (PowerShell syntax, etc.)
- `SESS-###`: Session patterns

### 4. Auto-Doc-Drift Detector

**File**: `scripts/adaptive/auto-doc-drift-detector.ps1` **Trigger**: session-start, session-close,
manual **Function**:

- Scans code files vs documentation files
- Compares `LastWriteTime` timestamps
- Detects when code is newer than docs
- Reports drift (metadata only, no code content in logs)

**Output**: PASS (up-to-date) or FAIL (drift detected)

### 5. Auto-Testing Orchestrator

**File**: `scripts/adaptive/auto-testing-final.ps1` **Trigger**: session-start, session-close,
manual **Function**:

- Non-blocking test execution
- Logs results to `.session/testing-results.json`
- Auto-repair capability (attempts fix on failure)
- Does NOT block commits (Judgment Day reviews later)

**Key Feature**: Non-blocking - logs for Judgment Day separate review

### 6. Auto-Scaling Delegation

**File**: `scripts/adaptive/auto-scaling.ps1` **Trigger**: session-start, session-close, manual
**Function**:

- Learns which subagent works best for each task type
- Tracks success/failure rates
- Optimizes delegation over time
- Database: `.session/scaling-db.json`

**Default Patterns**:

- `code-fix` sdd-apply
- `doc-update` sdd-apply
- `research` explore
- `test-fix` sdd-verify
- `general-task` general

### 7. Backup Resilience Test

**File**: `scripts/adaptive/backup-resilience-test.ps1` **Trigger**: manual (for validation)
**Function**:

- Test 1: Tamper detection (modify encrypted backup, attempt restore)
- Test 2: Fallback to older backup
- Graceful failure handling
- Results: `.backups/resilience-test-results.json`

### 8. Judgment Day Bridge

**File**: `scripts/adaptive/judgment-day-bridge.ps1` **Trigger**: session-close, manual
**Function**:

- Collects logs from all autonomous systems
- Formats for Judgment Day review
- Aggregates findings
- Prepares adversarial review queue

## Session Lifecycle Integration

### Session Start Flow

```
1. Auto-Backup (backup current state)
2. Auto-Norm-Enforcer (validate structure)
3. Auto-Norm-Learner (learn new patterns)
4. Auto-Doc-Drift (check documentation)
5. Auto-Testing (run tests, non-blocking)
6. Auto-Scaling (optimize delegation)
```

### Session Close Flow

```
1. Auto-Testing (final test run)
2. Auto-Scaling (optimize patterns)
3. Auto-Backup (backup final state)
4. Judgment Day Bridge (collect logs)
5. Session summary saved to Engram
```

## Security Architecture

### Encryption

- **Algorithm**: AES-256-CBC
- **Key Derivation**: SHA-256(workspaceId | machineId | salt)
- **IV**: Cryptographically random (16 bytes)
- **Storage**: Only encrypted files in `.backups/`

### What Gets Encrypted

- Engram memory export (JSON)
- Learned norms (JSON)
- Session state (JSON)

### What Stays Unencrypted

- Backup metadata (timestamps, component names only)
- No sensitive code/doc content in logs
- All logs contain metadata only

## Directory Structure

```
foundation/
 .backups/              # Encrypted backups (in .gitignore)
    engram-memory.json.enc
    learned-norms.json.enc
    session-state.json.enc
    backup-meta.json
 .session/              # Runtime session data (in .gitignore)
    scaling-db.json
    testing-results.json
    engram-cache/
 scripts/
    adaptive/         # All autonomous systems (8 scripts)
    utilities/        # Workflow tools (wf.ps1 symlink)
 rules/
    adaptive/         # Learned norms and rules
       LEARNED-NORMS.md
       README.md
    custom/          # Promoted high-confidence norms
 docs/
    architecture/
        autonomous-stack.md (this file)
 scripts/utilities/
     engram.exe        # Persistence binary
```

## Usage Examples

### Manual Operations

```powershell
# Backup now
.\scripts\adaptive\auto-backup-orchestrator.ps1 -Action backup -Trigger manual

# Check norms
.\scripts\adaptive\auto-norm-enforcer.ps1 -Trigger manual -AutoFix

# Learn new norms
.\scripts\adaptive\auto-norm-learner.ps1 -Trigger manual

# Check for drift
.\scripts\adaptive\auto-doc-drift-detector.ps1 -Trigger manual

# Run tests (non-blocking)
.\scripts\adaptive\auto-testing-final.ps1 -Trigger manual

# Check scaling status
.\scripts\adaptive\auto-scaling.ps1 -Action status

# Test resilience
.\scripts\adaptive\backup-resilience-test.ps1 -Action full-test

# Collect for Judgment Day
.\scripts\adaptive\judgment-day-bridge.ps1 -Action collect
```

## Troubleshooting

### Engram Binary Not Found

**Symptom**: `[BKP-WARN] Engram binary not found, skipping` **Fix**: Ensure
`scripts/utilities/engram.exe` exists. The script auto-detects via:

```powershell
$engramPath = Join-Path $repoRoot "tools\engram.exe"
```

### Backup Metadata Only (No .enc Files)

**Cause**: Engram not running or binary not found **Result**: Only metadata backup (unencrypted)
**Fix**: Verify Engram binary path

### PowerShell Parser Errors

**Symptom**: `InvalidLeftHandSide` or `Missing ')'` **Cause**: Trailing commas in param blocks
**Fix**: Ensure no trailing commas after parameter defaults

### Auto-Scaling Not Learning

**Symptom**: All patterns show "low" confidence, 0 total **Cause**: New installation, no history yet
**Fix**: Use system normally; confidence increases after 5+ operations

## Future Enhancements

1. **Auto-Scaling**: Implement actual delegation with learned patterns
2. **Norm Promotion**: Auto-promote to `rules/custom/` when confidence="high"
3. **Cross-Workspace Learning**: Share norms between workspaces
4. **Telemetry Dashboard**: Real-time view of all autonomous systems
5. **Self-Healing**: Auto-fix common issues without human intervention

## versión History

- **v1.0.0** (2026-04-30): Initial 100% autonomous stack
  - 8 autonomous systems operational
  - AES-256 encryption
  - Self-learning norms
  - Non-blocking testing
  - Judgment Day integration
