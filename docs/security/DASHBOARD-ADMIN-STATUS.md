# Dashboard Administration Status

**Status:** RBAC v1 complete (API + enforcement + audit + admin UI).

**Deployment scope:** Administration is local and deployment-scoped. This status does not assert
enterprise identity, SSO, OIDC, LDAP, or hosted SaaS authentication.

## Available

- Protected HTTP and WebSocket dashboard access.
- Opaque persistent dashboard sessions with TTL and revocation.
- Fail-closed production authentication.
- Deployment tenant boundary.
- SQLite `tenants`, `principals`, and `memberships` tables.
- Local trusted-user policy for stack operations, scoped to this deployment.

## RBAC v1 (implemented 2026-08-25)

- **Session → principal binding**: every login resolves/creates a principal
  (`GV_DASHBOARD_PRINCIPAL_SUBJECT`, default `dashboard-operator`) and stores
  `principal_id` + hashed CSRF token on the session row
  (`dashboard_auth_sessions`, migration `014_rbac_session_binding`).
- **Bootstrap semantics**: the first principal becomes `admin`; later logins
  keep their existing tenant role or default to `viewer` (fail-closed).
- **Versioned policy** (`apps/web-dashboard/server/rbac.ts`, version 1):
  roles `viewer < operator < admin`; reads require `viewer.read`, mutations
  require `operator.write`, `/api/admin/*` requires `admin`. The explicitly enabled
  dev-localhost bypass keeps full access only for loopback requests; production
  sessions without a bound principal get `403` and must re-login.
- **Admin API** (all under `/api/admin/principals`, admin role required):
  - `GET /api/admin/principals` — list principals with memberships.
  - `POST /api/admin/principals` — `{subject, displayName?, role?}` create +
    membership assignment.
  - `PATCH /api/admin/principals/:id/role` — `{role, tenantId?}` role change.
  - `POST /api/admin/principals/:id/revoke-sessions` — revoke all sessions of
    a principal.
  - `DELETE /api/admin/principals/:id` — delete principal (cascades
    memberships, revokes sessions).
- **CSRF double-submit**: login issues a `gv_dashboard_csrf` cookie; cookie
  mutations under `/api/admin/*` must send matching `X-GV-CSRF` header, both
  verified against the server-side hash. Logout clears it.
- **Login rate limiting**: sliding window per client address
  (`GV_DASHBOARD_LOGIN_MAX_FAILURES`, default 5 per
  `GV_DASHBOARD_LOGIN_WINDOW_MS`, default 60s) → `429` + `Retry-After`.
- **Lockout guards** (`409`): cannot change own role, cannot delete own
  principal, cannot demote/delete the last admin.
- **Audit trail**: `dashboard.auth.login`,
  `dashboard.admin.principal.{create,role_change,delete}`,
  `dashboard.admin.sessions.revoke` events persisted in Nexus `events`.
- **Negative coverage**: unit tests for policy matrix/route mapping/rate
  limiter and principal repo; E2E covers CSRF rejection, bootstrap admin,
  role-change denial after downgrade, and lockout guards with an isolated DB
  (`tests/e2e/dashboard-security.test.ts`).

## Admin UI (implemented 2026-08-25)

- Route `/admin` (`apps/web-dashboard/src/components/AdminPanel.tsx`), linked
  in the main navigation.
- Lists principals with tenant memberships and role badges; create principal
  (subject, display name, role), per-membership role change, session
  revocation, and principal deletion (with confirmation).
- All mutations go through `apiFetch` (`src/lib/api.ts`), which echoes the
  `gv_dashboard_csrf` cookie in the `X-GV-CSRF` header automatically.
- Clear error surface for `403` (non-admin) and `409` lockout guards;
  component coverage in `AdminPanel.test.tsx`.

## Not Available Yet

- Per-resource permission matrices (metrics/traces/backlog/routing/skill/mcp)
  beyond the coarse read/write/admin split; policy v2 may refine this without
  changing call sites.
- External identity providers: subjects are deployment-local; OIDC/LDAP/SSO federation is future
  opt-in and is not implemented yet.

## Operator Requirements

1. Provision the dashboard bootstrap secret through a secret manager
   (`GV_DASHBOARD_TOKEN`); never commit or paste it into repository files.
2. The first login bootstraps the admin principal automatically on a fresh
   database; subsequent operators can be created via the admin API.
3. Browser clients must keep both cookies (session + CSRF) and echo
   `X-GV-CSRF` on admin mutations — the bundled admin UI does this
   automatically via `apiFetch`.
