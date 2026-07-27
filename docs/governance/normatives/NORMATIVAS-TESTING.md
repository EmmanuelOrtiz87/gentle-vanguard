# NORMATIVAS-TESTING.md

Version: 1.0.0

---

## 1. PROPOSITO

Define la estrategia de testing para el stack Gentle-Vanguard y sus agentes. Aplica a todo codigo
nuevo y refactors.

---

## 2. PIRAMIDE DE TESTING

### 2.1 Distribucion Objetivo

- Unit tests: ~70% (no tocan LLM, mock responses)
- Integration tests: ~20% (usan LLM real, modelo barato en CI)
- E2E evaluations: ~10% (golden datasets, LLM-as-judge, pre-release)

### 2.2 Unit Tests (OBLIGATORIO)

1. **MUST** testear tools independientemente del LLM (input conocido -> output esperado)
2. **MUST** testear prompt templates (construccion, contexto, formato)
3. **MUST** testear output parsers (JSON malformed, missing fields, edge cases)
4. **MUST** testear routing logic (clasificacion, decision trees)
5. **MUST** testear guardrails (safety checks, content filtering)
6. **MUST** mockear LLM responses para tests deterministicos
7. **SHOULD** mantener temperatura=0 en config de tests

### 2.3 Integration Tests

1. **MUST** probar flujos completos con LLM real
2. **MUST** usar modelos mas baratos en CI (ej: gpt-4o-mini en lugar de gpt-4o)
3. **MUST** marcar tests como `[Integration]` para ejecucion selectiva
4. **MUST** ejecutar en merge a main, no en cada PR
5. **SHOULD** implementar retry con budget (3 intentos, pasa si alguno funciona)
6. **SHOULD** trackear costos de LLM en integration tests

### 2.4 E2E Evaluations

1. **MUST** mantener golden dataset de casos representativos con outputs esperados
2. **MUST** usar LLM-as-judge con rubrica detallada para evaluacion semantica
3. **MUST** medir: correctness, safety, format compliance, latency, robustness
4. **MUST** usar acceptance bands en lugar de pass/fail (non-determinismo)
5. **SHOULD** ejecutar suite completa pre-release o semanalmente
6. **SHOULD** version-lock model, system prompt, tool schemas en cada eval

### 2.5 Regression Testing

1. **MUST** ejecutar suite completa ante cambios de: prompt, modelo, RAG index, tool schemas
2. **MUST** trackear metricas a lo largo del tiempo
3. **SHOULD** alimentar failures de produccion al test suite como nuevos casos

---

## 3. CRITERIOS DE ACEPTACION

### 3.1 Code Coverage Targets

- Unit tests: > 80% coverage en codigo nuevo
- Integration tests: todos los flujos principales cubiertos
- E2E: caminos criticos de usuario cubiertos

### 3.2 Quality Gates

| Check              | PR Block    | Main Block | Frecuencia   |
| ------------------ | ----------- | ---------- | ------------ |
| Lint               | YES         | YES        | Cada commit  |
| Unit tests         | YES         | YES        | Cada PR      |
| Integration tests  | NO (report) | YES        | Merge a main |
| Coverage drop >5%  | NO (report) | YES        | Merge a main |
| Safety regressions | YES         | YES        | Cada PR      |
| Format compliance  | YES         | YES        | Cada PR      |
| Cost anomaly       | NO          | NO         | Nightly      |

---

## 4. ESTRUCTURA DE TESTS

### 4.1 Ubicacion

```
tests/
  unit/          # Tests sin LLM, mockeados
  integration/   # Tests con LLM real (modelo barato)
  e2e/           # Golden datasets + LLM-as-judge
  fixtures/      # Mocks, test data, golden datasets
```

### 4.2 Nomenclatura

- `<component>.<type>.tests.ps1` (PowerShell)
- `<component>.<type>.test.py` (Python)
- Tests sin LLM: sufijo `.unit`
- Tests con LLM: sufijo `.integration`

---

## 5. CI/CD INTEGRATION

```
Cada commit  -> Unit tests (segundos, gratis)
Cada PR      -> Unit + safety + format (minutos, bajo costo)
Merge main   -> Integration tests (modelo barato)
Nightly      -> Suite E2E completa (moderado)
Pre-release  -> Full suite + adversarial
```

---

## 6. REFERENCIAS

- Config: config/testing-policy.json
- Testing LLM Applications: enricopiovano.com/blog/testing-llm-applications-practical-guide
- AI Agent Testing: agent-patterns.readthedocs.io/en/stable/guides/testing.html
