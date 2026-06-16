# NORMATIVAS-COST-OPTIMIZATION.md — Cloud & API Cost Optimization

**Version:** 1.0.0 **Last updated:** 2026-06-01

---

## 1. PROPOSITO

Define estándares para optimización de costos en servicios cloud, APIs de LLM, y recursos de
infraestructura en Gentle-Vanguard.

---

## 2. PRINCIPIOS DE COST OPTIMIZATION

| Principio                    | Descripción                                              |
| ---------------------------- | -------------------------------------------------------- |
| **Medir antes de optimizar** | Todo cambio de costo debe estar basado en métricas       |
| **Costo por feature**        | Cada feature debe tener costo asociado trazable          |
| **Automatizar**              | Políticas de costos deben ser automatizadas, no manuales |
| **Right-size**               | Usar el modelo/recurso mínimo que cumpla el requisito    |

---

## 3. API COST GOVERNANCE

### 3.1 Model Routing por Costo

| Tarea                 | Modelo Recomendado      | Costo / 1K tokens | Notas                 |
| --------------------- | ----------------------- | ----------------- | --------------------- |
| Títulos, compactación | `qwen-3.6-plus` (small) | ~$0.00015         | Modelo barato         |
| DEV tasks             | `qwen-3.6-plus`         | ~$0.0003          | Balance costo/calidad |
| QA / OPS / GOV        | `kimi-k2.6`             | ~$0.0005          | Alta precisión        |
| BA / SAD (complejo)   | `kimi-k2.6`             | ~$0.0005          | Contexto largo        |
| Legal                 | `claude-haiku`          | ~$0.0008          | Mayor precisión       |

### 3.2 Token Budget Enforcement

Config en `config/orchestrator.json#subagent_orchestration.token_budget_guard`:

```json
{
  "dailyBudget": 30000,
  "softThresholdPct": 0.7,
  "hardThresholdPct": 0.9,
  "costAlertPct": 0.8
}
```

- Al 70% → WARN (notificar usuario)
- Al 80% → WARN + cost alert (notificar a GOV)
- Al 90% → BLOCK (detener dispatch de agentes)

### 3.3 Cache para Reducir Costos

| Cache                     | TTL    | Ahorro estimado       |
| ------------------------- | ------ | --------------------- |
| Response cache (SHA256)   | 30 min | 33-41%                |
| Pre-process trigger cache | Sesión | ~200ms/llamada        |
| Provider state cache      | 5 min  | Reduce failover calls |

---

## 4. PROVIDER COST COMPARISON

### 4.1 Active Providers

| Provider       | Modelo Principal | Costo/1K in | Costo/1K out | Especialidad       |
| -------------- | ---------------- | ----------- | ------------ | ------------------ |
| OpenRouter     | Qwen 3.6 Plus    | $0.00015    | $0.00015     | Balance general    |
| OpenRouter     | Kimi K2.6        | $0.00027    | $0.00027     | Contexto largo     |
| Anthropic      | Claude Haiku     | $0.00025    | $0.00125     | Precisión legal    |
| Ollama (local) | Qwen3 Coder 30B  | Gratis      | Gratis       | Desarrollo offline |

### 4.2 Cost Optimization Rules

1. **MUST** usar `provider-failover.ps1` con prioridad: OpenRouter → Anthropic (no al revés)
2. **MUST** usar `cost-optimizer.ps1` para seleccionar provider más barato disponible
3. **SHOULD** usar Ollama para tareas de desarrollo y pruebas
4. **SHOULD** habilitar `setCacheKey: true` en todos los providers
5. **MUST** registrar costos por sesión en `.session/token-spend.json`

---

## 5. CLOUD INFRASTRUCTURE COSTS

### 5.1 GitHub Actions

| Práctica                               | Ahorro                                      |
| -------------------------------------- | ------------------------------------------- |
| `concurrency.cancel-in-progress: true` | Evita ejecuciones duplicadas                |
| `timeout-minutes` en cada job          | Evita runners colgados                      |
| `paths:` filter en triggers            | Ejecuta solo cuando cambia código relevante |
| Usar `ubuntu-latest` por defecto       | Más barato que `windows-latest`             |
| Cachear dependencias                   | Reduce tiempo de instalación                |

### 5.2 Runner Selection

| Runner  | Costo/min | Usar para                                |
| ------- | --------- | ---------------------------------------- |
| Ubuntu  | $0.008    | Lint, build, test, security              |
| Windows | $0.016    | PowerShell tests (solo cuando necesario) |
| macOS   | $0.08     | Solo cross-platform obligatorio          |

**Regla**: Usar `runs-on: ubuntu-latest` salvo que el paso REQUIERA Windows/macOS.

---

## 6. COST MONITORING & ALERTS

### 6.1 Métricas de Costo

```yaml
# Recolectadas por: cost-optimizer.ps1
# Almacenadas en: .session/token-spend.json
- metric: daily_token_cost
  target: < $1.00/day
  warning: $1.00-$2.00
  critical: > $2.00

- metric: monthly_api_cost
  target: < $25.00/month
  warning: $25-$50
  critical: > $50
```

### 6.2 Alertas Automáticas

| Evento                      | Acción                     |
| --------------------------- | -------------------------- |
| Daily cost > 80% budget     | WARN al usuario + log      |
| Daily cost > 100% budget    | BLOCK nuevos dispatches    |
| Provider cost > alternative | Sugerir cambio de provider |
| Cache hit rate < 20%        | Revisar patrón de uso      |

---

## 7. ANNUAL COST REVIEW

- **Quarterly**: Revisar costos por provider, optimizar routing
- **Semi-annual**: Evaluar nuevos modelos/providers más baratos
- **Annual**: Renegociar contracts, revisar budget

---

## 8. COMPLIANCE CHECKPOINTS

- [ ] Token budget guard activo en orquestador
- [ ] Cost optimizer configurado con todos los providers
- [ ] Response cache habilitado (SHA256, TTL 30min)
- [ ] Provider failover con prioridad de costo
- [ ] Concurrency control en todos los workflows
- [ ] Session cost tracking en `.session/token-spend.json`
- [ ] Alertas de costo configuradas
- [ ] Cache hit rate monitoreado

---

## 9. REFERENCES

| Resource            | Path                                                |
| ------------------- | --------------------------------------------------- |
| Provider Costs      | `config/provider-costs.json`                        |
| Cost Optimizer      | `scripts/utilities/MODEL-ROUTER/cost-optimizer.ps1` |
| Token Guard         | `scripts/utilities/token-guard.ps1`                 |
| Provider Failover   | `scripts/utilities/provider-failover.ps1`           |
| Orchestrator Config | `config/orchestrator.json`                          |

---

_Version: 1.0.0 — 2026-06-01 — Status: ACTIVE_
