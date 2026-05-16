# ADR-001: Primary Language Choice — PowerShell (Not Bash/Python)

**Status**: Accepted (Implemented)  
**Date**: May 2026  
**Author**: Gentle-Vanguard Security Team  
**Context**: gentle-vanguard runs on Windows as primary platform  

---

## Context

The project needed a scripting language for:
- Git hooks (pre-commit, pre-push, commit-msg)
- CLI orchestration (gv.ps1)
- Build automation
- Test execution
- Deployment workflows

### Alternatives Considered

| Language | Pros | Cons | Decision |
|----------|------|------|----------|
| **PowerShell** | Native to Windows, GitHub Actions, powerful scripting | Less portable to Linux/Mac | ✅ **CHOSEN** |
| Bash | Portable, Unix standard | Weak on Windows, awkward WSL workarounds | ❌ Rejected |
| Python | Cross-platform, many libraries | Requires .py interpreter, extra install step | ❌ Rejected |
| JavaScript (Node) | Same ecosystem as npm | Overkill for shell scripts, worse error handling | ❌ Rejected |

---

## Decision

**Use PowerShell (7.x) as the primary scripting language for all automation.**

### Rationale

1. **Windows-Native Ecosystem**
   - GitHub Actions `windows-latest` runners have PowerShell 7 pre-installed
   - No additional CI/CD configuration needed
   - Direct access to Windows APIs if ever needed

2. **npm Integration**
   - gentle-vanguard uses npm for MCP servers
   - PowerShell scripts can call `npm` commands directly
   - Natural fit alongside Node.js tools

3. **Unified CI/CD**
   - All github workflows run PowerShell uniformly
   - No bash-to-PowerShell translation layer
   - Simpler GitHub Actions config (one shell: pwsh)

4. **Team Familiarity**
   - Primary team operates on Windows
   - Reduces learning curve
   - Better IDE support (VS Code PowerShell extension)

5. **Git Hooks Portability**
   - lefthook supports multi-platform hook execution
   - PowerShell scripts run on Windows; Bash scripts would on Linux (if added later)
   - Clean separation

---

## Consequences

### Positive

- ✅ All automation works without WSL or extra tools
- ✅ GitHub Actions workflow runs identically to local development
- ✅ Easier onboarding for Windows developers
- ✅ Type checking possible (PowerShell 7 PSScriptAnalyzer)
- ✅ Direct integration with Windows security features

### Negative

- ❌ Linux/Mac developers need WSL or virtual environment
- ❌ Bash scripts would not work natively on those platforms
- ❌ Requires PowerShell 7+ (not PowerShell 5.1, Windows built-in)
- ❌ Smaller ecosystem compared to Python for advanced use cases

### Mitigation

- Use `pwsh` (cross-platform PowerShell Core) instead of Windows-only PowerShell 5.1
- Document WSL setup for non-Windows developers (if needed in future)
- Pin PowerShell version in `.github/workflows/*.yml` files

---

## Implementation Notes

**All scripts follow these patterns**:

```powershell
# Shebang (for Unix compatibility, ignored on Windows)
#!/usr/bin/env pwsh

# Strict error handling
$ErrorActionPreference = 'Stop'

# Comments use # (not // like other languages)
# This is PowerShell

# Call external commands directly
npm install @package@version
git status
```

**GitHub Actions setup**:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
- shell: pwsh  # Use PowerShell
  run: npm ci
```

---

## Related Decisions

- [ADR-003](ADR-003-npx-offline-hardening.md) — Why npx hardening uses PowerShell hooks
- [SECURITY-HARDENING.md](../../guides/SECURITY-HARDENING.md) — Implementation details

---

## References

- [PowerShell 7 Releases](https://github.com/PowerShell/PowerShell/releases)
- [GitHub Actions: Using PowerShell](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#using-powershell)
- [PowerShell Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/scripts/writing-portable-modules)

---

**Review Date**: Q3 2026  
**Reviewers**: Security team, DevOps team

