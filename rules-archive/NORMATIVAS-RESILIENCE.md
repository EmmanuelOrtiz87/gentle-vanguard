# Resilience & Recovery Normativa

**Version:** 1.0.0 **Last updated:** 2026-06-04 **Status:** ACTIVE

---

## 1. Purpose

Define how the stack handles failures, timeouts, and degraded states. Every component MUST have a
defined fallback behavior — no operation should hang forever without user notification or recovery
path.

---

## 2. Resilience Patterns

### 2.1 Retry with Backoff

Operations that fail transiently MUST retry with exponential backoff:

| Component          | Max Retries | Delay | Backoff | Timeout |
| ------------------ | ----------- | ----- | ------- | ------- |
| Engram operations  | 3           | 500ms | 1.5x    | 15s     |
| Git operations     | 2           | 2s    | 2x      | 30s     |
| File locking       | 3           | 200ms | 1x      | 5s      |
| External API calls | 3           | 1s    | 2x      | 30s     |

### 2.2 Timeout Enforcement

Every operation MUST have a timeout. No unbounded waits:

| Component            | Timeout | Fallback      |
| -------------------- | ------- | ------------- |
| Agent verify (quick) | 30s     | warn_skip     |
| Agent verify (full)  | 120s    | notify_user   |
| PSScriptAnalyzer     | 120s    | warn_skip     |
| Normative audit      | 60s     | warn_continue |
| Pester tests         | 120s    | notify_user   |
| Engram search        | 15s     | warn_continue |

### 2.3 Circuit Breaker

When a component fails repeatedly, open the circuit to prevent cascading failures:

| Circuit    | Threshold  | Reset | Half-Open Probes |
| ---------- | ---------- | ----- | ---------------- |
| Engram     | 3 failures | 120s  | 1                |
| Git remote | 5 failures | 300s  | 2                |

States: `closed` (normal) -> `open` (failing, skip) -> `half-open` (probe) -> `closed` (recovered).

### 2.4 User Notification

When `notify_user` fallback triggers, show a standardized notification:

```
============================================
  [STACK] Error en: <operation>
============================================
  Detalle: <error message>
  Intentos: <N>
  Timeout: <N>s

  Sugerencias: Reintentar, Omitir, Continuar
============================================
```

---

## 3. Fallback Actions

| Action          | Behavior                           | When to Use                                    |
| --------------- | ---------------------------------- | ---------------------------------------------- |
| `notify_user`   | Show notification with suggestions | User-initiated operations, critical components |
| `warn_skip`     | Log warning and skip step          | Non-critical validations, analysis tools       |
| `warn_continue` | Log warning and continue           | Audits, background checks                      |
| `throw`         | Crash with error                   | Pre/post conditions, safety checks             |

---

## 4. Implementation

### 4.1 Central Handler

`scripts/utilities/resilience-handler.ps1` — the single entry point for all resilience operations.
Parameters:

| Parameter            | Default         | Description                    |
| -------------------- | --------------- | ------------------------------ |
| `ScriptBlock`        | required        | Command to execute             |
| `TimeoutSeconds`     | 30              | Max execution time             |
| `RetryAttempts`      | 3               | Number of retries              |
| `RetryDelayMs`       | 1000            | Base delay between retries     |
| `OperationName`      | 'unknown'       | Name for logging/notifications |
| `FallbackAction`     | 'warn_continue' | Behavior on final failure      |
| `CircuitBreakerName` | ''              | Circuit breaker tracking name  |

### 4.2 Central Configuration

`config/resilience-config.json` — all timeouts, retries, circuit breaker settings. Single source of
truth for resilience parameters.

### 4.3 Usage Example

```powershell
& scripts/utilities/resilience-handler.ps1 `
    -ScriptBlock { & scripts/utilities/AGENT/agent-verify.ps1 -Quick } `
    -TimeoutSeconds 120 `
    -OperationName "agent-verify" `
    -FallbackAction notify_user `
    -CircuitBreakerName "agent_verify"
```

---

## 5. Integration Points

### 5.1 pre-process-input.ps1

Every-turn operations that could hang:

- Tool detection: wrap with 15s timeout, `warn_continue` fallback
- Cache read/write: wrap with 5s timeout
- Session turn counter: no wrap (local file, fast)

### 5.2 .lefthook.yml (pre-commit)

- normative-audit: wrap with 60s timeout, `warn_continue` fallback
- karpathy-enforcer: wrap with 30s timeout, `warn_skip` fallback
- secretlint/format-check: wrap with 30s timeout, `warn_continue` fallback

### 5.3 agent-verify.ps1

Full mode (Invoke-Pester): wrap with 120s timeout, `notify_user` fallback.

---

## 6. Recovery Paths

| Situation              | Recovery                                             |
| ---------------------- | ---------------------------------------------------- |
| Script timeout         | Retry with more time, or skip                        |
| Component crash        | Fallback to alternative, or notify user              |
| Circuit breaker open   | Wait and retry, or use offline mode                  |
| Engram unavailable     | Proceed with degraded experience (no memory context) |
| Git remote unavailable | Proceed with local operations only                   |

---

## 7. Monitoring

All resilience events are logged to `.session/resilience-events.jsonl`:

```json
{
  "timestamp": "...",
  "operation": "agent-verify",
  "attempt": 3,
  "result": "timeout",
  "fallback": "notify_user"
}
```

Circuit breaker state files are stored in `.session/circuit-breakers/<name>.json`.

---

_Version: 1.0.0 — 2026-06-04 — Status: ACTIVE_
