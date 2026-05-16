# ADR-003: NPX Hardening — Offline Mode with Workspace & Security Policy

**Status**: Accepted (Implemented)  
**Date**: May 13, 2026  
**Author**: Gentle-Vanguard Security Team  
**Context**: Mitigating npm supply-chain attacks  

---

## Context

Modern npm supply chain attacks target two primary vectors:

1. **Live Registry Poisoning**
   - `npx -y @package` fetches latest version from npm registry on every run
   - Attacker pushes malicious `@package@latest` version
   - Developer runs npx → downloads poisoned version without knowing

2. **Post-Install Script Execution**
   - Many packages define post-install lifecycle scripts
   - Malicious scripts execute arbitrary code during `npm install`
   - Example: steal secrets, modify source files, compromise CI/CD

### Risk Assessment

- **Likelihood**: High (npm registry is attack target)
- **Impact**: Critical (full machine compromise possible)
- **Current Mitigation**: None (using `npx -y @package`)
- **Acceptable Risk**: None (unacceptable for production)

---

## Decision

**Implement 3-layer npx hardening:**

1. **Runtime Layer**: `--offline --no --workspace` flags
   - Block live registry fetches
   - Refuse to execute unknown packages
   - Use pre-vetted workspace

2. **Package Layer**: `.npmrc` policy
   - Disable post-install scripts globally
   - Enforce 3-day minimum release age
   - Block git-based dependencies

3. **Conscious Layer**: Documented update procedures
   - Explicit approval gates for version updates
   - Security review of package-lock.json changes
   - Manual validation before deployment

---

## Implementation

### Layer 1: Runtime Hardening

**In `config/mcp-servers.json`**:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "--include-workspace-root",      # Resolve packages in workspace
        "--workspace", "%USERPROFILE%\\mcp-workspace",  # Pre-vetted dir
        "--no",                          # Refuse auto-exec
        "--offline",                     # Block registry requests
        "@modelcontextprotocol/server-filesystem",
        "."
      ]
    }
  }
}
```

**How it works**:
```
Developer runs MCP server
  ↓
npx sees: --offline --no
  ↓
npx checks: is package in workspace? YES
  ↓
npx checks: is package available to execute? YES
  ↓
Use offline version (no network request)
  ↓
Success: MCP starts
```

**Attack prevention**:
```
Attacker poisons npm registry with @latest
  ↓
Developer runs MCP (npx --offline ...)
  ↓
npx says: "OFFLINE MODE: Cannot fetch from registry"
  ↓
Attack BLOCKED ✅
```

### Layer 2: NPM Security Policy

**In `.npmrc` (project-level)**:

```ini
# Disable post-install lifecycle scripts
ignore-scripts=true

# Minimum release age: 3 days
# Gives community time to detect malicious packages
min-release-age=3

# Block git-based dependencies
# Forces all packages through registry scrutiny
allow-git=none
```

**Defense depth**:
- `ignore-scripts=true` — Prevents post-install code execution
- `min-release-age=3` — Blocks zero-day package poisoning (package must be 3+ days old)
- `allow-git=none` — Common attack vector (cloning from malicious git repos)

### Layer 3: Conscious Update Procedure

**Documented in [MCP-WORKSPACE-SETUP.md](../../guides/MCP-WORKSPACE-SETUP.md) §Conscious Update Procedure**:

```powershell
# 1. Review current status
npm list @modelcontextprotocol/server-filesystem

# 2. Audit vulnerabilities
npm audit

# 3. Make update decision (not automatic)
npm update @modelcontextprotocol/server-filesystem --save-exact

# 4. HUMAN REVIEW: what changed?
git diff package-lock.json  # Inspect before approving

# 5. Test functionality
npm test

# 6. Conscious commit with justification
git commit -m "security(mcp): update @modelcontextprotocol/server-filesystem to vX.X.X

