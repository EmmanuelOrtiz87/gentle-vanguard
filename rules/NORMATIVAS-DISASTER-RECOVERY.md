# NORMATIVAS-DISASTER-RECOVERY.md — Disaster Recovery & Business Continuity

**Version:** 1.0.0 **Last updated:** 2026-06-01

---

## 1. PROPOSITO

Define el plan de Disaster Recovery (DR) y continuidad de negocio para Gentle-Vanguard. Aplica a
datos, configuraciones, y servicios críticos.

---

## 2. RECOVERY OBJECTIVES

| Métrica         | Objetivo  | Descripción                             |
| --------------- | --------- | --------------------------------------- |
| **RPO**         | 1 hora    | Máxima pérdida de datos aceptable       |
| **RTO**         | 4 horas   | Tiempo máximo para restaurar servicio   |
| **MTO**         | 8 horas   | Tiempo máximo de interrupción tolerable |
| **RPO crítico** | 5 minutos | Datos de configuración y session state  |

---

## 3. BACKUP HIERARCHY

| Tier   | Contenido                       | Frecuencia  | Retención | Método                    |
| ------ | ------------------------------- | ----------- | --------- | ------------------------- |
| **T1** | Engram DB (memoria persistente) | Post-sesión | 30 días   | `backup-engram.ps1` → Git |
| **T2** | Configs JSON (`config/*.json`)  | Por cambio  | 90 días   | Git versionado            |
| **T3** | Session state (`.session/`)     | Post-sesión | 7 días    | Git + backup local        |
| **T4** | Logs (`logs/`, `.runtime/`)     | Diario      | 30 días   | Archivo comprimido        |
| **T5** | Build artifacts (`dist/`)       | Por release | 1 año     | GitHub Releases           |

---

## 4. BACKUP AUTOMATION

### 4.1 Engram Backup (T1)

```powershell
# Auto-ejecutado al cerrar sesión (session-manager.ps1 End-Session)
pwsh -File scripts/utilities/BACKUP-RESTORE/backup-engram.ps1 -Mode backup

# Verificación semanal automática
pwsh -File scripts/utilities/BACKUP-RESTORE/backup-engram.ps1 -Mode verify
```

### 4.2 Config Backup (T2)

```powershell
# Backup point-in-time de configs
git archive --output=backup/config-$(Get-Date -Format 'yyyyMMdd').zip HEAD:config/
```

### 4.3 Automated Schedule

| Backup       | Schedule              | Herramienta           |
| ------------ | --------------------- | --------------------- |
| T1 - Engram  | Post-sesión           | `session-manager.ps1` |
| T2 - Configs | Cada commit           | Git nativo            |
| T3 - Session | Post-sesión           | `session-manager.ps1` |
| T4 - Logs    | Semanal (domingo 2AM) | Cron + script         |
| T5 - Build   | Cada release          | GitHub Actions        |

---

## 5. RECOVERY PROCEDURES

### 5.1 Engram Recovery

```powershell
# Listar backups disponibles
pwsh -File scripts/utilities/BACKUP-RESTORE/backup-engram.ps1 -Mode status

# Restaurar backup específico
pwsh -File scripts/utilities/BACKUP-RESTORE/backup-engram.ps1 -Mode restore -BackupFile .engram-backups/engram-20260601.ndjson
```

### 5.2 Config Recovery

```powershell
# Restaurar configs desde Git
git checkout <commit-hash> -- config/
```

### 5.3 Full Disaster Recovery

```
1. DETECTAR → health-check.ps1 reporta componente caído
2. AISLAR → circuit-breaker.json abre para el componente afectado
3. EVALUAR → evaluar si es failover o restore from backup
4. RECUPERAR → ejecutar procedimiento específico
5. VERIFICAR → health-check.ps1 confirma recuperación
6. NOTIFICAR → reportar incidente + lecciones aprendidas
```

---

## 6. DISASTER SCENARIOS

| Escenario             | Impacto                        | RTO   | Procedimiento                                 |
| --------------------- | ------------------------------ | ----- | --------------------------------------------- |
| Engram DB corrupta    | Pérdida de memoria persistente | 1h    | Restore from T1 backup                        |
| Config corrupta       | Framework no funciona          | 30min | `git checkout` + `validate-configs.ps1`       |
| Git repo dañado       | Pérdida de código              | 4h    | Clone from remote + restore local             |
| LLM provider outage   | Agentes no funcionales         | 5min  | `provider-failover.ps1` cambia provider       |
| GitHub Actions outage | CI/CD caído                    | 2h    | Local execution + manual deploy               |
| Disco lleno           | Scripts fallan                 | 1h    | Cleanup `logs/`, `.session/`, `node_modules/` |

---

## 7. BUSINESS CONTINUITY

### 7.1 Degraded Mode

Cuando un componente crítico no está disponible, operar en modo degradado:

| Componente Caído | Modo Degradado                          |
| ---------------- | --------------------------------------- |
| Engram           | Sin memoria persistente, pero funcional |
| OpenRouter       | Failover a Anthropic o Ollama local     |
| CodeGraph        | Sin indexación, grep/glob como fallback |
| GitHub           | Trabajar local, sync cuando disponible  |

### 7.2 Offline Mode

Gentle-Vanguard MUST funcionar completamente offline con Ollama local:

```powershell
# Cambiar a provider local
provider-failover.ps1 -Mode force-local
```

---

## 8. DR TESTING

| Test             | Frecuencia | Procedimiento                      |
| ---------------- | ---------- | ---------------------------------- |
| Backup integrity | Semanal    | `backup-engram.ps1 -Mode verify`   |
| Recovery drill   | Mensual    | Restore en entorno aislado         |
| Failover test    | Mensual    | `provider-failover.ps1 -TestAll`   |
| Full DR drill    | Trimestral | Simular caída total, medir RTO/RPO |

---

## 9. COMPLIANCE CHECKPOINTS

- [ ] RPO/RTO definidos y documentados
- [ ] Backups T1-T5 configurados y automatizados
- [ ] Procedimientos de recovery documentados
- [ ] Modo degradado funcional para cada componente crítico
- [ ] DR testing programado y ejecutado
- [ ] Offline mode verificado
- [ ] Contactos de emergencia definidos

---

## 10. REFERENCES

| Resource          | Path                                                 |
| ----------------- | ---------------------------------------------------- |
| Engram Backup     | `scripts/utilities/BACKUP-RESTORE/backup-engram.ps1` |
| NORMATIVA Backup  | `rules/NORMATIVA-ENGRAIN-BACKUP.md`                  |
| Health Check      | `scripts/health-check/health-check.ps1`              |
| Circuit Breaker   | `config/circuit-breaker.json`                        |
| Provider Failover | `scripts/utilities/provider-failover.ps1`            |
| SRE Practices     | `docs/NORMATIVAS-SRE.md`                             |

---

_Version: 1.0.0 — 2026-06-01 — Status: ACTIVE_
