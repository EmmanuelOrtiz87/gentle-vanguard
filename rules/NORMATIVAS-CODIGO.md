# NORMATIVAS-CODIGO.md — Code Standards

Version: 1.0.0 Last updated: 2026-05-10

---

## 1. PROPOSITO

Define los estándares de código para todo el stack Gentle-Vanguard. Aplica a scripts (PowerShell,
Python, Bash), configuraciones JSON/YAML, y cualquier código generado por agentes.

---

## 2. PRINCIPIOS GENERALES

### 2.1 Single Source of Truth

1. **MUST** centralizar configuraciones en archivos JSON (no hardcode en scripts)
2. **MUST** referenciar configs canónicas (`config/auto-delegation.json`,
   `config/orchestrator.json`)
3. **MUST NOT** duplicar mappings en múltiples archivos de instrucciones
4. **SHOULD** usar `$ref` para referencias cruzadas entre configs

### 2.2 Idempotencia

1. **MUST** diseñar scripts para ejecución segura múltiples veces
2. **MUST** verificar `Test-Path` antes de `New-Item`
3. **MUST** usar `-ErrorAction SilentlyContinue` + verificación explícita
4. **MUST** evitar efectos secundarios en lecturas/validaciones

### 2.3 Determinismo

1. **MUST** validar input antes de procesar
2. **MUST** retornar mismos resultados para mismos inputs
3. **MUST NOT** depender de estado global mutable
4. **SHOULD** evitar random en lógica de negocio (solo en tests)

---

## 3. ESTRUCTURA DE ARCHIVOS

### 3.1 Organization

```
scripts/
  utilities/    # Herramientas reutilizables
  validation/   # Validación y gates
  monitoring/   # Monitoreo y telemetría
  gentle-vanguard/   # Core del framework
  hooks/        # Git hooks
  testing/      # Testing utilities
  sre/          # Site Reliability Engineering (error budgets, SLOs)
  chaos/        # Chaos Engineering experiments
  adaptive/     # Auto-scaling, backup, orchestration
  diagnostics/  # System diagnostics, validation
  security/     # Security operations, logging, encryption
  common/       # Shared helpers, platform compat
  docs/         # Documentation generators
  project/      # Project-level scripts
  reports/      # Report generators
  git-hooks/    # Git hook scripts
skills/
  <skill-name>/
    SKILL.md         # Frontmatter + descripción
    scripts/         # Scripts del skill (opcional)
    references/      # Documentos de referencia
config/
  <domain>.json       # Configuraciones por dominio
```

### 3.2 Naming Conventions

| Tipo               | Convention         | Ejemplo                                        |
| ------------------ | ------------------ | ---------------------------------------------- |
| PowerShell scripts | PascalCase-kebab   | `token-budget-guard.ps1`                       |
| PowerShell modules | PascalCase         | `AutoDelegationRouter.psm1`                    |
| Python files       | snake_case         | `validate_config.py`                           |
| JSON configs       | kebab-case         | `auto-delegation.json`                         |
| YAML workflows     | kebab-case         | `gentle-vanguard-quality-gate.yml`             |
| Markdown docs      | UPPERCASE or Title | `NORMATIVAS-CODIGO.md`, `Development-Guide.md` |
| Test files         | `<name>.tests.ps1` | `auth.tests.ps1`                               |

### 3.3 File Size Limits

| Type            | Max Lines | Action if exceeded      |
| --------------- | --------- | ----------------------- |
| Script (.ps1)   | 500       | Split into modules      |
| Config (.json)  | 200       | Split into domain files |
| Skill SKILL.md  | 150       | Split references        |
| Workflow (.yml) | 100       | Use reusable workflows  |

---

## 4. POWERSCRIPT STANDARDS

### 4.1 Required Header

```powershell
# script-name.ps1
# Description: One-line description of purpose
# Usage: .\script-name.ps1 -Param1 value -Param2 value

param(
    [Parameter(Mandatory = $true)]
    [string]$Param1,
    [Parameter(Mandatory = $false)]
    [string]$Param2 = "default",
    [switch]$Force
)
```

### 4.2 Function Standards

```powershell
function Invoke-TaskName {
    <#
    .SYNOPSIS
        One-line summary
    .DESCRIPTION
        Detailed description
    .PARAMETER Param1
        Description
    .EXAMPLE
        Invoke-TaskName -Param1 "value"
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Param1
    )

    try {
        # Logic
    }
    catch {
        Write-Error "Invoke-TaskName failed: $_"
        return $null
    }
}
```

