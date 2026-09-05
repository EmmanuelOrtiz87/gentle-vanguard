# OWASP Agentic AI Top 10 — Compliance Mapping

**Document**: `docs/compliance/OWASP-AGENTIC-TOP10.md`  
**Version**: 2023  
**Last Updated**: 2026-09-03  
**Status**: ✅ Complete Coverage

---

## Overview

This document maps Gentle-Vanguard's security controls to the OWASP Agentic AI Top 10 risks. Each risk category includes:
- Description
- Risk Level
- GV Controls (existing and new)
- Evidence/Implementation
- Verification

---

## LLM01: Prompt Injection

**Risk**: Attacker manipulates LLM via crafted input
**Level**: Critical

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **Policy Engine** | `src/security/policy-engine/` - Deterministic evaluation pre-execution | ✅ NEW |
| **Input Moderation** | `src/security/guardrails/input-moderation.ts` | ✅ EXISTING |
| **Prompt Injection Detection** | `.opencode/skills/detecting-ai-model-prompt-injection-attacks` | ✅ EXISTING |
| **Indirect Injection Scanning** | `.opencode/skills/detecting-indirect-prompt-injection` | ✅ EXISTING |

### Evidence
```typescript
// Policy Engine - Structurally impossible to bypass
const safeTool = govern(dangerousTool, { policyPath: 'policies/shell.yaml' });
safeTool({ cmd: 'rm -rf /' }); // → GovernanceDenied (structural)
```

---

## LLM02: Insecure Output Handling

**Risk**: Unvalidated LLM output causes harm
**Level**: High

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **Output Encoding** | `src/security/output-encoding.ts` | ✅ EXISTING |
| **Structured Output Validation** | Zod schemas in all tool outputs | ✅ EXISTING |
| **Response Filtering** | `src/security/privacy-gateway.ts` | ✅ EXISTING |

---

## LLM03: Training Data Poisoning

**Risk**: Malicious data in training set
**Level**: Medium

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **Skill Hash Verification** | SHA-256 verification of skills | ✅ EXISTING |
| **Trusted Sources** | Only official skill repositories | ✅ EXISTING |
| **Supply Chain Scanning** | `.opencode/skills/generating-and-analyzing-sboms` | ✅ EXISTING |

---

## LLM04: Model Denial of Service

**Risk**: Resource exhaustion attacks
**Level**: Medium

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **Token Budget Guard** | `config/token-budget-guard.json` | ✅ EXISTING |
| **Rate Limiting** | `src/core/rate-limiter.ts` | ✅ EXISTING |
| **Adaptive Steps** | `src/orchestration/adaptive-steps.ts` | ✅ EXISTING |
| **Circuit Breaker** | `src/resilience/circuit-breaker-v2.ts` | ✅ EXISTING |

---

## LLM05: Supply Chain Vulnerabilities

**Risk**: Compromised dependencies
**Level**: High

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **SBOM Generation** | `npm run sbom:generate` | ✅ EXISTING |
| **Dependency Confusion Detection** | `.opencode/skills/detecting-dependency-confusion` | ✅ EXISTING |
| **Container Scanning** | `npm run container:scan` | ✅ EXISTING |
| **SLSA Provenance** | `npm run provenance:generate` | ✅ EXISTING |
| **Secret Linting** | `npm run secretlint` | ✅ EXISTING |

---

## LLM06: Sensitive Information Disclosure

**Risk**: Leakage of confidential data
**Level**: Critical

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **Privacy Gateway** | `src/security/privacy-gateway.ts` - PII detection | ✅ EXISTING |
| **Secret Scanner** | `src/secret-scanner.ts` - 80 patterns | ✅ EXISTING |
| **Differential Privacy** | `src/security/differential-privacy.ts` | ✅ EXISTING |
| **Output Redaction** | `.opencode/skills/ai-provenance` | ✅ EXISTING |

---

## LLM07: Insecure Plugin Design

**Risk**: Vulnerable tool/plugins
**Level**: High

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **MCP Security Gateway** | `src/mcp/security-gateway/` | ✅ EXISTING |
| **Tool Poisoning Detection** | `.opencode/skills/auditing-mcp-servers-for-tool-poisoning` | ✅ EXISTING |
| **Rug Pull Detection** | Hash-based tool pinning | ✅ EXISTING |
| **Policy Enforcement** | `src/security/policy-engine/` | ✅ NEW |

---

## LLM08: Excessive Agency

**Risk**: LLM performs unauthorized actions
**Level**: Critical

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **Policy Engine** | Pre-execution deterministic enforcement | ✅ NEW |
| **Permission System** | `opencode.json` permission gates | ✅ EXISTING |
| **RDD Gates** | 5 pre-delivery gates | ✅ EXISTING |
| **Kill Switch** | `src/rdd/rdd-kill-switch.ts` | ✅ EXISTING |
| **Sandboxing** | Process isolation via `runNpxTsx` | ✅ EXISTING |

---

## LLM09: Overreliance

**Risk**: Excessive trust in LLM outputs
**Level**: Medium

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **Receipt-Driven Development** | `src/rdd/` - Evidence-based validation | ✅ EXISTING |
| **Multi-Agent Review** | RDD 4R lens (Risk, Resilience, Readability, Reliability) | ✅ EXISTING |
| **Self-Diagnosis** | `src/agents/self-diag-agent.ts` | ✅ EXISTING |
| **Premortem Analysis** | `src/agents/premortem-agent.ts` | ✅ EXISTING |

---

## LLM10: Model Theft

**Risk**: Unauthorized model extraction
**Level**: Low

### GV Controls

| Control | Implementation | Status |
|---------|---------------|--------|
| **API Key Management** | `.runtime/` encrypted storage | ✅ EXISTING |
| **Rate Limiting** | API throttling | ✅ EXISTING |
| **Watermarking** | Output provenance tracking | ✅ EXISTING |
| **Access Control** | Permission-based tool access | ✅ EXISTING |

---

## Summary Matrix

| OWASP Risk | GV Coverage | Status |
|-----------|-------------|--------|
| LLM01: Prompt Injection | Policy Engine + Guardrails | ✅ Full |
| LLM02: Insecure Output | Output Encoding + Validation | ✅ Full |
| LLM03: Training Data Poisoning | Hash Verification + SBOM | ✅ Full |
| LLM04: Model DoS | Token Budget + Circuit Breaker | ✅ Full |
| LLM05: Supply Chain | SBOM + Container Scan + Provenance | ✅ Full |
| LLM06: Sensitive Info | Privacy Gateway + Secret Scanner | ✅ Full |
| LLM07: Insecure Plugins | MCP Security + Policy Engine | ✅ Full |
| LLM08: Excessive Agency | Policy Engine + RDD Gates | ✅ Full |
| LLM09: Overreliance | RDD + Multi-Agent Review | ✅ Full |
| LLM10: Model Theft | Access Control + Rate Limiting | ✅ Full |

**Overall Coverage**: 10/10 (100%)

---

## Verification

```bash
# Run OWASP compliance verification
npm run security:owasp-verify

# Expected output:
# ✓ LLM01: PASS (Policy Engine active)
# ✓ LLM02: PASS (Output encoding configured)
# ...
# ✓ LLM10: PASS (Access controls verified)
```

---

## References

- OWASP Agentic AI Top 10: https://genai.owasp.org/
- Gentle-Vanguard Security: `src/security/`
- Policy Engine: `src/security/policy-engine/`
- ADR-0027: Policy Engine Fail-Closed
- ADR-0028: MCP Security Gateway

---

**Validated**: 2026-09-03  
**Next Review**: 2026-12-03
