# NORMATIVAS-ORQUESTADOR.md

Versión: 2.0.0  
Autor: workspace-foundation  
Fecha: 2026-05-09

---

## 1. PROPÓSITO

Este documento define las normativas, reglas y restricciones que **TODO** agente y subagente debe
respetar en el workspace `workspace-foundation`.

---

## 2. REGLAS OBLIGATORIAS (BLOCKING)

Estas reglas **NO PUEDEN** ser omitidas, sobreescritas o depriorizadas bajo ninguna circunstancia:

### 2.1 Persistencia en Engram

1. **MUST** llamar `mem_save` INMEDIATAMENTE después de:
   - Decisión de arquitectura tomada
   - Bug fix completado (incluir root cause)
   - Patrón establecido (naming, estructura)
   - Configuración cambiada o entorno setup
   - Descubrimiento no obvio sobre el codebase
2. **MUST** llamar `mem_search` antes de:
   - Empezar trabajo que pueda haber sido hecho antes
   - Usuario menciona un tópico sin contexto
   - Primera mensaje referencia al proyecto, feature o problema

3. **MUST** ejecutar `mem_session_summary` antes de:
   - Terminar sesión ("done", "listo", "terminamos")
   - Hacer commit o push
   - Informar "done" al usuario

### 2.2 Session Management

4. **MUST NOT** declarar `JUDGMENT: APPROVED` hasta:
   - Round 1 judges return CLEAN, O
   - Round 2 judges confirm 0 CRITICALs + 0 confirmed real WARNINGs
5. **MUST NOT** ejecutar `git push`, `git commit`, o cualquier acción que modifique código después
   de fixes hasta que re-judgment complete.

6. **MUST NOT** guardar session summary o decir "done" hasta que cada JD (Judgment Day) alcance
   estado terminal (APPROVED o ESCALATED).

### 2.3 Cross-Session Continuity

7. **MUST** preservar estado en compaction:
   - `active-delegations.json` para delegaciones activas
   - `orchestrator-state.json` para estado completo
   - `mem_session_summary` para persistir aprendizaje PREVIO a compaction

8. **MUST** recuperar estado después de compaction:
   - Leer `mem_context` inmediatamente después de compaction
   - Restaurar `Restore-OrchestratorState` si existe
   - SOLO ENTONCES continuar trabajando

---

## 3. CONVENCIONES DE CÓDIGO Y DOCUMENTACIÓN

### 3.1 Skill Structure (SKILL.md)

TODO skill DEBE tener:

- **Deliverables** section (template con ejemplos)
- **Success Metrics** section (cómo medir éxito)
- **Communication Style** section (formato: "Be X", "Focus on Y", "Think Z", "Ensure clarity")

### 3.2 Behavior Prompts (config/behavior-prompts.json)

TODO behavior prompt DEBE tener:

- **vibe**: Descripción de personalidad (e.g., "focused and architectural")
- **emoji**: Emojis representativos (e.g., "🏗️📦⚙️")
- **communication_style**: Formato estructurado igual que SKILL.md

### 3.4 PR Template Standards

TODO PR DEBE seguir `.github/PULL_REQUEST_TEMPLATE.md`:

- **Summary**: Qué y por qué (una línea)
- **Changes**: Lista de cambios clave
- **Testing**: Checklist de pruebas realizadas
- **Related**: Issues, ADRs, SDDs relacionados

### 3.5 Python Code Standards (via Ruff)

TODO archivo `.py` DEBE cumplir con las reglas definidas en `pyproject.toml`:

- `ruff check .` — linting obligatorio
- `ruff format .` — formato obligatorio
- `pytest --cov` — coverage mínimo 80%
- `pyproject.toml` contiene toda la configuración centralizada

### 3.6 Secret Scanning Standards

TODO commit DEBE pasar:

1. **TruffleHog** (pre-push hook): scan completo de diff
2. **Gitleaks** (CI workflow): scan en PR/push a main/develop
3. **Secretlint** (pre-commit hook): scan de archivos staged