Reviewed: [describe what changed]
Vulnerabilities: [audit result]
Testing: [what was verified]
"
```

---

## Consequences

### Positive

- ✅ **Zero-Day Blocked**: Cannot download latest (potentially poisoned) versions
- ✅ **Explicit Updates**: No silent automatic version changes
- ✅ **Audit Trail**: package-lock.json changes are deliberate, reviewable
- ✅ **Post-Install Safe**: Even if package is malicious, scripts won't run
- ✅ **Reproducible**: Offline mode guarantees same package version across machines
- ✅ **Team Transparency**: All developers use reviewed versions

### Negative

- ❌ **Setup Overhead**: Developers must create MCP workspace initially (15-20 min)
- ❌ **Manual Updates Required**: No automatic patch updates (must run procedure consciously)
- ❌ **3-Day Lag**: Cannot use packages < 3 days old (even if urgent)
- ❌ **Network Dependency (Initial)**: First setup requires npm registry access
- ❌ **Complex for New Developers**: More steps than simple `npx -y`

### Mitigation

- ✅ Automated setup in [FIRST-TIME-SETUP-CHECKLIST.md](../../guides/FIRST-TIME-SETUP-CHECKLIST.md)
- ✅ Clear update procedure with examples
- ✅ `min-release-age=3` is configurable (can set to 0 for emergencies)
- ✅ Pre-push npm audit catches issues automatically
- ✅ Documentation reduces onboarding friction

---

## Security Analysis

### Attack Vectors Closed

| Attack | NPX -y | Hardened | Status |
|--------|--------|----------|--------|
| **Registry Poisoning** | ❌ Vulnerable | ✅ Blocked | Offline + workspace |
| **Post-Install Script** | ❌ Vulnerable | ✅ Blocked | ignore-scripts=true |
| **Zero-Day Exploit** | ❌ Vulnerable (no delay) | ✅ Delayed | 3-day min-release-age |
| **Compromised Git Repo** | ❌ Vulnerable | ✅ Blocked | allow-git=none |
| **Version Drift** | ❌ Auto-update | ✅ Conscious | Lockfile-locked |

### Remaining Risks

- **Compromised Package (Before 3 Days)**: Rare but possible
  - Mitigation: Security team monitors npm security advisories daily
  
- **Malicious Maintenance Access**: Package maintainer compromised
  - Mitigation: Regular audits of core MCP server updates
  
- **Workspace Tampering**: Local attacker modifies workspace
  - Mitigation: Windows file permissions, anti-malware tools

---

## Comparison to Alternatives

| Approach | Security | Ease | Recommendation |
|----------|----------|------|-----------------|
| **`npx -y` (current)** | ❌ None | ✅✅✅ Simple | ❌ DO NOT USE |
| **Offline workspace** | ✅✅✅ Strong | ✅ Medium | ✅ **THIS (chosen)** |
| **Signed packages** | ✅ Strong | ❌ Complex | 🤔 Future option |
| **Docker container** | ✅✅ Strong | ❌❌ Complex | 🤔 Consider later |
| **Monorepo vendor** | ✅✅ Strong | ✅ Medium | 🤔 If scaling |

---

## Future Evolution

**Year 2026-2027**:
- SLSA L2 attestation (provenance of packages)
- Signed releases (cryptographic verification)
- Automated supply-chain scanning (Snyk, Dependabot)

**Year 2027+**:
- SLSA L3+ (stronger build guarantees)
- Hardware-backed signing (Yubikey for releases)
- Federated package verification

---

## Related Decisions

- [ADR-002](ADR-002-mcp-workspace-external.md) — Why workspace is external local
- [ADR-001](ADR-001-powershell-language-choice.md) — Why PowerShell for hooks

---

## References

- [npm-security-best-practices §8](https://github.com/lirantal/npm-security-best-practices#8-harden-npx-execution)
- [SLSA Framework](https://slsa.dev/) — Supply-chain attacks
- [npm audit](https://docs.npmjs.com/cli/v10/commands/npm-audit)
- [npm post-install scripts](https://docs.npmjs.com/cli/v10/commands/npm-run-script)
- [2024 JavaScript/npm Supply-Chain Attacks](https://www.bleepingcomputer.com/)

---

**Review Date**: Q2 2027 (annual security review)  
**Reviewers**: Security team, compliance team  
**Status**: Stable, monitoring for threats

