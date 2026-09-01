# ADR-0017: Local-First Operating Model

## Status

Accepted

## Date

2026-08-25

## Context

Gentle-Vanguard already operates as a local stack: CLI/orchestration, SQLite/Nexus, the `.session/`
filesystem, Engram, CodeGraph, local MCP integrations, and the loopback dashboard work without a
hosted control plane. The repository also contains cloud connectors, Kubernetes manifests, image
promotion gates, and deployment security contracts. Those artifacts support future promotion, but
their external inputs are not local defaults and must not be presented as local prerequisites.

## Decision

Gentle-Vanguard is officially **LOCAL-FIRST / SERVER-OPTIONAL**.

- Local operation is the supported default and primary product scope.
- Existing local capabilities remain available, including the local dashboard, SQLite/Nexus,
  tenant-aware data paths, RBAC v1, MCP policy enforcement, tracing, audit, and local automation.
- Server, Kubernetes, cloud, and SaaS capabilities remain supported as opt-in evolution paths. They
  are not silently removed, enabled, or treated as requirements for local-first use.
- External promotion gates apply only when an operator targets an external deployment. Missing
  registry digests, CNI/NetworkPolicy evidence, OS/runtime sandbox evidence, or signing identity are
  promotion blockers, not local-operation blockers.

### Operating profiles

| Profile              | Scope                                                 | Default       | Identity and data boundary                                                    |
| -------------------- | ----------------------------------------------------- | ------------- | ----------------------------------------------------------------------------- |
| `local-default`      | One local workspace and local Nexus/SQLite            | Yes           | Local deployment scope; loopback dashboard; no enterprise identity assumption |
| `local-multi-tenant` | Multiple logical tenants in one local deployment      | Opt-in        | Tenant-scoped records and RBAC memberships remain deployment-local            |
| `server-promotion`   | Operator-managed server or Kubernetes deployment      | Opt-in/future | Requires external deployment inputs and promotion gates                       |
| `saas-federated`     | Hosted/federated service outside the local deployment | Opt-in/future | Requires explicit federation and enterprise identity contracts                |

### Authentication rules

1. Local authentication is deployment-scoped. Sessions, principals, memberships, roles, CSRF
   protection, audit events, and the bootstrap secret belong to the local deployment.
2. RBAC v1 (`viewer < operator < admin`) is enforced for protected requests and administrative
   mutations; tenant membership is the authorization boundary where tenant-scoped data applies.
3. A localhost bypass is permitted only when explicitly enabled and both host and remote address are
   loopback. It is never a production or enterprise identity mechanism.
4. OIDC, LDAP, SSO, and other enterprise identity providers are future opt-in federation features;
   local principals and session authentication must not imply them.
5. Promotion or SaaS deployments must retain fail-closed authentication and document an external
   identity, secret, tenancy, and audit contract before being called enterprise or federated.

## Consequences

### Positive

- Local users have a clear supported path with no Kubernetes, cloud account, registry, CNI, Cosign,
  or enterprise identity dependency.
- Existing server/cloud/SaaS implementations remain available for deliberate evolution.
- Documentation can distinguish locally verified behavior from operator-owned external inputs
  without inventing metrics, digests, or security evidence.

### Negative

- Multiple deployment profiles require explicit documentation boundaries.
- External promotion remains operator-led until its infrastructure and identity inputs are supplied.

### Mitigation

- Mark Kubernetes and deployment prerequisite documents as external-promotion gates.
- Keep local status, local auth, and external promotion status in separate sections.
- Review this ADR when a server or SaaS profile gains a verified identity and deployment contract.
