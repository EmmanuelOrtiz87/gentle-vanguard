---
name: incident-response-skill
description: Incident detection, response, and recovery automation for Gentle-Vanguard
trigger: "incident", "alert", "response", "recovery", "emergency"
---

# Incident Response Skill

## Purpose

Automated incident detection, alerting, and recovery procedures for Gentle-Vanguard workspace.

## Capabilities

- Real-time monitoring via continuous-status-monitor.ps1
- Token budget alerts via token-guard
- Security breach detection via security-orchestrator
- Session failure recovery via manual-recovery.ps1
- Automated runbook execution

## Triggers

| Event                    | Action                             |
| ------------------------ | ---------------------------------- |
| Token threshold 80%      | Notify user, continue monitoring   |
| Token threshold 90%      | Alert, suggest context compression |
| Token threshold 95%      | Force compression, block new tasks |
| Auth failure >3 attempts | Lock for 15 minutes                |
| Security breach detected | Block operation, log, alert        |
| Session failure          | Trigger recovery procedures        |

## Runbooks

### Token Exhaustion

1. Run compression: `compact-memory.ps1`
2. Archive old sessions: `rotate-artifacts.ps1`
3. Suggest handoff to new session

### Auth Lockout

1. Verify identity via alternative method
2. Wait 15 minutes or admin override
3. Reset lockout in secure-auth.ps1

### Security Breach

1. Block operation immediately
2. Log incident to docs/security/incidents/
3. Alert via configured channels
4. Document in PRIVACY-DATA-REGIMEN.md

## Integration

- monitoring/continuous-status-monitor.ps1
- security/security-orchestrator.ps1
- token-guard configuration
- event bus for alerts

## Next Steps

Add more automated runbooks as incidents occur.
