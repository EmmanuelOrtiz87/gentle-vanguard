# Canonical Current Status

**Current package version:** `3.8.2`  
**Source of truth:** [`package.json`](../../package.json)  
**Last reviewed:** 2026-08-25

This note identifies the current repository version without rewriting historical reports, release
snapshots, roadmaps, or archived presentation material. Version claims in dated or historical
documents describe the state they recorded when written and should not be treated as the current
package version.

For current operating guidance, start with the [documentation map](../README.md) and the
[Getting Started guide](../getting-started/README.md).

## Official operating model

Gentle-Vanguard is **LOCAL-FIRST / SERVER-OPTIONAL** (see
[ADR-0017](../adr/ADR-0017-local-first-operating-model.md)). Local operation is the supported
primary scope today:

- CLI/orchestration, local SQLite/Nexus, `.session/`, Engram, CodeGraph, local MCP integrations, and
  the loopback dashboard are the core operating path.
- The local dashboard supports deployment-scoped sessions, principals, memberships, and RBAC v1.
  Local authentication does not claim OIDC, LDAP, SSO, or enterprise identity.
- Cloud connectors, Kubernetes, image signing, CNI/NetworkPolicy, sandbox evidence, and external
  identity federation are preserved as opt-in promotion/federation paths.

## External promotion boundary

The repository contains contracts and gates for a future server/Kubernetes/SaaS deployment. They are
**not requirements for local-first operation**. Registry digests, Cosign identity/signatures,
CNI/NetworkPolicy evidence, MCP OS/runtime sandbox evidence, and enterprise identity inputs become
blocking only when an operator explicitly targets external promotion.
