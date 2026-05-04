# Scripts Utilities - Main Directory

Centralized collection of utility scripts organized by functionality for workspace foundation.

**Version**: 3.0.0  
**Last updated**: 2026-05-04  
**Status**: PRODUCTION

---

## Directory Structure

```
scripts/utilities/
 README.md                          # This file
 AI-AGENT-MANAGEMENT/               # AI agent management and routing
 AUDIT-REPORTING/                   # Audit and reporting
 CONFIG/                            # Configuration and profiles
 DEPLOYMENT/                        # Deployment scripts
 WORKSPACE-SKILLS/                  # Specialized skills
 GIT-VERSION-CONTROL/               # Git version control
 PERFORMANCE-OPTIMIZATION/          # Performance optimization
 SESSION-MANAGEMENT/                # Session management
 SKILLS-scripts/utilities/                      # Skill tools
 TELEMETRY-METRICS/                 # Telemetry and metrics
 UTILITIES/                         # General utilities
 WORKFLOW-ORCHESTRATION/            # Workflow orchestration
```

---

## Directories by Functionality

### 1. **AI-AGENT-MANAGEMENT/**
AI agent management and routing.

**Main scripts:**
- `agent-router.ps1` - Central agent router (BA, SAD, DEV, QA, OPS, GOV, DOC)
- `invoke-ai-review.ps1` - Invoke AI review
- `invoke-cloud-agent.ps1` - Invoke cloud agents
- `invoke-judgment.ps1` - Invoke dual judgment process
- `judgment-day.ps1` - Complete adversarial judgment protocol
- `sync-agent-instructions.ps1` - Sync agent instructions

**Typical usage:**
```powershell
.\scripts\utilities\AI-AGENT-MANAGEMENT\agent-router.ps1 -Agent DEV -Task "implement feature"
```

[View full documentation](./AI-AGENT-MANAGEMENT/README.md)

---

### 2. **AUDIT-REPORTING/**
Audit, reporting, and session artifacts.

**Main scripts:**
- `audit-script-normalization.ps1` - Normalize scripts for audit
- `context-metrics-report.ps1` - Context metrics report
- `generate-audit-report.ps1` - Generate audit report
- `generate-session-artifacts.ps1` - Generate session artifacts
- `generate-session-audit.ps1` - Session audit
- `generate-session-review.ps1` - Session review

**Typical usage:**
```powershell
.\scripts\utilities\AUDIT-REPORTING\generate-audit-report.ps1
```

[View full documentation](./AUDIT-REPORTING/README.md)

---

### 3. **CONFIG/**
Configuration, profiles, and config files.

**Main files:**
- `context-efficiency-config.json` - Context efficiency configuration
- `session-autostart.config.json` - Session autostart configuration
- `Microsoft.PowerShell_profile.ps1` - PowerShell profile

**Usage:** Centralized configuration for the entire workspace.

[View full documentation](./CONFIG/README.md)

---

### 4. **DEPLOYMENT/**
Deployment, migration, and remote configuration scripts.

**Main scripts:**
- `deploy.ps1` - Main deployment
- `migrate-structure.ps1` - Structure migration
- `setup-monitoring.ps1` - Monitoring setup
- `setup-remote-agent.ps1` - Remote agent setup
- `setup-wizard.ps1` - Setup wizard

**Typical usage:**
```powershell
.\scripts\utilities\DEPLOYMENT\deploy.ps1
```

[View full documentation](./DEPLOYMENT/README.md)

---

### 5. **GIT-VERSION-CONTROL/**
Git version control, branches, and pull requests.

**Main scripts:**
- `create-gitflow-branch.ps1` - Create gitflow branch
- `create-pull-request.ps1` - Create pull request
- `generate-pr-artifacts.ps1` - Generate PR artifacts

**Typical usage:**
```powershell
.\scripts\utilities\GIT-VERSION-CONTROL\create-gitflow-branch.ps1 -Type feature -Name "new-feature"
```

[View full documentation](./GIT-VERSION-CONTROL/README.md)

---

### 6. **PERFORMANCE-OPTIMIZATION/**
Performance optimization, memory compaction, and Engram.

**Main scripts:**
- `clean-runtime.ps1` - Clean runtime
- `compact-memory.ps1` - Compact memory
- `compact-start.ps1` - Start with compaction
- `optimize-engram-usage.ps1` - Optimize Engram usage
- `optimize-performance.ps1` - Optimize general performance
- `pre-compact-hook.ps1` - Pre-compaction hook

**Typical usage:**
```powershell
.\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-performance.ps1
```

[View full documentation](./PERFORMANCE-OPTIMIZATION/README.md)

---

### 7. **SESSION-MANAGEMENT/**
Session management, start, end, and monitoring.

**Main scripts:**
- `start-session.ps1` - Start session
- `end-session.ps1` - End session
- `finalize-session.ps1` - Finalize session with artifacts
- `session-manager.ps1` - Session manager
- `session-idle-monitor.ps1` - Idle monitor
- `validate-session-stack.ps1` - Validate session stack
- `session-autostart.cmd` - Session autostart (Windows)
- `session-manual-start.cmd` - Manual start (Windows)
- `session-manual-end.cmd` - Manual end (Windows)

