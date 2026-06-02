# Normativa: Feedback Loop

## Propósito
Establecer el mecanismo de recolección, análisis y acción sobre el feedback del usuario para retroalimentar el sistema de autoaprendizaje.

## Reglas

### R1 — Captura explícita de feedback
Todo comando o acción que genere una propuesta de mejora, healing, o decisión autónoma relevante DEBE ofrecer al usuario la oportunidad de calificar (1-5) o comentar, ya sea al momento o al cierre de sesión.

### R2 — Persistencia estructurada
El feedback se almacena en `.session/feedback/feedback.jsonl` en formato NDJSON con campos: `timestamp`, `sessionId`, `rate` (1-5 o 0 si no califica), `action` (healing, learning, routing, code-review, digest, general), `comment`, `context`.

### R3 — Análisis post-sesión
Al cierre de cada sesión, el feedback-analyzer DEBE procesar los datos:
- Detectar acciones con rating promedio < 3 (bandera roja)
- Identificar keywords recurrentes en comentarios negativos
- Generar propuestas de mejora en `.local/improvement-proposals/`
- Sugerir nuevas normativas si el mismo patrón aparece 3+ veces

### R4 — Umbral de intervención
- Rating 1-2 en la misma categoría 2 sesiones consecutivas → Propuesta de mejora automática
- Rating 1-2 en la misma categoría 3 sesiones consecutivas → Nueva normativa sugerida
- Rating 4-5 consistente → Patrón registrado como "buena práctica" en Engram

### R5 — No bloqueante
El feedback NUNCA debe bloquear el flujo de trabajo del usuario. Es opcional, asíncrono y no intrusivo.

### R6 — Transparencia
El usuario puede consultar su historial de feedback en cualquier momento con:
`gv feedback status` — muestra total, promedio y desglose por acción.

### R7 — Integración con auto-learning
El pipeline post-session-learning DEBE consumir el archivo feedback.jsonl como fuente de datos adicional para:
- Ponderar propuestas según rating del usuario
- Priorizar categorías con feedback negativo
- Registrar tendencias en Engram como observaciones de tipo `learning`
