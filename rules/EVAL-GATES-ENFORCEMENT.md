# EVAL-GATES-ENFORCEMENT — Ejecución de Compuertas de Calidad

**Versión:** 1.0 | **Vigente desde:** July 14, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Garantizar que todo código, skill o pipeline step supere umbrales de calidad objetivos antes de
avanzar a producción. Las compuertas de evaluación (eval gates) interceptan resultados por debajo
del umbral y bloquean el flujo o emiten advertencias según su categoría.

## 2. Configuración

### 2.1 Archivo de Thresholds

- `config/eval-gates.json` define todos los gates por skill y por pipeline step
- Cada gate contiene: `gateId`, `skill`, `metric`, `minScore`, `minPassRate`, `behavior`
- `behavior` puede ser `blocking` (detiene el pipeline) o `warning` (alerta sin bloquear)

### 2.2 Gates Blocking

- `minScore` por defecto: 0.7. `minPassRate` por defecto: 80%
- Skills críticos (deploy, security, auth): behavior obligatorio `blocking`
- Si un gate blocking falla: el pipeline se detiene y se registra el incidente

### 2.3 Gates Warning

- Skills auxiliares o en desarrollo (versión < 1.0) usan `warning`
- El warning se muestra en dashboard sin interrumpir el pipeline
- Tres warnings consecutivos en el mismo skill escalan a `blocking`

## 3. Integración con eval-runner.ps1

- `eval-runner.ps1` ejecuta las evaluaciones y exporta resultados
- Los gates se aplican post-evaluación mediante el flag `-EnforceGates`
- Resultados se almacenan en `.session/eval/results/<skill>/` con timestamp ISO 8601
- `eval-runner.ps1 -EnforceGates` retorna exit code 0 si todos los gates pasan, 1 si algún
  `blocking` falla, 0 con alerta si solo `warning` falla

## 4. Alertas y Escalación

- Fallo blocking → alerta en dashboard + notificación al canal de incidencias
- Fallo blocking recurrente (3+ en 1 hora) → escalación automática al orchestrator
- Fallo en skill crítico → notificación inmediata con severidad HIGH
- Todas las alertas se registran en `.session/audit/incidents/` con metadatos completos

## 5. Excepciones

- Hotfixes pueden saltar gates con `-SkipGates` y aprobación explícita
- Skills con `gateOverride: true` en eval-gates.json exentos temporalmente
- Ventana de excepción máxima: 72 horas, renovable una sola vez

## 6. Penalizaciones

- Deploy sin pasar gates blocking → rollback automático + post-mortem obligatorio
- Gates desactualizados >30 días respecto a eval-gates.json → alerta semanal
- Incumplimiento reiterado de thresholds → revisión de arquitectura
