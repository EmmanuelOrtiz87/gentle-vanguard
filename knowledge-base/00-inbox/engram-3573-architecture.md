---
created: 2026-09-01 11:06:28
tags: [engram, architecture]
engram_id: 3573
type: architecture
---

# oc-keyring v1.0.1 — probe command + documentation expansion

## Release v1.0.1 (2026-09-01)

### What changed

- Added oc-keyring probe — direct API probe that distinguishes FreeUsageLimitError, GoUsageLimitError, CreditsError, ModelError. Replaces the need to interpret generic 'Provider error' from the OpenCode Desktop client.
- Added oc-keyring validate — shortcut to the existing validation script.
- Reorganized docs into docs/operations/oc-keyring/:
  - README.md (index, 60 lines)
  - guide.md (moved from docs/operations/oc-keyring-guide.md)
  - rchitecture.md (moved from docs/operations/oc-keyring-architecture.md)
  - changelog.md (moved + v1.0.1 entry)
  -  roubleshooting.md (NEW — common issues with solutions)
  - lternatives.md (NEW — workarounds for OpenCode rate limits / quotas)
  - usiness-context.md (NEW — business case + security posture)
  - incidents/2026-09-01-zen-free-rate-limit.md (NEW — post-mortem)
- ADR-0025-oc-keyring-multi-account-rotation.md (NEW) in docs/adr/

### Why

The 2026-09-01 rate-limit incident showed the user needed a way to diagnose
problems without going through the OpenCode Desktop client. The probe
command + the structured troubleshooting guide give them a 2-minute
diagnostic path.

### Key insight from the incident

OpenCode's free model rate limit is per-IP, not per-account. Rotating
accounts does NOT bypass it. This was the user's surprise and is
documented in business-context.md and the incident post-mortem.

### Impact

- oc-keyring config: 0 changes
- Stack impact: 0
- New dependencies: 0
- Backwards compatibility: 100% (additive commands only)
- Probe results in current state: shows 429 FreeUsageLimitError for Zen free
  models on both accounts, 401 CreditsError for paid Zen, 429 GoUsageLimitError
  for Go. This matches the OpenCode quota situation, not an oc-keyring bug.

---
*Imported from Engram on 2026-09-06*