- `.gitleaks.toml` extiende reglas default con allowlists del proyecto
- Falsos positivos documentados en `.gitleaksignore` o `.secretlintignore`

### 3.3 Subagent Mapping (config/subagent-mapping.json)

- Mapear 7 agentes → opencode subagent types
- `BA` → `sdd-explore`
- `SAD` → `sdd-design`
- `DEV` → `sdd-apply`
- `QA` → `sdd-verify`
- `DOC` → `sdd-spec`
- `OPS/GOV` → `general`

---

## 4. ARQUITECTURA DE ORQUESTACIÓN

### 4.1 Tiered Routing (auto-delegation.json)

- **Tier 0**: Exact match (priority highest)
- **Tier 1**: Regex match
- **Tier 2**: Wildcard/fallback

### 4.2 Concurrency Control

- Semáforos por agente tipo (`agentSemaphores`)
- Límites: BA=2, DEV=3, QA=3, default=3
- Timeout: 300s para adquirir slot

### 4.3 Circuit Breaker Pattern

- **CLOSED**: Normal operation
- **OPEN**: Trip after 3 failures, 60s timeout
- **HALF_OPEN**: Testing recovery after timeout
- **Record-Success**: Reset on recovery
- **Record-Failure**: Incrementa failure count

### 4.4 Cross-Repo Sync Automation

- `sync-public.yml` workflow corre automáticamente en push a `main`
- Sincroniza skills (stubs públicos), configs, installer y docs
- Usa `PAT_SYNC` secret para autenticarse en foundation-public
- Requiere `skipPush` para dry-runs locales

### 4.5 Branch Protection Rulesets

- `main`: Requiere PR + 1 approval + status checks (tests, gitleaks, lint, format)
- `develop`: Requiere PR + 1 approval (lighter rules)
- Rulesets gestionados via `setup-branch-protection.ps1` usando `gh api`
- **MUST** ejecutar script después de crear nuevo repo

### 4.6 Skill Dependency Graph (config/skill-dependencies.json)

- `sdd-apply` REQUIRES `sdd-design` + `sdd-spec` (blocking)
- `sdd-verify` REQUIRES `sdd-apply` (blocking)
- `sdd-archive` REQUIRES `sdd-verify` (blocking)
- Non-blocking deps: warn but continue

---

## 5. METRICS & OBSERVABILITY

### 5.1 Metrics Tracked (config/metrics-config.json)

- `delegation_success_rate`: Target 95%
- `delegation_failure_rate`: Target <5%
- `average_time_to_completion`: Target <180s
- `token_usage_per_session`: Target <100K
- `circuit_breaker_trips`: Target 0
- `skill_dependency_violations`: Target 0

### 5.2 Per-Agent Metrics

- `general`: total/failures/successes/avg_time/last_success
- `sdd-apply`: (same)
- `sdd-design`: (same)
- `sdd-verify`: (same)

### 5.3 Alertas

- `low_success_rate`: <80% → Severity HIGH
- `circuit_open`: Circuit OPEN → Severity MEDIUM
- `slow_delegation`: >300s → Severity LOW

---

## 6. AI-NATIVE FEATURES (NIVEL 4)

### 6.1 Semantic Skill Matching

- Usar embeddings (Context7) para matching semántico
- Fallback: fuzzy matching + keyword
- Aprender de override del usuario ("siempre que mando X, elige Y")

### 6.2 Multi-Agent Consensus

- Fresh Eyes Validator: Tercer agente que revisa veredicto fríamente
- Usar cuando hay contradicciones entre Judge A y Judge B

### 6.3 Automated Learning

- `mem_save` automático después de cada delegación
- `mem_search` proactivo al inicio de tarea
- Skill Registry actualizado automáticamente tras nuevos skills

---

## 7. CONTEXTO ADAPTATIVO

### 7.1 Memory Tiering

- **Hot**: Active session, no compression
- **Warm**: Recent (1 day), 90% retention
- **Cold**: Archive (7 days), 70% retention

