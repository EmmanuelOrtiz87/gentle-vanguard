# Stack End-to-End Audit

**Date:** 2026-08-24  
**Scope:** operational health, integration, architecture, security, documentation, repository hygiene, scalability, stability, and token telemetry.

## Executive Verdict

**Current state: operationally healthy, not approved for production exposure.**

The runtime is active and coherent enough for local development and controlled use. Watchtower reports **94 PASS, 2 WARN, 0 FAIL**; the database is intact; the dashboard builds; and the full test runner passes. However, the audit confirmed security and scale risks that prevent a professional production-readiness claim, especially around dashboard authentication, tenant authorization, resource limits, arbitrary MCP command execution, and operational-source fragmentation.

## Validation Evidence

| Check | Result |
|---|---|
| Watchtower health | 94 pass, 2 warnings, 0 failures / 96 checks |
| Database health | Healthy, 23 tables, 52,079 rows, 8 migrations, integrity OK |
| Full tests | 5 suites passed, 0 failed; 402 tests, 399 passed in the unit aggregate |
| TypeScript | `npm run typecheck` passed |
| ESLint | `npm run lint` passed with zero warnings |
| Workflow lint | 21 workflow files passed |
| Dashboard build | Vite/TypeScript build passed; 15.82 s |
| Quick coverage | 78.29% statements, 64.28% branches, 85.18% functions |
| Dependency audit | `npm audit` could not run: repository has no npm lockfile; CI uses pnpm |
| Secret scan | 23 matches: 10 high, 2 medium, 11 low; examples/fixtures require classification |

Warnings observed: skill embeddings are stale by about 51.8 hours; Gemini 3.6 Flash provider health is unhealthy. The active model is `opencode-go/gpt-5.6-luna`.

## Changes Applied

- Made process-lock creation exclusive (`openSync(..., 'wx')`) to prevent concurrent duplicate daemons.
- Made `runNpxTsx` resolve the loader as a file URL, preserving hidden direct-child execution even when the child working directory is outside the repository.
- Fixed MCP gateway argument passing and failure propagation; actions no longer report success for an invalid command invocation.
- Added WebSocket handshake authorization when `GV_DASHBOARD_TOKEN` is configured, including browser-compatible query-token support.
- Fixed `skill_usage` housekeeping to use the actual `sessions.id` column and made pruning transactional.
- Made workflow lint accept a directory and enumerate YAML workflows, fixing the validation command used in this audit.
- Repaired confirmed documentation references in public README, knowledge-base skills, guides, governance configuration, and setup checklist.

## Confirmed Risks and Priorities

### P0: block production exposure

1. Dashboard authentication still fails open when `GV_DASHBOARD_TOKEN` is absent. Production deployment manifests do not require a secret. Make production startup fail closed and separate development mode explicitly.
2. Tenant isolation is advisory. Query-string tenant IDs are not bound to authenticated identity and most metrics remain global. Add authenticated tenant context, explicit tenant columns/foreign keys, and negative cross-tenant tests.
3. Generic MCP skill execution can pass skill-provided shell commands to `runSyncShell`. Enforce signed/approved skills, executable allowlists, sandboxing, least privilege, and human approval for side effects.

### P1: remediate before scale testing

1. Add centralized HTTP body limits, request timeouts, WebSocket message limits, slow-client eviction, and `bufferedAmount` backpressure handling.
2. Replace synchronous request-path filesystem, SQLite, and subprocess operations with queued/asynchronous work where practical.
3. Replace advisory multi-process locks with lease/heartbeat ownership and verify Windows PID identity, not merely command success.
4. Reduce startup fan-out and serialize shared SQLite/runtime resources.
5. Make circuit breakers cancellation-aware and state updates atomic across concurrent callers.

### P2: reliability and maintainability

