# NORMATIVAS-SEGURIDAD.md

Version: 1.0.0
Framework: OWASP LLM Top 10 2025 + OWASP Agentic Top 10 2026

---

## 1. PROPOSITO

Define las normativas de seguridad para agentes LLM en el stack Foundation.
Toda implementacion debe cumplir estos controles o documentar desvio aprobado.

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
1. **MUST** definir perfiles de least-privilege por herramienta (scopes, max rate, egress allowlists)
2. **MUST** validar tool calls antes de ejecucion
3. **MUST** monitorear patrones de uso de herramientas
4. **MUST** mantener execution logs de tool calls para anomaly detection
5. **SHOULD** implementar circuit breakers por herramienta

### 2.8 Inter-Agent Communication Security
1. **MUST** validar y sanear comunicaciones entre agentes
2. **MUST** aislar entornos de ejecucion de agentes
3. **SHOULD** implementar circuit breakers para prevenir cascading failures
4. **SHOULD** verificar integridad de comunicaciones multi-agente

### 2.9 Observability & Incident Response
1. **MUST** trackear token usage y costos por sesion/usuario
2. **MUST** mantener audit trails de decisiones y acciones del agente
3. **MUST** configurar alertas para eventos de seguridad
4. **MUST** permitir interrumpir y rollback operaciones de agente
5. **SHOULD** implementar anomaly detection en comportamiento de agente

---

## 3. MATRIZ DE RIESGOS

| Riesgo | Severidad | Control | Frecuencia |
|--------|-----------|---------|------------|
| Prompt Injection | CRITICAL | 2.1 | Cada request |
| Excessive Agency | CRITICAL | 2.2 | Cada tool call |
| Data Leakage | HIGH | 2.3 | Cada output |
| System Prompt Leakage | HIGH | 2.4 | Cada release |
| Supply Chain | HIGH | 2.5 | Semanal |
| Memory Poisoning | HIGH | 2.6 | Cada sesion |
| Tool Misuse | CRITICAL | 2.7 | Cada tool call |
| Inter-Agent Attack | MEDIUM | 2.8 | Cada sesion |
| Observability Gap | MEDIUM | 2.9 | Continuo |

---

## 4. REFERENCIAS

- OWASP LLM Top 10 2025: genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025
- OWASP Agentic Top 10 2026: genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026
- OWASP AI Agent Security Cheat Sheet: cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html
- Config: config/security-hardening.json
