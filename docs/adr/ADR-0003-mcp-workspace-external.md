# ADR-0003: MCP Workspace — External (Not Git-Tracked)

**Date**: May 2026  
**Author**: Gentle-Vanguard Security Team

## Status

Accepted (Implemented)

**Context**: MCP server management and workspace isolation

---

## Context

The project uses MCP (Model Context Protocol) servers as first-class citizens of the stack:
codegraph, engram, chrome-devtools, filesystem, memory (see `opencode.json` `mcp` section and
`config/mcp-registry.json`). When designing how MCP servers and their shared state are stored, the
project had to decide whether the MCP workspace should live inside the git repository or outside it.

Key drivers:

- MCP servers can hold **sensitive state** (session context, memory, embeddings, cached queries).
- The stack follows a **local-first, security-first** philosophy (see ADR-0004 npx hardening).
- Pre-vetted workspace is a core layer of the npx offline hardening (`--workspace` flag).
- The repo is public (`gentle-vanguard-public`) — nothing sensitive can be tracked.

### Alternatives Considered

| Option                         | Pros                                            | Cons                                                     | Decision      |
| ------------------------------ | ----------------------------------------------- | -------------------------------------------------------- | ------------- |
| **External workspace**         | Isolated from repo, no secret leakage, safe npx | Requires setup step, not cloned automatically            | ✅ **CHOSEN** |
| Git-tracked workspace (`mcp/`) | Ships with repo, zero setup                     | Secrets can leak in public repo, bloats git history      | ❌ Rejected   |
| System temp directory          | Zero config                                     | Not persistent, lost on reboot, no shared vetted state   | ❌ Rejected   |
| User home global dir           | Persistent, per-user                            | Not per-project, cross-project pollution, harder cleanup | ❌ Rejected   |

---

## Decision

**Keep the MCP workspace external to the repository** — outside git tracking, in a project-local
directory resolved at setup time (e.g. `$HOME\mcp-workspace` or a `.runtime/`-adjacent location),
registered in the MCP config as a pre-vetted workspace.

### Rationale

1. **Secret Isolation**
   - MCP servers store session context, memory and query caches that may contain sensitive data.
   - An external workspace guarantees none of it can be committed to a public repo.

2. **npx Hardening Dependency**
   - ADR-0004 relies on a pre-vetted workspace for offline mode (`--workspace`).
   - The workspace must be writable and persistent — not versioned — to accumulate vetted packages.

3. **Repository Hygiene**
   - Keeps the git history small (no generated state, no binaries, no server caches).
   - Avoids merge conflicts on machine-local state that has no meaningful diff.

4. **Per-Environment Flexibility**
   - Each machine/user can have its own workspace without polluting the shared repo.
   - Matches the multi-workspace mesh model (cross-workspace discovery via manifests).

---

## Consequences

### Positive

- ✅ No MCP state can leak into the public repo.
- ✅ Complements npx offline hardening (vetted workspace).
- ✅ Clean git history, no generated artifacts tracked.
- ✅ Per-user isolation across the mesh.

### Negative

- ❌ New clones need a setup step to create/point the workspace.
- ❌ Two environments won't share MCP state automatically.
- ❌ Workspace can grow large without repo-level oversight.

### Mitigation

- `src/stack-setup.ts` and `src/setup-complete.ts` create/verify the workspace during setup.
- `config/mcp-registry.json` + `src/mcp-manager.ts` centralize server definitions and paths.
<!-- REF-OBSOLETA: src/mcp-manager.ts no existe (ruta migrada o eliminada) -->
- Watchtower health check verifies the workspace exists and is writable.

---

## Implementation Notes

MCP servers defined in `opencode.json`:

```json
{
  "mcp": {
    "codegraph": { "type": "local", "command": "codegraph serve --mcp" },
    "engram": { "type": "stdio", "command": "engram", "args": "mcp --tools=agent" },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": "-y @modelcontextprotocol/server-filesystem@latest C:\\Workspace_local"
    }
  }
}
```

Workspace path is resolved at setup time and never tracked; `.gitignore` excludes generated state.

---

## Related Decisions

- [ADR-0004](ADR-0004-npx-offline-hardening.md) — npx offline mode with pre-vetted workspace
- [ADR-0005](ADR-0005-homologation-gate.md) — mandatory gates before release
- [NORMATIVAS-SBOM](../../governance/normatives/NORMATIVAS-SBOM.md) — SBOM generation for releases

---

## References

- [MCP Protocol](https://modelcontextprotocol.io/)
- [opencode.json MCP config](C:\Workspace_local\gentle-vanguard\opencode.json)
- [config/mcp-registry.json](C:\Workspace_local\gentle-vanguard\config\mcp-registry.json)

---

**Review Date**: Q3 2026  
**Reviewers**: Security team, DevOps team
