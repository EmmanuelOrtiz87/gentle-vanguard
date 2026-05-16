# NORMATIVAS-ISO27001.md — ISO/IEC 27001 Controls Mapping

Version: 1.0.0
Framework: ISO/IEC 27001:2022 Annex A Controls
Last updated: 2026-05-11

---

## 1. PROPOSITO

Mapea los controles del Anexo A de ISO/IEC 27001:2022 a automatizaciones, workflows y gates en el stack Gentle-Vanguard. Garantiza que las practicas de seguridad del framework esten alineadas con el estandar internacional de gestion de seguridad de la informacion.

---

## 2. CONTROLES ORGANIZACIONALES (A.5)

| Control ID | Control Name | Implementacion Gentle-Vanguard | Verification |
|---|---|---|---|
| A.5.1 | Information security policy | `docs/NORMATIVAS-SEGURIDAD.md` + `config/security-policy.json` | Policy documentada y revisada |
| A.5.2 | Information security roles | `config/access-control.json` + `config/owner-auth.json` | Roles definidos y asignados |
| A.5.4 | Segregation of duties | `config/auto-delegation.json#agentProfiles` | Agentes con responsabilidades separadas |
| A.5.8 | Project management | `config/adaptive-dag-config.json` | SDD lifecycle para proyectos |
| A.5.9 | Supplier relationships | `config/security-policy.json#suppliers` + SBOM | Dependencias escaneadas (Dependabot) |
| A.5.10 | Supplier agreements | Criterios de aceptacion en CI/CD | SLA de dependencias |
| A.5.11 | Inventory of assets | `config/plugin-manifest-schema.json` + `docs/architecture/` | Asset registry |
| A.5.12 | Classification of information | `config/security-privacy.json` | Data classification levels |
| A.5.14 | Information transfer | `privacy-gateway.ps1` + `privacy-sanitizer.ps1` | Redaccion automatica |
| A.5.15 | Access control | `config/access-control.json` + `secure-auth.ps1` | ACL enforce |
| A.5.16 | Identity management | `owner-auth.json` + auth session | Identity verification |
| A.5.25 | Assessment of security events | `scripts/security/security-orchestrator.ps1` | Event logging + alerting |

---

## 3. CONTROLES DE TECNOLOGIA (A.8)

| Control ID | Control Name | Implementacion Gentle-Vanguard | Verification |
|---|---|---|---|
| A.8.4 | Privileged access | `config/security-hardening.json#leastPrivilege` | Least privilege por agente |
| A.8.5 | Secure authentication | `secure-auth.ps1` + `auth-session.ps1` | Session-based auth |
| A.8.6 | Capacity management | `config/orchestrator.json#token_budget_guard` | Token budget enforcement |
| A.8.7 | Protection against malware | Trivy + Gitleaks + CodeQL scans | Weekly automated scanning |
| A.8.8 | Management of technical vulnerabilities | `dependabot.yml` + `security-scan.yml` | Dependency updates + vuln scanning |
| A.8.9 | Configuration management | `config/*.json` + `validate-configs.ps1` | Config validation |
| A.8.10 | Information deletion | `docs/NORMATIVAS-SESSION.md#cleanup` | Session cleanup |
| A.8.11 | Data masking | `privacy-sanitizer.ps1` + `privacy-gateway.ps1` | PII redaction |
| A.8.12 | Data leakage prevention | `security-hardening.json#outputFiltering` | Output validation |
| A.8.13 | Backup | `scripts/adaptive/auto-backup-orchestrator.ps1` | Auto backup |
| A.8.14 | Redundancy | `.session/` state persistence | Session recovery |
| A.8.15 | Logging | `scripts/security/security-logger.ps1` | Centralized logging |
| A.8.16 | Monitoring activities | `scripts/monitoring/` | Dashboard + alerts |
| A.8.20 | Network security | `config/security-deploy.json` + GitHub Runners | Deploy hardening |
| A.8.24 | Use of cryptography | `encryption-manager.ps1` + `backup-master-key.ps1` | Key management |
| A.8.25 | Secure development lifecycle | `rules/NORMATIVAS-CODIGO.md` + `sdd-gate.yml` | SDD + code standards |
| A.8.27 | Secure operations | `config/orchestrator.json#subagent_orchestration` | Agent ops security |
| A.8.28 | Prompt injection prevention | `docs/NORMATIVAS-SEGURIDAD.md#2.1` | Input sanitization |
| A.8.29 | Excessive agency prevention | `docs/NORMATIVAS-SEGURIDAD.md#2.2` | Tool permission scoping |
| A.8.30 | Secure AI agent communication | `docs/NORMATIVAS-SEGURIDAD.md#2.8` | Inter-agent validation |

