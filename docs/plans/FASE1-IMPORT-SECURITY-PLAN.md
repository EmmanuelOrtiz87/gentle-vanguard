# Fase 1 — Importación de Skills + Pipeline de Seguridad

## Objetivo
Incorporar ~20 skills metodológicas de mercury-agent-skills al stack GV y establecer un pipeline de seguridad con skillspector para vetar skills externas.

---

## Parte A — Importación de Skills (mercury-agent-skills)

### Skills identificadas para importar (20)

| # | Skill | Categoría | Gap en GV |
|---|-------|-----------|-----------|
| 1 | Prompt Engineering | AI/ML | No tenemos skill formal de ingeniería de prompts |
| 2 | Agent Design | AI/ML | No tenemos patrones de diseño de agentes |
| 3 | Memory Management | AI/ML | Estrategias de memoria para agentes |
| 4 | Token Budget Tracking | AI/ML | Gestión de presupuesto de tokens |
| 5 | Agent Audit Logging | AI/ML | Auditoría de acciones de agentes |
| 6 | Security Audit | Security | Auditoría formal de seguridad |
| 7 | Threat Modeling | Security | Modelado de amenazas (complementa security-skill) |
| 8 | Clean Code | Development | Estándares de código limpio |
| 9 | ADRs | Development | Architecture Decision Records |
| 10 | Testing Strategies | Testing & QA | Estrategia de testing integral |
| 11 | E2E Testing | Testing & QA | Testing end-to-end (complementa playwright-skill) |
| 12 | API Testing | Testing & QA | Testing de APIs específico |
| 13 | Accessibility Testing | Testing & QA | Testing de accesibilidad |
| 14 | Observability | DevOps | Monitoreo y observabilidad (complementa observability-skill) |
| 15 | GitOps | DevOps | GitOps workflows |
| 16 | Shell Scripting | Automation | Scripting shell avanzado |
| 17 | Design Thinking | Design | Design Thinking para fase BA |
| 18 | Accessibility | Design | Pautas de accesibilidad (WCAG) |
| 19 | Data Storytelling | Presentation | Narrativa de datos para reporting |
| 20 | SQL Optimization | Data | Optimización de consultas SQL |

### Proceso de importación
1. Clonar repo mercury-agent-skills → `tmp/mercury-skills/`
2. Ejecutar skillspector sobre cada skill candidata
3. Traducir frontmatter al formato GV (ajustar `name:`, `description:`, triggers)
4. Copiar a `skills/<category>/` con naming GV (`prompt-engineering-skill/`, `clean-code-skill/`, etc.)
5. Registrar en `skills/SKILL_INDEX.md`
6. Registrar en `config/auto-delegation.json` (triggers de activación)
7. Commit por lote de 5 skills

### Formato destino
```yaml
---
name: prompt-engineering-skill
description: >
  Prompt engineering patterns: few-shot, chain-of-thought, system prompts, structured output.
  Trigger: "prompt engineering", "prompt design", "system prompt", "few-shot", "chain of thought".
---
```

---

## Parte B — Integración de skillspector

### Componentes
1. **Wrapper PowerShell** (`scripts/security/scan-skill.ps1`) — wrapper sobre skillspector CLI
2. **Integración pre-commit** (`.lefthook.yml`) — scan automático en pre-commit sobre skills/
3. **Integración CI** (`.github/workflows/skill-scan.yml`) — scan en PRs que modifican skills/
4. **Batch scan** (`scripts/security/scan-all-skills.ps1`) — scan de todas las skills existentes

### Pipeline
```
skillspector scan <skill-dir> --format json
  → risk_score (0-100)
  → findings[]
  → severity (LOW/MEDIUM/HIGH/CRITICAL)
  → FAIL if score > 50
```

### Configuración
- Python 3.12+ (aislado con `uv` o venv)
- Modo `--no-llm` para CI (sin dependencia de LLM)
- Modo `--llm` opcional para análisis semántico local
- Output SARIF para integración con GitHub Advanced Security

### Thresholds
| Score | Etiqueta | Acción |
|-------|----------|--------|
| 0-20 | SAFE | Import permitido |
| 21-50 | CAUTION | Revisión manual requerida |
| 51-80 | HIGH | No importar sin aprobación |
| 81-100 | CRITICAL | Bloqueado |

### Skills existentes a escanear (137)
```powershell
scripts/security/scan-all-skills.ps1 -OutputDir reports/skill-security/
```
Esto produce un reporte consolidado de todas las skills actuales.

---

## Cronograma Estimado

| Paso | Duración | Dependencias |
|------|----------|-------------|
| A1: Setup skillspector (venv + wrapper) | 1h | — |
| A2: Scan skills existentes (batch) | 30min | A1 |
| B1: Importar skills lote 1 (1-5) | 1h | A2 |
| B2: Importar skills lote 2 (6-10) | 1h | — |
| B3: Importar skills lote 3 (11-15) | 1h | — |
| B4: Importar skills lote 4 (16-20) | 1h | — |
| C1: Pre-commit hook + CI workflow | 30min | A1 |
| C2: Registrar en SKILL_INDEX + auto-delegation | 30min | B1-B4 |
| D1: Reporte final + validación | 30min | C1-C2 |

**Total estimado: ~7h**

---

## Riesgos y Mitigaciones

| Riesgo | Mitigación |
|--------|-----------|
| skillspector requiere Python 3.12+ no instalado | Usar `uv` para runtime aislado |
| Skills de mercury con formato incompatible | Estandarización vía script de transformación |
| Duplicación con skills existentes | Mapping previo + review manual |
| Falsos positivos en skillspector | Thresholds conservadores + review override |
