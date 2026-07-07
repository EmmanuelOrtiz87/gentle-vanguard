# NORMATIVA: Evaluation & Quality Gates (v5.1)

**Versión:** 1.0 | **Vigente desde:** July 6, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Establecer un framework formal de evaluación y calidad para medir precisión de skills, efectividad
de prompts y rendimiento de agentes.

## 2. Reglas

### 2.1 Eval Suites Obligatorias

- Todo skill core debe tener una suite en `.eval/suites/<skill>.json`
- Mínimo 5 casos de prueba por suite
- Los suites deben versionarse (campo `version` en el JSON)
- Los casos deben cubrir: caso base, edge case, caso vacío/nulo

### 2.2 Eval Runner

- `eval-runner.ps1` es la interfaz única para ejecutar evaluaciones
- Resultados se almacenan en `.session/eval/results/<skill>/` con timestamp
- Cada ejecución debe exportarse con `-Export` para pipeline chaining

### 2.3 Quality Gates

- `config/eval-gates.json` define thresholds por skill
- `minScore` default: 0.7. `minPassRate` default: 80%
- Si un skill no alcanza el threshold: el pipeline step correspondiente se BLOQUEA
- Quality gates se ejecutan como paso opcional en `session-autostart.config.json`

### 2.4 A/B Prompt Testing

- Todo cambio de prompt debe pasar por `ab-prompt-runner.ps1`
- Delta mínimo para declarar ganador: 0.05 (configurable)
- Resultados almacenados en `.session/eval/ab-results/`
- Recomendación: PREFER_A, PREFER_B, o INCONCLUSIVE

### 2.5 Benchmarking

- `eval-registry.ps1 -Action list` muestra historial de resultados
- `eval-registry.ps1 -Action compare` compara dos ejecuciones
- `eval-registry.ps1 -Action prune` elimina resultados >90 días

## 3. Excepciones

- Skills en desarrollo (version < 1.0) exentos de quality gates
- Hotfixes pueden saltar eval con aprobación explícita

## 4. Penalizaciones

- Deploy sin pasar quality gates → rollback automático
- Suite desactualizada >30 días → alerta en dashboard
