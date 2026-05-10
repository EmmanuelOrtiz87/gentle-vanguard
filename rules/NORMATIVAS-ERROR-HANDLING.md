# NORMATIVAS-ERROR-HANDLING.md — Error Handling Standards

Version: 1.0.0
Last updated: 2026-05-10
Framework: Centralized Error Handling Pattern + OWASP LLM06 (Excessive Agency)

---

## 1. PROPOSITO

Define el manejo de errores centralizado para todo el stack Foundation. Aplica a scripts PowerShell, Python, Bash, workflows CI/CD, y agentes AI. Garantiza que los errores se capturen, clasifiquen, registren y escalen de manera consistente.

---

## 2. CLASIFICACION DE ERRORES

### 2.1 Severity Levels

| Level | Code | Description | Action |
|-------|------|-------------|--------|
| CRITICAL | 3 | System cannot continue | Immediate notification, block pipeline |
| HIGH | 2 | Feature/component broken | Escalate, block merge |
| MEDIUM | 1 | Non-critical failure | Log, warn, continue |
| LOW | 0 | Minor issue | Log only, no action |

### 2.2 Error Categories

| Category | Example | Severity |
|----------|---------|----------|
| CONFIG | Missing config key, invalid JSON | HIGH |
| DEPENDENCY | Missing script, module not found | CRITICAL |
| SECURITY | Secret detected, auth failure | CRITICAL |
| VALIDATION | Invalid input, schema mismatch | MEDIUM |
| RUNTIME | Unexpected exception, timeout | HIGH |
| NETWORK | Connection failed, timeout | MEDIUM |
| FILESYSTEM | File not found, permission denied | HIGH |
| AGENT | Agent dispatch failed, skill not found | MEDIUM |

---

## 3. ERROR HANDLING PATTERNS

### 3.1 PowerShell

#### Try/Catch with Context
```powershell
try {
    $result = Invoke-RiskyOperation -Param $value
    if (-not $result) {
        throw "Operation returned null/empty"
    }
}
catch {
    $errorContext = @{
        Script   = $MyInvocation.MyCommand.Name
        Line     = $_.InvocationInfo.ScriptLineNumber
        Message  = $_.Exception.Message
        Category = "RUNTIME"
    }
    Write-Error ($errorContext | ConvertTo-Json -Compress)
    return $null  # or throw, depending on recoverability
}
```

#### Centralized Error Handler
```powershell
function Write-FoundationError {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $true)]
        [ValidateSet("CRITICAL", "HIGH", "MEDIUM", "LOW")]
        [string]$Severity,
        [hashtable]$Context,
        [switch]$Throw
    )

    $errorRecord = @{
        Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        Severity  = $Severity
        Message   = $Message
        Context   = $Context
        Source    = $MyInvocation.ScriptName
    }

    # Log to runtime
    $logPath = Join-Path $PSScriptRoot "..\.runtime\errors.jsonl"
    Add-Content -Path $logPath -Value (ConvertTo-Json $errorRecord -Compress)

    # Console output
    switch ($Severity) {
        "CRITICAL" { Write-Host "[$Severity] $Message" -ForegroundColor Red }
        "HIGH"     { Write-Host "[$Severity] $Message" -ForegroundColor Yellow }
        "MEDIUM"   { Write-Host "[$Severity] $Message" -ForegroundColor Cyan }
        "LOW"      { Write-Verbose "[$Severity] $Message" }
    }

    if ($Throw) { throw $Message }
}
```

### 3.2 Python

```python
import logging
from enum import Enum
from typing import Optional

class ErrorSeverity(Enum):
    CRITICAL = 3
    HIGH = 2
    MEDIUM = 1
    LOW = 0

class FoundationError(Exception):
    def __init__(self, message: str, severity: ErrorSeverity, context: Optional[dict] = None):
        self.severity = severity
        self.context = context or {}
        super().__init__(message)

def handle_error(message: str, severity: ErrorSeverity, context: Optional[dict] = None, should_raise: bool = False):
    error_record = {
        "message": message,
        "severity": severity.value,
        "context": context or {},
    }
    logging.error(f"[{severity.name}] {message}")
    if should_raise:
        raise FoundationError(message, severity, context)
```

---

## 4. ERROR RECOVERY STRATEGIES

### 4.1 Recoverable Errors

