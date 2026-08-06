# NORMATIVAS-ENFORCEMENT.md — Sistema de Enforcement Automático

> **Propósito**: Define cómo las normativas del stack Gentle-Vanguard son **validadas y aplicadas**
> automáticamente. **Estado**: ACTIVO (v2.0)

## Niveles de Enforcement

| Nivel               | Tag       | Acción                  | Ejemplo                                 |
| ------------------- | --------- | ----------------------- | --------------------------------------- |
| **🔴 BLOQUEANTE**   | `[BLOCK]` | Detiene pipeline/commit | Violación de seguridad, schema inválido |
| **🟡 WARNING**      | `[WARN]`  | Alerta sin bloquear     | Norma de estilo, optimización sugerida  |
| **🟢 ADVISORY**     | `[ADV]`   | Recomendación           | Mejora sugerida, refactor opcional      |
| **🤖 AUTO-CORRECT** | `[AUTO]`  | Corrige automáticamente | Formato JSON, hash desactualizado       |

## Automatización

### Pipeline de Enforcement

```
                     ┌─────────────────┐
                     │  Pre-Commit      │ ← lefthook + secretlint + karpathy
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │  Session Start   │ ← security-orchestrator + auto-norm-learner
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │  Auto-Apply      │ ← auto-apply-safe.ts (threshold >80%)
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │  Watchtower      │ ← maintenance-watchtower.ts (60 checks)
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │  Post-Session    │ ← self-reflection + audit pipeline
                     └─────────────────┘
```

### Gatillos de Enforcement

| Gatillo               | Herramienta                      | Nivel           |
| --------------------- | -------------------------------- | --------------- |
| `git commit`          | lefthook-hooks                   | 🔴 BLOQUEANTE   |
| `session-start`       | security-orchestrator            | 🔴 BLOQUEANTE   |
| `pre-process-input`   | input-validator                  | 🟡 WARNING      |
| Cada 30s (background) | maintenance-watchtower           | 🟡 WARNING      |
| Post-sesión           | auto-norm-learner                | 🟢 ADVISORY     |
| Auto-detección        | auto-apply-safe (confianza >80%) | 🤖 AUTO-CORRECT |

## Reglas de Enforcement por Componente

### 1. Configs (`config/*.json`)

- **[BLOCK]** Schema inválido → rechazar
- **[AUTO]** Hash/cache desactualizada → regenerar automáticamente
- **[WARN]** Config drift detectado → notificar

### 2. Normativas (`rules/`, `docs/governance/`)

- **[BLOCK]** Normativa requerida faltante → error en CI
- **[WARN]** Normativa desactualizada (última revisión >90 días) → notificar
- **[AUTO]** LEARNED-NORMS.md desactualizada → regenerar

### 3. Skills (`.opencode/skills/`)

- **[WARN]** Skill sin uso en 30 días → sugerir archive
- **[AUTO]** Skill sin uso en 60 días → archivar automáticamente
- **[AUTO]** Skill sin SKILL.md → marcar como incompleto

### 4. Seguridad

- **[BLOCK]** Secret detectado → detener commit
- **[BLOCK]** Vulnerability crítica → bloquear PR
- **[WARN]** Dependencia desactualizada → alertar

### 5. Sesiones

- **[WARN]** Sesión activa >8 horas → sugerir cleanup
- **[AUTO]** Sesión huérfana >24 horas → cerrar automáticamente
- **[WARN]** Token budget excedido 90% → alertar

## Auto-Correction Rules Engine

El `correction-rules-engine.ts` ejecuta estas reglas automáticamente:

```typescript
interface CorrectionRule {
  id: string;
  name: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  trigger: string; // patrón o condición
  autoFix: boolean; // ¿se puede aplicar automáticamente?
  fixScript: string; // script/función de corrección
  requiresApproval: boolean; // necesita aprobación humana
  maxRetries: number;
}
```

### Reglas Activas

| Regla                   | Trigger          | Auto | Acción                     |
| ----------------------- | ---------------- | ---- | -------------------------- |
| `config-drift`          | session-start    | ✅   | Re-sincronizar configs     |
| `orphan-session`        | session-start    | ✅   | Cerrar sesiones huérfanas  |
| `stale-checkpoint`      | session-start    | ✅   | Prune checkpoints >14 días |
| `wal-size`              | watchtower (30s) | ✅   | Checkpoint WAL si >1MB     |
| `token-budget-exceeded` | session-start    | ❌   | Alertar solo               |
| `skill-unused-archive`  | post-session     | ✅   | Archivar skills sin uso    |

## Escalation Path

```
1er fallo auto-heal   → [WARN]  → Log + reintento
2do fallo auto-heal   → [WARN]  → Log + reintento con backoff
3er fallo auto-heal   → [BLOCK] → Critical alert + detener pipeline
4to+ fallo            → [BLOCK] → Escalar a findings-ledger + event-store
```

## Métricas de Enforcement

| Métrica                         | Tracking        | Threshold |
| ------------------------------- | --------------- | --------- |
| Tasa de auto-corrección exitosa | auto-apply-safe | >90%      |
| Tiempo medio de detección       | watchtower      | <30s      |
| Falsos positivos                | action-log      | <5%       |
| Compliance score                | governance      | >95%      |

## Integración CI/CD

```yaml
# .github/workflows/governance.yml
jobs:
  enforce:
    steps:
      - run: npx tsx src/auto-norm-enforcer.ts --check
      - run: npx tsx src/config-diff-detector.ts --report
      - run: npx tsx src/auto-apply-safe.ts --apply
```

## Referencias

- `src/auto-apply-safe.ts` — Motor de auto-aplicación
- `src/auto-norm-enforcer.ts` — Enforcer de normativas
- `src/correction-rules-engine.ts` — Reglas de corrección automática
- `src/config-diff-detector.ts` — Detector de drift en configs
- `rules/adaptive/LEARNED-NORMS.md` — Normas aprendidas automáticamente