### 7.2 Pre-Compact Hook

Antes de compaction (~25k tokens), ejecutar:

```powershell
.\tools\pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90
```

### 7.3 Handoff Compression

Para transferencias agente-a-agente:

```powershell
.\tools\handoff-compress.ps1
```

- Preserva: decisions, results, pendientes, status flags
- Trunca: verbose outputs, repeated patterns
- Output: state-only handoff (~30% size reduction)

---

## 8. RESTRICCIONES DE SEGURIDAD

### 8.1 Credentials

- **MUST NOT** commitear `.env`, `credentials.json`, o archivos con secretos
- **MUST** usar `engram_mem_save` para persistir API keys (NO en archivos)

### 8.2 Secret Scanning

- **3-layer defense**: Secretlint (pre-commit) → TruffleHog (pre-push) → Gitleaks (CI)
- Gitleaks corre en cada PR/push a main/develop
- `.gitleaks.toml` extiende reglas default de Gitleaks
- Falsos positivos: añadir a allowlist en `.gitleaks.toml` o a `.gitleaksignore`

### 8.3 Code Safety

- **MUST NOT** usar `git push --force` a main/master sin permiso explicito
- **MUST NOT** commitear cambios sin revisión (Judgment Day)
- **MUST** verificar si hay autorización global antes de preguntar

---

## 9. COMPLIANCE CHECKPOINTS

TODO subagente DEBE verificar:

1. ✅ **Security Review**: ¿Hay exposición de secretos o auth deficiente?
2. ✅ **Scalability Check**: ¿Agrega deuda técnica o mejora escalabilidad?
3. ✅ **MVP Scope Validation**: ¿Cumple con el alcance mínimo viable?
4. ✅ **Documentation Updated**: ¿ESTÁN actualizadas Deliverables + Success Metrics?
5. ✅ **Engram Persisted**: ¿Se guardó en Engram con `mem_save`?

---

## 10. ORQUESTADOR DEBE CONOCER Y SABER

El orquestador **DEBE** conocer:

1. **Todos los skills disponibles** (130+ skills) con sus triggers
2. **Mapeo a subagent types** (config/subagent-mapping.json)
3. **Tiered routing** (auto-delegation.json)
4. **Concurrency limits** (agentSemaphores)
5. **Circuit breaker state** (para detectar agentes caídos)
6. **Skill dependencies** (para ejecución ordenada)
7. **Active delegations** (para crash recovery)
8. **Metrics & Observability** (para mejorar continuamente)
9. **Normativas aquí descritas** (LEER antes de operar)

---

## APÉNDICE: Quick Reference

### Comandos Críticos

| Comando                       | Propósito                              |
| ----------------------------- | -------------------------------------- |
| `mem_save`                    | Guardar aprendizaje INMEDIATAMENTE     |
| `mem_search`                  | Buscar trabajo previo ANTES de empezar |
| `mem_session_summary`         | Persistir sesión ANTES de terminar     |
| `Restore-OrchestratorState`   | Recuperar estado tras compaction       |
| `Save-OrchestratorState`      | Guardar estado para cross-session      |
| `Invoke-AutoDelegate`         | Delegar a subagente con resilience     |
| `Test-SkillDependencies`      | Verificar deps antes de ejecutar       |
| `setup-branch-protection.ps1` | Configurar rulesets via API            |
| `sync-to-public.ps1`          | Sincronizar repo privado → público     |
| `gitleaks` (CI)               | Secret scanning automático en PRs      |

### Formato de Comunicación

- **Be [X]**: "Be architectural: 'Built 3-tier...'"
- **Focus on [Y]**: "Focus on MVP: 'Starting with auth...'"
- **Think [Z]**: "Think full-stack: 'Frontend forms...'"
- **Ensure clarity**: "Status: 🟢 Ready | 🟡 Pending | 🔴 Blocked"

---

**FIN DEL DOCUMENTO** — TODO agente debe leer y cumplir estas normativas.
