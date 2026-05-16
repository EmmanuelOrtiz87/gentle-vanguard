# ADR-002: MCP Workspace Location — External Local (Not Git-Tracked)

**Status**: Accepted (Implemented)  
**Date**: May 13, 2026  
**Author**: Gentle-Vanguard Security Team  
**Context**: Hardening npx execution against supply-chain attacks  

---

## Context

gentle-vanguard uses Model Context Protocol (MCP) servers for file system access. The challenge was:
- npm packages (MCP servers) need pre-vetting before use
- `npx -y @package` auto-downloads latest version on every invocation → supply chain risk
- Need offline-only execution mode with lockfile guarantee

### Alternatives Considered

| Location | Approach | Pros | Cons | Decision |
|----------|----------|------|------|----------|
| **External local** (`$HOME\mcp-workspace`) | Pre-vetted workspace at home dir | Isolated, offline mode, security focus | Not in git, manual setup per machine | ✅ **CHOSEN** |
| Git-tracked in repo | `gentle-vanguard/mcp-workspace/` folder | Version controlled, distributed with repo | Bloats repo (node_modules), harder CI/CD | ❌ Rejected |
| GitHub Releases | Download pre-built binaries | Deterministic, cacheable | Complex release process, duplicate artifacts | ❌ Rejected |
| Docker image | Container with preinstalled packages | Reproducible, isolated | Requires Docker, over-engineered | ❌ Rejected |
| npm ci in CI/CD only | Install only in GitHub Actions | No local concerns | Doesn't solve local dev problem | ❌ Rejected |

---

## Decision

**Maintain MCP workspace as external local artifact at `$HOME\mcp-workspace`.**

Not tracked in git. Manually set up once per machine using documented procedure.

### Rationale

1. **Security: Offline Execution**
   - Workspace contains lockfile with exact package versions
   - npx runs with `--offline --no` flags → blocks all registry requests
   - Prevents live poisoning attacks on every invocation

2. **Supply Chain Integrity**
   - Packages pre-vetted once (security team signs off)
   - Developers use verified versions, not latest
   - No silent updates = no surprises

3. **Local Development Autonomy**
   - Developers control when MCP workspace updates
   - Not forced into updates by CI/CD or automation
   - Conscious update procedure (with human review gate)

4. **Repository Cleanliness**
   - Keeps repo size small (no node_modules in git)
   - Separates MCP tool config from application code
   - Clear boundary: repo = application, workspace = tools

5. **CI/CD Simplicity**
   - GitHub Actions doesn't need MCP workspace (uses different approach)
   - Each machine manages its own tools
   - No git conflicts on lockfile updates

---

## Consequences

### Positive

- ✅ Strong security posture (offline + lockfile)
- ✅ Explicit updates (not automatic)
- ✅ Small repository footprint
- ✅ No git merge conflicts on MCP packages
- ✅ Each machine can have MCP workspace at different versions if needed
- ✅ Clear separation of concerns

### Negative

- ❌ Manual setup required on new machines (15-20 minutes)
- ❌ No version history (local changes not tracked)
- ❌ Risk of workspace getting out of sync across team
- ❌ Developers might forget to update workspace

### Mitigation

- ✅ Documented setup in [MCP-WORKSPACE-SETUP.md](../../guides/MCP-WORKSPACE-SETUP.md)
- ✅ First-time checklist in [FIRST-TIME-SETUP-CHECKLIST.md](../../guides/FIRST-TIME-SETUP-CHECKLIST.md)
- ✅ Conscious update procedure with review gates
- ✅ Pre-push npm audit validates workspace health
- ✅ .npmrc policy enforces 3-day minimum release age

---

## Implementation Details

### Setup (One Time Per Machine)

```powershell
mkdir $HOME\mcp-workspace
cd $HOME\mcp-workspace
npm init -y
npm install @modelcontextprotocol/server-filesystem@2026.1.14 --save-exact
```

### Usage (In config/mcp-servers.json)

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "--include-workspace-root",
        "--workspace", "%USERPROFILE%\\mcp-workspace",
        "--no",
        "--offline",
        "@modelcontextprotocol/server-filesystem",
        "."
      ]
    }
  }
}
```

### Update Procedure (Conscious & Reviewed)

```powershell
cd $HOME\mcp-workspace
npm audit
npm update @modelcontextprotocol/server-filesystem --save-exact
# Review package-lock.json changes
npm test  # Verify functionality
```

---

## Why NOT Git-Tracked?

**Common question**: "Why not include MCP workspace in the repo?"

**Answer**: Three reasons—

1. **Repository Bloat**
   - node_modules is huge (100MB+ with MCP ecosystem)
   - Git doesn't handle binary node_modules well
   - Clone times balloon, CI/CD gets slow

2. **Security Control**
   - Workspace locked by security team (conscious approval needed for updates)
   - Git history would show all intermediate versions
   - Harder to enforce "no auto-update" policy

3. **Developer Autonomy**
   - Team members can safely experiment locally without git concerns
   - Updates happen consciously, not through merge conflicts
   - Each machine can be at slightly different MCP versions if needed

---

## Related Decisions

- [ADR-003](ADR-003-npx-offline-hardening.md) — Why npx uses offline + workspace mode
- [ADR-004](ADR-004-homologation-gate.md) — Release workflow validation

---

## Migration Path (If Policy Changes)

If future team decides to version-control MCP workspace:

1. Create `.gitignore` entry: `# Remove: mcp-workspace/ to start tracking`
2. Add `gentle-vanguard/mcp-workspace/` to repo with lockfile and package.json
3. Update CI/CD to use repo workspace instead of external
4. Update onboarding docs

---

## References

- [npm Security Best Practices](https://github.com/lirantal/npm-security-best-practices) §8
- [MCP-WORKSPACE-SETUP.md](../../guides/MCP-WORKSPACE-SETUP.md)
- [SECURITY-HARDENING.md](../../guides/SECURITY-HARDENING.md#5-npx-supply-chain-hardening)

---

**Review Date**: Q4 2026  
**Reviewers**: Security team, DevOps team  
**Status**: Stable (re-evaluate annually)

