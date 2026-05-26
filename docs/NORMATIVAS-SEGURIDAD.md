# NORMATIVAS-SEGURIDAD.md

Version: 1.2.0 — 2026-05-24 Framework: OWASP LLM Top 10 2025 + OWASP Agentic Top 10 2026

> Cambios v1.1.0 → v1.2.0:
>
> - Se agregó control 2.11 (Prompt Injection & Jailbreak Detection): `privacy-gateway.ps1`
> - Se expandieron patrones críticos en `security-orchestrator.ps1` (jailbreak, leakage, code
>   execution)
> - Se actualizó `config/security-privacy.json` con `injectionBlock` patterns
> - Se corrigieron 13 vulnerabilidades de seguridad (null refs, CSPRNG, env fallback, $lock typo)
>
> Cambios v1.0.0 → v1.1.0:
>
> - Se actualizaron implementaciones de control 2.3 (PII redaction): `security-logger.ps1` v1.1
> - Se actualizó control 2.6 (secrets management): `secrets-manager.ps1` v2.0 con DPAPI vault
> - Se corrigió `input-validator.ps1` (syntax error Validate-Integer)
> - Se agregaron tests Pester en `tests/security/` para cobertura de controles

---

## 1. PROPOSITO

Define las normativas de seguridad para agentes LLM en el stack Gentle-Vanguard. Toda implementacion
debe cumplir estos controles o documentar desvio aprobado.

---

## 2. CONTROLES OBLIGATORIOS (BLOCKING)

### 2.1 Prompt Injection Prevention (OWASP LLM01)

1. **MUST** tratar todo input externo (usuario, documentos, API responses) como no confiable
2. **MUST** aplicar sanitizacion antes de incluir contenido externo en contexto del agente
3. **MUST** usar delimitadores claros entre instrucciones y datos en system prompts
4. **SHOULD** usar llamadas LLM separadas para validar/resumir contenido no confiable
5. **SHOULD** implementar content filtering para patrones de injection conocidos

### 2.2 Excessive Agency Prevention (OWASP LLM06 + ASI02)

1. **MUST** conceder a los agentes SOLO las herramientas minimas necesarias (Least Privilege)
2. **MUST** implementar scoping de permisos por herramienta (read-only vs write)
3. **MUST** require human-in-the-loop para acciones de alto impacto
4. **MUST** definir tool sets separados por nivel de confianza
5. **MUST** implementar rate limiting por herramienta
6. **SHOULD** registrar y auditar todas las tool calls

### 2.3 Sensitive Information Disclosure Prevention (OWASP LLM02)

1. **MUST** no loguear secrets, API keys, tokens (solo referencias)
2. **MUST** redactar PII en logs y traces antes de persistir
3. **MUST** implementar output filtering para data leakage
4. **MUST** clasificar datos y aplicar protecciones segun nivel
5. **SHOULD** usar output validation con schema validation antes de mostrar al usuario

### 2.4 System Prompt Leakage Prevention (OWASP LLM07)

1. **MUST NOT** considerar system prompts como secretos
2. **MUST** separar informacion sensible de las instrucciones del system prompt
3. **SHOULD** auditar system prompts periodicamente

### 2.5 Supply Chain Security (OWASP LLM03)

1. **MUST** mantener SBOM actualizado de todas las dependencias
2. **MUST** escanear dependencias con Trivy en cada PR a main
3. **MUST** escanear secrets con gitleaks en cada push
4. **MUST** firmar commits para contribuciones asistidas por IA
5. **SHOULD** mantener dependencias actualizadas (< 30 dias de desvio)

### 2.6 Data & Model Poisoning Prevention (OWASP LLM04)

1. **MUST** validar y sanear datos antes de almacenar en memoria de agente
2. **MUST** implementar isolation de memoria entre usuarios/sesiones
3. **MUST** establecer memory expiration y size limits
4. **SHOULD** auditar contenido de memoria antes de persistencia

### 2.7 Tool Misuse & Privilege Escalation Prevention (ASI02)

1. **MUST** definir perfiles de least-privilege por herramienta (scopes, max rate, egress
   allowlists)
2. **MUST** validar tool calls antes de ejecucion
3. **MUST** monitorear patrones de uso de herramientas
4. **MUST** mantener execution logs de tool calls para anomaly detection
5. **SHOULD** implementar circuit breakers por herramienta