1. Replace simulated resilience health checks (`Math.random`) with dependency-specific readiness probes and failure-injection tests.
2. Set SQLite busy timeout, serialize migrations, use transactional migrations, and test backup/restore drills.
3. Consolidate SQLite and filesystem artifacts into a documented source-of-truth model with retention and consistency guarantees.
4. Add dashboard server integration and E2E coverage for auth, WebSocket reconnect, MCP actions, tenancy, persistence, and overload behavior.
5. Pin all CI actions and scanner/tool versions consistently; standardize pnpm versions between CI and Docker.
6. Classify or replace realistic secret-like examples in public skills and test fixtures; narrow scanner ignores.

## Documentation and Hygiene

Confirmed drift remains: live documents advertise versions 3.5.0, 3.8.0, 3.8.2, 4.0.0, and 8.0.1; obsolete PowerShell commands remain in active guidance; several historical reports are presented alongside current status; and generated reports/runtime state are mixed into repository-adjacent operational areas. Establish one canonical version/status source, label historical artifacts, add broken-link CI, and define generated-artifact retention.

The worktree also contains pre-existing or autostart-generated changes in token assets, session summaries, optimization reports, and untracked `.test-results/`. These were not deleted because ownership and retention policy are not yet explicit.

## Token and Context Report

- Current session reported by `token:status`: **6 input, 69 output, 75 total tokens**; session budget **75 / 3,000,000**.
- Daily aggregate reported: **11,183,125 / 5,000,000**, **224%**, remaining 0. This is historical/shared telemetry, not consumption attributable solely to this request.
- Compression telemetry: **754,339 tokens saved**, 98%, from 768,731 to 14,392 in the latest compaction event.
- Trace sources active: opencode, zcode, codex, and minimax. Claude and Cursor were absent.
- Trace report today: orchestrator 334 transactions, subagent 90 transactions, cache savings 52,677,110 tokens, compression savings 8,057 tokens.
- The telemetry pipeline is integrated and active, but aggregate units and cost normalization should be reconciled before using the daily budget as a financial or capacity-control decision.

## Decision

Use the stack for local and controlled internal operation. Do not expose the dashboard or generic MCP execution to untrusted networks/users until the P0 controls are implemented and verified with integration tests. The next engineering tranche should be security boundary hardening, followed by overload/load testing and documentation/version consolidation.

## Follow-up Tranche 1

Since the initial audit, the following controls have been implemented and verified:

- Dashboard auth now uses opaque HttpOnly cookie sessions with TTL, constant-time bootstrap-token comparison, fail-closed protected routes, explicit localhost-only development bypass, and authenticated WebSocket handshakes.
- MCP command execution now requires an explicit policy entry; raw skill frontmatter is not executed and the default policy denies command execution.
- Dashboard request bodies and WebSocket payloads are bounded; server/request timeouts and basic slow-client backpressure handling are active.
- Process locks are atomically created; SQLite busy timeout, transactional/serialized migrations, and post-commit vacuum behavior are active.
- Circuit-breaker timers, cancellation, half-open reservation, and health-check socket cleanup were hardened.
- A canonical current status document was added and additional broken/stale live documentation references were corrected.

Verification after this tranche: root tests, dashboard tests (52/52), typecheck, lint, workflow lint, dashboard build, targeted security/MCP/SQLite/circuit-breaker tests, and content validation pass. Remaining blockers are authenticated tenant identity/data isolation, production secret enforcement in deployment manifests, stronger MCP sandboxing for approved commands, comprehensive HTTP/WS integration tests, and cleanup/reconciliation of generated artifacts and token accounting.

## Follow-up Tranche 2

- Added explicit MCP execution policy files and tests; command-bearing skills are denied unless an exact approved policy exists. The default policy has no approvals.
- Added bounded dashboard JSON bodies, WebSocket payload limits, safe-send backpressure checks, and HTTP/socket timeouts.
- Added SQLite busy-timeout configuration, serialized transactional migrations, and post-commit vacuum handling.
- Hardened circuit-breaker cancellation, timeout cleanup, half-open slot reservation, and health-check socket cleanup.
- Added `docs/status/CANONICAL-STATUS.md` and corrected additional live documentation links/version references.