### 4.3 Forbidden PowerShell Patterns

- `Write-Host` in reusable functions/libraries (use `Write-Output` or `Write-Verbose`); OK in CLI
  scripts, hooks, and `gv` commands for direct user output
- Empty `catch { }` blocks
- Hardcoded absolute paths
- `Select-String` (use `grep` tool via agent, or direct `-match`)
- Implicit string comparison without culture spec
- Using aliases in scripts (`gci`, `foreach`, `%`) — use full cmdlets

---

## 5. JSON CONFIG STANDARDS

### 5.1 Required Fields

```json
{
  "version": "1.0.0",
  "description": "What this config controls",
  "_comment": "Optional notes about usage or dependencies"
}
```

### 5.2 Conventions

- Keys in `camelCase`
- Use `$ref` for cross-file references (e.g., `"$ref:auto-delegation.json#/agentProfiles"`)
- Use `_comment` for inline documentation (JSON5 not supported)
- Arrays of objects for structured data
- Boolean values: `true`/`false` (not strings)
- No trailing commas

---

## 6. PYTHON STANDARDS

### 6.1 Linting

- MUST pass `ruff check .` without errors
- MUST pass `ruff format .` (formatting enforced)
- Configuration in `pyproject.toml` (single source)

### 6.2 Style

- Follow PEP 8 via Ruff
- Type hints required for function signatures
- Docstrings in Google style
- Max line length: 100 characters

---

## 7. YAML WORKFLOW STANDARDS

### 7.1 Required Fields

```yaml
name: Descriptive Name

permissions:
  contents: read

concurrency:
  group: workflow-name-${{ github.ref }}
  cancel-in-progress: true

on: ...
```

### 7.2 Scheduled Workflows

- MUST include `timeout-minutes` on every job
- MUST include timezone comment on cron lines
- MUST include concurrency control
- MUST set least-privilege permissions
- MUST NOT run on `push` to `main` without `workflow_dispatch` alternative

---

## 8. QUALITY GATES

### 8.1 Pre-Commit

| Check               | Tool                                       | Action on failure |
| ------------------- | ------------------------------------------ | ----------------- |
| JSON syntax         | `hooks/json-lint.ps1`                      | Block commit      |
| Workflow syntax     | `hooks/workflow-lint.ps1`                  | Block commit      |
| OpenCode validation | `hooks/pre-commit-opencode-validation.ps1` | Block commit      |

### 8.2 Pre-Push

| Check       | Tool                                                         | Action on failure |
| ----------- | ------------------------------------------------------------ | ----------------- |
| Auto-fix    | `scripts/hooks/orchestrate-auto-fix.ps1`                     | Fix + warn        |
| Test suite  | `scripts/run-tests-simple.ps1`                               | Block push        |
| Audit sweep | `skills/gentle-vanguard-audit-skill/scripts/audit-sweep.ps1` | Block push        |

### 8.3 CI/CD

| Gate              | Frequency | Blocks             |
| ----------------- | --------- | ------------------ |
| script-governance | Every PR  | PR to develop/main |
| workflow-lint     | Every PR  | PR to develop/main |
| quality-gate      | Every PR  | PR to develop/main |
| ps-lint           | Every PR  | PR to develop/main |
| sdd-gate          | Every PR  | PR to develop/main |
| security-scan     | Every PR  | PR to develop/main |
| format-check      | Every PR  | PR to develop/main |

---

## 9. REFERENCES

| Resource                 | Path                                 |
| ------------------------ | ------------------------------------ |
| Development Standards    | `rules/DEVELOPMENT-STANDARDS.md`     |
| AI Normatives            | `rules/AI-NORMATIVES.md`             |
| Error Handling           | `rules/NORMATIVAS-ERROR-HANDLING.md` |
| Testing Normatives       | `docs/NORMATIVAS-TESTING.md`         |
| Security Normatives      | `docs/NORMATIVAS-SEGURIDAD.md`       |
| Performance & Efficiency | `rules/NORMATIVAS-PERFORMANCE.md`    |
| Session Lifecycle        | `rules/NORMATIVAS-SESSION.md`        |
| Skill Style Guide        | `rules/SKILL-STYLE-GUIDE.md`         |
| Structure Policy         | `config/structure-policy.json`       |
| Quality Gates            | `config/quality-gates.json`          |

---

_Version: 1.0.0 — 2026-05-10 — Status: ACTIVE_
