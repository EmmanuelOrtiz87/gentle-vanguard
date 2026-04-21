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
| `judgment-day.ps1` | Orquesta juicio adversarial dual (review paralelo, síntesis, fix loop, escalado) |
| `invoke-judgment.ps1` | Ejecuta el proceso de juicio dual (actor/critic/fix) para un target dado |
# Juicio Adversarial (Judgment Day)

- `judgment-day.ps1` permite ejecutar el protocolo de juicio adversarial dual ("judgment day") bajo demanda, con passes iterativos, síntesis de resultados y escalado automático si no se logra convergencia.
- `invoke-judgment.ps1` implementa el flujo actor/critic/fix para un target dado.
- Ambos scripts están alineados con el skill `judgment-day` y el protocolo de sub-agentes documentado en `skills/judgment-day/SKILL.md`.

## Ejecución manual

```powershell
# Juicio adversarial completo sobre el workspace
.\scripts\utilities\judgment-day.ps1

# Juicio sobre un target específico, modo rápido, sin prompt interactivo
.\scripts\utilities\judgment-day.ps1 -Target "projects/mi-modulo" -Scope Quick -NoPrompt
```

## Protocolo y detalles

- El protocolo sigue el skill `judgment-day` (dual review, síntesis, fix, escalado)
- Documentación completa: `skills/judgment-day/SKILL.md` y `agent-teams-lite-main/docs/sub-agents.md`
- El resultado se muestra en consola y se puede auditar en `docs/judgment/` si está habilitado
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
| `create-pull-request.ps1` | Create pull request |
| `aggregate-metrics.ps1` | Aggregate metrics |
| `help.ps1` | Show help |
| `install-*.ps1` | Install various components |

## Auto-Repair & Detection

The stack includes automatic detection and repair for:

- Missing Engram CLI â†’ Auto-installed (required)
- Missing config files â†’ Created from templates
- Inactive orchestrator â†’ Auto-activated
- Missing workspace environment â†’ Auto-initialized
- Degraded dependencies â†’ Auto-verified
- Optional integrations missing (GGA/Gentle-AI/Gentleman-Skills) â†’ Warning only

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