---

## 4. CONTROLES DE PERSONAS (A.6)

| Control ID | Control Name | Implementacion Gentle-Vanguard | Verification |
|---|---|---|---|
| A.6.1 | Screening | `config/owner-auth.json` | Owner verification |
| A.6.2 | Terms and conditions | `config/security-policy.json` | Policy acceptance |
| A.6.3 | Awareness | `rules/AI-NORMATIVES.md` | Agent training via docs |
| A.6.4 | Disciplinary process | Audit trail + `access-control.json` | Violation logging |

---

## 5. CONTROLES FISICOS (A.7)
*(Aplican al entorno de ejecucion, no directamente al framework)*

| Control ID | Control Name | Recomendacion |
|---|---|---|
| A.7.1 | Physical security perimeter | GitHub Actions + `runs-on` hardening |
| A.7.9 | Clear desk policy | No secrets in logs, `privacy-sanitizer.ps1` |
| A.7.10 | Unattended user equipment | `auth-session.ps1` session timeout |

---

## 6. AUTOMATION DEL CONTROL MAPEO

### 6.1 CI Gate

```yaml
- name: ISO 27001 Control Validation
  shell: pwsh
  run: |
    $controls = @(
      @{ID="A.5.15"; Check="access-control.json exists"; Path="config/access-control.json"}
      @{ID="A.8.9"; Check="config files valid"; Script="validate-configs.ps1"}
      @{ID="A.8.8"; Check="Dependabot configured"; Path=".github/dependabot.yml"}
      @{ID="A.8.15"; Check="Security logging"; Script="security-logger.ps1"}
      @{ID="A.8.27"; Check="Agent operation security"; Config="orchestrator.json"}
    )
    $failed = 0
    foreach ($c in $controls) {
      if (-not (Test-Path $c.Path) -and -not (& $c.Script -Check)) {
        Write-Error "ISO27001 FAIL: $($c.ID) - $($c.Check)"
        $failed++
      }
    }
    if ($failed) { exit 1 }
```

### 6.2 Periodic Audit

Ejecutar semanalmente: `scripts/security/security-audit.ps1 -Standard ISO27001`

---

## 7. NIVELES DE CUMPLIMIENTO

| Nivel | Cobertura | Timeline |
|-------|-----------|----------|
| Baseline (P0) | Control ID documentado + herramienta asociada | Current (v2.0) |
| Automated (P1) | Control verificado automaticamente en CI | Q2 2026 |
| Measured (P2) | Control con metrica SLO + dashboard | Q3 2026 |
| Audited (P3) | Control auditado trimestralmente con evidencia | Q4 2026 |

---

## 8. COMPLIANCE CHECKPOINTS

TODO implementacion DEBE verificar:

1. [ ] A.5.15 — Access control configurado y validado
2. [ ] A.8.4 — Least-privilege por agente
3. [ ] A.8.8 — Vulnerabilidad escaneada semanalmente
4. [ ] A.8.9 — Configuraciones validadas pre-commit
5. [ ] A.8.15 — Logging centralizado activo
6. [ ] A.8.25 — SDD gate en CI
7. [ ] A.8.28 — Prompt injection prevention activa
8. [ ] A.8.29 — Excessive agency prevention activa
9. [ ] A.8.30 — Inter-agent communication segura
10. [ ] A.5.1 — Security policy documentada y revisada

---

## 9. REFERENCIAS

| Resource | Path |
|----------|------|
| ISO/IEC 27001:2022 | iso.org/standard/27001 |
| ISO/IEC 27002:2022 | iso.org/standard/27002 |
| NIST SP 800-53 | csrc.nist.gov/publications/sp800-53 |
| Security Normatives | `docs/NORMATIVAS-SEGURIDAD.md` |
| Security Policy | `config/security-policy.json` |
| Security Hardening | `config/security-hardening.json` |
| Access Control | `config/access-control.json` |
| AI Normatives | `rules/AI-NORMATIVES.md` |

---

_Version: 1.0.0 — 2026-05-11 — Status: ACTIVE_

