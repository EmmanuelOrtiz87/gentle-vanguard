# NORMATIVA: Autonomous Evolution (v6.0)

**Versión:** 1.0 | **Vigente desde:** July 6, 2026 | **Aplica a:** v6.0+

## 1. Propósito

Habilitar la evolución autónoma de agentes mediante retroalimentación de evaluaciones, colaboración
cross-workspace, revisión de código autónoma y respuesta predictiva a incidentes.

## 2. Self-Evolving Agents

### 2.1 Ciclo de Evolución

- `self-evolve-engine.ps1` evalúa score vs threshold → si score < threshold, muta
- Estrategias de mutación: prompt-tuning (50%), skill-composition (30%), tool-selection (20%)
- Toda mutación debe pasar A/B test contra champion actual
- Si score drop > 0.2 post-mutación → rollback automático

### 2.2 Safety Guards

- Máximo 5 mutaciones por día por agente
- Cooldown de 60 minutos entre mutaciones
- Patrones bloqueados: no pueden mutarse (delete, rm -rf, drop table, etc.)
- Después de 10 mutaciones totales: requiere aprobación humana

### 2.3 Evolution Logging

- Cada mutación se registra en `.session/evolution/<agentId>/` con timestamp
- `Get-EvolutionLog` must show strategy, scoreBefore, status
- Evolution log es inmutable (solo append)

## 3. Cross-Workspace Collaboration

### 3.1 Mesh Discovery

- Cada workspace expone `.workspace/manifest.json` con capabilities y agent scores
- Mesh seed via `$env:GENTLE_MESH_SEED` o escaneo de directorios hermanos
- Solo capabilities se comparten — NUNCA código ni payloads

### 3.2 Task Delegation

- `Invoke-MeshDelegate` registra delegación en `.session/mesh/`
- Solo tareas cuyas capabilities coinciden pueden delegarse
- Resultados de delegación se almacenan para auditoría

## 4. Autonomous Code Review

### 4.1 Pre-Commit Review

- `auto-code-review.ps1` se ejecuta en pre-commit hook
- Security issues: BLOCK commit inmediatamente
- Style issues: auto-fix + re-stage automáticamente
- Performance/SDD issues: WARNING en commit message

### 4.2 PR Review

- Workflow GitHub Actions ejecuta auto-code-review en cada PR
- Comentarios automáticos en PR via GENTILE_REVIEWER identity
- Criteria: style, security, performance, correctness, SDD compliance

## 5. Predictive Incident Response

### 5.1 Anomaly Detection

- `predictive-incident-response.ps1` analiza métricas cada ciclo
- Modelo: moving average + 3σ threshold (sin dependencia ML)
- Mínimo 10 data points antes de predecir

### 5.2 Preemptive Healing

- Confianza > 70% → trigger `maintenance-watchtower.ps1 -Action autoheal`
- False positives: ajuste automático de threshold (+0.05 por FP)
- True positives: ajuste de threshold (−0.01 por TP)

### 5.3 Learning

- `-Action learn` recalibra thresholds basado en historial
- Si false positive rate > 30% → threshold +0.5
- Si false positive rate < 10% (y >5 predicciones) → threshold −0.3

## 6. Excepciones

- Agentes con score > threshold no se mutan (excepto `-Force`)
- Cross-workspace deshabilitado si no hay `GENTLE_MESH_SEED`
- Predictive response deshabilitado si no hay `.telemetry/metrics/` ni dashboard WS

## 7. Penalizaciones

- Mutación que causa regression > 0.3 → pausa de evoluciones por 24h
- Cross-workspace sin manifest → exclusion del mesh
- Auto-review false positive rate > 50% → threshold +1.0