### 2.8 Inter-Agent Communication Security

1. **MUST** validar y sanear comunicaciones entre agentes
2. **MUST** aislar entornos de ejecucion de agentes
3. **SHOULD** implementar circuit breakers para prevenir cascading failures
4. **SHOULD** verificar integridad de comunicaciones multi-agente

### 2.9 Cross-Agent Communication Security (ASI03)

1. **MUST** sanitize ALL data received FROM other agents via `pre-process-input.ps1 -FromAgent`
2. **MUST** validate inter-agent payloads for critical patterns before processing
3. **MUST** tag inter-agent communication with `SOURCE: AGENT` marker for auditability
4. **MUST** block critical secrets (API keys, private keys) in cross-agent data
5. **SHOULD** log inter-agent data flow for anomaly detection
6. **SHOULD** implement circuit breaker when an agent produces repeated blocked patterns

### 2.10 Observability & Incident Response

1. **MUST** trackear token usage y costos por sesion/usuario
2. **MUST** mantener audit trails de decisiones y acciones del agente
3. **MUST** configurar alertas para eventos de seguridad
4. **MUST** permitir interrumpir y rollback operaciones de agente
5. **SHOULD** implementar anomaly detection en comportamiento de agente

### 2.11 Prompt Injection & Jailbreak Detection (OWASP LLM01 + ASI01)

1. **MUST** detect and BLOCK instruction override attempts en todo input de usuario antes de pasarlo
   al agente
2. **MUST** detectar intentos de jailbreak conocidos (DAN, unrestricted mode, developer mode)
3. **MUST** detectar intentos de extraccion de system prompt (prompt leakage)
4. **MUST** detectar intentos de code execution via el agente (exec, eval, shell, spawn)
5. **MUST** detectar intentos de role takeover y simulation attacks
6. **MUST** detectar encoding obfuscation (base64, hex, rot, unicode escape) usado para bypass
7. **MUST** detectar constraint bypass (forget instructions, disregard safeguards, override
   protocols)
8. **MUST** bloquear con exit code 1 y loguear el evento de seguridad
9. **SHOULD** permitir safe content sin falsos positivos
10. **SHOULD** auditar patrones de intentos de inyeccion por sesion

**Implementacion:**

- `scripts/security/privacy-gateway.ps1` — 10 patrones de deteccion en `$INJECTION_PATTERNS`
- `scripts/security/security-orchestrator.ps1` — 5 patrones en `$CRITICAL_PATTERNS`
- `config/security-privacy.json` — 7 patrones en `privacy.injectionBlock[]`
- Verificado con tests Pester en `tests/security/security-checks.tests.ps1` (7 tests)

---

## 3. MATRIZ DE RIESGOS

| Riesgo                     | Severidad | Control | Frecuencia                     |
| -------------------------- | --------- | ------- | ------------------------------ |
| Prompt Injection           | CRITICAL  | 2.1     | Cada request                   |
| Excessive Agency           | CRITICAL  | 2.2     | Cada tool call                 |
| Data Leakage               | HIGH      | 2.3     | Cada output                    |
| System Prompt Leakage      | HIGH      | 2.4     | Cada release                   |
| Supply Chain               | HIGH      | 2.5     | Semanal                        |
| Memory Poisoning           | HIGH      | 2.6     | Cada sesion                    |
| Tool Misuse                | CRITICAL  | 2.7     | Cada tool call                 |
| Inter-Agent Attack         | HIGH      | 2.8     | Cada sesion                    |
| Cross-Agent Data Poisoning | HIGH      | 2.9     | Cada interaccion entre agentes |
| Observability Gap          | MEDIUM    | 2.10    | Continuo                       |

---

## 4. REFERENCIAS

- OWASP LLM Top 10 2025: genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025
- OWASP Agentic Top 10 2026: genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026
- OWASP AI Agent Security Cheat Sheet:
  cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html
- ISO/IEC 27001 Controls Mapping: `docs/NORMATIVAS-ISO27001.md`
- ISO/IEC 25010 Quality Mapping: `docs/NORMATIVAS-ISO25010.md`
- SBOM Validation: `docs/NORMATIVAS-SBOM.md`
- Config: `config/security-hardening.json`
- Security Policy: `config/security-policy.json`
- Security Privacy: `config/security-privacy.json`
