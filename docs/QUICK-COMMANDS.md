# Quick Commands — Gentle-Vanguard

```powershell
# Start session (Windows)
.\scripts\utilities\session-autostart.cmd
# Start session (Linux/macOS)
bash ./scripts/utilities/session-autostart.sh

# Check all quality gates
gv verify
# Show stack version + skills count
gv version
# Begin tracked session
gv start-session
# Full QA gate before release
gv judgment-day
# SDD preflight
.\scripts\utilities\sdd-preflight.ps1 -Interactive
# Check review workload before implementation
.\scripts\utilities\review-workload-guard.ps1
# Rebuild skill registry
.\scripts\utilities\build-skill-registry.ps1

# Context log
.\scripts\utilities\session-context-log.ps1 -Action status
.\scripts\utilities\session-context-log.ps1 -Action close
.\scripts\utilities\session-context-log.ps1 -Action close -PromoteToPermanent

# Open HTML metrics dashboard
gv dashboard
# SLO benchmark
gv benchmark
# Detect workspace drift
gv sync-drift
```
