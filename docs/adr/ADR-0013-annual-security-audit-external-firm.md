# ADR-0013: Annual Security Audit (External Firm, Q4 Recurrence)

## Status

Accepted

## Date

2026-08-17

## Context

El roadmap de seguridad (`docs/guides/STACK-OPTIMIZATION-ROADMAP.md`, item 5.2) identificaba la
necesidad de una **auditoría de seguridad externa anual**. El stack cuenta con defensas nativas
extensas (secret-scanner, SBOM, SLSA provenance, npx hardening, homologation gate, watchtower con
95 checks) pero ninguna validación third-party independiente.

### Opciones consideradas

| Opción | Pros | Cons | Decisión |
| --- | --- | --- | --- |
| Solo auditoría interna | Cero costo, sin fricción | Sesgo del equipo que construyó las defensas; no detecta problemas sistémicos normalizados | ❌ Rechazada |
| **Auditoría externa anual** | Validación independiente, board/audit-ready, catch systemic issues | Costo ($5-20k), requiere preparación | ✅ **CHOSEN** |
| Auditoría externa bianual | Menor costo recurrente | Ventana de riesgo más larga entre auditorías | ❌ Rechazada |

## Decision

**Contratar una firma de seguridad externa para una auditoría anual**, con recurrencia en Q4 de
cada año. El plan operativo completo está en `docs/security/ANNUAL-AUDIT-PLAN.md` (26 controles
inventariados, checklist pre-audit de 15 items, log de hallazgos inicializado).

### Timeline

| Fase | Ventana | Estado |
| --- | --- | --- |
| Plan | Q3 2026 (creado 2026-08-16) | ✅ ACTIVO |
| Preparación | Q3 2026 (Sep) | ⏳ Pendiente |
| Ejecución | Q4 2026 (Oct-Nov) | ⏳ Pendiente |
| Reporte + remediación | Q4 2026 (Nov-Dic) | ⏳ Pendiente |
| Recurrencia | Anual (Q4) | 🔁 Recurrente |

### Alcance

1. Code review (seguridad del código TS)
2. Dependency audit (validación del SBOM + supply-chain)
3. Configuration review (CI/CD, hooks, secrets management)

## Consequences

### Positive

- ✅ Validación third-party independiente de las defensas nativas
- ✅ Documentación board/audit-ready (reporte, log de hallazgos, plan de remediación)
- ✅ Detección de problemas sistémicos que las defensas internas normalizan
- ✅ Cierra el ciclo de mejora continua (hallazgos → remediación → re-auditoría)

### Negative

- ⚠️ Costo recurrente ($5-20k por ciclo)
- ⚠️ Requiere preparación (checklist pre-audit, paquete de contexto para la firma)
- ⚠️ Los hallazgos pueden requerir remediación con SLAs que compiten con el roadmap de features

### Mitigation

- Preparación Q3 con checklist de 15 items (sección 5 del plan)
- Presupuesto anual asignado en Q1
- Tracking de hallazgos en el log hasta remediación (SLAs por severidad)

## Related

- **Related**: ADR-0014 (SLSA provenance — supply-chain attestation), ADR-0011 (dependency updates),
  ADR-0009 (watchtower — 95 checks internos)
- **Plan operativo**: `docs/security/ANNUAL-AUDIT-PLAN.md`

## References

- `docs/security/ANNUAL-AUDIT-PLAN.md` — plan operativo completo
- `docs/guides/STACK-OPTIMIZATION-ROADMAP.md` — item 5.2

---

**Review Date**: Q1 2027
**Reviewers**: GOV (Governance Agent), OPS