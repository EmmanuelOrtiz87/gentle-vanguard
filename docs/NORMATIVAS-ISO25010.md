# NORMATIVAS-ISO25010.md — ISO/IEC 25010 Quality Model Mapping

Version: 1.0.0
Framework: ISO/IEC 25010:2023 SQuaRE (Systems and software Quality Requirements and Evaluation)
Last updated: 2026-05-11

---

## 1. PROPOSITO

Mapea las 8 caracteristicas de calidad del modelo ISO/IEC 25010 a controles automatizados, scripts, y gates en el stack Gentle-Vanguard. Garantiza que la calidad del software sea medible, rastreable, y validable en cada fase del ciclo de vida.

---

## 2. MODELO DE CALIDAD ISO 25010

### 2.1 Funcional Suitability (Adecuacion Funcional)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Functional completeness | `scripts/testing/run-tests.ps1` | Test coverage >= 80% |
| Functional correctness | `tests/unit/*.tests.ps1` | Zero test failures |
| Functional appropriateness | `sdd-gate.yml` + BA review | SDD spec approval |

### 2.2 Performance Efficiency (Eficiencia de Rendimiento)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Time behaviour | `config/orchestrator.json#SLOs` | Dispatch < 500ms |
| Resource utilisation | `scripts/monitoring/cross-workspace-validator.ps1` | Token budget < 30K/session |
| Capacity | `config/orchestrator.json#concurrencyLimits` | Max 3 parallel agents |

### 2.3 Compatibility (Compatibilidad)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Co-existence | `config/tool-*.json` (opencode, cursor, windsurf, etc.) | Tool configs validos |
| Interoperability | `config/mcp-servers.json` + `adapters/` | MCP bridge estable |

### 2.4 Usability (Usabilidad)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Appropriateness recognisability | `docs/AGENTS.md` + `rules/README.md` | Docs actualizados |
| Learnability | `skills/` con SKILL.md | Cada skill documentada |
| Operability | `scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1` | Comandos gv funcionales |
| User error protection | `config/security-hardening.json` | Input validation en todas las entradas |
| User interface aesthetics | `docs/NORMATIVAS-ACCESIBILIDAD.md` | WCAG 2.2 AA compliance |
| Accessibility | axe-core + Playwright | WCAG automated checks |

### 2.5 Reliability (Fiabilidad)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Maturity | `tests/integration/*.tests.ps1` | Regression suite passing |
| Availability | `config/quality-gates.json` | CI gates blocking |
| Fault tolerance | `config/auto-delegation.json#maxRetries` | Agent retry logic |
| Recoverability | `.session/` state files + `mem_context` | Crash recovery protocol |

### 2.6 Security (Seguridad)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Confidentiality | `config/security-privacy.json` + `secrets-manager.ps1` | No secrets in logs |
| Integrity | `pre-commit-hook.ps1` + `gitleaks.yml` | Hook validation |
| Non-repudiation | `hooks-config.json` audit trail | ALL operations logged |
| Accountability | `.session/*.json` + engram mem | Session audit trail |
| Authenticity | `secure-auth.ps1` + `access-control.json` | Auth gates |
| Resistance | `security-scan.yml` (Trivy, CodeQL, Gitleaks) | Weekly scans |

### 2.7 Maintainability (Mantenibilidad)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Modularity | `rules/NORMATIVAS-CODIGO.md#3-Estructura` | File organization standards |
| Reusability | `skills/*/` modular skill structure | Skill isolation |
| Analysability | `scripts/diagnostics/*.ps1` + `agent-verify.ps1` | Diagnostic tools |
| Modifiability | `rules/DEVELOPMENT-STANDARDS.md` | Coding standards |
| Testability | `rules/TESTING-STANDARDS.md` | Test structure + coverage |

### 2.8 Portability (Portabilidad)