The production decision remains unchanged: these controls materially improve local stability and reduce accidental execution/resource exhaustion, but tenant identity/data isolation, deployment secret enforcement, full sandboxing, and end-to-end authorization tests remain required before external exposure.

## Follow-up Tranche 3

- Added a validated deployment tenant context. Production now requires `GENTLE_TENANT_ID` to be present in the tenant registry; mismatched dashboard selectors are rejected and the UI no longer offers an implicit global “All Tenants” view.
- Added focused tenant-boundary unit/E2E coverage and dashboard security E2E coverage for login, logout, cookie sessions, and WebSocket rejection/acceptance.
- Hardened Kubernetes manifests with an explicit namespace, secret references for dashboard tokens, required PVC declarations, readiness/liveness probes, resource limits, restricted capabilities, seccomp defaults, and the correct `WS_PORT`.
- Added `.env.example` guidance for production token and tenant configuration.

This is a deployment-scoped boundary, not row-level multi-tenancy. Tables and filesystem artifacts that lack tenant provenance remain system-wide and must not be represented as isolated tenant data until the planned schema migration and repository query conversion are complete. Kubernetes images still require release digest promotion, and MCP commands remain disabled by default until an OS/container sandbox is available.

## Follow-up Tranche 4

- Added migrations 009 and 010: tenant registry/ownership tables, default-tenant backfill for metric snapshots/sessions/events, tenant indexes, and persistent dashboard auth-session storage.
- Converted the first repository slice (metrics, sessions, events) to exact `tenant_id = ?` reads/writes and added isolation tests.
- Added a restricted MCP execution worker using `shell: false`, argv-only execution, minimal environment, isolated temporary workspace, output/timeout limits, and fail-closed behavior for network or broad filesystem access. The policy remains empty by default.
- Corrected the persistent auth repository to use the table created by migration 010; this was verified through login restart, expiry, revocation, and migration tests.
- Attempted the embedding refresh; the command began a full rebuild, but the watchtower result must be rechecked before considering the warning resolved.

Current boundary: the first tenant slice is real and tested, but traces, token usage, alerts, feedback, backlog, routing, filesystem artifacts, and other unscoped data remain system-wide. The next safe step is staged repository conversion with provenance tests, not a blanket claim of complete multi-tenancy.

## Follow-up Tranche 5

- Added the first row-level tenant migration slice: tenants, principals/memberships, tenant columns and indexes for metric snapshots, sessions, and events, with default-tenant backfill.
- Added persistent SQLite-backed dashboard auth sessions and verified restart, expiry, and revocation behavior.
- Added restricted MCP worker execution with argv-only spawning, no shell, minimal environment, isolated temporary workspace, output/time limits, and bounded Windows cleanup retries.
- Fixed the integration mismatch between the auth-session repository and migration table name.
- Current DB status: 27 tables, 53,163 rows, 10 migrations, integrity OK.

The full-suite run exposed one transient MCP worker cleanup failure on Windows; the retry fix passes the focused 7/7 MCP tests. A final full-suite run is required after this change before release approval.

## Follow-up Tranche 6

- Added migration 011 for traces, token usage/transactions, alerts, feedback, and response cache with tenant backfill and indexes.
- Converted the corresponding observability repository reads/writes to tenant-scoped equality queries and added cross-tenant isolation tests.
- Fixed embedding refresh path and native format parsing; watchtower now reports **96/96 PASS, 0 WARN, 0 FAIL**.
- Added CI static gates for production tenant/auth configuration, mutable Kubernetes images, and tracked generated artifacts. Normal mode warns on mutable images; strict mode blocks them without fabricating digests.
- Added a Kubernetes deployment README and wired the static gate into CI.
- Optimized SQLite with checkpoint/reindex/vacuum; integrity remains OK.
- Reconciled a Windows EBUSY cleanup failure in MCP worker tests; focused tests pass.

