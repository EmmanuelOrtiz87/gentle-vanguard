# Plan de Auditoría de Seguridad Anual (Annual Security Audit)

> **Roadmap**: 5.2 — "Add Annual Security Audit" (`docs/guides/STACK-OPTIMIZATION-ROADMAP.md`, línea 552)
> **Estado**: PLANIFICADO (Q3 2026)
> **Propietario**: GOV (Governance Agent) — co-revisión OPS
> **Última actualización**: 2026-08-16

---

## 1. Objetivo

Ejecutar una **auditoría de seguridad externa anual** que proporcione:

1. **Validación third-party** — una firma externa independiente revisa el stack sin el sesgo del
   equipo que lo construyó. Detecta problemas sistémicos que las defensas internas normalizan.
2. **Catch systemic issues** — los hallazgos se priorizan por severidad y se trackean hasta
   remediación, cerrando el ciclo de mejora continua.
3. **Board/audit-ready** — documentación profesional (reporte del firm, log de hallazgos, plan de
   remediación) lista para presentar a dirección, clientes SOC2/GDPR y auditores.

El stack ya cuenta con **defensas nativas extensas** (sección 4). El audit externo **valida** esas
defensas y busca lo que ellas no cubren — no reemplaza el trabajo interno.

---

## 2. Timeline

| Fase            | Ventana        | Estado      | Responsable |
| --------------- | -------------- | ----------- | ----------- |
| **Plan**        | Q3 2026 (ahora) | ✅ ACTIVO   | GOV         |
| Preparación     | Q3 2026 (Sep)  | ⏳ Pendiente | GOV + OPS   |
| **Ejecución**   | Q4 2026 (Oct-Nov) | ⏳ Pendiente | Firma externa |
| Reporte + remediación | Q4 2026 (Nov-Dic) | ⏳ Pendiente | GOV + DEV |
| **Recurrencia** | Anual (Q4 de cada año) | 🔁 Recurrente | GOV |

**Hitos clave:**

- **2026-08-16** — Plan creado (este documento) + log inicializado
- **2026-09-30** — Checklist de preparación completado (sección 5)
- **2026-10-15** — Kickoff con firma externa; entrega de paquete de contexto
- **2026-11-30** — Reporte del firm recibido; hallazgos registrados en el log
- **2026-12-15** — Plan de remediación aprobado con SLAs; tracking iniciado

---

## 3. Scope

Tres dominios, según el roadmap 5.2:

### 3.1 Code Review (revisión de código)

- Aplicación TypeScript (`src/`, `apps/web-dashboard/`)
- Scripts de automatización (`scripts/`, `src/cli/`)
- Hooks de git (`.lefthook.yml` + hooks TS en `src/hooks/`, `src/rdd/`)
- Workflows CI/CD (`.github/workflows/ci.yml`, `.github/workflows/security.yml`)
- Enfoque: inyección de prompts, manejo de secrets, validación de input, lógica de autorización,
  exposición de datos (PII), dependencias inseguras, patrones de código peligrosos.

### 3.2 Dependency Audit (auditoría de dependencias)

- Dependencias npm/pnpm (`package.json`, `pnpm-lock.yaml`)
- **SBOM**: `sbom.json` (CycloneDX 1.7, **1256 componentes**) — escaneo con grype/trivy
- Supply chain: `.npmrc` (ignore-scripts, min-release-age, allow-git=none), lockfile-lint,
  dependency-confusion, acciones de CI sin pinning
- Vulnerabilidades conocidas (CVEs) en runtime y devDependencies

### 3.3 Configuration Review (revisión de configuración)

- `opencode.json` — permisos, agentes, steps, MCP servers
- `.lefthook.yml` — hooks activos y su cobertura
- CI workflows — permisos mínimos (`contents: read`), pinning de acciones, secrets de GitHub
- MCP servers — tool poisoning, shadowing, SSRF, exposición no autenticada
- Gestión de secrets — `config/secrets-governance.json`, `config/security-policy.json`,
  `config/rbac-policy.json`, `config/access-control.json`, `config/safety-layer.json`
- Configs de seguridad: `config/secret-scanner.json`, `.secretlintrc.json`, `.trufflehogignore`

---

## 4. Inventario de Defensas Existentes

El stack ya implementa defensas nativas. El audit externo **valida** esta tabla y busca brechas.