**Typical usage:**
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\start-session.ps1
.\scripts\utilities\SESSION-MANAGEMENT\end-session.ps1
```

[View full documentation](./SESSION-MANAGEMENT/README.md)

---

### 8. **SKILLS-scripts/utilities/**
Installation and management of skills and tools.

**Main scripts:**
- `create-skill.ps1` - Create new skill
- `ensure-tools-active.ps1` - Ensure tools are active
- `install-architecture-governance-skill.ps1` - Install architecture governance skill
- `install-documentation-governance-skill.ps1` - Install documentation governance skill
- `install-engram.ps1` - Install Engram
- `install-workspace-skills.ps1` - Install workspace skills
- `skills-discovery.ps1` - Discover available skills
- `update-tools.ps1` - Update tools

**Typical usage:**
```powershell
.\scripts\utilities\SKILLS-TOOLS\install-workspace-skills.ps1
```

[View full documentation](./SKILLS-scripts/utilities/README.md)

---

### 9. **TELEMETRY-METRICS/**
Telemetry, metrics, and token budget.

**Main scripts:**
- `agent-usage-metrics.ps1` - Agent usage metrics
- `aggregate-metrics.ps1` - Aggregate metrics
- `consolidate-telemetry.ps1` - Consolidate telemetry
- `token-budget-guard.ps1` - Token budget guard
- `token-efficiency-estimator.ps1` - Token efficiency estimator
- `token-telemetry-report.ps1` - Token telemetry report
- `token-telemetry.ps1` - Token telemetry
- `extract-engram-json.ps1` - Extract Engram JSON
- `generate-management-report.ps1` - Generate monthly report in CSV
- `generate-management-report-simple.ps1` - Simplified version
- `validate-report.ps1` - Validate reports
- `validate-report-simple.ps1` - Simplified version

**Typical usage:**
```powershell
.\scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1
```

[View full documentation](./TELEMETRY-METRICS/README.md)

---

### 10. **UTILITIES/**
General utilities and general-purpose tools.

**Main scripts:**
- `auto-init-dev-environment.ps1` - Auto-initialize dev environment
- `context-pack.ps1` - Pack context
- `day-end-closure.ps1` - Day-end closure
- `detect-ide-session.ps1` - Detect IDE session
- `enforce-response-mode.ps1` - Enforce response mode
- `export-backlog-csv.ps1` - Export backlog to CSV
- `foundation-sync.ps1` - Sync foundation
- `handoff-compress.ps1` - Compress handoff
- `help.ps1` - Help
- `manage-backlog.ps1` - Manage backlog
- `manual-recovery.ps1` - Manual recovery
- `mcp-monitor.ps1` - MCP monitor
- `read-once-guard.ps1` - Read-once guard
- `response-mode.ps1` - Response mode
- `rotate-artifacts.ps1` - Rotate artifacts
- `run-engram.ps1` - Run Engram
- `simplify-text.ps1` - Simplify text
- `stack-dashboard.ps1` - Stack dashboard
- `stack-on-demand.ps1` - Stack on demand

**Typical usage:**
```powershell
.\scripts\utilities\UTILITIES\auto-init-dev-environment.ps1
```

[View full documentation](./UTILITIES/README.md)

---

### 11. **WORKFLOW-ORCHESTRATION/**
Workflow orchestration and runtime routing.

**Main scripts:**
- `dispatch-agent.ps1` - Dispatch agent
- `event-bus.ps1` - Event bus
- `orchestrator-next-steps.ps1` - Orchestrator next steps
- `orchestrator-status.ps1` - Orchestrator status
- `runtime-router.ps1` - Runtime router
- `wf-audit.ps1` - Workflow audit
- `wf.ps1` - Main workflow CLI
- `wf.sh` - Workflow CLI (Bash)

**Typical usage:**
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 diagnose
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 verify
```

[View full documentation](./WORKFLOW-ORCHESTRATION/README.md)

---

## Quick Start

### Start Session
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\start-session.ps1
```

### Run Full Diagnostics
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 diagnose
```

### End Session
```powershell
.\scripts\utilities\SESSION-MANAGEMENT\end-session.ps1
```

### Install Tools
```powershell
.\scripts\utilities\SKILLS-TOOLS\install-workspace-skills.ps1
```

---

## Requirements

- **PowerShell**: 7.0+
- **.NET**: 6.0+
- **Git**: 2.40+
- **Engram**: (automatically installed if needed)

---

## Security

- All scripts validate input
- Robust error handling
- Automatic logging
- Full audit available

---

## File Structure per Directory

Each subdirectory contains:
- `README.md` - Directory-specific documentation
- `.ps1` scripts - Implementation
- Configuration files (if applicable)

---

## Troubleshooting

### Issue: Script not executing
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Permissions denied
```powershell
# Run as administrator
Start-Process powershell -Verb RunAs
```

### Issue: Missing modules
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

---

## Related Documentation

- [scripts/README.md](../README.md) - Main scripts documentation
- [docs/getting-started/STACK-SETUP.md](../../docs/getting-started/STACK-SETUP.md) - Setup guide
- [skills/SKILL_INDEX.md](../../skills/SKILL_INDEX.md) - Skills index

---

## Notes

- All scripts are platform-agnostic
- Compatible with PowerShell 7+
- Automatic logging in `logs/`
- Complete inline documentation in each script

---

**Last updated**: 2026-05-04  
**Version**: 3.0.0  
**Status**: PRODUCTION