| Sub-caracteristica | Control Gentle-Vanguard | Verification |
|--------------------|-------------------|--------------|
| Adaptability | `config/orchestrator.json#platform` | Windows/Linux/macOS |
| Installability | `scripts/gentle-vanguard/bootstrap-machine.ps1` | Machine bootstrap |
| Replaceability | `config/tool-*.json` multi-tool support | Tool-agnostic design |

---

## 3. CALIDAD POR FASE DEL CICLO DE VIDA

| Fase | Calidad a Medir | Instrumento | Gate |
|------|-----------------|-------------|------|
| Analisis | Functional completeness | `sdd-gate.yml` | SDD spec approval |
| Diseno | Maintainability + Compatibility | Architecture review | Tech design review |
| Desarrollo | Functional correctness + Reliability | `agent-verify.ps1` | Zero failures |
| Testing | All 8 characteristics | `run-tests.ps1` + security-scan | Full suite pass |
| Deploy | Performance + Security | `quality-gate.yml` | All gates green |
| Operacion | Usability + Portability | `monitoring/` + telemetry | SLOs within budget |

---

## 4. METRICAS Y SLOs POR CARACTERISTICA

| Caracteristica | Metrica | Target | Warning | Critical |
|----------------|---------|--------|---------|----------|
| Functional Suitability | Test pass rate | 100% | < 100% | < 95% |
| Performance Efficiency | Agent dispatch time | < 500ms | 500-1000ms | > 1000ms |
| Compatibility | Tool config validation | 100% valid | < 100% | < 90% |
| Usability | WCAG violations | 0 critical | 1-5 | > 5 |
| Reliability | Regression failures | 0 | 1-3 | > 3 |
| Security | Scan findings (HIGH+) | 0 | 1-2 | > 2 |
| Maintainability | File line length avg | < 300 | 300-400 | > 400 |
| Portability | Platform coverage | 3/3 (Win/Mac/Lin) | 2/3 | < 2/3 |

---

## 5. AUTOMATION EN CI/CD

```yaml
- name: ISO 25010 Quality Gate
  shell: pwsh
  run: |
    $results = @{}
    $results.Functional = (Invoke-Pester -PassThru).FailedCount -eq 0
    $results.Performance = (Measure-AgentDispatch).TotalMilliseconds -lt 500
    $results.Security = (Invoke-SecurityScan).CriticalFindings -eq 0
    $results.Usability = (Invoke-WCAGCheck).Violations.Critical -eq 0
    
    $failed = $results.GetEnumerator() | Where-Object { -not $_.Value }
    if ($failed) {
      Write-Error "ISO25010 gate FAILED: $($failed.Count) characteristics below threshold"
      exit 1
    }
```

---

## 6. COMPLIANCE CHECKPOINTS

TODO implementacion DEBE verificar:

1. [ ] Las 8 caracteristicas ISO 25010 tienen metrica asociada
2. [ ] Cada caracteristica tiene SLO definido (target, warning, critical)
3. [ ] Test coverage mide functional correctness
4. [ ] Performance benchmarks miden time behaviour
5. [ ] Security scans miden todas las sub-caracteristicas de seguridad
6. [ ] WCAG checks miden usability
7. [ ] Code quality checks miden maintainability
8. [ ] Platform tests miden portability
9. [ ] Cada release pasa todas las metricas base
10. [ ] Dashboard visualiza las 8 caracteristicas (executive-dashboard.ps1)

---

## 7. REFERENCIAS

| Resource | Path |
|----------|------|
| ISO/IEC 25010:2023 | iso.org/standard/78176.html |
| ISO/IEC 25023:2016 | iso.org/standard/64186.html |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Performance Standards | `rules/NORMATIVAS-PERFORMANCE.md` |
| Security Normatives | `docs/NORMATIVAS-SEGURIDAD.md` |
| Quality Gates | `config/quality-gates.json` |
| Orchestrator Config | `config/orchestrator.json` |

---

_Version: 1.0.0 — 2026-05-11 — Status: ACTIVE_

