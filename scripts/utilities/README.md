# Utility Scripts

Miscellaneous utility scripts for various tasks.

## Quick Commands

```powershell
# Full system diagnostics
.\scripts\utilities\wf.ps1 diagnose

# Quick verify + auto-repair
.\scripts\utilities\wf.ps1 verify

# Health check + tool activation
.\scripts\utilities\wf.ps1 health

# Close session with verification and closure artifact
.\scripts\utilities\wf.ps1 end-session

# Install/verify Engram CLI
.\scripts\utilities\wf.ps1 install-engram

# IDE detection and activation recommendation
.\scripts\utilities\wf.ps1 ide-status
```

## Scripts

| Script | Description |
|--------|-------------|
| `wf.ps1` | Main workflow CLI - run all commands from here |
| `system-diagnostics.ps1` | Full stack diagnostics engine (supports JSON output) |
| `auto-init-dev-environment.ps1` | Auto-detect and initialize dev environment |
| `ensure-tools-active.ps1` | Activate all development tools |
| `init-dev-stack.ps1` | Complete stack initialization (one-shot) |
| `deploy.ps1` | Deploy project |
| `clean-runtime.ps1` | Clean runtime data and cache |
| `generate-audit-report.ps1` | Generate audit report |
| `generate-session-audit.ps1` | Generate session audit |
| `generate-session-review.ps1` | Generate session review |
| `finalize-session.ps1` | Finalize development session |
| `run-engram.ps1` | Run Engram memory |
| `install-engram.ps1` | Install or verify Engram CLI |
| `detect-ide-session.ps1` | Detect IDE session and suggest activation command |
| `orchestrator-status.ps1` | Check orchestrator + Engram integration |
| `end-session.ps1` | Run end-of-session checks and generate delivery closure artifact |
| `stack-on-demand.ps1` | Activate/validate/deactivate orchestrator in on-demand mode |
| `token-efficiency-estimator.ps1` | Estimate token, time, and equivalent cost savings |
| `run-gga.ps1` | Run GGA code review |
| `create-pull-request.ps1` | Create pull request |
| `aggregate-metrics.ps1` | Aggregate metrics |
| `help.ps1` | Show help |
| `install-*.ps1` | Install various components |

## Auto-Repair & Detection

The stack includes automatic detection and repair for:

- Missing Engram CLI â†’ Auto-installed
- Missing config files â†’ Created from templates
- Inactive orchestrator â†’ Auto-activated
- Missing workspace environment â†’ Auto-initialized
- Degraded dependencies â†’ Auto-verified

## Usage Patterns

### New Project
```powershell
.\scripts\utilities\wf.ps1 init-stack
```

### After Git Checkout (Automatic)
```powershell
git checkout feature/new-feature
# post-checkout hook runs automatically
# â†’ system-diagnostics.ps1
# â†’ auto-init-dev-environment.ps1
```

### Manual Verification
```powershell
# Full diagnostics
.\scripts\utilities\wf.ps1 diagnose

# Quick verify + repair
.\scripts\utilities\wf.ps1 verify

# For JSON output (CI/CD)
.\scripts\utilities\wf.ps1 diagnose -JSON
```

## See Also

- [STACK-SETUP.md](../../docs/getting-started/STACK-SETUP.md) - Complete stack setup guide
- [../../hooks/post-checkout.ps1](../../hooks/post-checkout.ps1) - Auto-repair on git checkout