| # | Control | Herramienta nativa | Verificación |
| - | ------- | ------------------ | ------------ |
| 1 | Secret scanning (80 patrones) | `src/secret-scanner.ts` + CLI `src/secret-scanner-cli.ts` | `npm run scan:secrets -- --scan . --json` |
| 2 | Secret scanning (pre-commit) | `.lefthook.yml` → `secret-scanner` + `secretlint` + `trufflehog-scan` | `npx lefthook validate` |
| 3 | Secret scanning (CI) | `.github/workflows/security.yml` → gitleaks, secretlint, trivy | Ejecutar workflow en PR |
| 4 | Secretlint (config) | `secretlint` + `.secretlintrc.json` | `npm run secretlint` |
| 5 | Watchtower (95 checks / 13 componentes) | `src/core/maintenance-watchtower.ts` | `npm run watchtower:health` |
| 6 | Privacy gateway (sanitización PII) | `src/security/privacy-gateway.ts` | `npm run privacy:gateway` |
| 7 | Security orchestrator | `src/security/security-orchestrator.ts` | `npm run security:orchestrator` |
| 8 | GateGuard MCP (validación MCP) | `src/gateguard-mcp.ts` | `npm run gateguard:mcp` |
| 9 | Findings gatekeeper | `src/result-gatekeeper.ts` | `npm run findings:gatekeeper` |
| 10 | Findings ledger | `src/findings-ledger.ts` | `npm run findings:ledger` |
| 11 | RDD gates (5 delivery gates) | `src/rdd/rdd-gates.ts` | `npm run rdd:gate` |
| 12 | SDD gate | `src/check-sdd-gate.ts` | `npm run hook:sdd-gate` |
| 13 | Security check hook | `src/check-security.ts` | `npm run hook:security` |
| 14 | Lockfile lint (pre-commit) | `src/lockfile-lint-pre-commit.ts` | `npm run hook:lockfile` |
| 15 | npm audit (pre-push) | `src/infrastructure/npm-audit-pre-push.ts` | `npm run hook:npm-audit` |
| 16 | SIEM audit bridge | `src/infrastructure/siem-audit-bridge.ts` | `npm run audit:siem` |
| 17 | Dependency validator | `src/dependency-validator.ts` | `npm run deps:check` |
| 18 | SBOM generation | `src/generate-sbom.ts` → `sbom.json` (CycloneDX 1.7, 1256 comp.) | `npm run sbom:generate` / `npm run sbom:validate` |
| 19 | Prompt injection guard (runtime) | `src/prompt-injection-guard.ts` | `npm run safety:injection-guard` |
| 20 | Mutation safety scorer (runtime) | `src/mutation-safety-scorer.ts` | `npm run safety:mutation-scorer` |
| 21 | Safety guardrails | `src/safety-guardrails.ts` | `npm run safety:guardrails` |
| 22 | Session close guardian | `src/session-close-guardian.ts` | `npm run guardian:check` |
| 23 | CI security-scan job | `.github/workflows/ci.yml` → `pnpm audit --audit-level=high` + SAST | PR en CI |
| 24 | Stack verify | `src/stack-verify.ts` | `npm run stack:verify` |
| 25 | Skills de cibersec (25 absorbidas) | `.opencode/skills/` — NIST 800-30, NIST CSF, ISO 27001, GDPR, CMMC, OWASP API Top 10, garak, promptfoo, SBOM, gitleaks, MCP tool-poisoning, etc. | `skill` tool / `.opencode/skills/` |
| 26 | Configs de governance | `config/security-policy.json`, `rbac-policy.json`, `access-control.json`, `secrets-governance.json`, `safety-layer.json` | Validación JSON + watchtower |

**Nota**: el inventario demuestra cobertura amplia. El audit externo debe enfocarse en **validar la
efectividad** de estos controles (¿se ejecutan realmente? ¿cubren los casos límite?) y en detectar
**brechas sistémicas** (p. ej., secrets en git history, MCP servers no auditados, configs con
permisos excesivos).

---

## 5. Checklist de Preparación Pre-Audit

Ejecutar **antes** del kickoff con la firma externa (deadline: 2026-09-30). Cada item incluye el
comando de verificación.

| # | Item | Comando de verificación | Estado |
| - | ---- | ----------------------- | ------ |
| 1 | Escaneo completo de secrets (repo completo) | `npm run scan:secrets -- --scan . --json` | ⬜ |
| 2 | Watchtower health (95 checks / 13 componentes) | `npm run watchtower:health` | ⬜ |
| 3 | Escaneo SBOM con grype (fail-on high) | `grype sbom:sbom.json --fail-on high` | ⬜ |
| 4 | Escaneo SBOM con trivy (filesystem) | `trivy fs . --severity CRITICAL,HIGH` | ⬜ |
| 5 | CI security.yml (gitleaks + secretlint + trivy) | Push/PR a `main` → revisar checks | ⬜ |
| 6 | Hooks activos y válidos | `npx lefthook validate` | ⬜ |
| 7 | Secretlint completo | `npm run secretlint` | ⬜ |
| 8 | Revisión de MCP servers (tool poisoning) | Skill `auditing-mcp-servers-for-tool-poisoning` + `npm run gateguard:mcp` | ⬜ |
| 9 | Revisión de permisos de `opencode.json` | Validación + revisión manual de `permission`/`tools` | ⬜ |
| 10 | Gates RDD/SDD activos | `npm run rdd:gate` + `npm run hook:sdd-gate` | ⬜ |
| 11 | Secrets en git history (gitleaks full history) | `gitleaks git --log-opts="--all"` | ⬜ |
| 12 | npm audit de dependencias | `npm run hook:npm-audit` (o `pnpm audit --audit-level=high`) | ⬜ |
| 13 | Dependency validator | `npm run deps:check` | ⬜ |
| 14 | Documentar incidentes previos | Revisar `docs/incidents/` (p. ej. `LESSONS-LEARNED-HOOKS-INCIDENT.md`) | ⬜ |
| 15 | Stack verify completo | `npm run stack:verify` | ⬜ |

