# NORMATIVAS-AI-SAFETY.md — Responsible AI & Safety Standards

**Version:** 1.0.0 **Last updated:** 2026-06-01

---

## 1. PROPOSITO

Define estándares de AI Safety, alineación, y uso responsable de modelos de lenguaje en el stack
Gentle-Vanguard. Aplica a todos los agentes, skills, y sistemas que usen LLMs.

---

## 2. PRINCIPIOS DE AI SAFETY (OWASP LLM Top 10 + NIST AI RMF)

| Principio            | Descripción                                 | Enforced by                |
| -------------------- | ------------------------------------------- | -------------------------- |
| **Beneficencia**     | AI debe beneficiar al usuario, nunca dañar  | `hallucinationGuardLevels` |
| **No Maleficencia**  | Prevenir usos maliciosos, jailbreaks        | `security-policy.json`     |
| **Autonomía Humana** | Usuario siempre tiene control y supervisión | `escalationPath`           |
| **Justicia**         | Sin sesgos, discriminación, o exclusión     | Prompt audits              |
| **Explicabilidad**   | Outputs deben ser trazables y explicables   | `requiredEvidence`         |

### 2.1 OWASP LLM Top 10 Compliance

| #     | Riesgo                   | Mitigación Gentle-Vanguard                                                      |
| ----- | ------------------------ | ------------------------------------------------------------------------------- |
| LLM01 | Prompt Injection         | `pre-process-input.ps1` sanitiza input; `security-policy.json` bloquea patrones |
| LLM02 | Insecure Output Handling | `hallucinationGuardLevels: critical` para QA/OPS/GOV                            |
| LLM03 | Training Data Poisoning  | No se hace fine-tuning; usar modelos confiables (OpenRouter, Anthropic)         |
| LLM04 | Model Denial of Service  | `token-guard.ps1` limita tokens/agente; `circuit-breaker.json` protege          |
| LLM05 | Supply Chain             | Modelos vía OpenRouter/Anthropic con reputación verificada                      |
| LLM06 | Excessive Agency         | Permisos granulares en `opencode.json#permission`                               |
| LLM07 | Insecure Plugin Design   | Skills validados por `validate-configs.ps1`                                     |
| LLM08 | Excessive Permissions    | Least-privilege: websearch DENY por defecto                                     |
| LLM09 | Over-reliance            | Outputs marcados como AI-generated; hedging language bloqueado                  |
| LLM10 | Model Theft              | `config/secrets-governance.json` protege API keys                               |

---

## 3. HALLUCINATION GUARD

### 3.1 Guard Levels

| Level      | Verification                                | Agents              |
| ---------- | ------------------------------------------- | ------------------- |
| `low`      | Auto-reporte, sin verificación externa      | SESSION, MKT, SALES |
| `medium`   | Spot-check: al menos 1 `requiredEvidence`   | DOC, FINANCE        |
| `high`     | Full check: TODOS los `requiredEvidence`    | DEV, BA/SAD         |
| `critical` | Full check + hedging scan + comando externo | QA, OPS, GOV, LEGAL |

### 3.2 Hedging Language Detection

Palabras/frases bloqueadas en outputs de QA/OPS/GOV:

- "podría", "tal vez", "probablemente" (ES)
- "maybe", "perhaps", "probably", "might", "could" (EN)
- "talvez", "provavelmente" (PT-BR)

Agentes CRITICAL MUST pasar `hallucination-guard.ps1` antes de entregar output.

---

## 4. PROMPT INJECTION PREVENTION

### 4.1 Input Sanitization Pipeline

```
User Input
  → pre-process-input.ps1 (normaliza, cachea)
  → security-policy.json#blockedPatterns (regex match)
  → prompt-injection-detect.ps1 (OWASP LLM01 patterns)
  → IF detected → "Input blocked: potential prompt injection"
  → ELSE → proceed to agent routing
```

### 4.2 System Prompt Integrity

- System prompts MUST ser inmutables durante la sesión
- User messages NO pueden modificar system prompts
- Separación estricta: system prompt / user message / tool output

---

## 5. EXPLICABILIDAD Y TRAZABILIDAD

Todo output de AI MUST incluir metadatos de trazabilidad:

```json
{
  "output": "...",
  "trace": {
    "agent": "DEV",
    "model": "qwen-3.6-plus",
    "temperature": 0.15,
    "evidence": ["file:line", "config:key"],
    "timestamp": "2026-06-01T10:00:00Z"
  }
}
```

### 5.1 Evidence Collection

Agentes MUST recolectar `requiredEvidence` antes de marcar tarea completa:

| Agent | Required Evidence             |
| ----- | ----------------------------- |
| DEV   | Test results, lint output     |
| QA    | Test results, coverage report |
| OPS   | Deployment logs, health check |
| GOV   | Policy checks, audit trail    |

---

## 6. SESGO Y JUSTICIA

### 6.1 Bias Detection Prompts

NO permitido en outputs:

- Generalizaciones basadas en género, raza, religión, nacionalidad
- Lenguaje excluyente o discriminatorio
- Suposiciones sobre capacidades del usuario

### 6.2 Inclusive Language

- Usar "they/them" cuando el género es desconocido (EN)
- Usar "usuario" / "persona" neutro (ES)
- Evitar términos técnicos innecesarios que excluyan a no-expertos

---

## 7. HUMAN-IN-THE-LOOP

| Acción                          | Requiere aprobación humana |
| ------------------------------- | -------------------------- |
| Deploy a producción             | SI                         |
| Modificar permisos de seguridad | SI                         |
| Ejecutar comandos destructivos  | SI                         |
| Acceder a secrets               | SI (MFA)                   |
| Modificar normativas            | SI                         |
| Generar código >400 líneas      | Review Workload Guard      |
| Commit sin hooks                | SI (GOV auth)              |

---

## 8. COMPLIANCE CHECKPOINTS

- [ ] Hallucination guard configurado por agente
- [ ] Prompt injection detection activo
- [ ] Hedging language scan en outputs CRITICAL
- [ ] Evidence collection antes de completar tareas
- [ ] Human-in-the-loop para acciones destructivas
- [ ] Bias scan en outputs generados
- [ ] System prompts inmutables
- [ ] Trazabilidad en todos los outputs

---

## 9. REFERENCES

| Resource            | Path                                                   |
| ------------------- | ------------------------------------------------------ |
| OWASP LLM Top 10    | `docs/NORMATIVAS-SEGURIDAD.md`                         |
| Hallucination Guard | `config/auto-delegation.json#hallucinationGuardLevels` |
| Security Policy     | `config/security-policy.json`                          |
| AI Normatives       | `rules/AI-NORMATIVES.md`                               |
| Error Handling      | `rules/NORMATIVAS-ERROR-HANDLING.md`                   |
| NIST AI RMF         | https://www.nist.gov/ai-rmf                            |

---

_Version: 1.0.0 — 2026-06-01 — Status: ACTIVE_