Remaining external-boundary work: backlog/routing/skill usage and filesystem provenance, real registry image digests/signing, cluster-specific NetworkPolicy, and enabling OS/container MCP sandboxing. These cannot be safely completed from the local repository without ownership semantics, registry coordinates, CNI/topology, and a supported isolation runtime.

## Follow-up Tranche 7

- Completed the observability tenant conversion and migration 011 for traces, token usage/transactions, alerts, feedback, and response cache.
- Refreshed native skill embeddings successfully; watchtower now reports **96/96 PASS, 0 WARN, 0 FAIL**.
- Added CI static gates for mutable images, production tenant/auth configuration, and tracked generated artifacts; current normal gate reports three mutable images as warnings and no tracked generated artifacts.
- Optimized SQLite WAL/checkpoint/reindex/vacuum. Transient WAL growth can occur while tests or ingest writers are active; integrity remains OK.
- Fixed the static-gate unsafe regex so root lint is green.

The remaining work is now limited to boundaries that need external deployment facts or product ownership policy: filesystem provenance, backlog/routing/skill usage scoping, release registry digests/signing, cluster CNI-specific NetworkPolicy, and an actual OS/container sandbox for MCP.

## Follow-up Tranche 8

- Added migration 012 for tenant-scoped backlog ownership, routing rules, and skill usage, including tenant-aware uniqueness/indexes and cross-tenant tests.
- Added migration 013 for tenant-aware token transaction uniqueness and introduced `TokenRepo`; ingestion now uses migration-owned schema rather than creating tables ad hoc.
- Routed dashboard feedback through the tenant-aware SQLite repository while retaining historical compatibility exports without deleting data.
- Added filesystem source classification: unprovenanced legacy files are labeled system-wide and cannot be represented as tenant-owned data without explicit provenance.
- Added deployment prerequisite validation for image digests, NetworkPolicy/CNI evidence, and MCP sandbox evidence; missing external inputs fail the promotion validation.
- Fixed the final dashboard build type errors and corrected a transient MCP cleanup test issue.

Final local checks: root tests 5/5, dashboard tests 52/52, typecheck, lint, dashboard build, database health, and watchtower **96/96 PASS**. Promotion validation intentionally remains blocked by missing real registry digests, cluster NetworkPolicy evidence, and an external OS/container sandbox provider.

## Follow-up Tranche 9

- Refactored the backlog CLI to use the tenant-aware `BacklogRepo`; removed its stale `src/manage-backlog.ts` synchronization reference.
- Updated active documentation to identify Nexus/SQLite as the feedback authority, distinguish raw token sources from aggregate storage, and identify `.session/session-current.json` as the session authority. Legacy files remain labeled compatibility/historical paths and were not deleted.
- Added and validated explicit deployment prerequisite contracts for immutable image promotion, NetworkPolicy enforcement evidence, and MCP sandbox enforcement.
- Verified local capability inventory: Docker, Podman, kubectl, Helm, cosign, and ORAS are unavailable; Syft, Grype, Trivy, WSL2, and native provenance tooling are available. No installation was attempted without an operator-approved provider/registry.

Final local status is healthy and fully green. External promotion remains intentionally blocked by missing operator inputs rather than an application defect.

## Administrative Capability Validation

- Nexus/Engram persistence is active and healthy; the audit/session findings were saved to both systems.
- `GV_DASHBOARD_TOKEN` is **not configured** in the current environment. No dashboard token is assigned or retrievable from this session.
- Dashboard authentication is functional when a bootstrap token is provisioned, including persistent sessions, TTL, revocation, and WebSocket authentication.
- Administrator lifecycle is **not complete**: no dashboard user-management API/UI, principal binding, role enforcement, permission assignment, disable/delete, or membership-revocation endpoints were found.
- The local `trusted-users-policy.json` and its `isAdmin` field are operational policy metadata, not a verified dashboard RBAC implementation.
- The exact gap and required implementation contract are documented in `docs/security/DASHBOARD-ADMIN-STATUS.md`.

Therefore the stack is healthy and authenticated, but it is not correct to claim that the requesting user has verified administrator permissions or can manage users and access from the dashboard today.