**Criterio de salida**: todos los items marcados ✅ antes del kickoff. Cualquier hallazgo
CRITICAL/HIGH debe remediarse o documentarse como hallazgo conocido para el firm.

---

## 6. Entregables del Audit

| # | Entregable | Descripción | Responsable |
| - | ---------- | ----------- | ----------- |
| 1 | **Reporte del firm externo** | Documento profesional con metodología, scope ejecutado, hallazgos por severidad, evidencia | Firma externa |
| 2 | **Log de hallazgos** | Registro en la tabla de la sección 7 — cada hallazgo con severidad, estado y responsable | GOV |
| 3 | **Plan de remediación con SLAs** | Acciones por hallazgo con deadline (CRITICAL: 7d, HIGH: 14d, MEDIUM: 30d, LOW: 90d) | GOV + DEV |
| 4 | **Resumen ejecutivo board-ready** | 1-2 páginas: postura general, top hallazgos, plan de acción | GOV |
| 5 | **Actualización del inventario** | Revisar sección 4 — marcar controles validados, añadir nuevos | GOV |

---

## 7. Log del Audit

Registro cronológico del ciclo de auditoría. Append-only — cada fila se añade, nunca se borra.

| Fecha | Fase | Hallazgo | Severidad | Estado | Responsable |
| ----- | ---- | -------- | --------- | ------ | ----------- |
| 2026-08-16 | Plan | Plan de auditoría anual creado (roadmap 5.2) | INFO | ✅ Cerrado | GOV |
| 2026-08-16 | Plan | Log de auditoría inicializado | INFO | ✅ Cerrado | GOV |

> **Convención de estados**: ⬜ Abierto · 🔄 En progreso · ✅ Cerrado · ⚠️ Aceptado (riesgo residual
> documentado) · ❌ Bloqueado

---

## 8. Presupuesto

| Concepto | Estimación |
| -------- | ---------- |
| Honorarios firma externa | **$5,000 – $20,000** (varía por firma y alcance) |
| Horas de auditoría externa | **40 – 80 horas** |
| Horas internas (preparación + remediación) | 20 – 40 horas (GOV + OPS + DEV) |
| Herramientas (grype/trivy/gitleaks — open source) | $0 |

**Decisión de presupuesto**: aprobar rango $5-20k en Q3 2026. Seleccionar firma con experiencia en
TypeScript/Node, LLM/agentes (OWASP LLM Top 10, OWASP Agentic) y compliance SOC2/GDPR.

---

## 9. Criterios de Éxito

Checklist de validación al cierre del ciclo (Q4 2026):

- [ ] **Board-ready**: resumen ejecutivo entregado y presentado a dirección
- [ ] **Hallazgos priorizados**: todos los hallazgos del firm registrados en el log (sección 7) con
      severidad asignada
- [ ] **Remediación trackeada**: plan de remediación con SLAs aprobado; cada hallazgo tiene
      responsable y deadline
- [ ] **CRITICAL/HIGH remediados**: 100% de hallazgos CRITICAL y HIGH remediados o aceptados con
      riesgo residual documentado
- [ ] **Inventario actualizado**: sección 4 refleja controles validados y nuevos
- [ ] **Lecciones aprendidas**: documentadas en `docs/incidents/` o `docs/security/`
- [ ] **Recurrencia programada**: próxima auditoría agendada (Q4 2027)
- [ ] **Evidencia archivada**: reporte del firm + log + plan de remediación archivados en
      `reports/` o `.archive/` (según `docs/security/README.md`)

---

## Referencias

- `docs/guides/STACK-OPTIMIZATION-ROADMAP.md` — sección 5.2 (línea 552), línea 524 ("No annual
  security audit log")
- `docs/security/SECURITY.md` — política de seguridad, controles, compliance frameworks
- `docs/security/SECURITY-IMPROVEMENTS.md` — historial de mejoras de seguridad
- `docs/security/SECURITY-USAGE-EXAMPLES.md` — ejemplos de uso de herramientas de seguridad
- `sbom.json` — SBOM CycloneDX 1.7 (1256 componentes)
- `.lefthook.yml` — hooks pre-commit/pre-push
- `.github/workflows/ci.yml` + `.github/workflows/security.yml` — CI/CD
- `config/` — security-policy, rbac-policy, access-control, secrets-governance, safety-layer,
  secret-scanner
- `.opencode/skills/` — 25 skills de ciberseguridad absorbidas (NIST, ISO, GDPR, OWASP, garak,
  promptfoo, SBOM, gitleaks, MCP tool-poisoning, etc.)