| Strategy | When | Implementation |
|----------|------|----------------|
| Retry | Transient failures (network, timeout) | Max 3 retries, exponential backoff |
| Fallback | Missing optional dependency | Try alternative path or default value |
| Degrade | Non-critical component failure | Continue with reduced functionality |
| Cache | Data source unavailable | Serve stale cache, log warning |

### 4.2 Non-Recoverable Errors

| Strategy | When | Implementation |
|----------|------|----------------|
| Fail-fast | Config error, security violation | Stop immediately, report with full context |
| Graceful shutdown | CRITICAL system error | Save state, notify, exit cleanly |
| Escalate | Unknown/unexpected error | Route to orchestrator/GOV for evaluation |

---

## 5. AGENT ERROR HANDLING

### 5.1 Agent Dispatch Failures

| Failure | Action |
|---------|--------|
| Skill not found | `"Trigger detected for [skill]. Requires @orchestrator."` — DO NOT invent paths |
| Agent timeout | Return fallback: clarify with user or use default agent |
| Hallucination detected | Re-run with lower temperature, escalate if persistent |
| Evidence missing | Block completion until evidence collected per `requiredEvidence` |
| Circuit breaker open | Wait for recovery or escalate to orchestrator |

### 5.2 Escalation Path

```
Error Detected
  -> Agent retry (maxRetries from agent profile)
  -> escalateOnFailure (defined in agent profile)
  -> Orchestrator review
  -> Human intervention (if CRITICAL)
```

### 5.3 Agent Error Logging

```powershell
# MUST log errors with this structure:
$agentError = @{
    AgentId    = $agentCode       # e.g., "DEV", "QA"
    Skill      = $skillName       # e.g., "react-19-skill"
    Task       = $taskDescription
    Error      = $error.Message
    RetryCount = $retryCount
    Timestamp  = (Get-Date -Format "o")
}
```

---

## 6. CI/CD ERROR HANDLING

### 6.1 Pipeline Failures

| Stage | Error | Action |
|-------|-------|--------|
| Lint | Syntax error | Block commit/PR, report file + line |
| Test | Test failure | Block PR, report failed test name |
| Security | Secret detected | Block PR, trigger security alert |
| Quality Gate | Gate not passed | Block PR, report gate name + reason |
| Deploy | Deploy failure | Rollback to previous version, notify OPS |

### 6.2 Workflow Error Handling

```yaml
steps:
  - name: Validate
    shell: pwsh
    continue-on-error: false  # CRITICAL: don't swallow failures
    run: |
      try {
        ./validate.ps1
      }
      catch {
        Write-Error "Validation failed: $_"
        exit 1
      }
```

---

## 7. ERROR LOGGING STANDARDS

### 7.1 Log Format (JSON Lines)

```json
{"timestamp":"2026-05-10T10:00:00Z","severity":"HIGH","message":"Config file not found","context":{"path":"config/missing.json","expected":true},"source":"validate-configs.ps1"}
```

### 7.2 Log Locations

| Type | Path | Retention |
|------|------|-----------|
| Runtime errors | `.runtime/errors.jsonl` | 30 days |
| Security auth | `.runtime/security-auth-audit.log` | 90 days |
| Override audit | `.logs/override-audit.jsonl` | 30 days |
| CI/CD logs | GitHub Actions artifacts | 14 days |

### 7.3 DO NOT Log

- API keys, tokens, passwords (always `<REDACTED>`)
- PII (personally identifiable information)
- Full system prompts
- User session tokens

---

## 8. COMPLIANCE CHECKPOINTS

TODO implementación DEBE verificar:

1. Every `catch` block has meaningful error handling (not empty)
2. Every script has `try/catch` at entry point
3. Every external call has timeout handling
4. Every config read has fallback or explicit error
5. Every agent dispatch has retry logic
6. CRITICAL errors always escalate to a human or orchestrator
7. No secrets in error messages or logs

---

## 9. REFERENCES

| Resource | Path |
|----------|------|
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Code Standards | `rules/NORMATIVAS-CODIGO.md` |
| AI Normatives | `rules/AI-NORMATIVES.md` |
| Performance & Efficiency | `rules/NORMATIVAS-PERFORMANCE.md` |
| Session Lifecycle | `rules/NORMATIVAS-SESSION.md` |
| Security Normatives | `docs/NORMATIVAS-SEGURIDAD.md` |
| Agent Profiles | `config/auto-delegation.json#agentProfiles` |
| Orchestrator Config | `config/orchestrator.json` |
| Quality Gates | `config/quality-gates.json` |

---

_Version: 1.0.0 — 2026-05-10 — Status: ACTIVE_
