# Task Brief: foundation-session-hardening

## Goal

- Problem to solve: governance checks lacked owner policy enforcement and did not verify performance
  budget or fallback resiliency.
- Desired outcome: enforce script ownership review and validate both runtime SLO and graceful
  failure paths in the governance validator.

## Scope

- In scope: CODEOWNERS updates, validator SLO checks, negative fallback simulation, governance
  artifact and toolchain checks, local validation, and publication.
- Out of scope: introducing new governance levels or changing startup command contracts.

## Key Files

- Primary implementation files: `.github/CODEOWNERS`,
  `scripts/diagnostics/validate-script-governance.ps1`.
- Tests or validation files: `scripts/diagnostics/validate-script-governance.ps1`.
- Documentation files: `docs/sessions/2026-04-11-session-start.md`,
  `docs/reference/script-registry.md`.

## Acceptance Criteria

- [x] Behavior is implemented
- [x] Focused validation passes
- [x] Documentation updated if needed
- [x] Ready for audit and repository publication review

## Risks

- Technical risk: fallback simulation mutates a file name temporarily.
- Product or workflow risk: stricter ownership may increase PR latency.
- Rollback or fallback plan: revert CODEOWNERS and validator commit if blocker is detected.

## Status

- Current state: homologation + runtime compatibility hardening completed and ready for PR
  publication.
- Next concrete step: publish current commit via PR and monitor CI trend; strict mode can run with
  native runtime routing and no legacy tool dependency.

## Future Release Backlog

- [ ] Make runtime-router mandatory before every critical command execution (`review`, `audit`,
      `publish`, `end-session`, `day-end-closure`, `context-pack`, `compact-start`) and fail when no
      valid fallback route is available.
