---
created: 2026-05-24 09:48:23
tags: [engram, architecture]
engram_id: 1095
type: architecture
---

# Prompt injection + SBOM validation implemented

**What**: Implemented prompt injection/jailbreak detection across the stack + SBOM validation script
**Why**: Required coverage for OWASP LLM01/ASI01 attacks (injection, jailbreaking, prompt leakage, code execution) and supply chain security (SBOM compliance)
**Where**: scripts/security/privacy-gateway.ps1, scripts/security/security-orchestrator.ps1, scripts/security/sbom-validate.ps1, config/security-privacy.json (injectionBlock), docs/NORMATIVAS-SEGURIDAD.md (§2.11), tests/security/security-checks.tests.ps1, scripts/security/encryption-manager.ps1
**Learned**:
1. PowerShell single-quoted strings can't use \' — use '' for literal apostrophe
2. privacy-gateway now blocks injection before sanitization (exit 1 + message)
3. 98 security tests total (was 87) covering injection detection, SBOM validation, and path fixes

---
*Imported from Engram on 2026-09-06*
